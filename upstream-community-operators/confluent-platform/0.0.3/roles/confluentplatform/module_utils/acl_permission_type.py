# enum in stdlib as of py3.4
try:
    from enum import IntEnum  # pylint: disable=import-error
except ImportError:
    # vendored backport module
    from kafka.vendor.enum34 import IntEnum


class ACLPermissionType(IntEnum):
    """An enumerated type of permissions"""

    ANY = 1,
    DENY = 2,
    ALLOW = 3

    @staticmethod
    def from_name(name):
        if not isinstance(name, str):
            raise ValueError("%r is not a valid ACLPermissionType" % name)

        if name.lower() == "any":
            return ACLPermissionType.ANY
        elif name.lower() == "deny":
            return ACLPermissionType.DENY
        elif name.lower() == "allow":
            return ACLPermissionType.ALLOW
        else:
            raise ValueError("%r is not a valid ACLPermissionType" % name)
