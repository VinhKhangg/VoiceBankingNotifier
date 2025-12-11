// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/backend/src/routes/notification_routes.js

const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notification_controller');
const verifyIdToken = require('../middlewares/verify_id_token');

// Route để test gửi notification
// Middleware verifyIdToken để đảm bảo chỉ người dùng đã đăng nhập mới gọi được
router.post('/send-test', verifyIdToken, notificationController.sendTestNotification);

module.exports = router;
