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

later, Alice assigned role `device-manager` to user Tom, `iam-resource-wather` will be notified and create the new relation tuples:

```json
OBJECT                            RELATION               SUBJECT

/role/device-manager              assignment             /user/Tom
```

# Scenario 2

Suppose Device and Asset have the following schema:

```js
// Device
{
  "id": "string",
}

// Asset
{
  "id": "string",
  "departmentId": "xxx",
  "deviceId": "ref: Device"
}
```

Alice grant Bob all devices and assets which belong to dep1, which will be a role `dep-device-manager` with the following properties:

```js
RoleDefinition: {
  actions: [
    "rc:Device:Read",
    "rc:Device:Update"
    "rc:Asset:Read",
    "rc:Asset:Update",
  ]
}

RoleAssignment: {
  "scopes": [
    "/Organization/org1/Subscription/{CMS}",
    "/Organization/org1/Subscription/{EAM}"
  ],
  "conditions": [
    {
      "resource": "Device",
      "expression": { "{link -> Asset}.departmentId": "dep1" }
    },
    {
      "resource": "Asset",
      "expression": { "departmentId": "dep1" }
    }
  ]
}
```

after the assignment, `iam-resource-watcher` will calculate all devices and assets using the operator which is combined by both scope and condition

calculate relation tuples for assets by operator: (scope = /Organization/org1/Subscription/{EAM} and { departmentId: dep1 })
calculate relation tuples for devices by operator: (scope = /Organization/org1/Subscription/{EAM} and { departmentId: dep1 })

```json
OBJECT                            RELATION               SUBJECT

/role/dep-device-manager          assignment             /user/Bob
/device/001                       Read                   /role/dep-device-manager#assignment
/device/001                       Update                 /role/dep-device-manager#assignment
/device/002                       Read                   /role/dep-device-manager#assignment
/device/002                       Update                 /role/dep-device-manager#assignment
/asset/001                        Read                   /role/dep-device-manager#assignment
/asset/001                        Update                 /role/dep-device-manager#assignment
/asset/002                        Read                   /role/dep-device-manager#assignment
/asset/002                        Update                 /role/dep-device-manager#assignment

all other devices ...

```

