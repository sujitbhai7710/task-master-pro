# TaskMaster API - Cloudflare Worker

This is the backend API for TaskMaster Pro (Task Pro) built on Cloudflare Workers with D1 SQL database.

## Features

- User authentication (register, login, password reset)
- Task management (CRUD operations)
- Subtask management
- Category management
- Statistics and analytics

## Setup

### Prerequisites

- Node.js 18+
- Cloudflare account with D1 enabled
- Wrangler CLI installed (`npm install -g wrangler`)

### Installation

```bash
npm install
```

### Configuration

1. Create a D1 database:
```bash
wrangler d1 create taskmaster-db
```

2. Copy the database ID and update `wrangler.toml`:
```toml
[[d1_databases]]
binding = "DB"
database_name = "taskmaster-db"
database_id = "your-database-id-here"
```

3. Run the schema to create tables:
```bash
wrangler d1 execute taskmaster-db --file=./schema.sql
```

4. Update the JWT secret in `wrangler.toml`:
```toml
[vars]
JWT_SECRET = "your-secure-jwt-secret"
```

### Development

```bash
npm run dev
```

### Deployment

```bash
npm run deploy
```

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `GET /api/auth/me` - Get current user
- `POST /api/auth/verify-email` - Verify email for password reset
- `POST /api/auth/verify-security` - Verify security questions
- `POST /api/auth/reset-password` - Reset password

### Tasks

- `GET /api/tasks` - Get all tasks
- `GET /api/tasks/:id` - Get single task
- `POST /api/tasks` - Create task
- `PUT /api/tasks/:id` - Update task
- `DELETE /api/tasks/:id` - Delete task

### Subtasks

- `GET /api/tasks/:taskId/subtasks` - Get subtasks
- `POST /api/tasks/:taskId/subtasks` - Create subtask
- `PUT /api/subtasks/:id` - Update subtask
- `DELETE /api/subtasks/:id` - Delete subtask

### Categories

- `GET /api/categories` - Get all categories
- `POST /api/categories` - Create category
- `PUT /api/categories/:id` - Update category
- `DELETE /api/categories/:id` - Delete category

### Statistics

- `GET /api/statistics` - Get user statistics

## Database Schema

See `schema.sql` for the complete database schema.

## License

MIT
