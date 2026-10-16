const nodemailer = require('nodemailer');
const env = require('../config/env');

let transporter = null;

const getTransporter = () => {
  if (transporter) return transporter;

  if (env.smtpHost && env.smtpUser && env.smtpPass) {
    transporter = nodemailer.createTransport({
      host: env.smtpHost,
      port: env.smtpPort,
      secure: env.smtpPort === 465,
      auth: {
        user: env.smtpUser,
        pass: env.smtpPass,
      },
    });
  }
  return transporter;
};

// Base HTML layout template
const renderEmailLayout = (title, contentHtml) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title}</title>
  <style>
    body {
      margin: 0;
      padding: 0;
      background-color: #0F172A;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      color: #F8FAFC;
    }
    .container {
      max-width: 600px;
      margin: 30px auto;
      background-color: #1E293B;
      border-radius: 16px;
      overflow: hidden;
      border: 1px solid rgba(255, 255, 255, 0.1);
      box-shadow: 0 10px 25px rgba(0, 0, 0, 0.4);
    }
    .header {
      background: linear-gradient(135deg, #6366F1 0%, #06B6D4 100%);
      padding: 30px 24px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      font-size: 26px;
      font-weight: 700;
      color: #FFFFFF;
      letter-spacing: 0.5px;
    }
    .content {
      padding: 32px 28px;
      line-height: 1.6;
    }
    .content h2 {
      margin-top: 0;
      font-size: 20px;
      color: #F8FAFC;
    }
    .content p {
      color: #94A3B8;
      font-size: 15px;
    }
    .otp-code {
      display: inline-block;
      letter-spacing: 8px;
      font-size: 32px;
      font-weight: bold;
      color: #6366F1;
      background-color: #0F172A;
      padding: 16px 28px;
      border-radius: 12px;
      border: 1px solid rgba(99, 102, 241, 0.3);
      margin: 20px 0;
      text-align: center;
    }
    .btn {
      display: inline-block;
      padding: 14px 28px;
      background: linear-gradient(135deg, #6366F1 0%, #06B6D4 100%);
      color: #FFFFFF !important;
      text-decoration: none;
      font-weight: 600;
      border-radius: 12px;
      margin: 20px 0;
      box-shadow: 0 4px 14px rgba(99, 102, 241, 0.3);
    }
    .footer {
      padding: 20px 24px;
      background-color: #0F172A;
      text-align: center;
      border-top: 1px solid rgba(255, 255, 255, 0.05);
      font-size: 13px;
      color: #64748B;
    }
    .footer a {
      color: #6366F1;
      text-decoration: none;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>✈ PlanMyTrip AI</h1>
    </div>
    <div class="content">
      ${contentHtml}
    </div>
    <div class="footer">
      <p>&copy; ${new Date().getFullYear()} PlanMyTrip AI. All rights reserved.</p>
      <p>Keep your account secure. Never share your passwords or OTPs with anyone.</p>
    </div>
  </div>
</body>
</html>
`;

// Helper to escape user inputs in HTML templates
const escapeHtml = (text) => {
  if (!text) return '';
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
};

const sendEmail = async ({ to, subject, html, text }) => {
  const mailTransporter = getTransporter();

  if (!mailTransporter) {
    console.log(`[Email Service - Simulated] To: ${to} | Subject: ${subject}`);
    return {
      success: true,
      simulated: true,
      message: 'SMTP not configured; notification logged to development console.',
    };
  }

  try {
    const info = await mailTransporter.sendMail({
      from: `"${env.emailFromName}" <${env.emailFromAddress}>`,
      to,
      subject,
      text,
      html,
    });
    console.log(`[Email Service] Message sent to ${to}: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error(`[Email Service] Failed to send email to ${to}:`, error.message);
    return { success: false, error: error.message };
  }
};

// 1. Welcome Email
const sendWelcomeEmail = async (user) => {
  const safeName = escapeHtml(user.name);
  const subject = 'Welcome to PlanMyTrip AI';
  const html = renderEmailLayout(
    subject,
    `
    <h2>Hi ${safeName},</h2>
    <p>Your PlanMyTrip AI account has been created successfully. You can now sign in and start planning your trips with personalized recommendations and smart itineraries.</p>
    <p>Keep your password private. We will never ask you to send it by email.</p>
    <a href="${env.clientUrl}/home" class="btn">Explore PlanMyTrip</a>
    <p>Thanks,<br><strong>The PlanMyTrip AI Team</strong></p>
    `
  );
  const text = `Hi ${user.name},\n\nYour PlanMyTrip AI account has been created successfully. You can now sign in and start planning your trips.\n\nKeep your password private. We will never ask you to send it by email.\n\nThanks,\nThe PlanMyTrip AI Team`;

  return sendEmail({ to: user.email, subject, html, text });
};

// 2. Email Verification Token / Link
const sendEmailVerification = async (user, verificationToken) => {
  const safeName = escapeHtml(user.name);
  const verifyUrl = `${env.clientUrl}/verify-email?token=${encodeURIComponent(verificationToken)}&email=${encodeURIComponent(user.email)}`;
  const subject = 'Verify your PlanMyTrip AI Email Address';
  const html = renderEmailLayout(
    subject,
    `
    <h2>Verify Your Email</h2>
    <p>Hi ${safeName}, please confirm your email address to secure your account and unlock full access to PlanMyTrip AI.</p>
    <a href="${verifyUrl}" class="btn">Confirm Email Address</a>
    <p>Or paste this link into your browser:<br><span style="word-break: break-all; color: #6366F1;">${verifyUrl}</span></p>
    <p>This verification link will expire in 24 hours.</p>
    `
  );
  const text = `Hi ${user.name},\n\nPlease verify your email address by visiting this link:\n${verifyUrl}\n\nThis link will expire in 24 hours.`;

  return sendEmail({ to: user.email, subject, html, text });
};

// 3. Login OTP
const sendLoginOtpEmail = async (email, code, expiresMinutes = 5) => {
  const subject = 'Your PlanMyTrip AI Login Code';
  const html = renderEmailLayout(
    subject,
    `
    <h2>Your Sign-in Code</h2>
    <p>Use the following single-use verification code to log in to your PlanMyTrip AI account:</p>
    <div style="text-align: center;">
      <div class="otp-code">${code}</div>
    </div>
    <p>This code will expire in ${expiresMinutes} minutes. If you did not request this login code, you can safely ignore this email.</p>
    `
  );
  const text = `Your PlanMyTrip AI login code is: ${code}\nThis code will expire in ${expiresMinutes} minutes.`;

  return sendEmail({ to: email, subject, html, text });
};

// 4. Signup Verification OTP
const sendSignupOtpEmail = async (email, code, expiresMinutes = 5) => {
  const subject = 'Your PlanMyTrip AI Verification Code';
  const html = renderEmailLayout(
    subject,
    `
    <h2>Verify Your Account</h2>
    <p>Thank you for registering with PlanMyTrip AI. Enter this code to verify your email address:</p>
    <div style="text-align: center;">
      <div class="otp-code">${code}</div>
    </div>
    <p>This code will expire in ${expiresMinutes} minutes.</p>
    `
  );
  const text = `Your PlanMyTrip AI verification code is: ${code}\nThis code will expire in ${expiresMinutes} minutes.`;

  return sendEmail({ to: email, subject, html, text });
};

// 5. Password Reset Instructions
const sendPasswordResetEmail = async (user, resetToken) => {
  const safeName = escapeHtml(user.name);
  const resetUrl = `${env.clientUrl}/reset-password?token=${encodeURIComponent(resetToken)}&email=${encodeURIComponent(user.email)}`;
  const subject = 'Reset Your PlanMyTrip AI Password';
  const html = renderEmailLayout(
    subject,
    `
    <h2>Password Reset Request</h2>
    <p>Hi ${safeName}, we received a request to reset the password for your PlanMyTrip AI account.</p>
    <a href="${resetUrl}" class="btn">Reset Password</a>
    <p>Or paste this link into your browser:<br><span style="word-break: break-all; color: #6366F1;">${resetUrl}</span></p>
    <p>This single-use link is valid for 15 minutes. If you did not make this request, please review your account security immediately.</p>
    `
  );
  const text = `Hi ${user.name},\n\nWe received a request to reset your PlanMyTrip AI password. Visit the following link:\n${resetUrl}\n\nThis link is valid for 15 minutes.`;

  return sendEmail({ to: user.email, subject, html, text });
};

// 6. Password Changed Security Notification
const sendPasswordChangedAlert = async (user) => {
  const safeName = escapeHtml(user.name);
  const subject = 'Security Alert: Password Changed';
  const html = renderEmailLayout(
    subject,
    `
    <h2>Password Changed Successfully</h2>
    <p>Hi ${safeName},</p>
    <p>The password for your PlanMyTrip AI account was changed on ${new Date().toUTCString()}.</p>
    <p>If you made this change, no further action is required. If you did NOT make this change, please reset your password immediately and contact support.</p>
    `
  );
  const text = `Hi ${user.name},\n\nThe password for your PlanMyTrip AI account was changed on ${new Date().toUTCString()}.\nIf you did not do this, please contact support immediately.`;

  return sendEmail({ to: user.email, subject, html, text });
};

// 7. New Login Security Alert
const sendNewLoginAlert = async (user, ipAddress, userAgent) => {
  const safeName = escapeHtml(user.name);
  const subject = 'Security Alert: New Sign-In to PlanMyTrip AI';
  const html = renderEmailLayout(
    subject,
    `
    <h2>New Sign-in Detected</h2>
    <p>Hi ${safeName},</p>
    <p>We detected a new sign-in to your PlanMyTrip AI account:</p>
    <ul>
      <li><strong>Time:</strong> ${new Date().toUTCString()}</li>
      <li><strong>IP Address:</strong> ${escapeHtml(ipAddress || 'Unknown')}</li>
      <li><strong>Device / Client:</strong> ${escapeHtml(userAgent || 'Mobile App / Browser')}</li>
    </ul>
    <p>If this was you, you can safely disregard this message.</p>
    `
  );
  const text = `Hi ${user.name},\n\nA new sign-in to your PlanMyTrip AI account occurred at ${new Date().toUTCString()} from IP: ${ipAddress}.\nIf this was not you, please secure your account immediately.`;

  return sendEmail({ to: user.email, subject, html, text });
};

module.exports = {
  sendWelcomeEmail,
  sendEmailVerification,
  sendLoginOtpEmail,
  sendSignupOtpEmail,
  sendPasswordResetEmail,
  sendPasswordChangedAlert,
  sendNewLoginAlert,
};
