// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/backend/src/app.js

const express = require('express');
const cors = require('cors');
require('dotenv').config(); // Tải biến môi trường

const authRoutes = require('./routes/auth_routes');
const notificationRoutes = require('./routes/notification_routes');
const app = express();

// Middlewares
app.use(cors()); // Cho phép frontend gọi API
app.use(express.json()); // Xử lý body của request dưới dạng JSON

// Tất cả các route sẽ có tiền tố là /api/
app.use('/api/auth', authRoutes);
app.use('/api/notifications', notificationRoutes);

// Route cơ bản để kiểm tra server có hoạt động không
app.get('/', (req, res) => {
  res.send('Backend for Voice Banking Notifier is running!');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
