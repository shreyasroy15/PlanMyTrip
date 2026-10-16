# PlanMyTrip AI - Backend Authentication & API Service

A secure, production-ready REST API built with **Node.js**, **Express**, and **MongoDB (Mongoose)** providing enterprise authentication, authorization, session management, multi-channel verification, and audit logging for PlanMyTrip AI.

---

## 🛠️ Technology Stack

- **Runtime**: Node.js (v18+)
- **Framework**: Express.js
- **Database**: MongoDB (v6.0+ / MongoDB Atlas) with Mongoose ORM
- **Password Hashing**: `bcryptjs` (salt rounds: 12)
- **Token Infrastructure**: `jsonwebtoken` (dual-token with access token + SHA-256 hashed refresh token family)
- **Social Authentication**:
  - `google-auth-library` (Google ID token cryptographic signature, audience, and issuer validation)
  - `jwks-rsa` + `jsonwebtoken` (Apple Sign-In JWKS public key rotation and identity token verification)
- **Email Delivery**: `nodemailer` with HTML5/text responsive transactional templates
- **SMS OTP**: Twilio integration with automatic unconfigured-provider guard
- **Security Middleware**: `helmet`, `cors`, `express-rate-limit`, central error handler

---

## 🚀 Setup & Execution

### 1. Prerequisites
- Node.js (v18 or higher)
- MongoDB instance running locally on `mongodb://127.0.0.1:27017/planmytrip` or MongoDB Atlas URI

### 2. Install Dependencies
```bash
cd backend
npm install
```

### 3. Configure Environment Variables
Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```
Fill in development secrets or keep defaults for local testing:
```ini
PORT=5000
NODE_ENV=development
CLIENT_URL=http://localhost:3000
MONGODB_URI=mongodb://127.0.0.1:27017/planmytrip

# JWT Secrets (Minimum 32 random characters in production)
JWT_ACCESS_SECRET=planmytrip_super_secret_access_key_min_32_chars!
JWT_REFRESH_SECRET=planmytrip_super_secret_refresh_key_min_32_chars!
JWT_ACCESS_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=30d
OTP_EXPIRES_MINUTES=5

# SMTP Email Delivery
SMTP_HOST=smtp.mailgun.org
SMTP_PORT=587
SMTP_USER=postmaster@yourdomain.com
SMTP_PASS=your_smtp_password
EMAIL_FROM_NAME="PlanMyTrip AI"
EMAIL_FROM_ADDRESS="no-reply@planmytrip.com"

# Google OAuth 2.0 Web Client ID
GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com

# Apple Sign-In
APPLE_CLIENT_ID=com.planmytrip.app
APPLE_TEAM_ID=YOUR_TEAM_ID
APPLE_KEY_ID=YOUR_KEY_ID

# Twilio SMS
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
TWILIO_PHONE_NUMBER=+1234567890
```

### 4. Run Development Server
```bash
npm run dev
# Server starts on http://localhost:5000
```

### 5. Run Automated Tests
```bash
npm test
# Runs 13 comprehensive unit and HTTP integration tests using Node.js test runner
```

---

## 🔒 Security Architecture

1. **Password Hashing**:
   - Uses `bcryptjs` with 12 salt rounds.
   - Plaintext passwords are never logged, never returned in responses, and never stored.
2. **Dual-Token System & Refresh Token Rotation**:
   - **Access Token**: Short-lived (15 minutes), containing user ID and role claims.
   - **Refresh Token**: Long-lived (30 days), stored as a **SHA-256 hash** in MongoDB with IP address, User-Agent, and rotation history.
   - **Replay / Reuse Detection**: If an already-rotated or revoked refresh token is submitted, the backend detects a replay breach and immediately revokes all tokens for that user family.
3. **Brute-Force Lockout Protection**:
   - Accounts track consecutive failed login attempts.
   - 5 failed attempts trigger an automatic **15-minute account lockout** (`lockoutUntil`).
4. **Secure Single-Use OTPs**:
   - 6-digit cryptographically secure codes (`crypto.randomInt`).
   - Stored in MongoDB using `bcrypt` hash with automatic TTL index expiration (5 minutes).
   - 60-second cooldown rate limit per target; maximum 5 invalid verification attempts per challenge.
5. **Single-Use Password Reset**:
   - Generates 64-character cryptographic hex token.
   - Database stores only the SHA-256 hash with 1-hour expiration.
   - Executing a reset invalidates the token and revokes all existing refresh sessions.
6. **Social Account Linking**:
   - Authenticates against Google and Apple public keys/JWKS endpoints.
   - Verifies subject ID, audience, and expiration before creating or linking user records.
   - Never silently merges unverified third-party accounts.

---

## 🌐 API Endpoints Reference

### Health Check
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/health` | Public | Returns server and database health status |

### Authentication (`/api/auth`)
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `POST` | `/api/auth/register` | Public (Rate Limited) | Create new account with hashed password & send verification email |
| `POST` | `/api/auth/login` | Public (Rate Limited) | Authenticate email/password with lockout tracking |
| `POST` | `/api/auth/refresh` | Public | Refresh access token using refresh token rotation |
| `POST` | `/api/auth/logout` | Public / Session | Revoke current refresh token session |
| `POST` | `/api/auth/logout-all` | Bearer Token | Revoke all active refresh sessions across all devices |
| `GET` | `/api/auth/me` | Bearer Token | Return currently authenticated user profile |
| `PATCH` | `/api/auth/profile` | Bearer Token | Update user display name |
| `POST` | `/api/auth/change-password` | Bearer Token | Authenticated password change with session rotation |
| `POST` | `/api/auth/forgot-password` | Public (Rate Limited) | Request password reset email (sanitized response) |
| `POST` | `/api/auth/reset-password` | Public | Reset password using valid, single-use reset token |
| `GET` | `/api/auth/verify-email` | Public | Verify email address from email link token |
| `POST` | `/api/auth/send-email-otp` | Public (Rate Limited) | Send 6-digit cryptographic OTP to email address |
| `POST` | `/api/auth/verify-email-otp` | Public | Verify 6-digit email OTP and authenticate session |
| `POST` | `/api/auth/send-otp` | Public (Rate Limited) | Send 6-digit OTP via Twilio SMS |
| `POST` | `/api/auth/verify-otp` | Public | Verify phone SMS OTP and authenticate session |
| `POST` | `/api/auth/google` | Public | Authenticate via verified Google OAuth ID Token |
| `POST` | `/api/auth/apple` | Public | Authenticate via verified Apple Sign-In Identity Token |

### Admin User Management (`/api/admin`)
| Method | Endpoint | Auth | Description |
|---|---|---|---|
| `GET` | `/api/admin/users` | Admin Role | Paginated list of registered users with search & filters |
| `PATCH` | `/api/admin/users/:userId/status` | Admin Role | Activate or deactivate user account |
| `PATCH` | `/api/admin/users/:userId/role` | SuperAdmin Role | Promote or change user platform role |
| `DELETE` | `/api/admin/users/:userId` | SuperAdmin Role | Remove user account and cascade associated data |

---

## 📧 Transactional Email System

The backend integrates an enterprise email dispatch module with HTML5 and plain-text fallback templates:
1. **Welcome Email**: Sent upon initial registration.
2. **Email Verification**: Contains secure HTTPS verification link.
3. **Login OTP**: Contains 6-digit code with 5-minute expiry warning.
4. **Signup OTP**: Dispatched when OTP registration is requested.
5. **Password Reset Instructions**: Single-use tokenized recovery link.
6. **Password Changed Alert**: Immediate security notification of password update.
7. **New Login Alert**: Security notification with IP and device details.

---

## 🧪 Automated Testing

Run the automated test suite with:
```bash
npm test
```
**Test Coverage Includes:**
- Registration validation and duplicate email rejection
- Bcrypt password hashing verification
- Login success and invalid password rejection
- Brute-force account lockout after 5 consecutive failures
- OTP generation, bcrypt hashing, cooldown, attempt lockout, and expiration
- Password reset token hashing, single-use enforcement, and session revocation
- Refresh token rotation and replay attack detection
- Google & Apple token verification mocking
- HTTP API integration tests for full authentication lifecycle
