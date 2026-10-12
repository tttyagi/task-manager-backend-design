# JWT Design

This document describes how JWT authentication will be used in the Task Manager application.

JWT is used to identify the authenticated user and to control access to protected APIs.

---

## 1. What is JWT?

JWT stands for JSON Web Token.

After a user successfully logs in, the authentication system generates an access token.

The client sends this token with requests to protected APIs.

Example:

```http
Authorization: Bearer <access_token>
```

The server verifies the token before allowing the request.

---

## 2. JWT Structure

A JWT contains three main parts:

```text
Header.Payload.Signature
```

### Header

The header contains information about the token type and signing algorithm.

Example:

```json
{
  "alg": "RS256",
  "typ": "JWT"
}
```

### Payload

The payload contains claims about the user and token.

### Signature

The signature is used by the server to verify that the token was not modified.

---

# 3. JWT Claims

The Task Manager application uses the following claims.

| Claim | Purpose |
|---|---|
| `sub` | User ID |
| `role` | User role |
| `email` | User email |
| `iat` | Token issued time |
| `exp` | Token expiration time |
| `iss` | Token issuer |
| `aud` | Intended audience |
| `jti` | Unique token ID |

---

## 3.1 Subject - `sub`

The `sub` claim identifies the user.

Example:

```json
{
  "sub": "1"
}
```

In this application, the value represents the user's ID.

The API should use the `sub` claim to identify the authenticated user instead of trusting a user ID sent by the client.

---

## 3.2 Role - `role`

The `role` claim represents the user's role.

Possible values are:

```text
USER
ADMIN
```

Example:

```json
{
  "sub": "1",
  "role": "ADMIN"
}
```

The role can be used for authorization checks.

For example, an admin may have access to all tasks while a normal user may only access their own tasks.

---

## 3.3 Email - `email`

The user's email can be included in the token.

Example:

```json
{
  "email": "tanishak@example.com"
}
```

The application should not use the email as the main identifier because the `sub` claim already identifies the user.

---

## 3.4 Issued At - `iat`

The `iat` claim represents when the token was issued.

Example:

```json
{
  "iat": 1790848800
}
```

The value is normally represented as a Unix timestamp.

---

## 3.5 Expiration - `exp`

The `exp` claim represents when the token expires.

Example:

```json
{
  "exp": 1790852400
}
```

After this time, the access token should no longer be accepted.

Short-lived access tokens reduce the risk of a stolen token being usable for a long time.

---

## 3.6 Issuer - `iss`

The `iss` claim identifies who issued the token.

Example:

```json
{
  "iss": "task-manager-auth"
}
```

The API can verify that the token was issued by the expected authentication service.

---

## 3.7 Audience - `aud`

The `aud` claim identifies the service for which the token is intended.

Example:

```json
{
  "aud": "task-manager-api"
}
```

The API should verify that the token is intended for the Task Manager API.

---

## 3.8 JWT ID - `jti`

The `jti` claim is a unique identifier for the token.

Example:

```json
{
  "jti": "7f4c7b8e-4d3e-4f4a-9f11-123456789abc"
}
```

It can be useful for token tracking or revocation.

---

# 4. Example Access Token Payload

A complete example payload can look like:

```json
{
  "sub": "1",
  "email": "tanishak@example.com",
  "role": "ADMIN",
  "iat": 1790848800,
  "exp": 1790852400,
  "iss": "task-manager-auth",
  "aud": "task-manager-api",
  "jti": "7f4c7b8e-4d3e-4f4a-9f11-123456789abc"
}
```

This payload tells the API:

- Which user is making the request
- What role the user has
- When the token was issued
- When the token expires
- Who issued the token
- Which API the token is intended for
- Which specific token is being used

---

# 5. Access Token Flow

The authentication flow can be represented as:

```text
User
 |
 | Login
 v
Authentication Service
 |
 | Verify credentials
 v
Generate JWT
 |
 | Access Token
 v
Client
 |
 | Authorization: Bearer <token>
 v
Task Manager API
 |
 | Verify JWT
 v
Allow / Deny Request
```

---

# 6. JWT Verification

For every protected API request, the server should verify:

1. The token exists.
2. The token has a valid signature.
3. The token has not expired.
4. The issuer is correct.
5. The audience is correct.
6. Required claims are present.
7. The user's role is allowed to perform the requested operation.

If verification fails, the API returns an authentication error.

For REST:

```http
401 Unauthorized
```

For gRPC:

```text
UNAUTHENTICATED
```

---

# 7. Authorization

Authentication answers:

> Who is the user?

Authorization answers:

> Is this user allowed to perform this operation?

The `sub` and `role` claims are mainly used for authorization.

### Example

Suppose the token contains:

```json
{
  "sub": "2",
  "role": "USER"
}
```

If user `2` requests their own task:

```text
Allowed
```

If user `2` tries to modify another user's task:

```text
Forbidden
```

An admin token can provide broader access.

---

# 8. JWT and Task Ownership

The application should not trust the client to provide the task owner.

For example, the client should not send:

```json
{
  "title": "Learn Docker",
  "userId": 5
}
```

Instead, the API gets the user ID from the JWT:

```text
JWT
 |
 | sub = 5
 v
Authenticated User
 |
 v
Create Task for User 5
```

This prevents users from simply changing the `userId` value in the request.

---

# 9. JWT with REST API

A REST request to create a task would look like:

```http
POST /api/v1/tasks
Authorization: Bearer <access_token>
Content-Type: application/json
```

Request body:

```json
{
  "title": "Learn Docker",
  "description": "Understand Docker Compose.",
  "status": "TODO",
  "priority": "HIGH",
  "dueDate": "2026-10-20"
}
```

The API gets the user ID from the JWT and creates the task for that user.

---

# 10. JWT with GraphQL

The JWT is sent through the HTTP Authorization header:

```http
Authorization: Bearer <access_token>
```

The GraphQL server verifies the token before executing protected queries and mutations.

Example:

```graphql
mutation {
  createTask(
    input: {
      title: "Learn Docker"
      description: "Understand Docker Compose."
      status: TODO
      priority: HIGH
      dueDate: "2026-10-20"
    }
  )
}
```

The user identity comes from the JWT.

---

# 11. JWT with gRPC

For gRPC, the JWT can be sent using gRPC metadata.

Example:

```text
authorization: Bearer <access_token>
```

The gRPC server verifies the token before executing the RPC method.

The authenticated user information can then be used by the service for authorization.

---

# 12. Access Token Expiration

Access tokens should be short-lived.

For example:

```text
Access Token Lifetime: 15 minutes
```

After the access token expires, the client needs to obtain a new access token.

Short-lived tokens reduce the impact of a stolen access token.

The exact expiration time can be changed based on application requirements.

---

# 13. Refresh Token

A refresh token can be used to obtain a new access token without requiring the user to log in again.

Basic flow:

```text
Access Token
     |
     | Expires
     v
Refresh Token
     |
     | Request new access token
     v
Authentication Service
     |
     v
New Access Token
```

Refresh tokens should be handled more carefully than access tokens and should not normally be sent with every API request.

---

# 14. Token Storage

The client application should store tokens securely.

The exact storage mechanism depends on the type of client.

For browser applications, secure cookie-based approaches can be considered.

For mobile or other clients, secure platform storage can be used.

Tokens should not be exposed unnecessarily to JavaScript or logs.

---

# 15. Sensitive Information

The JWT payload should not contain sensitive information such as:

- Passwords
- Password hashes
- Database credentials
- API keys
- Private secrets

JWT payload data should be considered readable by the token holder.

The signature protects the integrity of the token but does not make the payload secret.

---

# 16. Signing Algorithm

The design uses an asymmetric signing algorithm such as:

```text
RS256
```

With asymmetric signing:

```text
Private Key
    |
    | Sign
    v
JWT
    |
    | Verify
    v
Public Key
```

The private key is kept only by the authentication service.

The API can use the public key to verify the token.

The private key must never be exposed to clients.

---

# 17. Token Security

The following security practices should be followed:

- Use HTTPS in production.
- Use short-lived access tokens.
- Keep signing keys secure.
- Never put passwords or secrets in JWT claims.
- Validate the token signature.
- Validate `exp`.
- Validate `iss`.
- Validate `aud`.
- Check user roles before protected operations.
- Do not trust user IDs supplied by clients when the user identity is available from JWT.
- Avoid logging complete JWT tokens.

---

# 18. Authentication Errors

### Missing Token

If a protected endpoint is called without a token:

```http
401 Unauthorized
```

### Invalid Token

If the token has an invalid signature or format:

```http
401 Unauthorized
```

### Expired Token

If the token has expired:

```http
401 Unauthorized
```

### Insufficient Permission

If the user is authenticated but does not have permission:

```http
403 Forbidden
```

---

# 19. JWT Claims Summary

| Claim | Example | Purpose |
|---|---|---|
| `sub` | `1` | User ID |
| `email` | `tanishak@example.com` | User email |
| `role` | `ADMIN` | User role |
| `iat` | `1790848800` | Token issued time |
| `exp` | `1790852400` | Token expiration time |
| `iss` | `task-manager-auth` | Token issuer |
| `aud` | `task-manager-api` | Intended API |
| `jti` | UUID | Unique token ID |

---

# 20. Design Notes

The following decisions were made for the JWT design:

- JWT is used for authentication.
- `sub` is used as the main user identifier.
- `role` is used for authorization.
- Access tokens are short-lived.
- Refresh tokens can be used to obtain new access tokens.
- `iss` and `aud` are validated by the API.
- `exp` is checked to prevent expired tokens from being used.
- RS256 is preferred for signing because it uses separate private and public keys.
- Passwords and other sensitive information are never stored in JWT claims.
- JWT is sent using the Bearer token format for REST and GraphQL.
- JWT can be passed through metadata for gRPC.
- The API uses the authenticated user from the JWT instead of trusting a user ID supplied by the client.