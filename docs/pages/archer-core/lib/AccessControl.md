## `AccessControl`

Contract module that allows children to implement role-based access

control mechanisms.

Roles are referred to by their `bytes32` identifier. These should be exposed

in the external API and be unique. The best way to achieve this is by

using `public constant` hash digests:

```

bytes32 public constant MY_ROLE = keccak256("MY_ROLE");

```

Roles can be used to represent a set of permissions. To restrict access to a

function call, use {hasRole}:

```

function foo() public {

    require(hasRole(MY_ROLE, msg.sender));

    ...

}

```

Roles can be granted and revoked dynamically via the {grantRole} and

{revokeRole} functions. Each role has an associated admin role, and only

accounts that have a role's admin role can call {grantRole} and {revokeRole}.

By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means

that only accounts with this role will be able to grant or revoke other

roles. More complex role relationships can be created by using

{_setRoleAdmin}.

WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to

grant and revoke this role. Extra precautions should be taken to secure

accounts that have been granted it.

# Functions:

- [`hasRole(bytes32 role, address account)`](#AccessControl-hasRole-bytes32-address-)

- [`getRoleMemberCount(bytes32 role)`](#AccessControl-getRoleMemberCount-bytes32-)

- [`getRoleMember(bytes32 role, uint256 index)`](#AccessControl-getRoleMember-bytes32-uint256-)

- [`getRoleAdmin(bytes32 role)`](#AccessControl-getRoleAdmin-bytes32-)

- [`grantRole(bytes32 role, address account)`](#AccessControl-grantRole-bytes32-address-)

- [`revokeRole(bytes32 role, address account)`](#AccessControl-revokeRole-bytes32-address-)

- [`renounceRole(bytes32 role, address account)`](#AccessControl-renounceRole-bytes32-address-)

# Events:

- [`RoleAdminChanged(bytes32 role, bytes32 previousAdminRole, bytes32 newAdminRole)`](#AccessControl-RoleAdminChanged-bytes32-bytes32-bytes32-)

- [`RoleGranted(bytes32 role, address account, address sender)`](#AccessControl-RoleGranted-bytes32-address-address-)

- [`RoleRevoked(bytes32 role, address account, address sender)`](#AccessControl-RoleRevoked-bytes32-address-address-)

# Function `hasRole(bytes32 role, address account) → bool` {#AccessControl-hasRole-bytes32-address-}

No description

Returns `true` if `account` has been granted `role`.

# Function `getRoleMemberCount(bytes32 role) → uint256` {#AccessControl-getRoleMemberCount-bytes32-}

No description

Returns the number of accounts that have `role`. Can be used

together with {getRoleMember} to enumerate all bearers of a role.

# Function `getRoleMember(bytes32 role, uint256 index) → address` {#AccessControl-getRoleMember-bytes32-uint256-}

No description

Returns one of the accounts that have `role`. `index` must be a

value between 0 and {getRoleMemberCount}, non-inclusive.

Role bearers are not sorted in any particular way, and their ordering may

change at any point.

WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure

you perform all queries on the same block. See the following

https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]

for more information.

# Function `getRoleAdmin(bytes32 role) → bytes32` {#AccessControl-getRoleAdmin-bytes32-}

No description

Returns the admin role that controls `role`. See {grantRole} and

{revokeRole}.

To change a role's admin, use {_setRoleAdmin}.

# Function `grantRole(bytes32 role, address account)` {#AccessControl-grantRole-bytes32-address-}

No description

Grants `role` to `account`.

If `account` had not been already granted `role`, emits a {RoleGranted}

event.

Requirements:

- the caller must have ``role``'s admin role.

# Function `revokeRole(bytes32 role, address account)` {#AccessControl-revokeRole-bytes32-address-}

No description

Revokes `role` from `account`.

If `account` had been granted `role`, emits a {RoleRevoked} event.

Requirements:

- the caller must have ``role``'s admin role.

# Function `renounceRole(bytes32 role, address account)` {#AccessControl-renounceRole-bytes32-address-}

No description

Revokes `role` from the calling account.

Roles are often managed via {grantRole} and {revokeRole}: this function's

purpose is to provide a mechanism for accounts to lose their privileges

if they are compromised (such as when a trusted device is misplaced).

If the calling account had been granted `role`, emits a {RoleRevoked}

event.

Requirements:

- the caller must be `account`.

# Event `RoleAdminChanged(bytes32 role, bytes32 previousAdminRole, bytes32 newAdminRole)` {#AccessControl-RoleAdminChanged-bytes32-bytes32-bytes32-}

No description

Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`

`DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite

{RoleAdminChanged} not being emitted signaling this.

_Available since v3.1._

# Event `RoleGranted(bytes32 role, address account, address sender)` {#AccessControl-RoleGranted-bytes32-address-address-}

No description

Emitted when `account` is granted `role`.

`sender` is the account that originated the contract call, an admin role

bearer except when using {_setupRole}.

# Event `RoleRevoked(bytes32 role, address account, address sender)` {#AccessControl-RoleRevoked-bytes32-address-address-}

No description

Emitted when `account` is revoked `role`.

`sender` is the account that originated the contract call:

  - if using `revokeRole`, it is the admin role bearer

  - if using `renounceRole`, it is the role bearer (i.e. `account`)
