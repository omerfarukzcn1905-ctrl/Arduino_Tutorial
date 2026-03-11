# Arduino Backend API

A simple Node.js/Express backend for storing and authenticating Arduino tutorial app users.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Start the server:
```bash
npm start
```

The server will run on `http://localhost:3000`

For development with auto-reload:
```bash
npm run dev
```

## API Endpoints

### Health Check
- **GET** `/api/health` - Check if server is running

### Register
- **POST** `/api/register`
- Body: `{ "username": "john", "password": "password123" }`
- Response: `{ "success": true, "message": "Registration successful", "userId": 1 }`

### Login
- **POST** `/api/login`
- Body: `{ "username": "john", "password": "password123" }`
- Response: `{ "success": true, "message": "Login successful", "userId": 1, "username": "john" }`

### Check User
- **GET** `/api/user/:username` - Check if user exists
- Response: `{ "success": true, "exists": true, "user": { "id": 1, "username": "john" } }`

## Database

Users are stored in SQLite database (`users.db`). Passwords are hashed using bcryptjs for security.

## Features

- ✅ User registration with validation
- ✅ User login with password verification
- ✅ Password hashing with bcryptjs
- ✅ SQLite persistent storage
- ✅ CORS enabled for web apps
- ✅ Error handling
- ✅ Input validation
