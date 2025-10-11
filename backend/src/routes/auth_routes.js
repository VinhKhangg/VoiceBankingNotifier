// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/backend/src/routes/auth_routes.js

const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth_controller');

// Routes cho đăng ký
router.post('/send-otp', authController.sendOtp);
router.post('/verify-and-register', authController.verifyAndRegister);

// Routes cho đổi PIN
router.post('/send-pin-reset-otp', authController.sendOtpForPinReset);
router.post('/verify-otp', authController.verifyOtpOnly);

// ROUTES MỚI CHO ĐỔI MẬT KHẨU
router.post('/send-password-reset-otp', authController.sendPasswordResetOtp);
router.post('/reset-password-with-otp', authController.resetPasswordWithOtp);

module.exports = router;
