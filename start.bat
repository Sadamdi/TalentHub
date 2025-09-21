@echo off
echo 🚀 Starting Talent Hub Application...

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install Node.js first.
    pause
    exit /b 1
)

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed. Please install Flutter first.
    pause
    exit /b 1
)

REM Start backend
echo 📡 Starting backend server...
cd backend
call npm install
start "Backend Server" cmd /k "npm run dev"

REM Wait for backend to start
echo ⏳ Waiting for backend to start...
timeout /t 5 /nobreak >nul

REM Start frontend
echo 📱 Starting Flutter app...
cd ..\frontend
call flutter pub get
start "Flutter App" cmd /k "flutter run"

echo ✅ Talent Hub is running!
echo 📡 Backend: http://localhost:5000
echo 📱 Frontend: Check your device/emulator
echo.
echo Press any key to exit...
pause >nul
