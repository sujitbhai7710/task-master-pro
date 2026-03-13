import { Router } from 'itty-router';
import { jwtSign, jwtVerify, hashPassword, verifyPassword } from './auth';
import { corsHeaders, handleOptions } from './cors';

// Create router
const router = Router();

// Export D1 database binding
interface Env {
  DB: D1Database;
  JWT_SECRET: string;
  ENVIRONMENT: string;
}

// Helper to parse JSON body
async function parseBody(request: Request): Promise<any> {
  try {
    return await request.json();
  } catch {
    return {};
  }
}

// Helper to generate unique ID
function generateId(): string {
  return crypto.randomUUID();
}

// CORS preflight
router.options('*', () => new Response(null, { headers: corsHeaders }));

// Health check
router.get('/api/health', () => {
  return new Response(JSON.stringify({ status: 'ok', timestamp: new Date().toISOString() }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
});

// Register
router.post('/api/auth/register', async (request: Request, env: Env) => {
  try {
    const body = await parseBody(request);
    const { email, password, name, full_name, date_of_birth } = body;

    if (!email || !password || !name) {
      return new Response(JSON.stringify({ error: 'Email, password, and name are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    if (password.length < 6) {
      return new Response(JSON.stringify({ error: 'Password must be at least 6 characters' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Check if email exists
    const existingUser = await env.DB.prepare(
      'SELECT id FROM users WHERE email = ?'
    ).bind(email.toLowerCase()).first();

    if (existingUser) {
      return new Response(JSON.stringify({ error: 'Email already registered' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Hash password
    const hashedPassword = await hashPassword(password);
    const userId = generateId();

    // Insert user
    await env.DB.prepare(
      'INSERT INTO users (id, email, password, name, full_name, date_of_birth, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)'
    ).bind(
      userId,
      email.toLowerCase(),
      hashedPassword,
      name,
      full_name || name,
      date_of_birth || null,
      new Date().toISOString()
    ).run();

    // Generate JWT token
    const token = await jwtSign({ userId, email }, env.JWT_SECRET);

    // Get created user
    const user = await env.DB.prepare(
      'SELECT id, email, name, full_name, date_of_birth, created_at FROM users WHERE id = ?'
    ).bind(userId).first();

    return new Response(JSON.stringify({ 
      user,
      token 
    }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Register error:', error);
    return new Response(JSON.stringify({ error: 'Registration failed', details: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Login
router.post('/api/auth/login', async (request: Request, env: Env) => {
  try {
    const body = await parseBody(request);
    const { email, password } = body;

    if (!email || !password) {
      return new Response(JSON.stringify({ error: 'Email and password are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Get user
    const user = await env.DB.prepare(
      'SELECT * FROM users WHERE email = ?'
    ).bind(email.toLowerCase()).first();

    if (!user) {
      return new Response(JSON.stringify({ error: 'Invalid credentials' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Verify password
    const isValid = await verifyPassword(password, user.password as string);
    if (!isValid) {
      return new Response(JSON.stringify({ error: 'Invalid credentials' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Generate JWT token
    const token = await jwtSign({ userId: user.id, email: user.email }, env.JWT_SECRET);

    // Return user without password
    const { password: _, ...userWithoutPassword } = user as any;

    return new Response(JSON.stringify({ 
      user: userWithoutPassword,
      token 
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Login error:', error);
    return new Response(JSON.stringify({ error: 'Login failed', details: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get current user
router.get('/api/auth/me', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);

    const user = await env.DB.prepare(
      'SELECT id, email, name, full_name, date_of_birth, created_at FROM users WHERE id = ?'
    ).bind(decoded.userId).first();

    if (!user) {
      return new Response(JSON.stringify({ error: 'User not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({ user }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Get user error:', error);
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Verify Email for Password Reset
router.post('/api/auth/verify-email', async (request: Request, env: Env) => {
  try {
    const body = await parseBody(request);
    const { email } = body;

    if (!email) {
      return new Response(JSON.stringify({ error: 'Email is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Check if user exists
    const user = await env.DB.prepare(
      'SELECT id FROM users WHERE email = ?'
    ).bind(email.toLowerCase()).first();

    if (!user) {
      return new Response(JSON.stringify({ error: 'Email not found', exists: false }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({ 
      exists: true,
      message: 'Email verified. Please answer security questions.'
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Verify email error:', error);
    return new Response(JSON.stringify({ error: 'Verification failed' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Verify Security Answers for Password Reset
router.post('/api/auth/verify-security', async (request: Request, env: Env) => {
  try {
    const body = await parseBody(request);
    const { email, full_name, date_of_birth } = body;

    if (!email || !full_name || !date_of_birth) {
      return new Response(JSON.stringify({ error: 'All fields are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Get user with security details
    const user = await env.DB.prepare(
      'SELECT id, full_name, date_of_birth FROM users WHERE email = ?'
    ).bind(email.toLowerCase()).first();

    if (!user) {
      return new Response(JSON.stringify({ error: 'User not found', verified: false }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Normalize date format for comparison
    const normalizeDate = (dateStr: string): string => {
      // Handle both DD/MM/YYYY and YYYY-MM-DD formats
      if (dateStr.includes('/')) {
        return dateStr;
      }
      const parts = dateStr.split('-');
      if (parts.length === 3) {
        return `${parts[2]}/${parts[1]}/${parts[0]}`;
      }
      return dateStr;
    };

    const userDob = normalizeDate(user.date_of_birth as string || '');
    const inputDob = normalizeDate(date_of_birth);

    // Compare full name (case insensitive) and date of birth
    const nameMatch = (user.full_name as string || '').toLowerCase().trim() === full_name.toLowerCase().trim();
    const dobMatch = userDob === inputDob;

    if (!nameMatch || !dobMatch) {
      return new Response(JSON.stringify({ 
        error: 'Security verification failed. Please check your details.',
        verified: false 
      }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({ 
      verified: true,
      message: 'Identity verified. You can now reset your password.'
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Verify security error:', error);
    return new Response(JSON.stringify({ error: 'Verification failed' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Reset Password
router.post('/api/auth/reset-password', async (request: Request, env: Env) => {
  try {
    const body = await parseBody(request);
    const { email, new_password } = body;

    if (!email || !new_password) {
      return new Response(JSON.stringify({ error: 'Email and new password are required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    if (new_password.length < 6) {
      return new Response(JSON.stringify({ error: 'Password must be at least 6 characters' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Check if user exists
    const user = await env.DB.prepare(
      'SELECT id FROM users WHERE email = ?'
    ).bind(email.toLowerCase()).first();

    if (!user) {
      return new Response(JSON.stringify({ error: 'User not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Hash new password
    const hashedPassword = await hashPassword(new_password);

    // Update password
    await env.DB.prepare(
      'UPDATE users SET password = ? WHERE email = ?'
    ).bind(hashedPassword, email.toLowerCase()).run();

    return new Response(JSON.stringify({ 
      success: true,
      message: 'Password reset successfully'
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Reset password error:', error);
    return new Response(JSON.stringify({ error: 'Password reset failed' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// ==================== TASKS ====================

// Get all tasks for user
router.get('/api/tasks', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);

    const tasks = await env.DB.prepare(
      'SELECT * FROM tasks WHERE user_id = ? ORDER BY created_at DESC'
    ).bind(decoded.userId).all();

    return new Response(JSON.stringify({ tasks: tasks.results }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Get tasks error:', error);
    return new Response(JSON.stringify({ error: 'Failed to get tasks' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Get single task
router.get('/api/tasks/:id', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);
    const taskId = (request as any).params.id;

    const task = await env.DB.prepare(
      'SELECT * FROM tasks WHERE id = ? AND user_id = ?'
    ).bind(taskId, decoded.userId).first();

    if (!task) {
      return new Response(JSON.stringify({ error: 'Task not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    return new Response(JSON.stringify({ task }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Get task error:', error);
    return new Response(JSON.stringify({ error: 'Failed to get task' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Create task
router.post('/api/tasks', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);
    const body = await parseBody(request);

    const taskId = generateId();
    const now = new Date().toISOString();

    await env.DB.prepare(
      `INSERT INTO tasks (id, user_id, title, description, status, priority, category_id, due_date, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`
    ).bind(
      taskId,
      decoded.userId,
      body.title || 'Untitled Task',
      body.description || null,
      body.status || 'pending',
      body.priority || 'medium',
      body.category_id || null,
      body.due_date || null,
      now,
      now
    ).run();

    const task = await env.DB.prepare(
      'SELECT * FROM tasks WHERE id = ?'
    ).bind(taskId).first();

    return new Response(JSON.stringify({ task }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Create task error:', error);
    return new Response(JSON.stringify({ error: 'Failed to create task', details: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Update task
router.put('/api/tasks/:id', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);
    const taskId = (request as any).params.id;
    const body = await parseBody(request);

    // Check task exists and belongs to user
    const existingTask = await env.DB.prepare(
      'SELECT id FROM tasks WHERE id = ? AND user_id = ?'
    ).bind(taskId, decoded.userId).first();

    if (!existingTask) {
      return new Response(JSON.stringify({ error: 'Task not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const now = new Date().toISOString();

    await env.DB.prepare(
      `UPDATE tasks SET 
        title = COALESCE(?, title),
        description = COALESCE(?, description),
        status = COALESCE(?, status),
        priority = COALESCE(?, priority),
        category_id = COALESCE(?, category_id),
        due_date = COALESCE(?, due_date),
        updated_at = ?
       WHERE id = ? AND user_id = ?`
    ).bind(
      body.title,
      body.description,
      body.status,
      body.priority,
      body.category_id,
      body.due_date,
      now,
      taskId,
      decoded.userId
    ).run();

    const task = await env.DB.prepare(
      'SELECT * FROM tasks WHERE id = ?'
    ).bind(taskId).first();

    return new Response(JSON.stringify({ task }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Update task error:', error);
    return new Response(JSON.stringify({ error: 'Failed to update task' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Delete task
router.delete('/api/tasks/:id', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);
    const taskId = (request as any).params.id;

    // Check task exists and belongs to user
    const existingTask = await env.DB.prepare(
      'SELECT id FROM tasks WHERE id = ? AND user_id = ?'
    ).bind(taskId, decoded.userId).first();

    if (!existingTask) {
      return new Response(JSON.stringify({ error: 'Task not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Delete subtasks first
    await env.DB.prepare(
      'DELETE FROM subtasks WHERE task_id = ?'
    ).bind(taskId).run();

    // Delete task
    await env.DB.prepare(
      'DELETE FROM tasks WHERE id = ? AND user_id = ?'
    ).bind(taskId, decoded.userId).run();

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Delete task error:', error);
    return new Response(JSON.stringify({ error: 'Failed to delete task' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// ==================== SUBTASKS ====================

// Get subtasks for a task
router.get('/api/tasks/:taskId/subtasks', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);
    const taskId = (request as any).params.taskId;

    const subtasks = await env.DB.prepare(
      `SELECT s.* FROM subtasks s 
       JOIN tasks t ON s.task_id = t.id 
       WHERE s.task_id = ? AND t.user_id = ?
       ORDER BY s.created_at ASC`
    ).bind(taskId, decoded.userId).all();

    return new Response(JSON.stringify({ subtasks: subtasks.results }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Get subtasks error:', error);
    return new Response(JSON.stringify({ error: 'Failed to get subtasks' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Create subtask
router.post('/api/tasks/:taskId/subtasks', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);
    const taskId = (request as any).params.taskId;
    const body = await parseBody(request);

    // Check task exists and belongs to user
    const task = await env.DB.prepare(
      'SELECT id FROM tasks WHERE id = ? AND user_id = ?'
    ).bind(taskId, decoded.userId).first();

    if (!task) {
      return new Response(JSON.stringify({ error: 'Task not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const subtaskId = generateId();
    const now = new Date().toISOString();

    await env.DB.prepare(
      `INSERT INTO subtasks (id, task_id, title, completed, created_at)
       VALUES (?, ?, ?, ?, ?)`
    ).bind(
      subtaskId,
      taskId,
      body.title || 'Untitled Subtask',
      body.completed ? 1 : 0,
      now
    ).run();

    const subtask = await env.DB.prepare(
      'SELECT * FROM subtasks WHERE id = ?'
    ).bind(subtaskId).first();

    return new Response(JSON.stringify({ subtask }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Create subtask error:', error);
    return new Response(JSON.stringify({ error: 'Failed to create subtask' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Update subtask
router.put('/api/subtasks/:id', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);
    const subtaskId = (request as any).params.id;
    const body = await parseBody(request);

    // Check subtask belongs to user's task
    const existingSubtask = await env.DB.prepare(
      `SELECT s.id FROM subtasks s 
       JOIN tasks t ON s.task_id = t.id 
       WHERE s.id = ? AND t.user_id = ?`
    ).bind(subtaskId, decoded.userId).first();

    if (!existingSubtask) {
      return new Response(JSON.stringify({ error: 'Subtask not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    await env.DB.prepare(
      `UPDATE subtasks SET 
        title = COALESCE(?, title),
        completed = COALESCE(?, completed)
       WHERE id = ?`
    ).bind(
      body.title,
      body.completed !== undefined ? (body.completed ? 1 : 0) : null,
      subtaskId
    ).run();

    const subtask = await env.DB.prepare(
      'SELECT * FROM subtasks WHERE id = ?'
    ).bind(subtaskId).first();

    return new Response(JSON.stringify({ subtask }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Update subtask error:', error);
    return new Response(JSON.stringify({ error: 'Failed to update subtask' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Delete subtask
router.delete('/api/subtasks/:id', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);
    const subtaskId = (request as any).params.id;

    // Check subtask belongs to user's task
    const existingSubtask = await env.DB.prepare(
      `SELECT s.id FROM subtasks s 
       JOIN tasks t ON s.task_id = t.id 
       WHERE s.id = ? AND t.user_id = ?`
    ).bind(subtaskId, decoded.userId).first();

    if (!existingSubtask) {
      return new Response(JSON.stringify({ error: 'Subtask not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    await env.DB.prepare(
      'DELETE FROM subtasks WHERE id = ?'
    ).bind(subtaskId).run();

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Delete subtask error:', error);
    return new Response(JSON.stringify({ error: 'Failed to delete subtask' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// ==================== CATEGORIES ====================

// Get all categories for user
router.get('/api/categories', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);

    const categories = await env.DB.prepare(
      'SELECT * FROM categories WHERE user_id = ? ORDER BY name ASC'
    ).bind(decoded.userId).all();

    return new Response(JSON.stringify({ categories: categories.results }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Get categories error:', error);
    return new Response(JSON.stringify({ error: 'Failed to get categories' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Create category
router.post('/api/categories', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);
    const body = await parseBody(request);

    const categoryId = generateId();
    const now = new Date().toISOString();

    await env.DB.prepare(
      `INSERT INTO categories (id, user_id, name, color, icon, created_at)
       VALUES (?, ?, ?, ?, ?, ?)`
    ).bind(
      categoryId,
      decoded.userId,
      body.name || 'Untitled Category',
      body.color || '#6366F1',
      body.icon || 'folder',
      now
    ).run();

    const category = await env.DB.prepare(
      'SELECT * FROM categories WHERE id = ?'
    ).bind(categoryId).first();

    return new Response(JSON.stringify({ category }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Create category error:', error);
    return new Response(JSON.stringify({ error: 'Failed to create category' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Update category
router.put('/api/categories/:id', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);
    const categoryId = (request as any).params.id;
    const body = await parseBody(request);

    // Check category belongs to user
    const existingCategory = await env.DB.prepare(
      'SELECT id FROM categories WHERE id = ? AND user_id = ?'
    ).bind(categoryId, decoded.userId).first();

    if (!existingCategory) {
      return new Response(JSON.stringify({ error: 'Category not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    await env.DB.prepare(
      `UPDATE categories SET 
        name = COALESCE(?, name),
        color = COALESCE(?, color),
        icon = COALESCE(?, icon)
       WHERE id = ? AND user_id = ?`
    ).bind(
      body.name,
      body.color,
      body.icon,
      categoryId,
      decoded.userId
    ).run();

    const category = await env.DB.prepare(
      'SELECT * FROM categories WHERE id = ?'
    ).bind(categoryId).first();

    return new Response(JSON.stringify({ category }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Update category error:', error);
    return new Response(JSON.stringify({ error: 'Failed to update category' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// Delete category
router.delete('/api/categories/:id', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);
    const categoryId = (request as any).params.id;

    // Check category belongs to user
    const existingCategory = await env.DB.prepare(
      'SELECT id FROM categories WHERE id = ? AND user_id = ?'
    ).bind(categoryId, decoded.userId).first();

    if (!existingCategory) {
      return new Response(JSON.stringify({ error: 'Category not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Set category_id to null for tasks using this category
    await env.DB.prepare(
      'UPDATE tasks SET category_id = NULL WHERE category_id = ?'
    ).bind(categoryId).run();

    // Delete category
    await env.DB.prepare(
      'DELETE FROM categories WHERE id = ? AND user_id = ?'
    ).bind(categoryId, decoded.userId).run();

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Delete category error:', error);
    return new Response(JSON.stringify({ error: 'Failed to delete category' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// ==================== STATISTICS ====================

router.get('/api/statistics', async (request: Request, env: Env) => {
  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const token = authHeader.substring(7);
    const decoded = await jwtVerify(token, env.JWT_SECRET);

    // Get task counts by status
    const statusCounts = await env.DB.prepare(
      `SELECT status, COUNT(*) as count FROM tasks 
       WHERE user_id = ? 
       GROUP BY status`
    ).bind(decoded.userId).all();

    // Get task counts by priority
    const priorityCounts = await env.DB.prepare(
      `SELECT priority, COUNT(*) as count FROM tasks 
       WHERE user_id = ? 
       GROUP BY priority`
    ).bind(decoded.userId).all();

    // Get total tasks
    const totalResult = await env.DB.prepare(
      'SELECT COUNT(*) as total FROM tasks WHERE user_id = ?'
    ).bind(decoded.userId).first();

    // Get completed subtasks
    const subtaskResult = await env.DB.prepare(
      `SELECT COUNT(*) as completed FROM subtasks s
       JOIN tasks t ON s.task_id = t.id
       WHERE t.user_id = ? AND s.completed = 1`
    ).bind(decoded.userId).first();

    // Get overdue tasks
    const overdueResult = await env.DB.prepare(
      `SELECT COUNT(*) as overdue FROM tasks 
       WHERE user_id = ? 
       AND due_date < date('now') 
       AND status != 'completed'`
    ).bind(decoded.userId).first();

    return new Response(JSON.stringify({
      total_tasks: totalResult?.total || 0,
      status_breakdown: statusCounts.results,
      priority_breakdown: priorityCounts.results,
      completed_subtasks: subtaskResult?.completed || 0,
      overdue_tasks: overdueResult?.overdue || 0
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  } catch (error: any) {
    console.error('Statistics error:', error);
    return new Response(JSON.stringify({ error: 'Failed to get statistics' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});

// 404 handler
router.all('*', () => {
  return new Response(JSON.stringify({ error: 'Not Found' }), {
    status: 404,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
});

// Export the worker
export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    return router.handle(request, env, ctx);
  }
};
