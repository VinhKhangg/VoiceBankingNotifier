// lib/features/transaction/view/transaction_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/transaction_model.dart';
import '../../../services/database_service.dart';
import '../../../layout/app_bar_common.dart';
import 'package:month_year_picker/month_year_picker.dart';

class TransactionStatsScreen extends StatefulWidget {
  const TransactionStatsScreen({Key? key}) : super(key: key);

  @override
  TransactionStatsScreenState createState() => TransactionStatsScreenState();
}

class TransactionStatsScreenState extends State<TransactionStatsScreen> {
  late DateTime _selectedMonth;
  List<TransactionModel> _monthlyTransactions = [];
  Map<String, double> _dailyTotals = {};
  double _monthlyTotalAmount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    loadStats();
  }

  Future<void> loadStats() async {
    setState(() => _isLoading = true);

    final allTransactions = await DatabaseService.getAllTransactions();
    _monthlyTransactions = allTransactions.where((tx) {
      return tx.time.year == _selectedMonth.year && tx.time.month == _selectedMonth.month;
    }).toList();

    _monthlyTotalAmount = _monthlyTransactions.fold(0.0, (sum, tx) => sum + tx.amount);

    _dailyTotals = {};
    for (var tx in _monthlyTransactions) {
      final dayKey = DateFormat('dd').format(tx.time);
      _dailyTotals.update(dayKey, (value) => value + tx.amount, ifAbsent: () => tx.amount);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _pickMonth() async {
    final picked = await showMonthYearPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('vi'),
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() => _selectedMonth = picked);
      await loadStats();
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Lấy theme hiện tại
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      // ✅ Sử dụng màu từ theme
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CommonAppBar(title: "Thống kê"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildMonthSelector(theme),
            const SizedBox(height: 20),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildBarChart(theme),
            const SizedBox(height: 24),
            _buildBankPieChart(theme, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
        title: const Text("Tháng thống kê", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          DateFormat('MMMM yyyy', 'vi_VN').format(_selectedMonth),
          style: const TextStyle(fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: _pickMonth,
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        StatCard(
          icon: Icons.account_balance_wallet,
          iconColor: Colors.deepPurple,
          label: 'Tổng thu nhập tháng',
          value: _formatCurrency(_monthlyTotalAmount),
        ),
        const SizedBox(height: 12),
        StatCard(
          icon: Icons.swap_horiz,
          iconColor: Colors.orange,
          label: 'Số lượng giao dịch',
          value: '${_monthlyTransactions.length} lần',
        ),
      ],
    );
  }

  Widget _buildBarChart(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tổng thu nhập theo ngày", style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: _dailyTotals.isEmpty
              ? const Center(child: Text("Không có dữ liệu cho tháng này"))
              : BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _dailyTotals.isEmpty ? 1 : _dailyTotals.values.reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final day = _dailyTotals.keys.elementAt(group.x.toInt());
                    return BarTooltipItem(
                      'Ngày $day\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: [TextSpan(text: _formatCurrency(rod.toY), style: const TextStyle(color: Colors.yellow))],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= _dailyTotals.length) return const SizedBox();
                      final day = _dailyTotals.keys.elementAt(value.toInt());
                      return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(day, style: theme.textTheme.bodySmall));
                    },
                    reservedSize: 30,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: List.generate(_dailyTotals.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: _dailyTotals.values.elementAt(index),
                      color: theme.colorScheme.primary, // Sử dụng màu từ theme
                      width: 15,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                    )
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankPieChart(ThemeData theme, bool isDarkMode) {
    final Map<String, double> bankTotals = {};
    for (var tx in _monthlyTransactions) {
      bankTotals.update(tx.bankName, (value) => value + tx.amount, ifAbsent: () => tx.amount);
    }
    final List<Color> pieColors = isDarkMode ?
    [
      Colors.blue.shade300, Colors.green.shade300, Colors.orange.shade300,
      Colors.red.shade300, Colors.purple.shade300, Colors.teal.shade300, Colors.pink.shade300,
    ] : [
      Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal, Colors.pink,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Tỷ trọng theo ngân hàng", style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: bankTotals.isEmpty
              ? const Center(child: Text("Không có dữ liệu cho tháng này"))
              : Row(
            children: [
              Expanded(
                flex: 2,
                child: PieChart(
                  PieChartData(
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: List.generate(bankTotals.length, (index) {
                      final bankValue = bankTotals.values.elementAt(index);
                      final percentage = _monthlyTotalAmount > 0 ? (bankValue / _monthlyTotalAmount) * 100 : 0.0;
                      return PieChartSectionData(
                        color: pieColors[index % pieColors.length],
                        value: bankValue,
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: bankTotals.length,
                  itemBuilder: (context, index) {
                    return Indicator(
                      color: pieColors[index % pieColors.length],
                      text: bankTotals.keys.elementAt(index),
                      isSquare: false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  const StatCard({super.key, required this.icon, required this.label, required this.value, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              radius: 24,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value, style: Theme.of(context).textTheme.headlineSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  const Indicator({super.key, required this.color, required this.text, this.isSquare = true, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Container(width: size, height: size, decoration: BoxDecoration(shape: isSquare ? BoxShape.rectangle : BoxShape.circle, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
