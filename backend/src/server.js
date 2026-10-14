const app = require('./app');
const env = require('./config/env');
const { connectDB } = require('./config/database');

const startServer = async () => {
  // Connect to MongoDB
  await connectDB();

  app.listen(env.port, () => {
    console.log(`====================================================`);
    console.log(`🚀 PlanMyTrip Backend Server running on port ${env.port}`);
    console.log(`🌐 Environment: ${env.nodeEnv}`);
    console.log(`🏥 Health Check: http://localhost:${env.port}/api/health`);
    console.log(`====================================================`);
  });
};

startServer();
