import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:month_year_picker/month_year_picker.dart';
import '../../../models/transaction_model.dart';
import '../../../services/database_service.dart';
import '../../../layout/app_bar_common.dart';
import 'export_pdf_screen.dart';
import 'dart:math' as math;

class TransactionStatsScreen extends StatefulWidget {
  const TransactionStatsScreen({Key? key}) : super(key: key);

  @override
  TransactionStatsScreenState createState() => TransactionStatsScreenState();
}

class TransactionStatsScreenState extends State<TransactionStatsScreen> {
  late DateTime _selectedMonth;
  bool _isLoading = true;

  // Dữ liệu cho các thẻ tóm tắt và biểu đồ
  double _monthlyIncome = 0.0;
  double _monthlyExpense = 0.0;
  double _endOfMonthBalance = 0.0;
  Map<String, double> _dailyIncome = {};
  Map<String, double> _dailyExpense = {};

  // State để lưu trữ thống kê thu/chi theo TÀI KHOẢN CỦA BẠN
  Map<String, double> _incomeByMyBank = {};
  Map<String, double> _expenseByMyBank = {};

  // Biến state cho biểu đồ cột tương tác
  int _touchedIndex = -1;

  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Future<void> loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final allTransactions = await DatabaseService.getAllTransactions();
    allTransactions.sort((a, b) => a.time.compareTo(b.time));

    final lastTxBeforeMonth = allTransactions.lastWhere(
          (tx) => tx.time.isBefore(DateTime(_selectedMonth.year, _selectedMonth.month, 1)),
      orElse: () => TransactionModel(id: '', amount: 0, time: DateTime.now(), type: TransactionType.income, accountNumber: '', description: '', bankName: '', balanceAfter: 0, partnerAccountName: '', destinationBankName: '', destinationAccountNumber: ''),
    );
    final initialBalanceOfMonth = lastTxBeforeMonth.balanceAfter;

    final monthlyTransactions = allTransactions
        .where((tx) =>
    tx.time.year == _selectedMonth.year &&
        tx.time.month == _selectedMonth.month)
        .toList();

    double tempIncome = 0.0;
    double tempExpense = 0.0;
    Map<String, double> tempDailyIncome = {};
    Map<String, double> tempDailyExpense = {};
    double tempEndOfMonthBalance = initialBalanceOfMonth;

    // Reset state cho biểu đồ tròn
    Map<String, double> tempIncomeByMyBank = {};
    Map<String, double> tempExpenseByMyBank = {};


    if (monthlyTransactions.isNotEmpty) {
      tempEndOfMonthBalance = monthlyTransactions.last.balanceAfter;
    }

    for (var tx in monthlyTransactions) {
      final dayKey = DateFormat('dd').format(tx.time);
      // Lấy tên ngân hàng của BẠN làm key để nhóm
      final myBankKey = tx.destinationBankName;

      if (tx.type == TransactionType.income) {
        tempIncome += tx.amount;
        tempDailyIncome.update(dayKey, (value) => value + tx.amount, ifAbsent: () => tx.amount);
        // Tính tổng THU vào tài khoản này của bạn
        tempIncomeByMyBank.update(myBankKey, (value) => value + tx.amount, ifAbsent: () => tx.amount);
      } else {
        tempExpense += tx.amount;
        tempDailyExpense.update(dayKey, (value) => value + tx.amount, ifAbsent: () => tx.amount);
        // Tính tổng CHI từ tài khoản này của bạn
        tempExpenseByMyBank.update(myBankKey, (value) => value + tx.amount, ifAbsent: () => tx.amount);
      }
    }

    if (!mounted) return;
    setState(() {
      _monthlyIncome = tempIncome;
      _monthlyExpense = tempExpense;
      _dailyIncome = tempDailyIncome;
      _dailyExpense = tempDailyExpense;
      _endOfMonthBalance = tempEndOfMonthBalance;
      _incomeByMyBank = tempIncomeByMyBank;
      _expenseByMyBank = tempExpenseByMyBank;
      _isLoading = false;
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showMonthYearPicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('vi'),
    );
    if (picked != null && picked != _selectedMonth) {
      setState(() => _selectedMonth = picked);
      await loadStats();
    }
  }

  String _formatCurrency(double amount, {bool compact = false}) {
    if (compact) {
      if (amount.abs() >= 1000000000) {
        return '${(amount / 1000000000).toStringAsFixed(1)} Tỷ';
      }
      if (amount.abs() >= 1000000) {
        return '${(amount / 1000000).toStringAsFixed(1)} Tr';
      }
      if (amount.abs() >= 1000) {
        return '${(amount / 1000).toStringAsFixed(0)} K';
      }
    }
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CommonAppBar(title: "Thống kê giao dịch"),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ExportPdfScreen()),
          );
        },
        tooltip: 'Xuất sao kê PDF',
        child: const Icon(Icons.picture_as_pdf_outlined),
      ),
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

            // ✅ GOM LẠI: Chỉ hiển thị widget gom nhóm nếu có dữ liệu
            if (_incomeByMyBank.isNotEmpty || _expenseByMyBank.isNotEmpty)
              _CombinedPieChart(
                incomeData: _incomeByMyBank,
                expenseData: _expenseByMyBank,
                totalIncome: _monthlyIncome,
                totalExpense: _monthlyExpense,
              ),

            const SizedBox(height: 80), // Khoảng trống cho FAB
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        StatCard(
          icon: Icons.arrow_downward_rounded,
          iconColor: Colors.green,
          label: 'Tổng thu tháng',
          value: _formatCurrency(_monthlyIncome),
        ),
        const SizedBox(height: 12),
        StatCard(
          icon: Icons.arrow_upward_rounded,
          iconColor: Colors.red,
          label: 'Tổng chi tháng',
          value: _formatCurrency(_monthlyExpense),
        ),
        const SizedBox(height: 12),
        StatCard(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: Colors.blue,
          label: 'Số dư cuối kỳ',
          value: _formatCurrency(_endOfMonthBalance),
        ),
      ],
    );
  }

  Widget _buildMonthSelector(ThemeData theme) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(Icons.calendar_month, color: theme.colorScheme.primary),
        title: const Text("Tháng thống kê",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          DateFormat('MMMM yyyy', 'vi_VN').format(_selectedMonth),
          style: const TextStyle(fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: _pickMonth,
      ),
    );
  }

  Widget _buildBarChart(ThemeData theme) {
    final allDays = {..._dailyIncome.keys, ..._dailyExpense.keys}.toList()
      ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Biến động theo ngày", style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Container(
          height: 300,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: allDays.isEmpty
              ? const Center(child: Text("Không có giao dịch trong tháng này."))
              : LayoutBuilder(
            builder: (context, constraints) {
              // 🔹 mỗi ngày ~ 26px, nhưng tối thiểu vẫn phải >= width container
              final double perDayWidth = 26.0;
              final double chartWidth = math.max(
                allDays.length * perDayWidth,
                constraints.maxWidth,
              );

              // 🔹 nếu nhiều ngày thì tự giảm width cột cho đỡ dày
              final double barWidth =
              allDays.length > 20 ? 8.0 : 12.0;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        handleBuiltInTouches: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: isDarkMode
                              ? Colors.black.withOpacity(0.85)
                              : Colors.grey.shade900.withOpacity(0.9),
                          getTooltipItem:
                              (group, groupIndex, rod, rodIndex) {
                            final isIncome = rodIndex == 0;
                            final type = isIncome ? 'Thu' : 'Chi';
                            return BarTooltipItem(
                              '$type\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: _formatCurrency(rod.toY),
                                  style: TextStyle(
                                    color: isIncome
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFE53935),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        touchCallback: (event, barTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                barTouchResponse == null ||
                                barTouchResponse.spot == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = barTouchResponse
                                .spot!.touchedBarGroupIndex;
                          });
                        },
                      ),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 ||
                                  index >= allDays.length) {
                                return const SizedBox.shrink();
                              }

                              final day = allDays[index];

                              // 🔹 nếu quá nhiều ngày, ẩn bớt label cho đỡ rối
                              if (allDays.length > 20 && index % 2 != 0) {
                                return const SizedBox.shrink();
                              }

                              return Padding(
                                padding:
                                const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  day,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 46,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                _formatCurrency(value, compact: true),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                  fontSize: 11,
                                  color: theme.hintColor,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 500000,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.15),
                          strokeWidth: 1,
                        ),
                      ),
                      barGroups: List.generate(allDays.length, (index) {
                        final day = allDays[index];
                        final income = _dailyIncome[day] ?? 0;
                        final expense = _dailyExpense[day] ?? 0;
                        final isTouched = index == _touchedIndex;

                        return BarChartGroupData(
                          x: index,
                          barsSpace: 6,
                          barRods: [
                            BarChartRodData(
                              toY: income.toDouble(),
                              width: barWidth,
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(8),
                              borderSide: isTouched
                                  ? const BorderSide(
                                color: Color(0xFFB2FF59),
                                width: 1.5,
                              )
                                  : BorderSide.none,
                            ),
                            BarChartRodData(
                              toY: expense.toDouble(),
                              width: barWidth,
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(8),
                              borderSide: isTouched
                                  ? const BorderSide(
                                color: Color(0xFFFF8A80),
                                width: 1.5,
                              )
                                  : BorderSide.none,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Widget thẻ tóm tắt
class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const StatCard({Key? key, required this.icon, required this.iconColor, required this.label, required this.value}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget chú thích cho biểu đồ
class Indicator extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final bool isTouched;

  const Indicator({
    super.key,
    required this.color,
    required this.text,
    this.isSquare = false,
    this.size = 16,
    this.isTouched = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
              shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
              color: color,
              borderRadius: isSquare ? BorderRadius.circular(2) : null,
              border: isTouched ? Border.all(color: color.withOpacity(0.7), width: 2) : null
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(
            text,
            style: TextStyle(
                fontSize: 14,
                fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                overflow: TextOverflow.ellipsis
            ))
        )
      ],
    );
  }
}

// ✅ TẠO WIDGET MỚI: Widget gom nhóm hai biểu đồ tròn
class _CombinedPieChart extends StatefulWidget {
  final Map<String, double> incomeData;
  final Map<String, double> expenseData;
  final double totalIncome;
  final double totalExpense;

  const _CombinedPieChart({
    required this.incomeData,
    required this.expenseData,
    required this.totalIncome,
    required this.totalExpense,
  });

  @override
  State<_CombinedPieChart> createState() => _CombinedPieChartState();
}

enum _PieChartType { income, expense }

class _CombinedPieChartState extends State<_CombinedPieChart> {
  // Mặc định hiển thị biểu đồ Thu nếu có dữ liệu, nếu không thì hiển thị Chi
  late _PieChartType _selectedType;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.incomeData.isNotEmpty ? _PieChartType.income : _PieChartType.expense;
  }

  // Xử lý khi dữ liệu đầu vào của Widget thay đổi (ví dụ: người dùng chọn tháng khác)
  @override
  void didUpdateWidget(covariant _CombinedPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu đang chọn 'chi' mà hết dữ liệu chi, thì chuyển sang 'thu' nếu có
    if (_selectedType == _PieChartType.expense && widget.expenseData.isEmpty && widget.incomeData.isNotEmpty) {
      _selectedType = _PieChartType.income;
    }
    // Ngược lại, nếu đang chọn 'thu' mà hết dữ liệu thu, thì chuyển sang 'chi'
    else if (_selectedType == _PieChartType.income && widget.incomeData.isEmpty && widget.expenseData.isNotEmpty) {
      _selectedType = _PieChartType.expense;
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncomeSelected = _selectedType == _PieChartType.income;

    final Map<String, double> data = isIncomeSelected ? widget.incomeData : widget.expenseData;
    final double totalValue = isIncomeSelected ? widget.totalIncome : widget.totalExpense;

    final sortedData = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.pink, Colors.amber];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề
        Text("Tỷ Trọng Tài khoản", style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        // Container chính
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              // Các nút bấm chọn Thu/Chi
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.incomeData.isNotEmpty)
                    _buildTypeButton(label: "Thu", type: _PieChartType.income, theme: theme),
                  if (widget.incomeData.isNotEmpty && widget.expenseData.isNotEmpty)
                    const SizedBox(width: 16),
                  if (widget.expenseData.isNotEmpty)
                    _buildTypeButton(label: "Chi", type: _PieChartType.expense, theme: theme),
                ],
              ),
              const SizedBox(height: 20),
              // Biểu đồ và chú thích
              if (data.isEmpty)
                const SizedBox(
                    height: 180,
                    child: Center(child: Text("Không có dữ liệu cho mục này.")))
              else
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                if (!mounted) return;
                                setState(() {
                                  if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1; return;
                                  }
                                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 2,
                            centerSpaceRadius: 40,
                            sections: List.generate(sortedData.length, (i) {
                              final isTouched = i == _touchedIndex;
                              final fontSize = isTouched ? 16.0 : 12.0;
                              final radius = isTouched ? 60.0 : 50.0;
                              final value = sortedData[i].value;
                              final percentage = (totalValue > 0) ? (value / totalValue * 100) : 0;
                              return PieChartSectionData(
                                color: colors[i % colors.length],
                                value: value,
                                title: '${percentage.toStringAsFixed(percentage > 10 ? 0 : 1)}%',
                                radius: radius,
                                titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)]),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(sortedData.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Indicator(
                              color: colors[i % colors.length],
                              text: sortedData[i].key,
                              isSquare: true,
                              size: _touchedIndex == i ? 14 : 12,
                              isTouched: _touchedIndex == i,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget cho nút bấm Thu/Chi
  Widget _buildTypeButton({
    required String label,
    required _PieChartType type,
    required ThemeData theme
  }) {
    final bool isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
            _touchedIndex = -1; // Reset khi đổi biểu đồ
          });
        }
      },
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.textTheme.bodyLarge?.color,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: StadiumBorder(
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400,
        ),
      ),
    );
  }
}
