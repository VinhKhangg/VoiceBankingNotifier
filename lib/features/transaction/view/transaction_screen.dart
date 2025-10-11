import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../services/notification_service.dart';
import '../../../services/database_service.dart';
import '../../../models/transaction_model.dart';
import '../../../layout/app_bar_common.dart';

class TransactionNotifierScreen extends StatefulWidget {
  const TransactionNotifierScreen({Key? key}) : super(key: key);

  @override
  _TransactionNotifierScreenState createState() =>
      _TransactionNotifierScreenState();
}

class _TransactionNotifierScreenState extends State<TransactionNotifierScreen> {
  final FlutterTts flutterTts = FlutterTts();
  String? lastNotification;

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
    _restoreLastNotification();
  }

  Future<void> _restoreLastNotification() async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? "guest";

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('last_notification_$uid');
    if (saved != null && saved.isNotEmpty) {
      setState(() => lastNotification = saved);
    }
  }

  void _simulateTransaction() {
    String? selectedBank;
    String? selectedSender;

    final List<String> banks = [
      "Vietcombank", "VietinBank", "BIDV", "Agribank", "Techcombank",
      "MB Bank", "ACB", "Sacombank", "TPBank", "VPBank", "SHB",
      "Eximbank", "OCB", "SCB", "HDBank", "DongA Bank",
    ];

    final List<String> senders = [
      "khang", "thien", "huy", "long", "son", "nam",
      "tuan", "minh", "quang", "an",
    ];

    showDialog(
      context: context,
      builder: (context) {
        final accountController = TextEditingController();
        final amountController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Nhập giao dịch'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedSender,
                      decoration: const InputDecoration(labelText: "Người gửi"),
                      items: senders.map((sender) => DropdownMenuItem(value: sender, child: Text(sender))).toList(),
                      onChanged: (value) => setStateDialog(() => selectedSender = value),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: accountController,
                      decoration: const InputDecoration(labelText: 'Số tài khoản'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedBank,
                      decoration: const InputDecoration(labelText: "Ngân hàng"),
                      items: banks.map((bank) => DropdownMenuItem(value: bank, child: Text(bank))).toList(),
                      onChanged: (value) => setStateDialog(() => selectedBank = value),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Số tiền (VND)'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final sender = selectedSender ?? "";
                    final account = accountController.text.trim();
                    final bank = selectedBank ?? "";
                    final amountText = amountController.text.trim();

                    if (sender.isEmpty || account.isEmpty || bank.isEmpty || amountText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Vui lòng nhập đầy đủ thông tin')));
                      return;
                    }

                    final amount = double.tryParse(amountText.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Số tiền không hợp lệ')));
                      return;
                    }

                    final now = DateTime.now();
                    final formattedAmountForTTS = NumberFormat("#,###", "vi_VN").format(amount.toInt());
                    final voiceMessage = "Bạn vừa nhận được $formattedAmountForTTS đồng";

                    try {
                      await DatabaseService.insertTransaction(TransactionModel(
                        senderName: sender,
                        accountNumber: account,
                        bankName: bank,
                        amount: amount,
                        time: now,
                      ));

                      setState(() => lastNotification = voiceMessage);

                      final prefs = await SharedPreferences.getInstance();
                      final uid = FirebaseAuth.instance.currentUser?.uid ?? "guest";
                      await prefs.setString('last_notification_$uid', voiceMessage);

                      final speechRate = prefs.getDouble('speechRate') ?? 0.4;
                      final pitch = prefs.getDouble('pitch') ?? 1.0;

                      final player = AudioPlayer();
                      await player.play(AssetSource('sounds/tingting.mp3'));

                      await Future.delayed(const Duration(milliseconds: 500));

                      await flutterTts.stop();
                      await flutterTts.setLanguage("vi-VN");
                      await flutterTts.setPitch(pitch);
                      await flutterTts.setSpeechRate(speechRate);
                      await flutterTts.speak(voiceMessage);

                      final formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(now);
                      final bankMessage = "STK $account tại $bank: +${NumberFormat("#,###", "vi_VN").format(amount)}đ, lúc $formattedTime";
                      await NotificationService.show("Ngân Hàng $bank", bankMessage);

                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Lỗi khi lưu giao dịch: $e')));
                    }
                  },
                  child: const Text('Gửi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _getBankLogo(String bankName) {
    final formattedName = bankName.toLowerCase().replaceAll(' ', '');
    return Image.asset(
      'assets/banks/$formattedName.png',
      height: 40,
      width: 40,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).primaryColorLight,
          child: Icon(Icons.account_balance, color: Theme.of(context).primaryColor),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CommonAppBar(title: "Biến động số dư"),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simulateTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Thêm giao dịch'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Column(
        children: [
          // Phần hiển thị thông báo gần nhất
          if (lastNotification != null)
            Builder(
                builder: (context) {
                  // ✅ Quyết định màu nền card thông báo dựa trên theme
                  final bool isDarkMode = theme.brightness == Brightness.dark;
                  final cardBackgroundColor = isDarkMode
                      ? theme.colorScheme.primary.withOpacity(0.1) // Giữ màu cũ cho dark mode
                      : Colors.blue[50]; // ✅ Dùng màu sáng hơn cho light mode

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      // ✅ Áp dụng màu đã chọn
                      color: cardBackgroundColor,
                      child: ListTile(
                        leading: Icon(Icons.notifications_active, color: theme.colorScheme.primary),
                        title: const Text('Thông báo gần nhất:', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(lastNotification!),
                      ),
                    ),
                  );
                }
            ),

          // GIAO DIỆN LỊCH SỬ GIAO DỊCH MỚI
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: DatabaseService.listenTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Lỗi: ${snapshot.error}'));
                }

                final transactions = snapshot.data ?? [];
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('Chưa có giao dịch nào.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    final amountFormatted = NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: '', // Bỏ ký hiệu ₫
                    ).format(t.amount);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(15.0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              _getBankLogo(t.bankName),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Từ: ${t.senderName}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "STK: ${t.accountNumber} - ${t.bankName}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "+$amountFormatted đ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[600],
                                      fontSize: 17,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('HH:mm dd/MM').format(t.time),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
