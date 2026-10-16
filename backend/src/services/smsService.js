const env = require('../config/env');

const sendSms = async (phone, message) => {
  if (!env.twilioAccountSid || !env.twilioAuthToken || !env.twilioPhoneNumber) {
    if (env.nodeEnv === 'development' || env.nodeEnv === 'test') {
      console.log(`[SMS Service - Dev Log] To: ${phone} | Message: ${message}`);
      return {
        success: true,
        providerConfigured: false,
        simulated: true,
        message: 'SMS provider not configured. Code logged to development console.',
      };
    }
    const error = new Error('SMS service is currently unavailable. No SMS provider is configured.');
    error.code = 'SMS_PROVIDER_NOT_CONFIGURED';
    error.statusCode = 503;
    throw error;
  }

  try {
    const authHeader = Buffer.from(`${env.twilioAccountSid}:${env.twilioAuthToken}`).toString('base64');
    const params = new URLSearchParams({
      To: phone,
      From: env.twilioPhoneNumber,
      Body: message,
    });

    const response = await fetch(
      `https://api.twilio.com/2010-04-01/Accounts/${env.twilioAccountSid}/Messages.json`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${authHeader}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params.toString(),
      }
    );

    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.message || 'Twilio SMS failed to dispatch.');
    }

    return {
      success: true,
      providerConfigured: true,
      sid: data.sid,
    };
  } catch (error) {
    console.error('[SMS Service] Failed to send SMS:', error.message);
    throw error;
  }
};

module.exports = { sendSms };
