// ============================================================
// USER SERVICE — Microservice for user management
// Part of the Task Manager enterprise DevOps system (CA2)
// ============================================================

const express = require('express');
const mongoose = require('mongoose');
const morgan = require('morgan');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/taskmanager';

// Middleware
app.use(express.json());
app.use(cors());
app.use(morgan('combined'));

// ---- MongoDB Connection ----
mongoose.connect(MONGO_URI)
  .then(() => console.log('[user-service] Connected to MongoDB'))
  .catch((err) => {
    console.error('[user-service] MongoDB connection error:', err.message);
    process.exit(1);
  });

// ---- User Schema & Model ----
const userSchema = new mongoose.Schema({
  name:  { type: String, required: true },
  email: { type: String, required: true, unique: true },
  createdAt: { type: Date, default: Date.now }
});

const User = mongoose.model('User', userSchema);

// ============================================================
// ROUTES
// ============================================================

// Health check — used by Kubernetes readiness/liveness probes
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'healthy', service: 'user-service' });
});

// Create a new user
app.post('/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    if (!name || !email) {
      return res.status(400).json({ error: 'name and email are required' });
    }
    const user = new User({ name, email });
    await user.save();
    console.log(`[user-service] Created user: ${user._id}`);
    res.status(201).json(user);
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ error: 'Email already exists' });
    }
    res.status(500).json({ error: err.message });
  }
});

// Get all users
app.get('/users', async (_req, res) => {
  try {
    const users = await User.find().sort({ createdAt: -1 });
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get user by ID — called by task-service for validation
app.get('/users/:id', async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================================
// START SERVER
// ============================================================
app.listen(PORT, () => {
  console.log(`[user-service] Running on port ${PORT}`);
});
