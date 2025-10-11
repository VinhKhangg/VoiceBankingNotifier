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
        if (!selectedMonths.any(
                (m) => m.year == picked.year && m.month == picked.month)) {
          selectedMonths.add(picked);
          savedPath = null;
        }
      });

      // Load dữ liệu để preview
      final transactions = await DatabaseService.getAllTransactions();
      final filtered = transactions.where((tx) => selectedMonths.any(
              (m) => tx.time.year == m.year && tx.time.month == m.month)).toList();

      setState(() {
        previewTransactions = filtered;
      });
    }
  }

  Future<void> _exportPdf() async {
    if (selectedMonths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng chọn ít nhất một tháng")),
      );
      return;
    }

    if (!await Permission.manageExternalStorage.request().isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Không có quyền ghi file vào Download")),
      );
      return;
    }

    setState(() {
      isExporting = true;
      savedPath = null;
    });

    try {
      final roboto = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Roboto-VariableFont_wdth,wght.ttf'),
      );

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(base: roboto, bold: roboto),
      );

      final monthLabels = selectedMonths
          .map((m) => DateFormat('MM/yyyy').format(m))
          .join(", ");
      final headers = ['Ngày', 'Số TK', 'Ngân hàng', 'Người gửi', 'Số tiền'];
      final rows = previewTransactions.map((tx) => [
        DateFormat('dd/MM/yyyy HH:mm').format(tx.time),
        tx.accountNumber,
        tx.bankName,
        tx.senderName,
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(tx.amount),
      ]).toList();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Text(
              'Danh sách giao dịch các tháng: $monthLabels',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            if (rows.isEmpty)
              pw.Text('Không có giao dịch nào trong các tháng đã chọn.')
            else
              pw.Table.fromTextArray(
                headers: headers,
                data: rows,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
                cellStyle: const pw.TextStyle(fontSize: 11),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerAlignment: pw.Alignment.center,
              ),
          ],
        ),
      );

      final downloadsDir = Directory('/storage/emulated/0/Download');
      final fileName =
          "giao_dich_${selectedMonths.map((m) => DateFormat('MM_yyyy').format(m)).join('_')}.pdf";
      final filePath = '${downloadsDir.path}/$fileName';

      final outFile = File(filePath);
      await outFile.writeAsBytes(await pdf.save());

      setState(() {
        savedPath = filePath;
        isExporting = false;

        // 👉 Reset về trạng thái ban đầu
        selectedMonths.clear();
        previewTransactions.clear();
      });

      await OpenFile.open(filePath);
    } catch (e) {
      setState(() => isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi khi tạo file PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthChips = selectedMonths.map((m) {
      final label = DateFormat('MM/yyyy').format(m);
      return Chip(
        label: Text(label),
        onDeleted: () {
          setState(() {
            selectedMonths.remove(m);
            previewTransactions = previewTransactions.where((tx) =>
                selectedMonths.any((mm) =>
                tx.time.year == mm.year && tx.time.month == mm.month))
                .toList();
          });
        },
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Xuất PDF giao dịch')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔹 Nút mở file gần nhất
            if (savedPath != null) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  if (savedPath != null) {
                    await OpenFile.open(savedPath!);
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text("Mở file gần nhất"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 🔹 Nút chọn tháng
            ElevatedButton.icon(
              onPressed: _pickMonth,
              icon: const Icon(Icons.edit_calendar),
              label: const Text("Chọn tháng"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 20),
            if (monthChips.isNotEmpty)
              Wrap(spacing: 8, children: monthChips)
            else
              const Text(
                "Hãy chọn tháng sao kê",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 20),

            // ...
            if (selectedMonths.isNotEmpty)
              Expanded(
                child: previewTransactions.isEmpty
                    ? Center(
                  child: Text(
                    "Tháng ${DateFormat('MM/yyyy').format(selectedMonths.last)} chưa có giao dịch nào.",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                )
                    : ListView.builder(
                  itemCount: previewTransactions.length,
                  itemBuilder: (context, index) {
                    final tx = previewTransactions[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.monetization_on,
                            color: Colors.green),
                        title: Text(
                          NumberFormat.currency(locale: 'vi_VN', symbol: '₫')
                              .format(tx.amount),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Text(
                          "${tx.senderName} | ${tx.bankName}\n${DateFormat('dd/MM/yyyy HH:mm').format(tx.time)}",
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            if (previewTransactions.isNotEmpty)
              ElevatedButton.icon(
                onPressed: isExporting ? null : _exportPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Xuất PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),

            if (isExporting) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 10),
              const Text("Đang tạo file PDF...", textAlign: TextAlign.center),
            ] else if (savedPath != null) ...[
              const SizedBox(height: 10),
              const Text(
                '✅ Lưu file thành công!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
