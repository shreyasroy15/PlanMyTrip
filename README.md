# PlanMyTrip AI - Complete Travel Planning & Enterprise Authentication System

PlanMyTrip AI is an intelligent travel planning mobile and web application built with **Flutter** (frontend) and **Node.js / Express / MongoDB** (backend). It features complete enterprise-grade authentication, session management, social logins, multi-channel OTP verification, responsive layouts, and AI-driven itinerary management.

---

## 🏗️ System Architecture

```mermaid
graph TD
    Client[Flutter Client Application<br/>(iOS, Android, Web, Desktop)]
    
    subgraph Core Flutter Layer
        ApiClient[ApiClient with Dio & Mutex Refresh]
        TokenStorage[TokenStorage with FlutterSecureStorage]
        AuthProvider[Riverpod AuthProvider & State]
    end

    subgraph Backend Services (Port 5000)
        Express[Node.js Express REST API]
        AuthCtrl[AuthController & Rate Limiters]
        TokenSvc[TokenService & Rotation Engine]
        EmailSvc[Nodemailer Email Service]
        SmsSvc[Twilio SMS Service]
        GoogleAuth[Google OAuth2 Client]
        AppleAuth[Apple JWKS RSA Validator]
    end

    subgraph Database
        MongoDB[(MongoDB Database<br/>Users, RefreshTokens, OTPs, AuditLogs)]
    end

    Client --> ApiClient
    ApiClient --> Express
    Express --> AuthCtrl
    AuthCtrl --> TokenSvc
    AuthCtrl --> EmailSvc
    AuthCtrl --> SmsSvc
    AuthCtrl --> GoogleAuth
    AuthCtrl --> AppleAuth
    TokenSvc --> MongoDB
```

---

## ✨ Features Implemented

### 1. Complete Login Flow
- Clean, responsive glassmorphism UI matching PlanMyTrip AI visual branding.
- Email & password authentication with client-side and server-side validation.
- Show / hide password visibility toggle.
- "Remember me" option persisting user email across app restarts.
- Centralized error banner displaying server error codes (`INVALID_CREDENTIALS`, `ACCOUNT_LOCKED`, `UNVERIFIED_EMAIL`).
- Integrated single-tap **Continue with Google** and **Continue with Apple** buttons.
- Direct link to **Sign In with One-Time Code (OTP)**.
- Deep link to **Forgot Password** recovery.

### 2. Complete Signup / Create Account
- Full name, email address, optional phone number, password, and password confirmation.
- Password policy enforcement (minimum 8 characters, upper/lowercase, numbers, special characters).
- Mandatory Terms of Service & Privacy Policy agreement checkbox.
- Passwords securely hashed with `bcryptjs` (salt rounds: 12); plaintext passwords are never stored or logged.
- Account creation automatically generates an email verification challenge and sends an onboarding welcome email.

### 3. Email & Phone OTP Authentication
- **Email OTP**: Cryptographically random 6-digit codes hashed with `bcrypt`, 5-minute TTL index expiration, 60-second resend cooldown, and 5-attempt brute-force protection.
- **Phone OTP**: Twilio integration verifying phone ownership without storing plaintext codes.
- Dual-tab switching interface between Email OTP and Phone SMS OTP with real-time countdown timer.

### 4. Social Authentication
- **Google Sign-In**: Native Google Sign-In SDK (`google_sign_in: 7.2.0`) integration obtaining ID tokens verified on the backend via Google's OAuth2 verification library.
- **Apple Sign-In**: Sign in with Apple SDK (`sign_in_with_apple: 8.2.0`) retrieving identity tokens and cryptographically validating them via Apple JWKS public keys.
- Secure account linking preventing silent account hijacking.

### 5. Password Recovery & Authenticated Password Change
- **Forgot Password**: Generic sanitized response protecting against user enumeration.
- **Reset Password**: 64-character cryptographic single-use hex token with SHA-256 database hashing and 1-hour expiration.
- **Authenticated Password Change**: Modal in user profile allowing secure password updates and immediate rotation of all other active device sessions.

### 6. Profile & Session Management
- **Display Name Updates**: Authenticated profile modification persisting changes to MongoDB.
- **Token Storage**: Mobile tokens stored via `flutter_secure_storage` (Keychain / KeyStore).
- **Silent Session Restoration**: Automatic restoration of authenticated sessions upon application launch.
- **Refresh Token Rotation**: Automatic token refresh with mutex lock preventing race conditions on concurrent 401 responses.
- **Replay Detection**: Detection of rotated refresh token reuse triggers immediate family session revocation.
- **Sign Out**: Revokes server refresh token and clears device credentials.
- **Sign Out from All Devices**: Revokes all active refresh tokens associated with the user account.

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: 3.22+ installed and available on PATH
- **Node.js**: 18+ installed
- **MongoDB**: Local MongoDB instance (`mongodb://127.0.0.1:27017`) or MongoDB Atlas URI

---

### Step 1: Start the Backend Service

```bash
cd backend

# Install dependencies
npm install

# Setup environment configuration
cp .env.example .env

# Start development server
npm run dev
```

The backend starts at `http://localhost:5000`. You can verify health status at:
```bash
curl http://localhost:5000/api/health
# {"success":true,"status":"ok","database":"connected"}
```

To run all backend unit and HTTP integration tests:
```bash
npm test
```

---

### Step 2: Run the Flutter Application

From the root project directory:

```bash
# Get Flutter dependencies
flutter pub get

# Run on Chrome (Web)
flutter run -d chrome

# Run on Android Emulator (Auto-maps to 10.0.2.2:5000)
flutter run -d android

# Run on Linux Desktop
flutter run -d linux

# Run with custom API URL (e.g., physical device or production backend)
flutter run -d chrome --dart-define=API_URL=http://localhost:5000/api
```

To run all Flutter unit and widget tests:
```bash
flutter test
```

To perform static analysis:
```bash
flutter analyze
```

---

## 🔑 Environment Configuration

### Backend (`backend/.env`)

| Variable | Description | Default / Example |
|---|---|---|
| `PORT` | Backend server port | `5000` |
| `MONGODB_URI` | MongoDB connection URI | `mongodb://127.0.0.1:27017/planmytrip` |
| `JWT_ACCESS_SECRET` | 32+ character key for Access Tokens | `your_secret_key` |
| `JWT_REFRESH_SECRET` | 32+ character key for Refresh Tokens | `your_secret_key` |
| `JWT_ACCESS_EXPIRES_IN` | Access token lifespan | `15m` |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token lifespan | `30d` |
| `OTP_EXPIRES_MINUTES` | OTP code lifespan | `5` |
| `SMTP_HOST` | Transactional email SMTP server | `smtp.mailgun.org` |
| `SMTP_PORT` | SMTP port | `587` |
| `SMTP_USER` | SMTP username | `user@domain.com` |
| `SMTP_PASS` | SMTP password | `password` |
| `GOOGLE_CLIENT_ID` | Google OAuth 2.0 Client ID | `client_id.apps.googleusercontent.com` |
| `APPLE_CLIENT_ID` | Apple Developer Service ID | `com.planmytrip.app` |
| `TWILIO_ACCOUNT_SID` | Twilio SMS Account SID | `AC...` |
| `TWILIO_AUTH_TOKEN` | Twilio SMS Auth Token | `...` |

### Flutter Environment
The Flutter app automatically routes to:
- `http://localhost:5000/api` on Web, Linux, macOS, and iOS Simulator.
- `http://10.0.2.2:5000/api` on the Android Emulator.
- Pass `--dart-define=API_URL=https://api.yourdomain.com/api` for physical device or production testing.

---

## 📋 Test Summary

| Test Suite | Tests Run | Result |
|---|---|---|
| **Backend Unit & Security Tests** | 9 | **100% Passed** |
| **Backend HTTP API Integration Tests** | 4 | **100% Passed** |
| **Flutter Widget & Auth Flow Tests** | 8 | **100% Passed** |
| **Flutter Core & Model Tests** | 15 | **100% Passed** |
| **Flutter Static Analysis** | 0 Issues | **100% Clean** |
