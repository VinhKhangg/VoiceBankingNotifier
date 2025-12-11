const admin = require('../config/firebase');
const Intl = require('intl');

const sendTestNotification = async (req, res) => {
    const { userId, amount, partnerName, balanceAfter, destinationBankName, transactionType } = req.body;

    if (!userId || amount === undefined || !partnerName || balanceAfter === undefined || !destinationBankName || !transactionType) {
        return res.status(400).send({ message: "Vui lòng cung cấp đầy đủ thông tin..." });
    }

    try {
        const tokensSnapshot = await admin.firestore().collection('users').doc(userId).collection('tokens').get();
        if (tokensSnapshot.empty) {
            return res.status(404).send({ message: "Không tìm thấy thiết bị nào của người dùng." });
        }
        const tokens = tokensSnapshot.docs.map(doc => doc.id);

        const isIncome = transactionType === 'income';
        const formattedAmount = new Intl.NumberFormat('vi-VN').format(amount);

        // ✅✅✅ ĐÂY LÀ PHẦN SỬA LỖI QUAN TRỌNG NHẤT ✅✅✅
        // Xây dựng message cơ bản
        const multicastMessage = {
            tokens: tokens,
            data: {
                type: 'transaction',
                amount: String(amount),
                partnerName: String(partnerName),
                balanceAfter: String(balanceAfter),
                destinationBankName: String(destinationBankName),
                transactionType: String(transactionType),
            },
            android: {
                priority: 'high',
            },
            apns: {
                payload: {
                    aps: {
                        contentAvailable: true,
                    }
                }
            }
        };

        if (isIncome) {
            // NẾU LÀ GIAO DỊCH NHẬN TIỀN:
            // Message đã là data-only hoàn hảo, không cần làm gì thêm.
            // Handler dưới nền sẽ được kích hoạt.
        } else {
            // NẾU LÀ GIAO DỊCH TRỪ TIỀN:
            // Bổ sung thêm trường `notification` vào message để hệ điều hành tự hiển thị.
            multicastMessage.notification = {
                title: "Thông báo Voice Banking",
                body: `Biến động số dư -${formattedAmount}đ`,
            };
            // Thêm cấu hình âm thanh im lặng cho iOS
            multicastMessage.apns.payload.aps.sound = { "critical": 0, "name": "default", "volume": 0 };
        }
        // ✅✅✅ KẾT THÚC PHẦN SỬA LỖI ✅✅✅

        const response = await admin.messaging().sendEachForMulticast(multicastMessage);

        console.log(`Successfully sent message to ${response.successCount} of ${tokens.length} devices for user ${userId}.`);
        res.status(200).send({ message: `Đã gửi thông báo thành công đến ${response.successCount} thiết bị.` });

    } catch (error) {
        console.error('Error sending message:', error);
        res.status(500).send({ message: 'Lỗi khi gửi thông báo.', error: error.message });
    }
};

module.exports = {
    sendTestNotification,
};
