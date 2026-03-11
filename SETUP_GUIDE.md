# Arduino App - Backend + Frontend Setup Guide

## Step 1: Start the Backend Server

```bash
cd /home/omer/Documents/Projects/Flutter/Arduino_Tutorial/arduino_backend
npm install
npm start
```

You should see:
```
🚀 Arduino Backend Server running on http://localhost:3000
```

## Step 2: Update Flutter App

```bash
cd /home/omer/Documents/Projects/Flutter/Arduino_Tutorial/arduino_tutorial
flutter pub get
```

## Step 3: Run the Flutter App

```bash
flutter run -d chrome --web-experimental-hot-reload
```

## How It Works

1. **User Registration**: User enters username + password in Flutter app → Sends HTTP POST request to backend `/api/register` → Backend hashes password with bcryptjs → Stores in SQLite database

2. **User Login**: User enters credentials → Flask app sends HTTP POST to `/api/login` → Backend verifies password against hash → Returns success/failure

3. **Data Persistence**: All user data is stored in SQLite database on the server (not in browser localStorage)

4. **Security**: Passwords are hashed using bcryptjs, so even if the database is compromised, passwords are safe

## API Endpoints Available

- `GET /api/health` - Check server status
- `POST /api/register` - Register new user
- `POST /api/login` - Login user
- `GET /api/user/:username` - Check if username exists

## Troubleshooting

**"Error connecting to backend"**
- Make sure Node.js server is running on port 3000
- Check that you ran `npm start` in the backend folder

**"Connection refused"**
- Backend server is not running
- Try restarting: `npm start` in arduino_backend folder

**Clear database**
- Delete `users.db` file in arduino_backend folder and restart the server

## Database

User data is stored in `arduino_backend/users.db` (SQLite database)

Passwords are hashed with bcryptjs - never stored in plain text!
