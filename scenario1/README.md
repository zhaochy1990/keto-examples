# 

suppose the following scenarios:

- user Alice is the org admin of organization org1
- Alice subscribed `CMS`, `IDF`, `EAM` for org1


# Scenario 1

user Bob is the device manager in org1

Alice grant Bob permissions of `all devices` of org1.

Alice created role `device-manager` and assign this role to Bob
```json
{
  "actions": [
    "rc:Device:Read",
    "rc:Device:Update",
  ],
  "scopes": ["/Organization/org1/Subscription/{CMS}"],
  "conditions": [
    {
      "resource": "Device",
      "expression": {}
    }
  ]
}
```

after the assignment, `iam-resource-watcher` will create the following relation tuples:

```json
OBJECT                            RELATION               SUBJECT

/role/device-manager              assignment             /user/Bob
/device/001                       Read                   /role/device-manager#assignment
/device/001                       Update                 /role/device-manager#assignment
/device/002                       Read                   /role/device-manager#assignment
/device/002                       Update                 /role/device-manager#assignment

all other devices ...

```

> for converient, use `create.sh` to create the testing relation tuples.

Now, check if Bob has permission for some device

```bash
keto check /user/Bob Read rc /device/001
# Expect Allow

keto check /user/Bob Update rc /device/002
# Expect Allow

keto check /user/Bob Update rc /device/003
# Expect Deny
```
> for converient, use `check.sh` to create the testing relation tuples.

List All devices that Bob has permission to Read

```bash
# get all object that Bob has permission to
keto relation-tuple get rc --subject-id /user/Bob

# get all object that role device-manager has Read permissions
keto relation-tuple get rc --subject-set rc:/role/device-manager#role-assignment --relation Read
```

List All users that has `Update` permission for device 001

```bash
keto expand Update rc /device/001
```

later, Alice assigned role `device-manager` to user Tom, `iam-resource-wather` will be notified and create the new relation tuples:

```json
OBJECT                            RELATION               SUBJECT

/role/device-manager              assignment             /user/Tom
```

