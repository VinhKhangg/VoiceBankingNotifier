import 'package:flutter/material.dart';
import '../../../core/widgets/bank_logo.dart';
import 'add_bank_account_detail_screen.dart';


class SelectBankForLinkingScreen extends StatelessWidget {
  // Danh sách TẤT CẢ các ngân hàng mà ứng dụng hỗ trợ
  final List<String> allVietnamBanks = const [
    'ACB', 'Agribank', 'BIDV', 'Eximbank', 'HDBank',
    'MBBank', 'OCB', 'Sacombank', 'Techcombank',
    'TPBank', 'VIB', 'Vietcombank', 'VietinBank', 'VPBank'
  ];

  // Danh sách tên các ngân hàng ĐÃ được liên kết, truyền từ màn hình trước
  final List<String> linkedBankNames;

  const SelectBankForLinkingScreen({
    super.key,
    required this.linkedBankNames,
  });

  @override
  Widget build(BuildContext context) {
    // Lọc ra danh sách các ngân hàng CÓ THỂ liên kết (chưa được liên kết)
    final availableBanks = allVietnamBanks
        .where((bank) => !linkedBankNames.contains(bank))
        .toList()..sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn ngân hàng để liên kết'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Hiển thị 3 logo trên một hàng
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0, // Đảm bảo các ô là hình vuông
        ),
        itemCount: availableBanks.length,
        itemBuilder: (context, index) {
          final bankName = availableBanks[index];
          return InkWell(
            onTap: () async {
              // Khi người dùng chọn một ngân hàng, điều hướng đến màn hình nhập chi tiết
              // và chờ kết quả trả về
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => AddBankAccountDetailScreen(
                    selectedBankName: bankName, // Truyền tên ngân hàng đã chọn
                  ),
                ),
              );

              // Nếu màn hình chi tiết trả về true (liên kết thành công),
              // thì pop luôn màn hình chọn ngân hàng này để quay về màn hình quản lý
              if (result == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BankLogo(bankName: bankName, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    bankName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
