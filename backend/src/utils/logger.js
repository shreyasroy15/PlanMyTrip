const morgan = require('morgan');

const sanitizeBody = (body) => {
  if (!body) return {};
  const sanitized = { ...body };
  if (sanitized.password) sanitized.password = '***REDACTED***';
  if (sanitized.confirmPassword) sanitized.confirmPassword = '***REDACTED***';
  if (sanitized.otp) sanitized.otp = '***REDACTED***';
  if (sanitized.code) sanitized.code = '***REDACTED***';
  if (sanitized.refreshToken) sanitized.refreshToken = '***REDACTED***';
  if (sanitized.accessToken) sanitized.accessToken = '***REDACTED***';
  return sanitized;
};

const requestLogger = morgan((tokens, req, res) => {
  return [
    `[HTTP]`,
    tokens.method(req, res),
    tokens.url(req, res),
    tokens.status(req, res),
    tokens['response-time'](req, res), 'ms'
  ].join(' ');
});

module.exports = { requestLogger, sanitizeBody };
