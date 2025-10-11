# Voice Banking Notifier - Ứng dụng Thông báo Biến động Số dư

Đây là dự án Khoá luận Tốt nghiệp, xây dựng một ứng dụng Flutter mô phỏng chức năng nhận và đọc thông báo biến động số dư bằng giọng nói tiếng Việt.

## Mục tiêu Dự án

Xây dựng một ứng dụng di động hoàn chỉnh, an toàn và có trải nghiệm người dùng tốt, với các công nghệ hiện đại như Flutter cho frontend và Node.js/Express.js cho backend, tích hợp cùng Firebase cho các dịch vụ đám mây.

## Chức năng nổi bật

-   **Xác thực người dùng an toàn:**
    -   Đăng ký tài khoản qua backend với xác thực OTP gửi qua email.
    -   Đăng nhập và quản lý phiên làm việc bằng Firebase Authentication.
    -   Chức năng "Quên mật khẩu" an toàn thông qua OTP.
-   **Bảo mật hai lớp:**
    -   Bắt buộc người dùng tạo mã PIN 6 số sau khi đăng ký.
    -   Mỗi lần mở lại ứng dụng đều yêu cầu nhập mã PIN.
    -   Chức năng "Quên mã PIN" được xác thực qua OTP gửi về email.
-   **Thông báo biến động số dư:**
    -   Mô phỏng việc nhận một giao dịch mới.
    -   Phát âm thanh "ting ting" và đọc thông báo bằng giọng nói tiếng Việt (Text-to-Speech).
    -   Hiển thị thông báo trên giao diện với hiệu ứng cuộn mượt mà.
    -   Gửi thông báo đẩy (Push Notification) của hệ thống.
-   **Quản lý & Thống kê:**
    -   Hiển thị lịch sử các giao dịch đã nhận.
    -   Thống kê thu nhập theo tháng, biểu đồ cột thu nhập theo ngày và biểu đồ tròn tỷ trọng theo ngân hàng.
-   **Tùy chỉnh cá nhân:**
    -   Cho phép người dùng bật/tắt **Chế độ tối (Dark Mode)**.
    -   Tùy chỉnh **Tốc độ** và **Cao độ (Pitch)** của giọng nói thông báo.

## Công nghệ sử dụng

-   **Frontend:** Flutter
-   **Backend:** Node.js, Express.js
-   **Cơ sở dữ liệu & Dịch vụ đám mây:** Firebase (Authentication, Cloud Firestore)
-   **Gửi Email:** Nodemailer

## Hướng dẫn cài đặt và chạy dự án

### Yêu cầu

-   Flutter SDK
-   Node.js và npm
-   Một máy ảo Android (Android Emulator) hoặc thiết bị Android thật.
-   Tài khoản Firebase và tài khoản email (Gmail) để cấu hình backend.

### Bước 1: Cấu hình Backend

1.  Di chuyển vào terminal chạy lệnh:
- cd backend
- node src/app.js
khi thấy ✅ Firebase Admin SDK initialized successfully.
          🚀 Server is running on port 3000  => bạn đã thành công

2. Chạy máy ảo 
- Vào Device Manager tạo 1 máy ảo phiên bản 34 trở lên 
- Sau khi có máy ảo thì chỉ cần chọn máy ảo sử dụng và chọn main.dart rồi chạy ứng dụng tự cài vào máy
