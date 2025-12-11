// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/backend/src/services/mailer.js

const nodemailer = require('nodemailer');

// Tạo đối tượng transporter để kết nối với dịch vụ Gmail
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER, // Lấy từ file .env
    pass: process.env.EMAIL_PASS, // Lấy từ file .env
  },
});

/**
 * Gửi email chứa mã OTP.
 * @param {string} toEmail - Địa chỉ email người nhận.
 * @param {string} otp - Mã OTP để gửi.
 * @param {string} [subject='Mã xác thực tài khoản'] - Tiêu đề của email.
 */
const sendOtpEmail = async (toEmail, otp, subject = 'Mã xác thực tài khoản') => {
  const mailOptions = {
    from: `"Voice Banking Notifier" <${process.env.EMAIL_USER}>`,
    to: toEmail,
    subject: subject, // Sử dụng tiêu đề được truyền vào
    html: `
      <div style="font-family: Arial, sans-serif; color: #333;">
        <h2>Xác thực tài khoản của bạn</h2>
        <p>Xin chào,</p>
        <p>Mã OTP được yêu cầu từ ứng dụng Voice Banking Notifier của bạn là:</p>
        <p style="text-align:center; font-size: 24px; font-weight: bold; letter-spacing: 2px; color: #1E88E5;">
          ${otp}
        </p>
        <p>Mã này sẽ hết hạn sau 5 phút.</p>
        <hr/>
        <p style="font-size: 0.9em; color: #777;">Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email.</p>
      </div>
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`OTP email sent successfully to ${toEmail} with subject: "${subject}"`);
  } catch (error) {
    console.error(`Error sending email to ${toEmail}:`, error);
    // Ném lỗi ra ngoài để controller có thể bắt và xử lý
    throw new Error('Không thể gửi email OTP. Vui lòng kiểm tra lại cấu hình email trong file .env');
  }
};

module.exports = {
  sendOtpEmail,
};
