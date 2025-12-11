const crypto = require('crypto');

const otpStore = {};
const tokenStore = {}; // Bộ nhớ cho token

// Tạo và lưu trữ OTP
const generateAndStoreOtp = (email) => {
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expires = Date.now() + 5 * 60 * 1000; // 5 phút
  otpStore[email] = { otp, expires };
  console.log(`Generated OTP for ${email}: ${otp}`);
  return otp;
};

// ✅ ĐÃ SỬA LỖI: Xác thực OTP
const verifyOtp = (email, otp) => {
  const storedData = otpStore[email];

  // 1. Kiểm tra xem OTP có tồn tại và còn hạn không
  if (!storedData) {
    console.warn(`Verify OTP failed for ${email}: OTP not found.`);
    return false;
  }

  if (Date.now() > storedData.expires) {
    delete otpStore[email]; // Xóa OTP đã hết hạn
    console.warn(`Verify OTP failed for ${email}: OTP expired.`);
    return false;
  }

  // 2. Kiểm tra xem OTP nhập vào có khớp không
  if (storedData.otp !== otp) {
    // KHÔNG XÓA OTP Ở ĐÂY! Cho phép người dùng nhập lại.
    console.warn(`Verify OTP failed for ${email}: Incorrect OTP.`);
    return false;
  }

  // 3. Nếu OTP khớp và còn hạn: Xác thực thành công
  delete otpStore[email]; // Xóa OTP sau khi xác thực thành công (đúng logic)
  console.log(`OTP for ${email} verified successfully.`);
  return true;
};

// Tạo và lưu token xác thực tạm thời
const generateAndStoreVerificationToken = (email) => {
  const token = crypto.randomBytes(32).toString('hex');
  const expires = Date.now() + 5 * 60 * 1000; // 10 phút
  tokenStore[email] = { token, expires };
  console.log(`Generated verification token for ${email}`);
  return token;
};

// Xác thực token tạm thời
const verifyVerificationToken = (email, token) => {
  const storedData = tokenStore[email];
  if (!storedData || Date.now() > storedData.expires || storedData.token !== token) {
    if (storedData) delete tokenStore[email]; // Xóa token nếu hết hạn hoặc sai
    console.warn(`Verification token validation failed for ${email}.`);
    return false;
  }
  delete tokenStore[email]; // Xóa token sau khi xác thực thành công
  console.log(`Verification token for ${email} validated successfully.`);
  return true;
};

module.exports = {
  generateAndStoreOtp,
  verifyOtp,
  generateAndStoreVerificationToken,
  verifyVerificationToken,
};