const { sendError } = require('../utils/response');
const { ZodError } = require('zod');

const errorHandler = (err, req, res, next) => {
  console.error(`[Error] ${err.name || 'Error'}: ${err.message}`);

  if (err instanceof ZodError) {
    const formattedErrors = err.errors.map((e) => ({
      field: e.path.join('.'),
      message: e.message,
    }));
    return sendError(
      res,
      err.errors[0]?.message || 'Validation failed. Please check highlighted fields.',
      'VALIDATION_ERROR',
      400,
      formattedErrors
    );
  }

  if (err.name === 'ValidationError') {
    const formattedErrors = Object.keys(err.errors || {}).map((key) => ({
      field: key,
      message: err.errors[key].message,
    }));
    return sendError(res, 'Validation failed.', 'VALIDATION_ERROR', 400, formattedErrors);
  }

  if (err.code === 11000) {
    const field = Object.keys(err.keyPattern || {})[0] || 'field';
    return sendError(res, `An account with this ${field} already exists.`, 'DUPLICATE_KEY', 400);
  }

  const statusCode = err.statusCode || 500;
  const message = err.statusCode ? err.message : 'Something went wrong on our server. Please try again later.';
  const code = err.code || 'INTERNAL_SERVER_ERROR';

  return sendError(res, message, code, statusCode);
};

module.exports = { errorHandler };
