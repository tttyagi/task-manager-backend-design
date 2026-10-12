# gRPC Design

This document describes the gRPC API design for the Task Manager application.

gRPC is mainly useful for communication between backend services. In this project, the Task Manager service exposes gRPC methods for task, comment, and job operations.

---

## 1. gRPC Service

The main gRPC service is:

```protobuf
service TaskManagerService {
  // Task operations
}
```

The service communicates using Protocol Buffers (`.proto`).

The API uses strongly typed request and response messages.

---

# 2. Task Manager Service

The main service contains methods for:

- Getting tasks
- Getting a single task
- Searching tasks
- Creating tasks
- Updating tasks
- Deleting tasks
- Managing comments
- Starting task export
- Checking job status

---

# 3. Task Messages

## Task

```protobuf
message Task {
  int64 id = 1;
  int64 user_id = 2;
  string title = 3;
  string description = 4;
  TaskStatus status = 5;
  TaskPriority priority = 6;
  string due_date = 7;
  string created_at = 8;
  string updated_at = 9;
}
```

---

## Task Status

```protobuf
enum TaskStatus {
  TASK_STATUS_UNSPECIFIED = 0;
  TODO = 1;
  IN_PROGRESS = 2;
  COMPLETED = 3;
  CANCELLED = 4;
}
```

---

## Task Priority

```protobuf
enum TaskPriority {
  TASK_PRIORITY_UNSPECIFIED = 0;
  LOW = 1;
  MEDIUM = 2;
  HIGH = 3;
}
```

---

# 4. Get Tasks

The `GetTasks` method returns a paginated list of tasks.

```protobuf
rpc GetTasks(GetTasksRequest) returns (GetTasksResponse);
```

### Request

```protobuf
message GetTasksRequest {
  int32 page = 1;
  int32 limit = 2;
  TaskStatus status = 3;
  TaskPriority priority = 4;
}
```

### Response

```protobuf
message GetTasksResponse {
  repeated Task tasks = 1;
  Pagination pagination = 2;
}
```

### Example

```text
Client
   |
   | GetTasks(page=1, limit=10)
   v
TaskManagerService
   |
   v
Task list
```

---

# 5. Get Single Task

The `GetTask` method returns one task.

```protobuf
rpc GetTask(GetTaskRequest) returns (GetTaskResponse);
```

### Request

```protobuf
message GetTaskRequest {
  int64 task_id = 1;
}
```

### Response

```protobuf
message GetTaskResponse {
  Task task = 1;
}
```

---

# 6. Search Tasks

The `SearchTasks` method searches tasks using a search string.

```protobuf
rpc SearchTasks(SearchTasksRequest) returns (SearchTasksResponse);
```

### Request

```protobuf
message SearchTasksRequest {
  string query = 1;
  int32 page = 2;
  int32 limit = 3;
  TaskStatus status = 4;
  TaskPriority priority = 5;
}
```

### Response

```protobuf
message SearchTasksResponse {
  repeated Task tasks = 1;
  Pagination pagination = 2;
}
```

The search can check task titles and descriptions.

---

# 7. Create Task

The `CreateTask` method creates a new task.

```protobuf
rpc CreateTask(CreateTaskRequest) returns (CreateTaskResponse);
```

### Request

```protobuf
message CreateTaskRequest {
  string title = 1;
  string description = 2;
  TaskStatus status = 3;
  TaskPriority priority = 4;
  string due_date = 5;
}
```

The client does not provide:

- Task ID
- User ID
- Created timestamp
- Updated timestamp

The server generates these values.

The authenticated user's ID is taken from the JWT.

### Response

```protobuf
message CreateTaskResponse {
  bool success = 1;
}
```

The response only confirms whether the task was created successfully.

---

# 8. Full Update Task

The `UpdateTask` method is used for a full update.

```protobuf
rpc UpdateTask(UpdateTaskRequest) returns (UpdateTaskResponse);
```

### Request

```protobuf
message UpdateTaskRequest {
  int64 task_id = 1;
  string title = 2;
  string description = 3;
  TaskStatus status = 4;
  TaskPriority priority = 5;
  string due_date = 6;
}
```

### Response

```protobuf
message UpdateTaskResponse {
  Task task = 1;
}
```

All editable fields are expected in the request.

---

# 9. Partial Update Task

The `PatchTask` method is used for partial updates.

```protobuf
rpc PatchTask(PatchTaskRequest) returns (PatchTaskResponse);
```

### Request

```protobuf
message PatchTaskRequest {
  int64 task_id = 1;
  optional string title = 2;
  optional string description = 3;
  optional TaskStatus status = 4;
  optional TaskPriority priority = 5;
  optional string due_date = 6;
}
```

Only the fields provided by the client are changed.

### Response

```protobuf
message PatchTaskResponse {
  Task task = 1;
}
```

---

# 10. Delete Task

The `DeleteTask` method deletes a task.

```protobuf
rpc DeleteTask(DeleteTaskRequest) returns (DeleteTaskResponse);
```

### Request

```protobuf
message DeleteTaskRequest {
  int64 task_id = 1;
}
```

### Response

```protobuf
message DeleteTaskResponse {
  bool success = 1;
}
```

When a task is deleted, its related comments are also deleted because the database uses:

```text
ON DELETE CASCADE
```

---

# 11. Comment Messages

## Comment

```protobuf
message Comment {
  int64 id = 1;
  int64 task_id = 2;
  int64 user_id = 3;
  string content = 4;
  string created_at = 5;
  string updated_at = 6;
}
```

---

# 12. Get Task Comments

```protobuf
rpc GetTaskComments(GetTaskCommentsRequest) returns (GetTaskCommentsResponse);
```

### Request

```protobuf
message GetTaskCommentsRequest {
  int64 task_id = 1;
  int32 page = 2;
  int32 limit = 3;
}
```

### Response

```protobuf
message GetTaskCommentsResponse {
  repeated Comment comments = 1;
  Pagination pagination = 2;
}
```

---

# 13. Get Single Comment

```protobuf
rpc GetComment(GetCommentRequest) returns (GetCommentResponse);
```

### Request

```protobuf
message GetCommentRequest {
  int64 task_id = 1;
  int64 comment_id = 2;
}
```

### Response

```protobuf
message GetCommentResponse {
  Comment comment = 1;
}
```

The server verifies that the comment belongs to the specified task.

---

# 14. Create Comment

```protobuf
rpc CreateComment(CreateCommentRequest) returns (CreateCommentResponse);
```

### Request

```protobuf
message CreateCommentRequest {
  int64 task_id = 1;
  string content = 2;
}
```

The user ID is taken from the authenticated user's JWT.

### Response

```protobuf
message CreateCommentResponse {
  bool success = 1;
}
```

---

# 15. Delete Comment

```protobuf
rpc DeleteComment(DeleteCommentRequest) returns (DeleteCommentResponse);
```

### Request

```protobuf
message DeleteCommentRequest {
  int64 task_id = 1;
  int64 comment_id = 2;
}
```

### Response

```protobuf
message DeleteCommentResponse {
  bool success = 1;
}
```

---

# 16. Pagination

A common pagination message is used by list operations.

```protobuf
message Pagination {
  int32 page = 1;
  int32 limit = 2;
  int32 total = 3;
  int32 total_pages = 4;
}
```

This is used by:

- `GetTasks`
- `SearchTasks`
- `GetTaskComments`

---

# 17. Long-Running Task Export

Task export is handled as an asynchronous job.

## Start Task Export

```protobuf
rpc StartTaskExport(StartTaskExportRequest) returns (StartTaskExportResponse);
```

### Request

```protobuf
message StartTaskExportRequest {
}
```

No request data is required.

### Response

```protobuf
message StartTaskExportResponse {
  string job_id = 1;
  JobStatus status = 2;
}
```

Example response:

```text
job_id: "550e8400-e29b-41d4-a716-446655440000"
status: QUEUED
```

The request returns quickly while the actual export runs in the background.

---

# 18. Job Messages

## Job

```protobuf
message Job {
  string id = 1;
  string type = 2;
  JobStatus status = 3;
  int64 requested_by = 4;
  string created_at = 5;
  string completed_at = 6;
  string result_url = 7;
  string error_message = 8;
}
```

---

## Job Status

```protobuf
enum JobStatus {
  JOB_STATUS_UNSPECIFIED = 0;
  QUEUED = 1;
  RUNNING = 2;
  COMPLETED = 3;
  FAILED = 4;
}
```

---

# 19. Get Job Status

```protobuf
rpc GetJob(GetJobRequest) returns (GetJobResponse);
```

### Request

```protobuf
message GetJobRequest {
  string job_id = 1;
}
```

### Response

```protobuf
message GetJobResponse {
  Job job = 1;
}
```

The client can call this method to check whether the export job is still running or has completed.

---

# 20. Job Flow

The export process works like this:

```text
Client
   |
   | StartTaskExport()
   v
TaskManagerService
   |
   | Create Job
   v
QUEUED
   |
   v
RUNNING
   |
   +------------> COMPLETED
   |
   +------------> FAILED
```

The client does not need to wait for the export to finish.

---

# 21. Authentication

JWT is used for authentication.

The JWT access token can be passed through gRPC metadata.

Example:

```text
authorization: Bearer <access_token>
```

The server extracts the authenticated user information from the token.

The user ID should not be trusted from the request body when it can be obtained from the JWT.

---

# 22. Authorization

The service checks the authenticated user's permissions before performing operations.

### Normal User

A normal user can:

- View their own tasks
- Create tasks
- Update their own tasks
- Delete their own tasks
- Manage comments they are allowed to access
- Start task exports for their own data
- Check their own jobs

### Admin

An admin can have broader access to tasks, comments, and jobs.

Authorization is based on the user's role from the JWT.

---

# 23. gRPC Error Handling

gRPC uses standard status codes for errors.

| gRPC Status | Meaning | Example |
|---|---|---|
| OK | Request successful | Successful operation |
| INVALID_ARGUMENT | Invalid request data | Invalid task ID |
| UNAUTHENTICATED | Authentication missing or invalid | Invalid JWT |
| PERMISSION_DENIED | User is not allowed | Accessing another user's resource |
| NOT_FOUND | Resource does not exist | Task not found |
| ALREADY_EXISTS | Resource already exists | Duplicate resource |
| FAILED_PRECONDITION | Current state does not allow operation | Invalid task state |
| INTERNAL | Unexpected server error | Database/server error |

Example:

```text
NOT_FOUND
Task with id 10 was not found.
```

---

# 24. Complete Service Definition

The main service can be represented as:

```protobuf
service TaskManagerService {

  rpc GetTasks(GetTasksRequest)
      returns (GetTasksResponse);

  rpc GetTask(GetTaskRequest)
      returns (GetTaskResponse);

  rpc SearchTasks(SearchTasksRequest)
      returns (SearchTasksResponse);

  rpc CreateTask(CreateTaskRequest)
      returns (CreateTaskResponse);

  rpc UpdateTask(UpdateTaskRequest)
      returns (UpdateTaskResponse);

  rpc PatchTask(PatchTaskRequest)
      returns (PatchTaskResponse);

  rpc DeleteTask(DeleteTaskRequest)
      returns (DeleteTaskResponse);

  rpc GetTaskComments(GetTaskCommentsRequest)
      returns (GetTaskCommentsResponse);

  rpc GetComment(GetCommentRequest)
      returns (GetCommentResponse);

  rpc CreateComment(CreateCommentRequest)
      returns (CreateCommentResponse);

  rpc DeleteComment(DeleteCommentRequest)
      returns (DeleteCommentResponse);

  rpc StartTaskExport(StartTaskExportRequest)
      returns (StartTaskExportResponse);

  rpc GetJob(GetJobRequest)
      returns (GetJobResponse);
}
```

---

# 25. REST vs GraphQL vs gRPC

The Task Manager application can expose the same business functionality using different API styles.

| Feature | REST | GraphQL | gRPC |
|---|---|---|---|
| Main interface | HTTP endpoints | GraphQL endpoint | gRPC service |
| Data format | Usually JSON | JSON | Protocol Buffers |
| Contract | OpenAPI can define it | GraphQL schema | `.proto` file |
| Client controls fields | Limited | Yes | Defined by messages |
| Communication | HTTP | HTTP | HTTP/2 |
| Best suited for | Public APIs and web/mobile clients | Flexible client data requirements | Service-to-service communication |
| Type safety | Depends on implementation | Strong schema | Strong typing |
| Streaming | Possible but less common | Supported | Strong support |

For this project, REST is the main public API design, GraphQL provides flexible data querying, and gRPC is mainly considered for communication between internal backend services.

---

# 26. Design Notes

The following decisions were made for the gRPC design:

- gRPC uses a strongly typed `.proto` contract.
- The main service is `TaskManagerService`.
- Protocol Buffers are used for request and response messages.
- Enums are used for task status, task priority, and job status.
- Pagination is supported for list operations.
- Full and partial task updates are represented by separate RPC methods.
- Task comments are handled as separate RPC methods.
- Long-running exports use an asynchronous job.
- JWT is passed through gRPC metadata.
- Authentication and authorization are handled by the server.
- Standard gRPC status codes are used for errors.
- gRPC is mainly intended for internal service-to-service communication in this design.