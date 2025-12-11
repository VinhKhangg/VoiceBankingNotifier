import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:month_year_picker/month_year_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';

import '../../../models/transaction_model.dart';
import '../../../services/database_service.dart';

class ExportPdfScreen extends StatefulWidget {
  const ExportPdfScreen({super.key});

  @override
  State<ExportPdfScreen> createState() => _ExportPdfScreenState();
}

class _ExportPdfScreenState extends State<ExportPdfScreen> {
  List<DateTime> selectedMonths = [];
  bool isExporting = false;
  String? savedPath;
  List<TransactionModel> previewTransactions = [];

  Future<void> _pickMonth() async {
    final picked = await showMonthYearPicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
    );

    if (picked != null) {
      setState(() {
        if (!selectedMonths.any((m) => m.year == picked.year && m.month == picked.month)) {
          selectedMonths.add(picked);
          savedPath = null;
        }
      });
      _loadPreviewData();
    }
  }

  Future<void> _loadPreviewData() async {
    final transactions = await DatabaseService.getAllTransactions();
    final filtered = transactions.where((tx) => selectedMonths.any(
            (m) => tx.time.year == m.year && tx.time.month == m.month)).toList();
    setState(() {
      previewTransactions = filtered;
    });
  }

  Future<void> _exportPdf() async {
    if (selectedMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Vui lòng chọn tháng")));
      return;
    }
    if (!await Permission.manageExternalStorage.request().isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Không có quyền ghi file")));
      return;
    }

    setState(() => isExporting = true);

    try {
      final roboto = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-VariableFont_wdth,wght.ttf'));
      final pdf = pw.Document(theme: pw.ThemeData.withFont(base: roboto, bold: roboto));

      final monthLabels = selectedMonths.map((m) => DateFormat('MM/yyyy').format(m)).join(", ");
      final headers = ['ID Giao dịch', 'Ngày', 'Loại', 'Số TK', 'Số tiền'];
      final rows = previewTransactions.map((tx) {
        final isIncome = tx.type == TransactionType.income;
        return [
          tx.id.substring(0, 10), // Rút gọn ID
          DateFormat('dd/MM/yyyy HH:mm').format(tx.time),
          isIncome ? 'Nhận tiền' : 'Trừ tiền',
          tx.accountNumber,
          "${isIncome ? '+' : '-'} ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(tx.amount)}",
        ];
      }).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(level: 0, child: pw.Text('Sao kê giao dịch tháng: $monthLabels')),
            pw.Table.fromTextArray(
              headers: headers,
              data: rows,
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
              cellAlignments: {
                4: pw.Alignment.centerRight,
              },
            ),
          ],
        ),
      );

      final downloadsDir = Directory('/storage/emulated/0/Download');
      final fileName = "SaoKe_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf";
      final filePath = '${downloadsDir.path}/$fileName';

      final outFile = File(filePath);
      await outFile.writeAsBytes(await pdf.save());

      setState(() {
        isExporting = false;
        savedPath = filePath;
        selectedMonths.clear();
        previewTransactions.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✅ Đã lưu file PDF vào thư mục Download!'),
        action: SnackBarAction(label: 'MỞ', onPressed: () => OpenFile.open(filePath)),
      ));
    } catch (e) {
      setState(() => isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Lỗi khi tạo PDF: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xuất sao kê PDF')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickMonth,
              icon: const Icon(Icons.calendar_month),
              label: const Text("Chọn tháng sao kê"),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: selectedMonths.map((m) => Chip(
                label: Text(DateFormat('MM/yyyy').format(m)),
                onDeleted: () {
                  setState(() => selectedMonths.remove(m));
                  _loadPreviewData();
                },
              )).toList(),
            ),
            const Divider(height: 32),
            if (previewTransactions.isNotEmpty)
              const Text("Xem trước dữ liệu:", style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: previewTransactions.isEmpty
                  ? const Center(child: Text("Chọn tháng để xem trước dữ liệu."))
                  : ListView.builder(
                itemCount: previewTransactions.length,
                itemBuilder: (context, index) {
                  final tx = previewTransactions[index];
                  final isIncome = tx.type == TransactionType.income;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        "${isIncome ? '+' : '-'} ${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(tx.amount)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text("STK: ${tx.accountNumber}"),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (previewTransactions.isNotEmpty)
              ElevatedButton.icon(
                onPressed: isExporting ? null : _exportPdf,
                icon: isExporting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(isExporting ? 'Đang xử lý...' : 'Tạo và Lưu File PDF'),
              ),
          ],
        ),
      ),
    );
  }
}
