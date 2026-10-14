const sendSuccess = (res, message, data = {}, code = 'SUCCESS', statusCode = 200) => {
  return res.status(statusCode).json({
    success: true,
    message,
    code,
    data
  });
};

const sendError = (res, message, code = 'ERROR', statusCode = 400, errors = []) => {
  return res.status(statusCode).json({
    success: false,
    message,
    code,
    errors
  });
};

module.exports = { sendSuccess, sendError };
