# enum in stdlib as of py3.4
try:
    from enum import IntEnum  # pylint: disable=import-error
except ImportError:
    # vendored backport module
    from kafka.vendor.enum34 import IntEnum


class ACLOperation(IntEnum):
    """An enumerated type of acl operations"""

    ANY = 1,
    ALL = 2,
    READ = 3,
    WRITE = 4,
    CREATE = 5,
    DELETE = 6,
    ALTER = 7,
    DESCRIBE = 8,
    CLUSTER_ACTION = 9,
    DESCRIBE_CONFIGS = 10,
    ALTER_CONFIGS = 11,
    IDEMPOTENT_WRITE = 12

    @staticmethod
    def from_name(name):
        if not isinstance(name, str):
            raise ValueError("%r is not a valid ACLOperation" % name)

        if name.lower() == "any":
            return ACLOperation.ANY
        elif name.lower() == "all":
            return ACLOperation.ALL
        elif name.lower() == "read":
            return ACLOperation.READ
        elif name.lower() == "write":
            return ACLOperation.WRITE
        elif name.lower() == "create":
            return ACLOperation.CREATE
        elif name.lower() == "delete":
            return ACLOperation.DELETE
        elif name.lower() == "alter":
            return ACLOperation.ALTER
        elif name.lower() == "describe":
            return ACLOperation.DESCRIBE
        elif name.lower() == "cluster_action":
            return ACLOperation.CLUSTER_ACTION
        elif name.lower() == "describe_configs":
            return ACLOperation.DESCRIBE_CONFIGS
        elif name.lower() == "alter_configs":
            return ACLOperation.ALTER_CONFIGS
        elif name.lower() == "idempotent_write":
            return ACLOperation.IDEMPOTENT_WRITE
        else:
            raise ValueError("%r is not a valid ACLOperation" % name)
