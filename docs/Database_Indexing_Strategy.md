# Database Indexing Strategy

## 1. Introduction

Database indexes help PostgreSQL find records faster without scanning the entire table.

In our Task Manager project, indexes will improve the performance of task listing, filtering, comment retrieval, and job status queries.

However, indexes also consume storage and can slow down INSERT, UPDATE, and DELETE operations because the indexes may need to be updated.

## 2. Existing Automatic Indexes

PostgreSQL automatically creates indexes for primary keys and unique constraints.

In our database:

* `users.id` has an index because it is a primary key.
* `users.email` has an index because it has a UNIQUE constraint.
* Primary keys of `tasks`, `comments`, and `jobs` are also indexed.

We should not create duplicate indexes for these columns.

## 3. Recommended Indexes

### 3.1 Tasks by User and Creation Date

```sql
CREATE INDEX idx_tasks_user_created
ON tasks (user_id, created_at DESC);
```

**Reason:** Users frequently view their own tasks, usually ordered by creation date. This index helps PostgreSQL locate a user's tasks and retrieve them in the required order.

### 3.2 Tasks by User, Status, and Creation Date

```sql
CREATE INDEX idx_tasks_user_status_created
ON tasks (user_id, status, created_at DESC);
```

**Reason:** The task listing API supports filtering by status. This index can help when a query filters tasks by both `user_id` and `status`, then orders the results by creation date.

### 3.3 Comments by Task and Creation Date

```sql
CREATE INDEX idx_comments_task_created
ON comments (task_id, created_at ASC);
```

**Reason:** The API frequently retrieves comments belonging to a particular task. This index helps find those comments and retrieve them in chronological order.

### 3.4 Jobs by User and Creation Date

```sql
CREATE INDEX idx_jobs_user_created
ON jobs (requested_by, created_at DESC);
```

**Reason:** Users may need to retrieve their export jobs, ordered from newest to oldest. This index supports queries using the requesting user's ID and creation date.

## 4. Search Optimization

Our API supports searching tasks by title and description.

A normal B-tree index is generally not effective for searches such as:

```sql
WHERE title ILIKE '%docker%'
```

For larger datasets, we can evaluate PostgreSQL full-text search with a GIN index or trigram indexes using the `pg_trgm` extension.

The correct approach depends on the actual search requirements and query performance.

## 5. Foreign Keys and Indexes

PostgreSQL does not automatically create indexes on the referencing columns of foreign keys.

Our recommended indexes also support these relationships:

* `tasks.user_id`
* `comments.task_id`
* `jobs.requested_by`

We should also evaluate an index on `comments.user_id` if queries frequently retrieve comments by user.

## 6. Measuring Index Performance

We should use `EXPLAIN ANALYZE` to evaluate important queries against realistic data.

Example:

```sql
EXPLAIN ANALYZE
SELECT *
FROM tasks
WHERE user_id = 1
ORDER BY created_at DESC
LIMIT 10;
```

This shows the query execution plan and actual execution time.

An index is not guaranteed to improve every query. PostgreSQL may choose a sequential scan when a table is small or when a large proportion of rows must be returned.

## 7. Indexing Trade-offs

Advantages:

* Faster data retrieval for suitable queries.
* Better performance for filtering and sorting.
* Improved scalability as tables grow.

Disadvantages:

* Additional storage usage.
* Extra work during INSERT, UPDATE, and DELETE operations.
* More indexes to maintain.

We should create indexes based on actual query patterns instead of indexing every column.

## 8. Project Decision

The Task Manager project will prioritize indexes for user-specific task lists, status-filtered tasks, task comments, and user-specific export jobs.

These indexes will be reviewed using query plans and realistic data before production deployment. Index creation will be managed through database migrations when backend implementation begins.
