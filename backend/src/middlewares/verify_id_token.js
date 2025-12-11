// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/backend/src/middleware/verify_id_token.js

const admin = require('../config/firebase');

const verifyIdToken = async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).send({ message: 'Không có token xác thực hoặc định dạng không đúng.' });
  }

  const idToken = authHeader.split('Bearer ')[1];

  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.uid = decodedToken.uid; // Thêm UID của người dùng vào request
    next(); // Chuyển sang middleware/controller tiếp theo
  } catch (error) {
    console.error('Error verifying Firebase ID token:', error);
    return res.status(403).send({ message: 'Token xác thực không hợp lệ hoặc đã hết hạn.' });
  }
};

module.exports = verifyIdToken;