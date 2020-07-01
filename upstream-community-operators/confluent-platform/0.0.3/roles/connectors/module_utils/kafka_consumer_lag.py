from kafka.protocol.commit import OffsetFetchRequest_v2,\
    OffsetFetchResponse_v2, GroupCoordinatorRequest_v0,\
    GroupCoordinatorResponse_v0
from kafka.protocol.offset import OffsetRequest_v1, OffsetResponse_v1

_OffsetRequest = OffsetRequest_v1
_OffsetResponse = OffsetResponse_v1

_OffsetFetchRequest = OffsetFetchRequest_v2
_OffsetFetchResponse = OffsetFetchResponse_v2

_GroupCoordinatorRequest = GroupCoordinatorRequest_v0
_GroupCoordinatorResponse = GroupCoordinatorResponse_v0

# Time value '-1' is to get the offset for next new message (=> last offset)
LATEST_TIMESTAMP = -1

EARLIEST_TIMESTAMP = -2

AS_CONSUMER = -1


class KafkaConsumerLag:

    def __init__(self, kafka_client):

        self.client = kafka_client
        self.client.check_version()

    def _send(self, broker_id, request, response_type=None):

        f = self.client.send(broker_id, request)
        self.client.poll(future=f)
        if f.succeeded():
            if response_type is not None:
                assert isinstance(f.value, response_type)
            return f.value
        else:
            raise f.exception()

    def get_lag_stats(self, consumer_group=None,
                      ignore_empty_partition=False):
        cluster = self.client.cluster
        brokers = cluster.brokers()

        # coordinating broker
        consumer_coordinator = {}

        # Current offset for each topic partition
        current_offsets = {}

        # Topic consumed by this consumer_group
        topics = []

        # Global lag
        global_lag = 0

        # result object containing kafka statistics
        results = {}

        # Ensure connections to all brokers
        for broker in brokers:
            while not self.client.is_ready(broker.nodeId):
                self.client.ready(broker.nodeId)

        # Identify which broker is coordinating this consumer group
        response = self._send(
                 next(iter(brokers)).nodeId,
                 _GroupCoordinatorRequest(consumer_group),
                 _GroupCoordinatorResponse)

        consumer_coordinator = response.coordinator_id

        # Get current offset for each topic partitions
        response = self._send(
                 consumer_coordinator,
                 _OffsetFetchRequest(consumer_group, None),
                 _OffsetFetchResponse)

        for topic, partitions in response.topics:
            current_offsets[topic] = {}
            if topic not in topics:
                topics.append(topic)
            for partition in partitions:
                partition_index, commited_offset, _, _ = partition
                current_offsets[topic][partition_index] = commited_offset

        # Get last offset for each topic partition coordinated by each broker
        # Result object is set up also
        for broker in brokers:
            # filter only topic consumed by consumer_group
            topics_partitions_by_broker = filter_by_topic(
                                cluster.partitions_for_broker(broker.nodeId),
                                topics)
            request_latest_topic_partitions = \
                build_offset_request_topics_partitions(
                    topics_partitions_by_broker, LATEST_TIMESTAMP)
            request_earliest_topic_partitions = \
                build_offset_request_topics_partitions(
                    topics_partitions_by_broker, EARLIEST_TIMESTAMP)

            response_latest = self._send(
                     broker.nodeId,
                     _OffsetRequest(AS_CONSUMER,
                                    request_latest_topic_partitions),
                     _OffsetResponse)
            response_earliest = self._send(
                     broker.nodeId,
                     _OffsetRequest(AS_CONSUMER,
                                    request_earliest_topic_partitions),
                     _OffsetResponse)

            earliest_offsets = {}
            for topic, partitions in response_earliest.topics:
                earliest_offsets[topic] = {}
                for partition in partitions:
                    partition_id, _, _, offset = partition
                    earliest_offsets[topic][partition_id] = offset

            for topic, partitions in response_latest.topics:
                for partition in partitions:
                    partition_id, _, _, last_offset = partition
                    # Ignore empty partition for lag count
                    if ignore_empty_partition and \
                       earliest_offsets[topic][partition_id] == last_offset:
                        continue
                    if partition_id in current_offsets[topic]:
                        current_offset = current_offsets[topic][partition_id]
                        lag = last_offset - current_offset
                        global_lag += lag
                        # Set up result object
                        results.setdefault(topic, {})[partition_id] = {
                            'current_offset': current_offset,
                            'last_offset': last_offset,
                            'lag': last_offset - current_offset
                        }

        results["global_lag_count"] = global_lag
        return results


def filter_by_topic(topics_partitions, topics):
    return [tp for tp in topics_partitions if tp.topic in topics]


def build_offset_request_topics_partitions(topics_partitions, timestamp):
    _topics_partitions = {}
    for topic, partition in topics_partitions:
        _topics_partitions.setdefault(topic, []).append(
            (partition, timestamp)
        )
    # convert to array for _OffsetRequest Struct
    return list(_topics_partitions.items())
