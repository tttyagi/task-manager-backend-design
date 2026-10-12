# GraphQL Design

This document describes the GraphQL API design for the Task Manager application.

The GraphQL API provides another way to access the same data and functionality that is available through the REST API.

---

## 1. GraphQL Endpoint

The application uses a single GraphQL endpoint:

```http
POST /graphql
```

Unlike REST, GraphQL does not need a separate endpoint for every resource.

The client sends a GraphQL query or mutation to the `/graphql` endpoint.

---

## 2. Authentication

The GraphQL API uses JWT authentication.

The client sends the JWT access token using the Authorization header:

```http
Authorization: Bearer <access_token>
```

The server uses the token to identify the logged-in user.

The user ID should not be directly provided by the client for operations where the authenticated user is required.

---

# 3. GraphQL Types

## 3.1 User

```graphql
type User {
  id: ID!
  name: String!
  email: String!
  role: UserRole!
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

The password hash is not exposed through GraphQL.

---

## 3.2 Task

```graphql
type Task {
  id: ID!
  title: String!
  description: String
  status: TaskStatus!
  priority: TaskPriority!
  dueDate: Date
  createdAt: DateTime!
  updatedAt: DateTime!
  user: User!
  comments: [Comment!]!
}
```

A task contains information about its owner and comments.

---

## 3.3 Comment

```graphql
type Comment {
  id: ID!
  content: String!
  task: Task!
  user: User!
  createdAt: DateTime!
  updatedAt: DateTime!
}
```

---

## 3.4 Job

```graphql
type Job {
  id: ID!
  type: JobType!
  status: JobStatus!
  requestedBy: User!
  createdAt: DateTime!
  completedAt: DateTime
  resultUrl: String
  errorMessage: String
}
```

---

# 4. Enums

## Task Status

```graphql
enum TaskStatus {
  TODO
  IN_PROGRESS
  COMPLETED
  CANCELLED
}
```

## Task Priority

```graphql
enum TaskPriority {
  LOW
  MEDIUM
  HIGH
}
```

## User Role

```graphql
enum UserRole {
  USER
  ADMIN
}
```

## Job Status

```graphql
enum JobStatus {
  QUEUED
  RUNNING
  COMPLETED
  FAILED
}
```

## Job Type

```graphql
enum JobType {
  TASK_EXPORT
}
```

---

# 5. Query Operations

Queries are used to read data.

---

## 5.1 Get Tasks

```graphql
type Query {
  tasks(
    page: Int
    limit: Int
    status: TaskStatus
    priority: TaskPriority
  ): TaskConnection!
}
```

Example:

```graphql
query {
  tasks(page: 1, limit: 10, status: TODO) {
    data {
      id
      title
      status
      priority
      dueDate
    }
    pagination {
      page
      limit
      total
      totalPages
    }
  }
}
```

---

## 5.2 Get Single Task

```graphql
type Query {
  task(id: ID!): Task
}
```

Example:

```graphql
query {
  task(id: 1) {
    id
    title
    description
    status
    priority
    dueDate
  }
}
```

---

## 5.3 Search Tasks

```graphql
type Query {
  searchTasks(
    query: String!
    page: Int
    limit: Int
    status: TaskStatus
    priority: TaskPriority
  ): TaskConnection!
}
```

Example:

```graphql
query {
  searchTasks(query: "docker", page: 1, limit: 10) {
    data {
      id
      title
      description
      status
    }
    pagination {
      page
      limit
      total
      totalPages
    }
  }
}
```

---

## 5.4 Get Task Comments

Comments can also be requested through the task relationship.

Example:

```graphql
query {
  task(id: 1) {
    id
    title
    comments {
      id
      content
      createdAt
    }
  }
}
```

This is one of the main advantages of GraphQL because the client can request related data in the same query.

---

## 5.5 Get Job

```graphql
type Query {
  job(id: ID!): Job
}
```

Example:

```graphql
query {
  job(id: "550e8400-e29b-41d4-a716-446655440000") {
    id
    type
    status
    createdAt
    completedAt
    resultUrl
    errorMessage
  }
}
```

---

# 6. Pagination

Tasks use pagination so that the API does not return a very large number of records at once.

```graphql
type Pagination {
  page: Int!
  limit: Int!
  total: Int!
  totalPages: Int!
}
```

The task result uses this pagination object:

```graphql
type TaskConnection {
  data: [Task!]!
  pagination: Pagination!
}
```

Example:

```graphql
query {
  tasks(page: 1, limit: 10) {
    data {
      id
      title
    }
    pagination {
      page
      limit
      total
      totalPages
    }
  }
}
```

---

# 7. Input Types

Input types are used when sending data to mutations.

## Create Task Input

```graphql
input CreateTaskInput {
  title: String!
  description: String
  status: TaskStatus!
  priority: TaskPriority!
  dueDate: Date
}
```

The client does not send:

- `id`
- `userId`
- `createdAt`
- `updatedAt`

These values are handled by the server/database.

---

## Update Task Input

```graphql
input UpdateTaskInput {
  title: String!
  description: String
  status: TaskStatus!
  priority: TaskPriority!
  dueDate: Date
}
```

This input is used for a full update.

---

## Partial Update Task Input

```graphql
input PatchTaskInput {
  title: String
  description: String
  status: TaskStatus
  priority: TaskPriority
  dueDate: Date
}
```

Only the fields provided by the client are updated.

---

## Create Comment Input

```graphql
input CreateCommentInput {
  content: String!
}
```

The user ID comes from the JWT.

---

# 8. Mutation Operations

Mutations are used when data needs to be created, updated, or deleted.

---

## 8.1 Create Task

```graphql
type Mutation {
  createTask(input: CreateTaskInput!): Boolean!
}
```

Example:

```graphql
mutation {
  createTask(
    input: {
      title: "Learn Docker"
      description: "Understand Docker Compose and PostgreSQL."
      status: TODO
      priority: HIGH
      dueDate: "2026-10-20"
    }
  )
}
```

The mutation returns `true` when the task is created successfully.

The create operation does not return the created task data because the REST design requirement specifies that the create operation should return no content.

---

## 8.2 Full Update Task

```graphql
type Mutation {
  updateTask(
    id: ID!
    input: UpdateTaskInput!
  ): Task!
}
```

Example:

```graphql
mutation {
  updateTask(
    id: 1
    input: {
      title: "Learn Docker Compose"
      description: "Learn Docker Compose and PostgreSQL."
      status: IN_PROGRESS
      priority: HIGH
      dueDate: "2026-10-22"
    }
  ) {
    id
    title
    status
    priority
    dueDate
  }
}
```

---

## 8.3 Partial Update Task

```graphql
type Mutation {
  patchTask(
    id: ID!
    input: PatchTaskInput!
  ): Task!
}
```

Example:

```graphql
mutation {
  patchTask(
    id: 1
    input: {
      status: COMPLETED
    }
  ) {
    id
    title
    status
  }
}
```

Only the provided fields are changed.

---

## 8.4 Delete Task

```graphql
type Mutation {
  deleteTask(id: ID!): Boolean!
}
```

Example:

```graphql
mutation {
  deleteTask(id: 1)
}
```

The mutation returns `true` when the task is successfully deleted.

The related comments are also deleted because the database uses `ON DELETE CASCADE`.

---

## 8.5 Create Comment

```graphql
type Mutation {
  createComment(
    taskId: ID!
    input: CreateCommentInput!
  ): Boolean!
}
```

Example:

```graphql
mutation {
  createComment(
    taskId: 1
    input: {
      content: "I have reviewed this task."
    }
  )
}
```

The authenticated user's ID is taken from the JWT.

---

## 8.6 Delete Comment

```graphql
type Mutation {
  deleteComment(
    taskId: ID!
    commentId: ID!
  ): Boolean!
}
```

Example:

```graphql
mutation {
  deleteComment(
    taskId: 1
    commentId: 2
  )
}
```

---

# 9. Long-Running Task Export

Task export is handled using a background job.

## Start Export

```graphql
type Mutation {
  startTaskExport: ExportJobResponse!
}
```

Example:

```graphql
mutation {
  startTaskExport {
    jobId
    status
  }
}
```

Response:

```json
{
  "jobId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "QUEUED"
}
```

---

## Check Export Job

The client can use the `job` query to check the status:

```graphql
query {
  job(id: "550e8400-e29b-41d4-a716-446655440000") {
    id
    type
    status
    createdAt
    completedAt
    resultUrl
    errorMessage
  }
}
```

The job can move through the following states:

```text
QUEUED
   |
   v
RUNNING
   |
   +--------> COMPLETED
   |
   +--------> FAILED
```

---

# 10. Export Job Response

```graphql
type ExportJobResponse {
  jobId: ID!
  status: JobStatus!
}
```

---

# 11. Custom Scalar Types

The API uses custom scalar types for date and timestamp values.

```graphql
scalar Date
scalar DateTime
```

Example values:

```text
Date:
2026-10-20

DateTime:
2026-10-01T10:00:00Z
```

---

# 12. Complete Query Structure

The main query structure can be represented as:

```graphql
type Query {
  tasks(
    page: Int
    limit: Int
    status: TaskStatus
    priority: TaskPriority
  ): TaskConnection!

  task(id: ID!): Task

  searchTasks(
    query: String!
    page: Int
    limit: Int
    status: TaskStatus
    priority: TaskPriority
  ): TaskConnection!

  job(id: ID!): Job
}
```

---

# 13. Complete Mutation Structure

The main mutation structure can be represented as:

```graphql
type Mutation {
  createTask(input: CreateTaskInput!): Boolean!

  updateTask(
    id: ID!
    input: UpdateTaskInput!
  ): Task!

  patchTask(
    id: ID!
    input: PatchTaskInput!
  ): Task!

  deleteTask(id: ID!): Boolean!

  createComment(
    taskId: ID!
    input: CreateCommentInput!
  ): Boolean!

  deleteComment(
    taskId: ID!
    commentId: ID!
  ): Boolean!

  startTaskExport: ExportJobResponse!
}
```

---

# 14. Error Handling

GraphQL normally returns errors using the standard GraphQL `errors` response field.

Example:

```json
{
  "data": null,
  "errors": [
    {
      "message": "Task with id 10 was not found."
    }
  ]
}
```

For validation errors:

```json
{
  "data": null,
  "errors": [
    {
      "message": "Priority must be LOW, MEDIUM, or HIGH."
    }
  ]
}
```

Authentication errors can also be returned through the GraphQL error response.

For example:

```json
{
  "data": null,
  "errors": [
    {
      "message": "Unauthorized"
    }
  ]
}
```

---

# 15. Authorization

JWT is used to identify the authenticated user.

Normal users can access their own tasks and jobs.

Admins can have broader access depending on the operation.

The server gets the user information from the JWT instead of trusting a user ID provided by the client.

The detailed JWT design is documented separately in:

`docs/JWT_Design.md`

---

# 16. REST vs GraphQL

The same Task Manager functionality can be provided using both REST and GraphQL.

### REST

For example, to get a task and its comments:

```http
GET /api/v1/tasks/1
```

and:

```http
GET /api/v1/tasks/1/comments
```

### GraphQL

The client can request both in one query:

```graphql
query {
  task(id: 1) {
    id
    title
    status
    priority
    comments {
      id
      content
    }
  }
}
```

GraphQL allows the client to specify exactly which fields it needs.

---

# 17. Design Notes

The following decisions were made for the GraphQL design:

- GraphQL uses a single `/graphql` endpoint.
- Queries are used for reading data.
- Mutations are used for creating, updating, and deleting data.
- Tasks contain their related comments through GraphQL relationships.
- The client can request only the fields it needs.
- Pagination is provided for task lists.
- JWT is used for authentication.
- User identity comes from the JWT.
- Password hashes are never exposed through GraphQL.
- Enums are used for task status, priority, user role, and job status.
- Input types are used for create and update operations.
- Long-running task exports use a background job.
- GraphQL errors are returned through the standard `errors` field.