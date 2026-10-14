const mongoose = require('mongoose');
const env = require('./env');

let isConnected = false;

const connectDB = async () => {
  if (isConnected && mongoose.connection.readyState === 1) {
    return mongoose.connection;
  }

  try {
    const conn = await mongoose.connect(env.mongoUri, {
      serverSelectionTimeoutMS: 5000,
    });
    isConnected = true;
    console.log(`[Database] MongoDB Connected successfully to host: ${conn.connection.host}`);
    return conn.connection;
  } catch (error) {
    console.error(`[Database Error] MongoDB connection failure: ${error.message}`);
    isConnected = false;
    return null;
  }
};

const getDBStatus = () => {
  const readyState = mongoose.connection.readyState;
  switch (readyState) {
    case 1:
      return 'connected';
    case 2:
      return 'connecting';
    case 3:
      return 'disconnecting';
    default:
      return 'disconnected';
  }
};

module.exports = { connectDB, getDBStatus };
