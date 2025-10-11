// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/backend/src/services/otp_service.js

// Lưu trữ OTP tạm thời (Trong môi trường production, nên dùng Redis)
const otpStore = {};

/**
 * Tạo và lưu trữ một mã OTP mới cho email.
 * @param {string} email - Email để gửi OTP.
 * @returns {string} - Mã OTP đã tạo.
 */
const generateAndStoreOtp = (email) => {
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expires = Date.now() + 5 * 60 * 1000;

  otpStore[email] = { otp, expires };
  console.log(`Generated OTP for ${email}: ${otp}`);
  return otp;
};

/**
 * Xác thực mã OTP.
 * @param {string} email - Email cần xác thực.
 * @param {string} otp - Mã OTP người dùng nhập.
 * @returns {boolean} - True nếu OTP hợp lệ, ngược lại là false.
 */
const verifyOtp = (email, otp) => {
  const storedData = otpStore[email];

  if (!storedData) {
    console.warn(`Verify OTP failed: No OTP request found for ${email}`);
    return false;
  }

  if (Date.now() > storedData.expires) {
    console.warn(`Verify OTP failed: OTP for ${email} has expired.`);
    delete otpStore[email]; // Xóa OTP đã hết hạn
    return false;
  }

  if (storedData.otp !== otp) {
    console.warn(`Verify OTP failed: Incorrect OTP for ${email}.`);
    return false;
  }

  // OTP hợp lệ, xóa nó đi để không dùng lại được
  delete otpStore[email];
  return true;
};

module.exports = {
  generateAndStoreOtp,
  verifyOtp,
};
