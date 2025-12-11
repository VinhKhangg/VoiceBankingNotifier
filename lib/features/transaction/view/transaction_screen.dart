import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/notification_service.dart';
import '../../../services/database_service.dart';
import '../../../models/transaction_model.dart';
import '../../../layout/app_bar_common.dart';
import '../../../core/widgets/recent_notifications.dart';
import '../../../core/widgets/add_transaction_dialog.dart';
import 'transaction_detail_screen.dart';


class TransactionNotifierScreen extends StatefulWidget {
  const TransactionNotifierScreen({Key? key}) : super(key: key);

  @override
  _TransactionNotifierScreenState createState() => _TransactionNotifierScreenState();
}

class _TransactionNotifierScreenState extends State<TransactionNotifierScreen> {
  // ... (Các biến và hàm initState, _showAddTransactionDialog, _buildFilterBar, _buildFilterChip giữ nguyên)
  TransactionType? _filterType;
  DateTime? _filterDate;

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddTransactionDialog(),
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
    // Sửa lỗi: Đảm bảo `cardColor` không bao giờ null bằng cách cung cấp giá trị mặc định.
    final Color cardColor = theme.cardColor ?? (theme.brightness == Brightness.dark ? const Color(0xFF303030) : Colors.white);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      // Giữ nguyên màu nền là cardColor như code gốc của bạn
      child: Row(
        children: [
          // --- Lọc theo loại giao dịch ---
          Expanded(
            child: PopupMenuButton<TransactionType?>(
              onSelected: (TransactionType? result) {
                setState(() => _filterType = result);
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<TransactionType?>>[
                const PopupMenuItem(value: null, child: Text('Tất cả loại')),
                const PopupMenuDivider(),
                const PopupMenuItem(value: TransactionType.income, child: Text('Nhận tiền')),
                const PopupMenuItem(value: TransactionType.expense, child: Text('Trừ tiền')),
              ],
              // Sử dụng chip tùy chỉnh đẹp hơn
              child: _buildFilterChip(
                  icon: Icons.filter_list_alt, // Icon rõ ràng hơn
                  label: _filterType == null
                      ? 'Loại GD'
                      : (_filterType == TransactionType.income ? 'Nhận tiền' : 'Trừ tiền'),
                  isActive: _filterType != null,
                  theme: theme
              ),
            ),
          ),
          const SizedBox(width: 12),

          // --- Lọc theo ngày ---
          Expanded(
            flex: 2, // Cho phép phần ngày rộng hơn một chút
            child: InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _filterDate ?? DateTime.now(),
                  firstDate: DateTime(2022),
                  lastDate: DateTime.now(),
                  locale: const Locale('vi', 'VN'),
                  // Tùy chỉnh giao diện DatePicker cho đẹp hơn
                  builder: (context, child) {
                    return Theme(
                      data: theme.copyWith(
                        colorScheme: theme.colorScheme.copyWith(
                          primary: theme.colorScheme.primary, // Màu chính
                          surface: cardColor, // Nền của picker
                        ),
                        dialogBackgroundColor: cardColor, // Nền của dialog
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() => _filterDate = pickedDate);
                }
              },
              child: _buildFilterChip(
                  icon: Icons.calendar_today_outlined,
                  label: _filterDate == null ? 'Chọn ngày' : DateFormat('dd/MM/yyyy').format(_filterDate!),
                  isActive: _filterDate != null,
                  theme: theme
              ),
            ),
          ),

          // --- Nút xóa bộ lọc ---
          if (_filterType != null || _filterDate != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: IconButton(
                icon: const Icon(Icons.clear_rounded, color: Colors.redAccent),
                tooltip: "Xóa bộ lọc",
                onPressed: () {
                  setState(() {
                    _filterType = null;
                    _filterDate = null;
                  });
                },
              ),
            )
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required ThemeData theme,
  }) {
    // ... (Nội dung hàm này giữ nguyên)
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final Color activeColor = theme.colorScheme.primary;
    final Color inactiveColor = isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700;

    // Màu nền của chip
    final Color chipBackgroundColor = isActive
        ? activeColor.withOpacity(0.12)
        : (isDarkMode ? Colors.grey.shade800 : Colors.white);

    // Màu viền của chip
    final Color chipBorderColor = isActive
        ? activeColor.withOpacity(0.8)
        : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: chipBackgroundColor,
        borderRadius: BorderRadius.circular(25), // Bo góc tròn trịa hơn
        border: Border.all(color: chipBorderColor, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: isActive ? activeColor : inactiveColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : inactiveColor,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CommonAppBar(title: "Biến động số dư"),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm giao dịch'),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: DatabaseService.listenTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          var allTransactions = snapshot.data ?? [];

          var filteredTransactions = allTransactions.where((tx) {
            final typeMatch = _filterType == null || tx.type == _filterType;
            final dateMatch = _filterDate == null ||
                (tx.time.year == _filterDate!.year &&
                    tx.time.month == _filterDate!.month &&
                    tx.time.day == _filterDate!.day);
            return typeMatch && dateMatch;
          }).toList();

          return Column(
            children: [
              RecentNotifications(transactions: allTransactions),
              _buildFilterBar(theme),
              Expanded(
                child: filteredTransactions.isEmpty
                    ? Center(
                  child: Text(
                    _filterType != null || _filterDate != null
                        ? 'Không tìm thấy giao dịch phù hợp.'
                        : 'Chưa có giao dịch nào.',
                    style: const TextStyle(
                        fontSize: 16, color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final t = filteredTransactions[index];
                    final isIncome = t.type == TransactionType.income;

                    final amountFormatted = NumberFormat.currency(
                        locale: 'vi_VN', symbol: '₫')
                        .format(t.amount);
                    final balanceFormatted = NumberFormat.currency(
                        locale: 'vi_VN', symbol: '₫')
                        .format(t.balanceAfter);

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TransactionDetailScreen(transaction: t),
                            ),
                          );
                        },
                        child: ListTile(
                          leading: Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                          // ✅ STYLE CHO TIÊU ĐỀ
                          title: Text(
                            isIncome
                                ? "Nhận tiền"
                                : "Trừ tiền",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          // ✅ STYLE CHO PHỤ ĐỀ
                          subtitle: Text(
                            "${t.description}\nSố dư: $balanceFormatted\n${DateFormat('HH:mm - dd/MM/yyyy').format(t.time)}",
                            style:
                            TextStyle(color: Colors.grey.shade600),
                          ),
                          // ✅ STYLE CHO SỐ TIỀN Ở CUỐI
                          trailing: Text(
                            "${isIncome ? '+' : '-'} $amountFormatted",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isIncome
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
