Deploy CRD and operator:
========================
```
kubectl create ns operators
kubectl -n operators apply -f deploy/mandatory.yaml
```

Create cluster:
===============
```
kubectl create ns confluent
kubectl -n confluent apply -f deploy/confluent-platform.yaml
```

Confluent Platform configuration (example):
===========================================
```
---
apiVersion: kafka.pm.bet/v1beta1
kind: ConfluentPlatform
metadata:
  name: confluent
spec:
  # Version of Confluent Platform.
  version: 5.5.0

  license: ""

  zookeeper:
    enabled: true

    # Number of nodes of the zookeeper cluster. The amount must be odd.
    size: 3

    # This is the port where ZooKeeper clients will listen on.
    # This is where the Brokers will connect to ZooKeeper.
    # Typically this is set to 2181.
    clientPort: 2181

    # This port is used by followers to connect to the active leader.
    # This port should be open between all ZooKeeper ensemble members.
    serverPort: 2888

    # This port is used to perform leader elections between ensemble members.
    # This port should be open between all ZooKeeper ensemble members.
    electionPort: 3888

    # JMX port
    jmxPort: 9999

    # The unit of time for ZooKeeper translated to milliseconds.
    # This governs all ZooKeeper time dependent operations.
    # It is used for heartbeats and timeouts especially.
    # Note that the minimum session timeout will be two ticks.
    tickTime: 2000

    # The initLimit and syncLimit are used to govern how long following ZooKeeper servers can take
    # to initialize with the current leader and how long they can be out of sync with the leader.
    initLimit: 5
    syncLimit: 2

    # When enabled, ZooKeeper auto purge feature retains the autopurge.snapRetainCount most recent snapshots
    # and the corresponding transaction logs in the dataDir and dataLogDir respectively and deletes the rest.
    autopurgeSnapRetainCount: 3

    # The time interval in hours for which the purge task has to be triggered.
    # Set to a positive integer (1 and above) to enable the auto purging.
    autopurgePurgeInterval: 24

    # The maximum allowed number of client connections for a ZooKeeper server.
    # To avoid running out of allowed connections set this to 0 (unlimited).
    maxClientCnxns: 60

    logRootLoglevel: "INFO"
    logLoggers: "INFO"

    persistent: true
    dataDirSize: 1Gi
    datalogDirSize: 1Gi

  kafka:
    enabled: true
    persistent: true
    storageSize: 5Gi
    size: 3
    plaintextPort: 9092
    sslPort: 9093
    saslPort: 9094
    jmxPort: 9999
    allowEveryoneIfNoAclFound: true
    alterLogDirsReplicationQuotaWindowNum: 11
    alterLogDirsReplicationQuotaWindowSizeSeconds: 1
    authorizerClassName: kafka.security.auth.SimpleAclAuthorizer
    autoCreateTopicsEnable: true
    autoLeaderRebalanceEnable: true
    backgroundThreads: 10
    brokerIdGenerationEnable: true
    brokerRack: kubernetes
    comperssionType: producer
    connectionsMaxIdleMs: 600000
    connectionFailedAuthenticationDelayMs: 100
    controlledShutdownEnable: true
    controlledShutdownMaxRetries: 3
    controlledShutdownRetryBackoffMs: 5000
    controlledSocketTimeoutMs: 30000
    defaultReplicationFactor: 3
    delegationTokenExpiryCheckIntervalMs: 3600000
    delegationTokenExpiryTimeMs: 86400000
    delegationTokenMaxLifetimeMs: 604800000
    deleteRecordPurgatoryPurgeIntervalRequests: 1
    deleteTopicEnable: true
    fetchPurgatoryPurgeIntervalRequests: 1000
    groupInitialRebalanceDelayMs: 3000
    groupMaxSessionTimeoutMs: 300000
    groupMinSessionTimeoutMs: 6000
    leaderImbalanceCheckIntervalSeconds: 300
    leaderImbalancePerBrokerPercentage: 10
    log4jRootLoglevel: INFO
    logCleanerBackoffMs: 15000
    logCleanerDedupeBufferSize: 134217728
    logCleanerDeleteRetentionMs: 86400000
    logCleanerEnable: true
    logCleanerIoBufferLoadFactor: 0.9
    logCleanerIoBufferSize: 524288
    logCleanerIoMaxBytesPerSecond: "1.7976931348623157E308"
    logCleanerMinCleanableRatio: 0.5
    logCleanerMinCompactionLagMs: 0
    logMessageTimestampType: CreateTime

  schemaRegistry:
    enabled: true
    size: 1
    port: 8081
    jmxPort: 9999
    avro_compatibility_level: backward
    compression_enable: true

  kafkaConnect:
    enabled: true
    size: 1
    port: 8083
    jmxPort: 9999
    configStorageTopic: connect-configs
    groupId: connect
    keyConverter: org.apache.kafka.connect.json.JsonConverter
    offsetStorageTopic: connect-offsets
    statusStorageTopic: connect-status
    valueConverter: org.apache.kafka.connect.json.JsonConverter

  ksqldbServer:
    enabled: true
    size: 1
    port: 8088
    jmxPort: 9999
    ksqlAccessValidatorEnable: autooo

  kafkaRest:
    enabled: true
    size: 1
    port: 8082
    jmxPort: 9999
    compressionEnable: true

  controlCenter:
    enabled: true
    size: 1
    port: 9021
    jmxPort: 9999

    # Auto create a trigger and an email action for Control Center’s cluster down alerts.
    alertClusterDownAutocreate: false

    # Send rate per hour for auto-created cluster down alerts.
    # Default: 12 times per hour (every 5 minutes).
    alertClusterDownSendRate: 12

    # Email to send alerts to when Control Center’s cluster is down.
    # alertClusterDownToEmail: duty@example.com

    # The PagerDuty integration key to post alerts to a certain service when Control Center’s cluster is down.
    # alertClusterDownToPagerdutyIntegrationkey: xxxxxx

    # The Slack webhook URL to post alerts to when Control Center’s cluster is down.
    # alertClusterDownToWebhookurlSlack: xxxxxx

    # The maximum number of trigger events in one alert.
    alertMaxTriggerEvents: 1000

    # JWT token issuer.
    authBearerIssuer: Confluent

    # List of roles with limited access. No editing or creating using the UI.
    # Any role here must also be added to confluent.controlcenter.rest.authentication.roles
    # authRestrictedRoles: []

    # Timeout in milliseconds after which a user session will have to be re-authenticated
    # with the authentication service (e.g. LDAP). Defaults to 0, which means authentication is done for every request.
    # Increase this value to avoid calling the LDAP service for each request.
    authSessionExpirationMs: 0

    # Enable user access to Edit dynamic broker configuration settings.
    brokerConfigEditEnable: false

    # Command streams start timeout
    commandStreamsStartTimeout: 300000

    # Topic used to store Control Center configuration.
    commandTopic: _confluent-command

    # Retention for command topic.
    commandTopicRetentionMs: 259200000

    # Time to wait when attempting to retrieve Consumer Group metadata.
    consumerMetadataTimeoutMs: 15000

    # Enable the Consumers view in Control Center.
    consumersViewEnable: true

    # Enable deprecated Streams Monitoring and System Health views.
    deprecatedViewsEnable: false

    # Threshold for the max difference in disk usage across all brokers before disk skew warning is published.
    diskSkewWarningMinBytes: 1073741824

    
    internalStreamsStartTimeout: 21600000
    internalTopicsChangelogSegmentBytes: 134217728
    internalTopicsPartition: 4
    internalTopicsReplication: 3
    internalTopicsRetentionBytes: -1
    internalTopicsRetentionMs: 604800000

    # Enable user access to the ksqlDB GUI.
    ksqlEnable: true

    # License Manager topic
    licenseManager: _confluent-controlcenter-license-manager-5-5-0

    # Enable License Manager in Control Center.
    licenseManagerEnable: true

    # Override for mailFrom config to send message bounce notifications.
    # mailBounceAddress: 

    # Enable email alerts. If this setting is false, you cannot add email alert actions in the web user interface.
    mailEnabled: false

    # The originating address for emails sent from Control Center.
    mailFrom: c3@confluent.io

    # Hostname of outgoing SMTP server.
    mailHostName: localhost

    # Password for username/password authentication.
    # mailPassword: 

    # SMTP port open on mailHostName.
    mailPort: 587

    # SMTP port open on confluent.controlcenter.mail.host.name.
    mailSslCheckServerIdentity: false

    # Forces using STARTTLS.
    mailStarttlsRequired: false

    # Username for username/password authentication.
    # Authentication with your SMTP server only performs if this value is set.
    # mailUsername: 

    # Control Center Name.
    name: _confluent-controlcenter

    productiveSupportUiCtaEnable: false
    restCompressionEnable: true
    restHstsEnable: true

    # REST port.
    restPort: 9021

    sbkUiEnable: false

    # Enable user access to Manage Schemas for Topics.
    schemaRegistryEnable: true

    # The interval (in seconds) used for checking the health of Confluent Platform nodes.
    # This includes ksqlDB, Connect, Schema Registry, REST Proxy, and Metadata Service (MDS).
    serviceHealthcheckIntervalSec: 20

    # Maximum number of memory bytes used for record caches across all threads.
    streamsCacheMaxBytesBuffering: 1073741824

    streamsConsumerSessionTimeoutMs: 60000
    streamsNumStreamThreads: 8

    # Compression type to use on internal topic production.
    streamsProducerCompressionType: lz4

    streamsProducerDeliveryTimeoutMs: 2147483647
    streamsProducerLingerMs: 500
    streamsProducerMaxBlockMs: "9223372036854775807"
    streamsProducerRetries: 2147483647
    streamsProducerRetryBackofMs: 100

    # Number of times to retry client requests failing with transient errors.
    # Does not apply to producer retries, which are defined using the streamsProducerRetries setting described below.
    streamsRetries: 2147483647

    streams_upgrade_from: 2.3

    # Enable users to inspect topics.
    topicInspectionEnable: true

    triggerActiveControllerCountEnable: false

    # Enable auto updating the Control Center UI.
    uiAutoupdateEnable: true

    # Enable the Active Controller chart to display within the Broker uptime panel in the Control Center UI.
    uiControllerChartEnable: true

    # Configure a threshold (in seconds) before data is considered out of date. Default: 120 seconds (2 minutes).
    uiDataExpiredThreshold: 120

    # Enable Replicator monitoring in the Control Center UI.
    uiReplicatorMonitoringEnable: true

    # Enable or disable usage data collection in Control Center.
    usageDataCollectionEnable: true

    # Enable supported webhook alerts. If this setting is false, you cannot add webhook alert actions in the web user interface.
    webhookEnabled: true

```

Create topic:
=============
```
kubectl -n confluent apply -f deploy/topic.yaml
```

Topic configuration (example):
==============================
```
---
apiVersion: kafka.pm.bet/v1beta1
kind: Topic
metadata:
  name: test-topic
  namespace: confluent
spec:
  replicationFactor: 3
  partitions: 10
  options:
    # A string that is either "delete" or "compact" or both.
    # This string designates the retention policy to use on old log segments.
    # The default policy ("delete") will discard old segments when their retention time or size limit has been reached.
    # The "compact" setting will enable log compaction on the topic.
    cleanupPolicy: delete

    # True if schema validation at record key is enabled for this topic.
    # confluentKeySchemaValidation: false

    # Determines how to construct the subject name under which the key schema is registered with the schema registry.
    # By default, TopicNameStrategy is used.
    # confluentKeySubjectNameStrategy: io.confluent.kafka.serializers.subject.TopicNameStrategy

    # This configuration is a JSON object that controls the set of brokers (replicas) which will always be allowed to join the ISR.
    # And the set of brokers (observers) which are not allowed to join the ISR.
    # The format of JSON is:
    # {
    #   "version": 1,
    #   "replicas": [
    #     {
    #       "count": 2,
    #       "constraints": {"rack": "east-1"}
    #     },
    #     {
    #       "count": 1,
    #       "constraints": {"rack": "east-2"}
    #     }
    #    ],
    #   "observers":[
    #     {
    #       "count": 1,
    #       "constraints": {"rack": "west-1"}
    #     }
    #   ]
    # }
    # confluentPlacementConstraints: ""

    # True if schema validation at record value is enabled for this topic.
    # confluentValueSchemaValidation: false

    # Determines how to construct the subject name under which the value schema is registered with the schema registry.
    # By default, TopicNameStrategy is used.
    # confluentValueSubjectNameStrategy: io.confluent.kafka.serializers.subject.TopicNameStrategy

    # Specify the final compression type for a given topic.
    # This configuration accepts the standard compression codecs ('gzip', 'snappy', 'lz4', 'zstd').
    # It additionally accepts 'uncompressed' which is equivalent to no compression;
    # and 'producer' which means retain the original compression codec set by the producer.
    compressionType: producer

    # The amount of time to retain delete tombstone markers for log compacted topics.
    # This setting also gives a bound on the time in which a consumer must complete a read
    # if they begin from offset 0 to ensure that they get a valid snapshot of the final
    # stage (otherwise delete tombstones may be collected before they complete their scan).
    deleteRetentionMs: 86400000

    # The time to wait before deleting a file from the filesystem.
    fileDeleteDelayMs: 60000

    # This setting allows specifying an interval at which we will force an fsync of data written to the log.
    # For example if this was set to 1 we would fsync after every message;
    # if it were 5 we would fsync after every five messages.
    # In general we recommend you not set this and use replication for durability and allow the operating
    # system's background flush capabilities as it is more efficient. This setting can be overridden
    # on a per-topic basis (see the per-topic configuration section).
    flushMessage: 9223372036854775807

    # This setting allows specifying a time interval at which we will force an fsync of data written to the log.
    # For example if this was set to 1000 we would fsync after 1000 ms had passed.
    # In general we recommend you not set this and use replication for durability and allow the operating system's
    # background flush capabilities as it is more efficient.
    flushMs: 9223372036854775807

    # A list of replicas for which log replication should be throttled on the follower side.
    # The list should describe a set of replicas in the form [PartitionId]:[BrokerId],[PartitionId]:[BrokerId]:...
    # or alternatively the wildcard '*' can be used to throttle all replicas for this topic.
    # followerReplicationThrottledReplicas: ""

    # This setting controls how frequently Kafka adds an index entry to its offset index.
    # The default setting ensures that we index a message roughly every 4096 bytes.
    # More indexing allows reads to jump closer to the exact position in the log but makes the index larger.
    # You probably don't need to change this.
    indexIntervalBytes: 4096

    # A list of replicas for which log replication should be throttled on the leader side.
    # The list should describe a set of replicas in the form [PartitionId]:[BrokerId],[PartitionId]:[BrokerId]:...
    # or alternatively the wildcard '*' can be used to throttle all replicas for this topic.
    # leaderReplicationRhrottledReplicas: ""

    # The maximum time a message will remain ineligible for compaction in the log.
    #  Only applicable for logs that are being compacted.
    maxCompactionLagMs: 9223372036854775807

    # The largest record batch size allowed by Kafka (after compression if compression is enabled).
    # If this is increased and there are consumers older than 0.10.2, the consumers' fetch size
    # must also be increased so that the they can fetch record batches this large.
    # In the latest message format version, records are always grouped into batches for efficiency.
    # In previous message format versions, uncompressed records are not grouped into batches
    # and this limit only applies to a single record in that case.
    maxMessageBytes: 1048588

    # This configuration controls whether down-conversion of message formats is enabled to satisfy consume requests.
    # When set to false, broker will not perform down-conversion for consumers expecting an older message format.
    # The broker responds with UNSUPPORTED_VERSION error for consume requests from such older clients.
    # This configurationdoes not apply to any message format conversion that might be required for replication to followers.
    messageDownconversionEnable: true

    # Specify the message format version the broker will use to append messages to the logs.
    # The value should be a valid ApiVersion. Some examples are: 0.8.2, 0.9.0.0, 0.10.0,
    # check ApiVersion for more details. By setting a particular message format version,
    # the user is certifying that all the existing messages on disk are smaller or equal than 
    # the specified version. Setting this value incorrectly will cause consumers with older
    # versions to break as they will receive messages with a format that they don't understand.
    #
    # Valid values: 0.8.0, 0.8.1, 0.8.2, 0.9.0, 0.10.0-IV0, 0.10.0-IV1, 0.10.1-IV0, 0.10.1-IV1,
    #               0.10.1-IV2, 0.10.2-IV0, 0.11.0-IV0, 0.11.0-IV1, 0.11.0-IV2, 1.0-IV0, 1.1-IV0,
    #               2.0-IV0, 2.0-IV1, 2.1-IV0, 2.1-IV1, 2.1-IV2, 2.2-IV0, 2.2-IV1, 2.3-IV0, 2.3-IV1,
    #               2.4-IV0, 2.4-IV1, 2.5-IV0
    messageFormatVersion: 2.5-IV0

    # The maximum difference allowed between the timestamp when a broker receives a message and the timestamp
    # specified in the message. If message.timestamp.type=CreateTime, a message will be rejected
    # if the difference in timestamp exceeds this threshold. This configuration is ignored if message.timestamp.type=LogAppendTime.
    messageTimestampDifferenceMaxMs: 9223372036854775807

    # Define whether the timestamp in the message is message create time or log append time.
    # The value should be either `CreateTime` or `LogAppendTime`
    messageTimestampType: CreateTime

    # This configuration controls how frequently the log compactor will attempt to clean the log (assuming log compaction is enabled).
    # By default we will avoid cleaning a log where more than 50% of the log has been compacted.
    # This ratio bounds the maximum space wasted in the log by duplicates (at 50% at most 50% of the log could be duplicates).
    # A higher ratio will mean fewer, more efficient cleanings but will mean more wasted space in the log.
    # If the max.compaction.lag.ms or the min.compaction.lag.ms configurations are also specified,
    # then the log compactor considers the log to be eligible for compaction as soon as either: (i) the dirty ratio threshold
    # has been met and the log has had dirty (uncompacted) records for at least the min.compaction.lag.ms duration,
    # or (ii) if the log has had dirty (uncompacted) records for at most the max.compaction.lag.ms period.
    minCleanableDirtyRatio: 0.5

    # The minimum time a message will remain uncompacted in the log. Only applicable for logs that are being compacted.
    minCompactionLagMs: 0

    # When a producer sets acks to "all" (or "-1"), this configuration specifies the minimum number of replicas
    # that must acknowledge a write for the write to be considered successful. If this minimum cannot be met,
    # then the producer will raise an exception (either NotEnoughReplicas or NotEnoughReplicasAfterAppend).
    # When used together, min.insync.replicas and acks allow you to enforce greater durability guarantees.
    # A typical scenario would be to create a topic with a replication factor of 3, set min.insync.replicas to 2,
    # and produce with acks of "all". This will ensure that the producer raises an exception if a majority
    # of replicas do not receive a write.
    minInsyncReplicas: 1

    # True if we should preallocate the file on disk when creating a new log segment.
    preallocate: false

    # This configuration controls the maximum size a partition (which consists of log segments) can grow to before
    # we will discard old log segments to free up space if we are using the "delete" retention policy.
    # By default there is no size limit only a time limit. Since this limit is enforced at the partition level,
    # multiply it by the number of partitions to compute the topic retention in bytes.
    retentionBytes: -1

    # This configuration controls the maximum time we will retain a log before we will discard old log segments
    # to free up space if we are using the "delete" retention policy. This represents an SLA on how soon consumers
    # must read their data. If set to -1, no time limit is applied.
    retentionMs: 86000000

    # This configuration controls the segment file size for the log. Retention and cleaning is always done a file
    # at a time so a larger segment size means fewer files but less granular control over retention.
    segmentBytes: 1073741824

    # This configuration controls the size of the index that maps offsets to file positions. We preallocate
    # this index file and shrink it only after log rolls. You generally should not need to change this setting.
    segmentIndexBytes: 10485760

    # The maximum random jitter subtracted from the scheduled segment roll time to avoid thundering herds of segment rolling.
    segmentJitterMs: 0

    # This configuration controls the period of time after which Kafka will force the log to roll even
    # if the segment file isn't full to ensure that retention can delete or compact old data.
    segmentMs: 604800000

    # Indicates whether to enable replicas not in the ISR set to be elected as leader as a last resort,
    # even though doing so may result in data loss.
    uncleanLeaderElectionEnable: false
---
```