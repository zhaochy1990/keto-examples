# Scenario 2

Background:

- user Alice is the org admin of organization org1
- Alice subscribed service `CMS`, `IDF`, `EAM` for org1

split role => role definition + role assignment

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
  id: "dep-device-manager",
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

calculate relation tuples for assets by operator: 
```js
{
  $and: [
    { scope: '/Organization/org1/Subscription/{EAM}' },
    { departmentId: dep1 }
  ]
}
```
calculate relation tuples for devices by operator:
```js
{
  $and: [
    // the following scope expression will be transfered to a tenantId expression
    // i.e.,
    // { tenantId: org1, dcid: xxx }
    { scope: '/Organization/org1/Subscription/{CMS}' },
    { "{link: Asset.deviceId}.departmentId": dep1 }
  ]
}
```

## Unified Resource Modeling

```js
Resource {
  id: "string, globally unique",
  uri: "rc:<service_providor>[:tenant: tenantId]:<resource_name>:<resource_id>",
  resource_name: "device",
  service_provider: "cms",
  tenant_id: "string"
}

ResourceProperty {
  key: "string",
  val: "string",
  resource_id: "Ref<Resource>"
}

```

suppose we are using the resource model above, and have the following resources in your application

```
Resource

id           resource_name      service_provider     tenant_id    name

5851dc72     User               IAM                  org1         Bob
6cfa21da     User               IAM                  org1         Tom
761d2f8f     RoleDefinition     IAM                  org1         device-manager 
b233506e     RoleAssignment     IAM                  org1         dep01-device-manager
d038f916     Device             CMS                  org1         device01
b24b4f92     Device             CMS                  org1         device02
3d440bc5     Asset              EAM                  org1         asset01
b233506e     Asset              EAM                  org1         asset02

...

b233506e
ba5640b2
eea94c9c
4b8b4ecf
cc884448
3bfd4aef
5f8c4b11
49cd46a0
```

after calculation the users' permissions, we got the following relation-tuples:

```
OBJECT         RESOURCE_NAME           RELATION               SUBJECT

761d2f8f       RoleDefinition          assignment             5851dc72
761d2f8f       RoleDefinition          assignment             6cfa21da
d038f916       Device                  Read                   761d2f8f#assignment
d038f916       Device                  Update                 761d2f8f#assignment
b24b4f92       Device                  Read                   761d2f8f#assignment
b24b4f92       Device                  Update                 761d2f8f#assignment
3d440bc5       Asset                   Read                   761d2f8f#assignment
3d440bc5       Asset                   Update                 761d2f8f#assignment
b233506e       Asset                   Read                   761d2f8f#assignment
b233506e       Asset                   Update                 761d2f8f#assignment
```

we could use the following list function for PG to retrieve all resources that a user has direct/indirect relation to.

```sql
CREATE OR REPLACE FUNCTION list(user_id text, relation text, type text) RETURNS SETOF relation_tuples AS $$
DECLARE
    r relations%ROWTYPE;
BEGIN
    FOR r IN SELECT * from relation_tuples AS rt
    WHERE subject = user_id
    LOOP
        IF r.relation = 'assignment' THEN
            return QUERY select * from list(r.object || '#' || r.relation, relation, type);
        ELSIF r.relation = relation AND r.resource_name = type THEN
            return NEXT r;
        END IF;
    END LOOP;
    RETURN;
END
$$ LANGUAGE plpgsql;

SELCECT * from list('6cfa21da', 'Read', 'Asset');

-- which will get the following results

OBJECT         RESOURCE_NAME           RELATION               SUBJECT

b233506e       Asset                   Read                   761d2f8f#assignment
3d440bc5       Asset                   Read                   761d2f8f#assignment
```

