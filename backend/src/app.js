const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { getDBStatus } = require('./config/database');
const { requestLogger } = require('./utils/logger');
const { sendSuccess, sendError } = require('./utils/response');
const { errorHandler } = require('./middleware/errorMiddleware');
const authRoutes = require('./routes/authRoutes');
const adminRoutes = require('./routes/adminRoutes');

const app = express();

// Security Headers
app.use(helmet());

// CORS Configuration
app.use(
  cors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  })
);

// Body Parser
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// Logging Middleware
app.use(requestLogger);

// Health Check Endpoint (Requirements Section 6 & 36)
app.get('/api/health', (req, res) => {
  const dbStatus = getDBStatus();
  return res.status(200).json({
    success: true,
    status: 'ok',
    database: dbStatus,
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);

// 404 Handler
app.use((req, res) => {
  return sendError(res, `Route ${req.originalUrl} not found`, 'NOT_FOUND', 404);
});

// Centralized Error Handler
app.use(errorHandler);

module.exports = app;
