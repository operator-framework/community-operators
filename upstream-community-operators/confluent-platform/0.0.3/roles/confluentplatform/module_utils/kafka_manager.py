import time
import json
import itertools

from kafka.client import KafkaClient
from kazoo.client import KazooClient

from kafka.protocol.admin import (
    CreatePartitionsResponse_v0,
    CreateTopicsRequest_v0,
    DeleteTopicsRequest_v0,
    CreateAclsRequest_v0,
    CreateAclsRequest_v1,
    DeleteAclsRequest_v0,
    DescribeAclsRequest_v0,
    DescribeAclsRequest_v1)

from kafka.protocol.api import Request, Response
from kafka.protocol.metadata import MetadataRequest_v1
from kafka.protocol.types import (
    Array, Boolean, Int8, Int16, Int32, Schema, String
)

import kafka.errors
from kafka.errors import IllegalArgumentError
from pkg_resources import parse_version

from ansible.module_utils.acl_operation import ACLOperation
from ansible.module_utils.acl_permission_type import ACLPermissionType


class UndefinedController(Exception):
    pass


class ReassignPartitionsTimeout(Exception):
    """
    Raised when the reassignment znode is still present after all retries
    """
    pass


# KAFKA PROTOCOL RESPONSES DEFINITION
class DescribeConfigsResponse_v0(Response):
    """
    DescribeConfigs version 0 from Kafka protocol
    Response serialization
    """
    API_KEY = 32
    API_VERSION = 0
    SCHEMA = Schema(
        ('throttle_time_ms', Int32),
        ('resources', Array(
            ('error_code', Int16),
            ('error_message', String('utf-8')),
            ('resource_type', Int8),
            ('resource_name', String('utf-8')),
            ('config_entries', Array(
                ('config_name', String('utf-8')),
                ('config_value', String('utf-8')),
                ('read_only', Boolean),
                ('is_default', Boolean),
                ('is_sensitive', Boolean)))))
    )


class AlterConfigsResponse_v0(Response):
    """
    AlterConfigs version 0 from Kafka protocol
    Response serialization
    """
    API_KEY = 33
    API_VERSION = 0
    SCHEMA = Schema(
        ('throttle_time_ms', Int32),
        ('resources', Array(
            ('error_code', Int16),
            ('error_message', String('utf-8')),
            ('resource_type', Int8),
            ('resource_name', String('utf-8'))))
    )


# KAFKA PROTOCOL REQUESTS DEFINITION
class DescribeConfigsRequest_v0(Request):
    """
    DescribeConfigs version 0 from Kafka protocol
    Request serialization
    """
    API_KEY = 32
    API_VERSION = 0
    RESPONSE_TYPE = DescribeConfigsResponse_v0
    SCHEMA = Schema(
        ('resources', Array(
            ('resource_type', Int8),
            ('resource_name', String('utf-8')),
            ('config_names', Array(String('utf-8')))))
    )


class CreatePartitionsRequest_v0(Request):
    """
    CreatePartitionsRequest version 0 from Kafka protocol
    Request serialization
    kafka-python's class is wrong (fixed in 1.4.3)
    """
    API_KEY = 37
    API_VERSION = 0
    RESPONSE_TYPE = CreatePartitionsResponse_v0
    SCHEMA = Schema(
        ('topic_partitions', Array(
            ('topic', String('utf-8')),
            ('new_partitions', Schema(
                ('count', Int32),
                ('assignment', Array(Array(Int32))))))),
        ('timeout', Int32),
        ('validate_only', Boolean)
    )


class AlterConfigsRequest_v0(Request):
    """
    AlterConfigs version 0 from Kafka protocol
    Request serialization
    """
    API_KEY = 33
    API_VERSION = 0
    RESPONSE_TYPE = AlterConfigsResponse_v0
    SCHEMA = Schema(
        ('resources', Array(
            ('resource_type', Int8),
            ('resource_name', String('utf-8')),
            ('config_entries', Array(
                ('config_name', String('utf-8')),
                ('config_value', String('utf-8')))))),
        ('validate_only', Boolean)
    )


class KafkaManager:
    """
    A class used to interact with Kafka and Zookeeper
    and easily retrive useful information
    """

    MAX_RETRY = 10
    MAX_POLL_RETRIES = 3
    MAX_ZK_RETRIES = 5
    TOPIC_RESOURCE_ID = 2
    DEFAULT_TIMEOUT = 15000
    SUCCESS_CODE = 0
    ZK_REASSIGN_NODE = '/admin/reassign_partitions'
    ZK_TOPIC_PARTITION_NODE = '/brokers/topics/'
    ZK_TOPIC_CONFIGURATION_NODE = '/config/topics/'

    # Not used yet.
    ZK_TOPIC_DELETION_NODE = '/admin/delete_topics/'

    def __init__(self, module, **configs):
        self.module = module
        self.zk_client = None
        self.client = KafkaClient(**configs)

    def init_zk_client(self, **configs):
        """
        Zookeeper client initialization
        """
        self.zk_client = KazooClient(**configs)
        self.zk_client.start()

    def close_zk_client(self):
        """
        Closes Zookeeper client
        """
        self.zk_client.stop()

    def close(self):
        """
        Closes Kafka client
        """
        self.client.close()

    def refresh(self):
        """
        Refresh topics state
        """
        fut = self.client.cluster.request_update()
        self.client.poll(future=fut)
        if not fut.succeeded():
            self.close()
            self.module.fail_json(
                msg='Error while updating topic state from Kafka server: %s.'
                % fut.exception
            )

    def create_topic(self, name, partitions, replica_factor,
                     replica_assignment=[], config_entries=[],
                     timeout=None):
        """
        Creates a topic
        Usable for Kafka version >= 0.10.1
        """
        if timeout is None:
            timeout = self.DEFAULT_TIMEOUT
        request = CreateTopicsRequest_v0(
            create_topic_requests=[(
                name, partitions, replica_factor, replica_assignment,
                config_entries
            )],
            timeout=timeout
        )
        response = self.send_request_and_get_response(request)

        for topic, error_code in response.topic_error_codes:
            if error_code != self.SUCCESS_CODE:
                self.close()
                self.module.fail_json(
                    msg='Error while creating topic %s. '
                    'Error key is %s, %s.' % (
                        topic, kafka.errors.for_code(error_code).message,
                        kafka.errors.for_code(error_code).description
                    )
                )

    def delete_topic(self, name, timeout=None):
        """
        Deletes a topic
        Usable for Kafka version >= 0.10.1
        Need to know which broker is controller for topic
        """
        if timeout is None:
            timeout = self.DEFAULT_TIMEOUT
        request = DeleteTopicsRequest_v0(topics=[name], timeout=timeout)
        response = self.send_request_and_get_response(request)

        for topic, error_code in response.topic_error_codes:
            if error_code != self.SUCCESS_CODE:
                self.close()
                self.module.fail_json(
                    msg='Error while deleting topic %s. '
                    'Error key is: %s, %s. '
                    'Is option \'delete.topic.enable\' set to true on '
                    ' your Kafka server?' % (
                        topic, kafka.errors.for_code(error_code).message,
                        kafka.errors.for_code(error_code).description
                    )
                )

    @staticmethod
    def _convert_create_acls_resource_request_v0(acl_resource):
        if acl_resource.operation == ACLOperation.ANY:
            raise IllegalArgumentError("operation must not be ANY")
        if acl_resource.permission_type == ACLPermissionType.ANY:
            raise IllegalArgumentError("permission_type must not be ANY")

        return (
            acl_resource.resource_type,
            acl_resource.name,
            acl_resource.principal,
            acl_resource.host,
            acl_resource.operation,
            acl_resource.permission_type
        )

    @staticmethod
    def _convert_create_acls_resource_request_v1(acl_resource):
        if acl_resource.operation == ACLOperation.ANY:
            raise IllegalArgumentError("operation must not be ANY")
        if acl_resource.permission_type == ACLPermissionType.ANY:
            raise IllegalArgumentError("permission_type must not be ANY")

        return (
            acl_resource.resource_type,
            acl_resource.name,
            acl_resource.pattern_type,
            acl_resource.principal,
            acl_resource.host,
            acl_resource.operation,
            acl_resource.permission_type
        )

    @staticmethod
    def _convert_delete_acls_resource_request_v0(acl_resource):
        return (
            acl_resource.resource_type,
            acl_resource.name,
            acl_resource.principal,
            acl_resource.host,
            acl_resource.operation,
            acl_resource.permission_type
        )

    def describe_acls(self, acl_resource, api_version):
        """Describe a set of ACLs
        """

        if api_version < parse_version('2.0.0'):
            request = DescribeAclsRequest_v0(
                resource_type=acl_resource.resource_type,
                resource_name=acl_resource.name,
                principal=acl_resource.principal,
                host=acl_resource.host,
                operation=acl_resource.operation,
                permission_type=acl_resource.permission_type
            )
        else:
            request = DescribeAclsRequest_v1(
                resource_type=acl_resource.resource_type,
                resource_name=acl_resource.name,
                resource_pattern_type_filter=acl_resource.pattern_type,
                principal=acl_resource.principal,
                host=acl_resource.host,
                operation=acl_resource.operation,
                permission_type=acl_resource.permission_type
            )

        response = self.send_request_and_get_response(request)

        if response.error_code != self.SUCCESS_CODE:
            self.close()
            self.module.fail_json(
                msg='Error while describing ACL %s. '
                    'Error %s: %s.' % (
                        acl_resource, response.error_code,
                        response.error_message
                    )
            )

        return response.resources

    def create_acls(self, acl_resources, api_version):
        """Create a set of ACLs"""

        if api_version < parse_version('2.0.0'):
            request = CreateAclsRequest_v0(
                creations=[self._convert_create_acls_resource_request_v0(
                    acl_resource) for acl_resource in acl_resources]
            )
        else:
            request = CreateAclsRequest_v1(
                creations=[self._convert_create_acls_resource_request_v1(
                    acl_resource) for acl_resource in acl_resources]
            )
        response = self.send_request_and_get_response(request)

        for error_code, error_message in response.creation_responses:
            if error_code != self.SUCCESS_CODE:
                self.close()
                self.module.fail_json(
                    msg='Error while creating ACL %s. '
                    'Error %s: %s.' % (
                        acl_resources, error_code, error_message
                    )
                )

    def delete_acls(self, acl_resources):
        """Delete a set of ACLSs"""

        request = DeleteAclsRequest_v0(
            filters=[self._convert_delete_acls_resource_request_v0(
                acl_resource) for acl_resource in acl_resources]
        )

        response = self.send_request_and_get_response(request)

        for error_code, error_message, _ in response.filter_responses:
            if error_code != self.SUCCESS_CODE:
                self.close()
                self.module.fail_json(
                    msg='Error while deleting ACL %s. '
                    'Error %s: %s.' % (
                        acl_resources, error_code, error_message
                    )
                )

    def send_request_and_get_response(self, request):
        """
        Sends a Kafka protocol request and returns
        the associated response
        """
        try:
            node_id = self.get_controller()

        except UndefinedController:
            self.module.fail_json(
                msg='Cannot determine a controller for your current Kafka '
                'server. Is your Kafka server running and available on '
                '\'%s\' with security protocol \'%s\'?' % (
                    self.client.config['bootstrap_servers'],
                    self.client.config['security_protocol']
                )
            )

        except Exception as e:
            self.module.fail_json(
                msg='Cannot determine a controller for your current Kafka '
                'server. Is your Kafka server running and available on '
                '\'%s\' with security protocol \'%s\'? Are you using the '
                'library versions from given \'requirements.txt\'? '
                'Exception was: %s' % (
                    self.client.config['bootstrap_servers'],
                    self.client.config['security_protocol'],
                    e
                )
            )

        if self.connection_check(node_id):
            future = self.client.send(node_id, request)
            self.client.poll(future=future)
            if future.succeeded():
                return future.value
            else:
                self.close()
                self.module.fail_json(
                    msg='Error while sending request %s to Kafka server: %s.'
                    % (request, future.exception)
                )
        else:
            self.close()
            self.module.fail_json(
                msg='Connection is not ready, please check your client '
                'and server configurations.'
            )

    def get_controller(self):
        """
        Returns the current controller
        """
        if self.client.cluster.controller is not None:
            node_id, _host, _port, _rack = self.client.cluster.controller
            return node_id
        else:
            raise UndefinedController(
                'Cant get a controller for this cluster.'
            )

    def get_controller_id_for_topic(self, topic_name):
        """
        Returns current controller for topic
        """
        request = MetadataRequest_v1(topics=[topic_name])
        response = self.send_request_and_get_response(request)
        return response.controller_id

    def get_config_for_topic(self, topic_name, config_names):
        """
        Returns responses with configuration
        Usable with Kafka version >= 0.11.0
        """
        request = DescribeConfigsRequest_v0(
            resources=[(self.TOPIC_RESOURCE_ID, topic_name, config_names)]
        )
        return self.send_request_and_get_response(request)

    def get_responses_from_client(self, connection_sleep=1):
        """
        Obtains response from server using poll()
        It may need some times to get the response, so we had some retries
        """
        retries = 0
        if self.get_awaiting_request() > 0:
            while retries < self.MAX_POLL_RETRIES:
                resp = self.client.poll()
                if resp:
                    return resp
                time.sleep(connection_sleep)
                retries += 1
            self.close()
            self.module.fail_json(
                msg='Error while getting responses : no response to request '
                'was obtained, please check your client and server '
                'configurations.'
            )
        else:
            self.close()
            self.module.fail_json(
                msg='No pending request, please check your client and server '
                'configurations.'
            )

    def get_topics(self):
        """
        Returns the topics list
        """
        return self.client.cluster.topics()

    def get_total_partitions_for_topic(self, topic):
        """
        Returns the number of partitions for topic
        """
        return len(self.client.cluster.partitions_for_topic(topic))

    def get_partitions_for_topic(self, topic):
        """
        Returns all partitions for topic, with information
        TODO do not use private property anymore
        """
        return self.client.cluster._partitions[topic]

    def get_total_brokers(self):
        """
        Returns number of brokers available
        """
        return len(self.client.cluster.brokers())

    def get_brokers(self):
        """
        Returns all brokers
        """
        return self.client.cluster.brokers()

    def get_api_version(self):
        """
        Returns Kafka server version
        """
        major, minor, patch = self.client.config['api_version']
        return '%s.%s.%s' % (major, minor, patch)

    def get_awaiting_request(self):
        """
        Returns the number of requests currently in the queue
        """
        return self.client.in_flight_request_count()

    def connection_check(self, node_id, connection_sleep=0.1):
        """
        Checks that connection with broker is OK and that it is possible to
        send requests
        Since the _maybe_connect() function used in ready() is 'async', we
        need to manually call it several time to make the connection
        """
        retries = 0
        if not self.client.ready(node_id):
            while retries < self.MAX_RETRY:
                if self.client.ready(node_id):
                    return True
                time.sleep(connection_sleep)
                retries += 1
            return False
        return True

    def is_topic_configuration_need_update(self, topic_name, topic_conf):
        """
        Checks whether topic's options need to be updated or not.
        Since the DescribeConfigsRequest does not give all current
        configuration entries for a topic, we need to use Zookeeper.
        Requires zk connection.
        """
        current_config, _zk_stats = self.zk_client.get(
            self.ZK_TOPIC_CONFIGURATION_NODE + topic_name
        )
        current_config = json.loads(current_config)['config']

        if len(topic_conf) != len(current_config.keys()):
            return True
        else:
            for conf_name, conf_value in topic_conf:
                if (
                        conf_name not in current_config.keys() or
                        str(conf_value) != str(current_config[conf_name])
                ):
                    return True

        return False

    def is_topic_partitions_need_update(self, topic_name, partitions):
        """
        Checks whether topic's partitions need to be updated or not.
        """
        total_partitions = self.get_total_partitions_for_topic(topic_name)
        need_update = False

        if partitions != total_partitions:
            if partitions > total_partitions:
                # increasing partition number
                need_update = True
            else:
                # decreasing partition number, which is not possible
                self.close()
                self.module.fail_json(
                    msg='Can\'t update \'%s\' topic partition from %s to %s :'
                    'only increase is possible.' % (
                        topic_name, total_partitions, partitions
                        )
                )

        return need_update

    def is_topic_replication_need_update(self, topic_name, replica_factor):
        """
        Checks whether a topic replica needs to be updated or not.
        """
        need_update = False
        for _id, part in self.get_partitions_for_topic(topic_name).items():
            _topic, _partition, _leader, replicas, _isr, _error = part
            if len(replicas) != replica_factor:
                need_update = True

        return need_update

    def update_topic_partitions(self, topic_name, partitions):
        """
        Updates the topic partitions
        Usable for Kafka version >= 1.0.0
        Requires to be the sended to the current controller of the Kafka
        cluster.
        The request requires to precise the total number of partitions and
        broker assignment for each new partition without forgeting replica.
        See NewPartitions class for explanations
        apache/kafka/clients/admin/NewPartitions.java#L53
        """
        brokers = []
        for node_id, _, _, _ in self.get_brokers():
            brokers.append(int(node_id))
        brokers_iterator = itertools.cycle(brokers)
        topic, _, _, replicas, _, _ = (
            self.get_partitions_for_topic(topic_name)[0]
        )
        total_replica = len(replicas)
        old_partition = self.get_total_partitions_for_topic(topic_name)
        assignments = []
        for _new_partition in range(partitions - old_partition):
            assignment = []
            for _replica in range(total_replica):
                assignment.append(next(brokers_iterator))
            assignments.append(assignment)

        request = CreatePartitionsRequest_v0(
            topic_partitions=[(topic_name, (partitions, assignments))],
            timeout=self.DEFAULT_TIMEOUT,
            validate_only=False
        )
        response = self.send_request_and_get_response(request)
        for topic, error_code, _error_message in response.topic_errors:
            if error_code != self.SUCCESS_CODE:
                self.close()
                self.module.fail_json(
                    msg='Error while updating topic \'%s\' partitions. '
                    'Error key is %s, %s. Request was %s.' % (
                        topic, kafka.errors.for_code(error_code).message,
                        kafka.errors.for_code(error_code).description,
                        str(request)
                    )
                )
        self.refresh()

    def update_topic_configuration(self, topic_name, topic_conf):
        """
        Updates the topic configuration
        Usable for Kafka version >= 0.11.0
        Requires to be the sended to the current controller of the Kafka
        cluster.
        """
        request = AlterConfigsRequest_v0(
            resources=[(self.TOPIC_RESOURCE_ID, topic_name, topic_conf)],
            validate_only=False
        )
        response = self.send_request_and_get_response(request)

        for error_code, _, _, resource_name in response.resources:
            if error_code != self.SUCCESS_CODE:
                self.close()
                self.module.fail_json(
                    msg='Error while updating topic \'%s\' configuration. '
                    'Error key is %s, %s' % (
                        resource_name,
                        kafka.errors.for_code(error_code).message,
                        kafka.errors.for_code(error_code).description
                    )
                )
        self.refresh()

    def get_assignment_for_replica_factor_update(self, topic_name,
                                                 replica_factor):
        """
        Generates a json assignment based on replica_factor given to update
        replicas for a topic.
        Uses all brokers available and distributes them as replicas using
        a round robin method.
        """
        all_replicas = []
        assign = {'partitions': [], 'version': 1}

        if replica_factor > self.get_total_brokers():
            self.close()
            self.close_zk_client()
            self.module.fail_json(
                msg='Error while updating topic \'%s\' replication factor : '
                'replication factor \'%s\' is more than available brokers '
                '\'%s\'' % (
                    topic_name,
                    replica_factor,
                    self.get_total_brokers()
                )
            )
        else:
            for node_id, _, _, _ in self.get_brokers():
                all_replicas.append(node_id)
            brokers_iterator = itertools.cycle(all_replicas)
            for _, part in self.get_partitions_for_topic(topic_name).items():
                _, partition, _, _, _, _ = part
                assign_tmp = {
                    'topic': topic_name,
                    'partition': partition,
                    'replicas': []
                }
                for _i in range(replica_factor):
                    assign_tmp['replicas'].append(next(brokers_iterator))
                assign['partitions'].append(assign_tmp)

            return bytes(str(json.dumps(assign)).encode('ascii'))

    def get_assignment_for_partition_update(self, topic_name, partitions):
        """
        Generates a json assignment based on number of partitions given to
        update partitions for a topic.
        Uses all brokers available and distributes them among partitions
        using a round robin method.
        """
        all_brokers = []
        assign = {'partitions': {}, 'version': 1}

        _, _, _, replicas, _, _ = self.get_partitions_for_topic(topic_name)[0]
        total_replica = len(replicas)

        for node_id, _host, _port, _rack in self.get_brokers():
            all_brokers.append(node_id)
        brokers_iterator = itertools.cycle(all_brokers)

        for i in range(partitions):
            assign_tmp = []
            for _j in range(total_replica):
                assign_tmp.append(next(brokers_iterator))
            assign['partitions'][str(i)] = assign_tmp

        return bytes(str(json.dumps(assign)).encode('ascii'))

    def wait_for_znode_assignment(self, zk_sleep_time, zk_max_retries):
        """
        Wait for the reassignment znode to be consumed by Kafka.

        Raises `ReassignPartitionsTimeout` if `zk_max_retries` is reached.
        """
        retries = 0
        while (
                self.zk_client.exists(self.ZK_REASSIGN_NODE) and
                retries < zk_max_retries
        ):
            retries += 1
            time.sleep(zk_sleep_time)

        if retries >= zk_max_retries:
            raise ReassignPartitionsTimeout(
                'The znode %s, is still present after %s tries, giving up.'
                'Consider increasing your `zookeeper_max_retries` and/or '
                '`zookeeper_sleep_time` parameters and check your cluster.',
                self.ZK_REASSIGN_NODE,
                retries
            )

    def update_admin_assignment(self, json_assignment, zk_sleep_time,
                                zk_max_retries):
        """
Updates the topic replica factor using a json assignment
Cf core/src/main/scala/kafka/admin/ReassignPartitionsCommand.scala#L580
 1 - Send AlterReplicaLogDirsRequest to allow broker to create replica in
     the right log dir later if the replica has not been created yet.

  2 - Create reassignment znode so that controller will send
      LeaderAndIsrRequest to create replica in the broker
      def path = "/admin/reassign_partitions" ->
      zk.create("/admin/reassign_partitions", b"a value")
  case class ReplicaAssignment(
    @BeanProperty @JsonProperty("topic") topic: String,
    @BeanProperty @JsonProperty("partition") partition: Int,
    @BeanProperty @JsonProperty("replicas") replicas: java.util.List[Int])
  3 - Send AlterReplicaLogDirsRequest again to make sure broker will start
      to move replica to the specified log directory.
     It may take some time for controller to create replica in the broker
     Retry if the replica has not been created.
 It may be possible that the node '/admin/reassign_partitions' is already
 there for another topic. That's why we need to check for its existence
 and wait for its consumption if it is already present.
 Requires zk connection.
        """

        try:
            self.wait_for_znode_assignment(zk_sleep_time, zk_max_retries)
            self.zk_client.create(self.ZK_REASSIGN_NODE, json_assignment)
            self.wait_for_znode_assignment(zk_sleep_time, zk_max_retries)

        except ReassignPartitionsTimeout as e:
            self.close()
            self.close_zk_client()
            self.module.fail_json(
                msg=str(e)
            )

        self.refresh()

    def update_topic_assignment(self, json_assignment, zknode):
        """
 Updates the topic partition assignment using a json assignment
 Used when Kafka version < 1.0.0
 Requires zk connection.
        """
        if not self.zk_client.exists(zknode):
            self.close()
            self.close_zk_client()
            self.module.fail_json(
                msg='Error while updating assignment: zk node %s missing. '
                'Is the topic name correct?' % (zknode)
            )
        self.zk_client.set(zknode, json_assignment)
        self.refresh()
