import 'package:flutter/material.dart';

class BankLogo extends StatelessWidget {
  final String bankName;
  final double size;

  const BankLogo({
    Key? key,
    required this.bankName,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Chuyển đổi tên ngân hàng thành tên file (chữ thường, không dấu)
    final String logoFileName = bankName.toLowerCase().replaceAll(' ', '');
    final String imagePath = 'assets/images/bank_logo/$logoFileName.png';

    return Image.asset(
      imagePath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // Xử lý lỗi nếu không tìm thấy logo
      errorBuilder: (context, error, stackTrace) {
        // Nếu không có logo, hiển thị avatar chữ cái đầu
        return CircleAvatar(
          radius: size / 2,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            bankName.isNotEmpty ? bankName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.5,
            ),
          ),
        );
      },
    );
  }
}
