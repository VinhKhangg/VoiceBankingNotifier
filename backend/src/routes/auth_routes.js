const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth_controller');
const verifyIdToken = require('../middlewares/verify_id_token');

// Routes cho đăng ký
router.post('/send-otp', authController.sendOtp);
router.post('/verify-and-register', authController.verifyAndRegister);

// Routes cho đổi PIN
router.post('/send-pin-reset-otp', authController.sendOtpForPinReset);
router.post('/verify-otp', authController.verifyOtpOnly);

// Routes cho quên mật khẩu
router.post('/send-password-reset-otp', authController.sendPasswordResetOtp);
router.post('/verify-password-reset-otp', authController.verifyPasswordResetOtp); // Route xác thực OTP & lấy token
router.post('/reset-password-with-token', authController.resetPasswordWithToken); // Route đổi MK bằng token

// Routes cho thiết lập PIN
router.post('/set-pin', verifyIdToken, authController.setPin);
router.post('/verify-pin', verifyIdToken, authController.verifyPin);

//ROUTES MỚI CHO QUẢN LÝ TÀI KHOẢN NGÂN HÀNG
router.post('/bank-accounts', verifyIdToken, authController.addBankAccount);
router.get('/bank-accounts', verifyIdToken, authController.getBankAccounts);
router.delete('/bank-accounts/:accountId', verifyIdToken, authController.deleteBankAccount);

module.exports = router;
