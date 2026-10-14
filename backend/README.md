# PlanMyTrip Node.js + Express + MongoDB Backend API

Backend REST API server for PlanMyTrip authentication, role-based authorization, and user management.

## 🚀 Setup & Execution Commands

### Prerequisites
- Node.js (v18+)
- MongoDB Atlas or local MongoDB instance

### Installation
```bash
cd backend
npm install
```

### Development Mode
```bash
npm run dev
```

### Production Start
```bash
npm start
```

### Run Tests
```bash
npm test
```

---

## 🔑 Environment Variables (`.env`)

| Variable | Description | Default / Example |
|---|---|---|
| `PORT` | Server Port | `5000` |
| `MONGODB_URI` | MongoDB Connection URI | `mongodb://127.0.0.1:27017/planmytrip` |
| `JWT_ACCESS_SECRET` | JWT Secret Key for Access Tokens | `CHANGE_ME_SECRET` |
| `JWT_REFRESH_SECRET` | JWT Secret Key for Refresh Tokens | `CHANGE_ME_REFRESH_SECRET` |
| `JWT_ACCESS_EXPIRES_IN` | Access Token Lifetime | `15m` |
| `JWT_REFRESH_EXPIRES_IN` | Refresh Token Lifetime | `30d` |
| `OTP_EXPIRES_MINUTES` | OTP Expiration Duration | `10` |

---

## 🌐 Endpoints Overview

### Health Check
- `GET /api/health`
  - **Auth**: None
  - **Response**: `{ "success": true, "status": "ok", "database": "connected" }`

### Authentication Endpoints (`/api/auth`)
- `POST /api/auth/register`
  - **Body**: `{ name, email, phone, password, confirmPassword }`
  - **Error Codes**: `EMAIL_EXISTS`, `PHONE_EXISTS`, `VALIDATION_ERROR`
- `POST /api/auth/login`
  - **Body**: `{ email, password }`
  - **Error Codes**: `INVALID_CREDENTIALS`, `ACCOUNT_DISABLED`
- `POST /api/auth/refresh`
  - **Body**: `{ refreshToken }`
  - **Error Codes**: `INVALID_REFRESH_TOKEN`, `TOKEN_REQUIRED`
- `POST /api/auth/logout`
  - **Body**: `{ refreshToken }`
- `GET /api/auth/me`
  - **Headers**: `Authorization: Bearer <accessToken>`
- `POST /api/auth/forgot-password`
  - **Body**: `{ email }`
- `POST /api/auth/reset-password`
  - **Body**: `{ token, password, confirmPassword }`
- `POST /api/auth/send-otp`
  - **Body**: `{ phone }`
- `POST /api/auth/verify-otp`
  - **Body**: `{ phone, otp }`
- `POST /api/auth/google`
  - **Body**: `{ idToken, email, name, photoUrl }`

### Admin Endpoints (`/api/admin`)
- `GET /api/admin/users`
  - **Auth**: Required (Role: `admin` or `superAdmin`)
- `PATCH /api/admin/users/:userId/status`
  - **Body**: `{ isActive: boolean }`
  - **Auth**: Required (Role: `admin` or `superAdmin`)
