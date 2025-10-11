// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/backend/src/controllers/auth_controller.js

const admin = require('../config/firebase');
const otpService = require('../services/otp_service');
const mailerService = require('../services/mailer');

// 1. Gửi OTP để đăng ký
const sendOtp = async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).send({ message: 'Vui lòng cung cấp email.' });
  }

  try {
    // ✅ BƯỚC KIỂM TRA MỚI: Dùng Firebase Admin SDK để tìm người dùng bằng email
    await admin.auth().getUserByEmail(email);

    // Nếu không có lỗi, tức là TÌM THẤY người dùng -> email đã tồn tại
    console.log(`Registration attempt failed: Email ${email} already exists.`);
    return res.status(400).send({ message: 'Địa chỉ email này đã được sử dụng bởi một tài khoản khác.' });

  } catch (error) {
    // Nếu có lỗi, kiểm tra mã lỗi
    if (error.code === 'auth/user-not-found') {
      // ✅ TUYỆT VỜI: KHÔNG TÌM THẤY người dùng -> email hợp lệ để đăng ký
      try {
        const otp = otpService.generateAndStoreOtp(email);
        await mailerService.sendOtpEmail(email, otp, 'Mã xác thực đăng ký tài khoản');
        return res.status(200).send({ message: 'Mã OTP đã được gửi đến email của bạn.' });
      } catch (mailError) {
        return res.status(500).send({ message: mailError.message });
      }
    } else {
      // Một lỗi Firebase khác đã xảy ra (ví dụ: project không được cấu hình đúng)
      console.error('Firebase getUserByEmail error:', error);
      return res.status(500).send({ message: 'Lỗi khi kiểm tra email với Firebase.' });
    }
  }
};

// 2. Xác thực OTP và Đăng ký tài khoản
const verifyAndRegister = async (req, res) => {
  const { email, password, name, otp } = req.body;
  if (!email || !password || !name || !otp) {
    return res.status(400).send({ message: 'Vui lòng điền đầy đủ thông tin.' });
  }
  if (!otpService.verifyOtp(email, otp)) {
    return res.status(400).send({ message: 'Mã OTP không hợp lệ hoặc đã hết hạn.' });
  }
  try {
    const userRecord = await admin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
      emailVerified: true,
    });
    res.status(201).send({
      uid: userRecord.uid,
      message: 'Tài khoản được tạo thành công!',
    });
  } catch (error) {
    console.error('Firebase createUser error:', error.code, error.message);
    let userMessage = 'Đã xảy ra lỗi không xác định khi tạo tài khoản.';
    if (error.code === 'auth/email-already-exists') {
      userMessage = 'Địa chỉ email này đã được sử dụng bởi một tài khoản khác.';
    } else if (error.code === 'auth/invalid-password') {
      userMessage = 'Mật khẩu không hợp lệ. Mật khẩu phải có ít nhất 6 ký tự.';
    }
    res.status(400).send({ message: userMessage, code: error.code });
  }
};

// 3. Gửi OTP để đổi mã PIN
const sendOtpForPinReset = async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).send({ message: 'Vui lòng cung cấp email.' });
  }
  try {
    const otp = otpService.generateAndStoreOtp(email);
    await mailerService.sendOtpEmail(email, otp, 'Mã xác thực đổi mã PIN');
    res.status(200).send({ message: 'Mã OTP đã được gửi đến email của bạn.' });
  } catch (error) {
    res.status(500).send({ message: error.message });
  }
};

// 4. Chỉ xác thực OTP (dùng cho đổi PIN)
const verifyOtpOnly = (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) {
    return res.status(400).send({ message: 'Vui lòng cung cấp email và OTP.' });
  }
  if (otpService.verifyOtp(email, otp)) {
    res.status(200).send({ message: 'Xác thực OTP thành công.' });
  } else {
    res.status(400).send({ message: 'Mã OTP không hợp lệ hoặc đã hết hạn.' });
  }
};

// 5. Gửi OTP để ĐẶT LẠI MẬT KHẨU
const sendPasswordResetOtp = async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).send({ message: 'Vui lòng cung cấp email.' });
  }

  try {
    // Ngược với đăng ký, ở đây ta phải KIỂM TRA XEM EMAIL CÓ TỒN TẠI KHÔNG
    await admin.auth().getUserByEmail(email);

    // Email tồn tại -> Gửi OTP
    const otp = otpService.generateAndStoreOtp(email);
    await mailerService.sendOtpEmail(email, otp, 'Mã xác thực đặt lại mật khẩu');
    // Luôn trả về thông báo chung để tăng bảo mật, tránh việc kẻ xấu dò email
    res.status(200).send({ message: 'Nếu email của bạn tồn tại trong hệ thống, bạn sẽ nhận được mã OTP.' });

  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      // Nếu không tìm thấy user, vẫn trả về thông báo thành công chung để bảo mật
      console.warn(`Password reset attempt for non-existent email: ${email}`);
      return res.status(200).send({ message: 'Nếu email của bạn tồn tại trong hệ thống, bạn sẽ nhận được mã OTP.' });
    }
    // Các lỗi Firebase khác
    console.error('Firebase password reset OTP error:', error);
    return res.status(500).send({ message: 'Lỗi khi xử lý yêu cầu.' });
  }
};

// 6. Xác thực OTP và ĐẶT LẠI MẬT KHẨU
const resetPasswordWithOtp = async (req, res) => {
  const { email, otp, newPassword } = req.body;

  // Validate input
  if (!email || !otp || !newPassword) {
    return res.status(400).send({ message: 'Vui lòng cung cấp đầy đủ email, OTP và mật khẩu mới.' });
  }
  if (newPassword.length < 6) {
    return res.status(400).send({ message: 'Mật khẩu mới phải có ít nhất 6 ký tự.' });
  }

  // Verify OTP
  if (!otpService.verifyOtp(email, otp)) {
    return res.status(400).send({ message: 'Mã OTP không hợp lệ hoặc đã hết hạn.' });
  }

  try {
    // Lấy UID của user từ email
    const userRecord = await admin.auth().getUserByEmail(email);
    const uid = userRecord.uid;

    // Cập nhật mật khẩu cho user bằng UID
    await admin.auth().updateUser(uid, {
      password: newPassword,
    });

    console.log(`Password for user ${email} (UID: ${uid}) has been reset successfully.`);
    return res.status(200).send({ message: 'Mật khẩu đã được đặt lại thành công!' });

  } catch (error) {
    console.error('Firebase reset password error:', error);
    if (error.code === 'auth/user-not-found') {
       return res.status(404).send({ message: 'Không tìm thấy người dùng với email này.' });
    }
    return res.status(500).send({ message: 'Đã xảy ra lỗi khi đặt lại mật khẩu.' });
  }
};

module.exports = {
  sendOtp,
  verifyAndRegister,
  sendOtpForPinReset,
  verifyOtpOnly,
  sendPasswordResetOtp,
  resetPasswordWithOtp,
};


