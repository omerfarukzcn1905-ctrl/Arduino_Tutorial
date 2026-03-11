require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const { MongoClient } = require('mongodb');

const app = express();
const PORT = process.env.PORT || 3000;

// Configuration
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/arduino_tutorial';
const MONGODB_DB = process.env.MONGODB_DB || 'arduino_tutorial';

// Middleware
app.use(cors());
app.use(express.json());

let usersCollection;

async function startServer() {
  try {
    const client = new MongoClient(MONGODB_URI, {
      useUnifiedTopology: true,
    });

    await client.connect();
    const db = client.db(MONGODB_DB);

    usersCollection = db.collection('users');
    await usersCollection.createIndex({ username: 1 }, { unique: true });

    console.log('✅ Connected to MongoDB');

    app.listen(PORT, '0.0.0.0', () => {
      console.log(`\n🚀 Arduino Backend Server running on http://0.0.0.0:${PORT}`);
      console.log(`📝 API Health Check: http://0.0.0.0:${PORT}/api/health\n`);
    });

    process.on('SIGINT', async () => {
      console.log('\nShutting down...');
      await client.close();
      process.exit(0);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

// Routes

app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Arduino backend is running' });
});

app.post('/api/register', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ success: false, message: 'Username and password are required' });
    }

    if (username.trim().length < 3) {
      return res.status(400).json({ success: false, message: 'Username must be at least 3 characters' });
    }

    if (password.length < 4) {
      return res.status(400).json({ success: false, message: 'Password must be at least 4 characters' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    await usersCollection.insertOne({
      username: username.trim(),
      password: hashedPassword,
      createdAt: new Date(),
    });

    console.log(`User registered: ${username}`);
    res.status(201).json({ success: true, message: 'Registration successful' });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ success: false, message: 'Username already exists' });
    }

    console.error('Register error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body;

    if (!username || !password) {
      return res.status(400).json({ success: false, message: 'Username and password are required' });
    }

    const user = await usersCollection.findOne({ username: username.trim() });
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid username or password' });
    }

    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ success: false, message: 'Invalid username or password' });
    }

    console.log(`User logged in: ${username}`);
    res.json({ success: true, message: 'Login successful', userId: user._id, username: user.username });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.get('/api/user/:username', async (req, res) => {
  try {
    const { username } = req.params;
    const user = await usersCollection.findOne({ username: username.trim() });

    res.json({ success: true, exists: !!user, user: user ? { username: user.username, id: user._id } : null });
  } catch (err) {
    console.error('Check user error:', err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
});

app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ success: false, message: 'Internal server error' });
});

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Endpoint not found' });
});

startServer();

