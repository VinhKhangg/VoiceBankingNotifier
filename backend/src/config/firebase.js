// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/backend/src/config/firebase.js

const admin = require('firebase-admin');

// Đảm bảo bạn đã tải file serviceAccountKey.json từ Firebase Console
// và đặt nó vào cùng thư mục 'config'
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

console.log("Firebase Admin SDK initialized successfully.");

module.exports = admin;
