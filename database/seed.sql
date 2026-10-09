INSERT INTO users (name, email, password_hash, role)
VALUES
    ('Tanishak Tyagi', 'tanishak@example.com', 'seed-hash-user-1', 'ADMIN'),
    ('Rahul Sharma', 'rahul@example.com', 'seed-hash-user-2', 'USER'),
    ('Priya Singh', 'priya@example.com', 'seed-hash-user-3', 'USER');




INSERT INTO tasks (
    user_id,
    title,
    description,
    status,
    priority,
    due_date
)
VALUES
    (
        1,
        'Complete backend design',
        'Finish the database and API design for the Task Manager application.',
        'IN_PROGRESS',
        'HIGH',
        '2026-10-15'
    ),
    (
        1,
        'Review API documentation',
        'Review the REST, GraphQL, and gRPC API designs.',
        'TODO',
        'MEDIUM',
        '2026-10-18'
    ),
    (
        2,
        'Prepare project notes',
        'Prepare notes for the upcoming project discussion.',
        'COMPLETED',
        'LOW',
        '2026-10-10'
    ),
    (
        3,
        'Test task workflow',
        'Check the task status and priority workflow.',
        'TODO',
        'HIGH',
        '2026-10-20'
    );



    INSERT INTO comments (
    task_id,
    user_id,
    content
)
VALUES
    (
        1,
        2,
        'The database design looks good. Continue with the API documentation.'
    ),
    (
        1,
        3,
        'Make sure the REST API handles validation errors properly.'
    ),
    (
        2,
        1,
        'I will review the API documentation after completing the database design.'
    ),
    (
        3,
        1,
        'This task has been completed successfully.'
    );



    INSERT INTO jobs (
    type,
    status,
    requested_by,
    completed_at,
    result_url,
    error_message
)
VALUES
    (
        'TASK_EXPORT',
        'COMPLETED',
        1,
        CURRENT_TIMESTAMP,
        '/exports/tasks-1.csv',
        NULL
    ),
    (
        'TASK_EXPORT',
        'RUNNING',
        2,
        NULL,
        NULL,
        NULL
    ),
    (
        'TASK_EXPORT',
        'FAILED',
        3,
        CURRENT_TIMESTAMP,
        NULL,
        'Unable to generate task export.'
    );