// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/backend/src/controllers/auth_controller.js

const admin = require('../config/firebase');
const otpService = require('../services/otp_service');
const mailerService = require('../services/mailer');
const bcrypt = require('bcrypt');
const SALT_ROUNDS = 10;

// 1. Gửi OTP để đăng ký
const sendOtp = async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).send({ message: 'Vui lòng cung cấp email.' });
  }

  try {
    await admin.auth().getUserByEmail(email);
    console.log(`Registration attempt failed: Email ${email} already exists.`);
    return res.status(400).send({ message: 'Địa chỉ email này đã được sử dụng bởi một tài khoản khác.' });

  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      try {
        const otp = otpService.generateAndStoreOtp(email);
        await mailerService.sendOtpEmail(email, otp, 'Mã xác thực đăng ký tài khoản');
        return res.status(200).send({ message: 'Mã OTP đã được gửi đến email của bạn.' });
      } catch (mailError) {
        return res.status(500).send({ message: mailError.message });
      }
    } else {
      console.error('Firebase getUserByEmail error:', error);
      return res.status(500).send({ message: 'Lỗi khi kiểm tra email với Firebase.' });
    }
  }
};

// 2. Xác thực OTP và Đăng ký tài khoản
const verifyAndRegister = async (req, res) => {
  const { email, password, name, otp, phoneNumber } = req.body;
  if (!email || !password || !name || !otp || !phoneNumber) { // ✅ THÊM KIỂM TRA
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

    // LƯU THÔNG TIN BỔ SUNG VÀO FIRESTORE
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      email: email,
      name: name,
      phoneNumber: phoneNumber, // ✅ LƯU SỐ ĐIỆN THOẠI
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      pin: "", // Khởi tạo PIN rỗng
    });

    res.status(201).send({
      uid: userRecord.uid,
      message: 'Tài khoản được tạo thành công!',
    });
  } catch (error) {
    // ... (phần xử lý lỗi giữ nguyên)
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
    await admin.auth().getUserByEmail(email);
    const otp = otpService.generateAndStoreOtp(email);
    await mailerService.sendOtpEmail(email, otp, 'Mã xác thực đặt lại mật khẩu');
    res.status(200).send({ message: 'Nếu email của bạn tồn tại trong hệ thống, bạn sẽ nhận được mã OTP.' });

  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      console.warn(`Password reset attempt for non-existent email: ${email}`);
      return res.status(200).send({ message: 'Nếu email của bạn tồn tại trong hệ thống, bạn sẽ nhận được mã OTP.' });
    }
    console.error('Firebase password reset OTP error:', error);
    return res.status(500).send({ message: 'Lỗi khi xử lý yêu cầu.' });
  }
};


// 🔴 HÀM MỚI (6): Chỉ xác thực OTP và trả về token
const verifyPasswordResetOtp = (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) {
    return res.status(400).send({ message: 'Vui lòng cung cấp email và OTP.' });
  }

  // Xác thực OTP
  if (otpService.verifyOtp(email, otp)) {
    // Tạo một token xác thực tạm thời, có hiệu lực ngắn
    const verificationToken = otpService.generateAndStoreVerificationToken(email);
    console.log(`OTP for ${email} verified. Generated verification token.`);
    res.status(200).send({
      message: 'Xác thực OTP thành công.',
      verificationToken: verificationToken, // Trả token về cho client
    });
  } else {
    res.status(400).send({ message: 'Mã OTP không hợp lệ hoặc đã hết hạn.' });
  }
};


// 🔴 HÀM CŨ (7 - đã sửa đổi): Đặt lại mật khẩu bằng TOKEN
const resetPasswordWithToken = async (req, res) => {
  const { email, verificationToken, newPassword } = req.body;

  // Validate input
  if (!email || !verificationToken || !newPassword) {
    return res.status(400).send({ message: 'Vui lòng cung cấp đầy đủ email, token và mật khẩu mới.' });
  }
  if (newPassword.length < 6) {
    return res.status(400).send({ message: 'Mật khẩu mới phải có ít nhất 6 ký tự.' });
  }

  // Xác thực verification token
  if (!otpService.verifyVerificationToken(email, verificationToken)) {
    return res.status(400).send({ message: 'Token xác thực không hợp lệ hoặc đã hết hạn.' });
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

// NEW: API để tạo hoặc cập nhật PIN (sau khi đăng ký hoặc reset)
const setPin = async (req, res) => {
  const { newPin } = req.body;
  // req.uid sẽ được thêm vào bởi middleware xác thực Firebase ID Token
  const uid = req.uid;

  if (!uid) {
    return res.status(401).send({ message: 'Người dùng chưa được xác thực.' });
  }
  if (!newPin || newPin.length !== 6) {
    return res.status(400).send({ message: 'Mã PIN không hợp lệ. Vui lòng nhập 6 số.' });
  }

  try {
    const hashedPin = await bcrypt.hash(newPin, SALT_ROUNDS); // Băm mã PIN

    // Lưu mã PIN đã băm vào Firestore
    await admin.firestore().collection('users').doc(uid).set(
      { pin: hashedPin, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true } // Merge để không ghi đè các trường khác
    );

    console.log(`✅ PIN for user ${uid} set successfully.`);
    return res.status(200).send({ message: 'Mã PIN đã được thiết lập thành công.' });
  } catch (error) {
    console.error('Error setting PIN:', error);
    return res.status(500).send({ message: 'Lỗi khi thiết lập mã PIN.' });
  }
};

// NEW: API để xác thực PIN khi đăng nhập hoặc vào ứng dụng
const verifyPin = async (req, res) => {
  const { pinAttempt } = req.body;
  const uid = req.uid;

  if (!uid) {
    return res.status(401).send({ message: 'Người dùng chưa được xác thực.' });
  }
  if (!pinAttempt || pinAttempt.length !== 6) {
    return res.status(400).send({ message: 'Mã PIN không hợp lệ.' });
  }

  try {
    const userDoc = await admin.firestore().collection('users').doc(uid).get();

    if (!userDoc.exists) {
      return res.status(404).send({ message: 'Không tìm thấy thông tin người dùng.' });
    }

    const userData = userDoc.data();
    const storedHashedPin = userData?.pin;

    if (!storedHashedPin) {
      return res.status(404).send({ message: 'Người dùng chưa thiết lập mã PIN.' });
    }

    const isMatch = await bcrypt.compare(pinAttempt, storedHashedPin); // So sánh PIN

    if (isMatch) {
      console.log(`✅ PIN for user ${uid} verified successfully.`);
      return res.status(200).send({ message: 'Mã PIN chính xác.', verified: true });
    } else {
      console.log(`❌ Incorrect PIN attempt for user ${uid}.`);
      return res.status(401).send({ message: 'Mã PIN không chính xác.', verified: false });
    }
  } catch (error) {
    console.error('Error verifying PIN:', error);
    return res.status(500).send({ message: 'Lỗi khi xác thực mã PIN.' });
  }
};

const addBankAccount = async (req, res) => {
  const uid = req.uid; // Lấy UID từ middleware verifyIdToken
  const { bankName, accountHolder, accountNumber, bankPhoneNumber } = req.body;

  // 1. Kiểm tra đầu vào
  if (!bankName || !accountHolder || !accountNumber || !bankPhoneNumber) {
    return res.status(400).send({ message: 'Vui lòng cung cấp đầy đủ thông tin tài khoản và số điện thoại ngân hàng.' });
  }

  try {
    // 2. Lấy thông tin người dùng từ Firestore để có SĐT đã đăng ký
    const userDoc = await admin.firestore().collection('users').doc(uid).get();
    if (!userDoc.exists) {
      return res.status(404).send({ message: 'Không tìm thấy thông tin người dùng.' });
    }

    const userData = userDoc.data();
    const userRegisteredPhoneNumber = userData.phoneNumber;

    // 3. Xử lý trường hợp người dùng cũ CHƯA CÓ số điện thoại
    if (!userRegisteredPhoneNumber || userRegisteredPhoneNumber.trim() === '') {
      // Trả về mã lỗi 412 (Precondition Failed) và một mã code để client dễ dàng xử lý
      return res.status(412).send({
        message: 'Bạn cần cập nhật số điện thoại trong hồ sơ trước khi có thể liên kết tài khoản.',
        code: 'PHONE_NUMBER_REQUIRED'
      });
    }

    // 4. Logic kiểm tra điều kiện quan trọng: SĐT ứng dụng phải khớp SĐT ngân hàng
    if (userRegisteredPhoneNumber !== bankPhoneNumber) {
      return res.status(400).send({ message: 'Số điện thoại liên kết với ngân hàng không khớp với số điện thoại bạn đã đăng ký với ứng dụng.' });
    }

    const userBankAccountsRef = admin.firestore().collection('users').doc(uid).collection('bank_accounts');

    // 5. Kiểm tra xem ngân hàng này đã tồn tại chưa
    const querySnapshot = await userBankAccountsRef.where('bankName', '==', bankName).limit(1).get();
    if (!querySnapshot.empty) {
      return res.status(409).send({ message: `Bạn đã liên kết với ngân hàng ${bankName} rồi.` });
    }

    // 6. Thêm tài khoản mới vào sub-collection
    const newAccountRef = await userBankAccountsRef.add({
      bankName,
      accountHolder,
      accountNumber,
      bankPhoneNumber, // Lưu lại số điện thoại của tài khoản ngân hàng
      linkedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Bank account added for user ${uid} with ID: ${newAccountRef.id}`);
    res.status(201).send({ message: 'Liên kết tài khoản ngân hàng thành công!', accountId: newAccountRef.id });

  } catch (error) {
    console.error('Error adding bank account:', error);
    return res.status(500).send({ message: 'Lỗi khi thêm tài khoản ngân hàng.' });
  }
};


// 2. Lấy danh sách tất cả tài khoản ngân hàng đã liên kết
const getBankAccounts = async (req, res) => {
  const uid = req.uid;
  try {
    const snapshot = await admin.firestore().collection('users').doc(uid).collection('bank_accounts').orderBy('linkedAt', 'desc').get();

    if (snapshot.empty) {
      return res.status(200).send([]); // Trả về mảng rỗng nếu chưa có tài khoản nào
    }

    const accounts = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.status(200).send(accounts);

  } catch (error) {
    console.error('Error fetching bank accounts:', error);
    return res.status(500).send({ message: 'Lỗi khi lấy danh sách tài khoản.' });
  }
};

// 3. Xóa một tài khoản ngân hàng
const deleteBankAccount = async (req, res) => {
  const uid = req.uid;
  const { accountId } = req.params; // Lấy accountId từ URL parameter

  if (!accountId) {
    return res.status(400).send({ message: 'Vui lòng cung cấp ID tài khoản cần xóa.' });
  }

  try {
    const docRef = admin.firestore().collection('users').doc(uid).collection('bank_accounts').doc(accountId);

    await docRef.delete();

    console.log(`✅ Bank account ${accountId} deleted for user ${uid}.`);
    res.status(200).send({ message: 'Xóa liên kết tài khoản thành công.' });

  } catch (error) {
    console.error('Error deleting bank account:', error);
    return res.status(500).send({ message: 'Lỗi khi xóa tài khoản.' });
  }
};

module.exports = {
  sendOtp,
  verifyAndRegister,
  sendOtpForPinReset,
  verifyOtpOnly,
  sendPasswordResetOtp,
  verifyPasswordResetOtp,
  resetPasswordWithToken,
  setPin,
  verifyPin,
  addBankAccount,
  getBankAccounts,
  deleteBankAccount,
};
