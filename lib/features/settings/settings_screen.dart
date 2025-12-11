import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _speechRate = 0.4;
  double _pitch = 1.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speechRate = prefs.getDouble('speechRate') ?? 0.4;
      _pitch = prefs.getDouble('pitch') ?? 1.0;
      _isLoading = false;
    });
  }

  Future<void> _saveSpeechRate(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('speechRate', value);
    setState(() => _speechRate = value);
  }

  Future<void> _savePitch(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pitch', value);
    setState(() => _pitch = value);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cài đặt"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          _buildSectionTitle("Giao diện"),
          SwitchListTile(
            title: const Text("Chế độ tối"),
            subtitle: const Text("Bật/tắt giao diện tối cho ứng dụng"),
            value: themeProvider.themeMode == ThemeMode.dark,
            activeColor: Theme.of(context).colorScheme.primary,
            // ✅ ĐÃ SỬA LỖI HIỂN THỊ NỀN NÚT GẠT
            inactiveTrackColor: Colors.grey.shade300,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
          const Divider(height: 20, indent: 16, endIndent: 16),
          _buildSectionTitle("Giọng nói thông báo (TTS)"),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tốc độ nói: ${_speechRate.toStringAsFixed(2)}"),
                Slider(
                  value: _speechRate,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: _speechRate.toStringAsFixed(2),
                  onChanged: (value) =>
                      setState(() => _speechRate = value),
                  onChangeEnd: _saveSpeechRate,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Cao độ (Pitch): ${_pitch.toStringAsFixed(2)}"),
                Slider(
                  value: _pitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: _pitch.toStringAsFixed(2),
                  onChanged: (value) => setState(() => _pitch = value),
                  onChangeEnd: _savePitch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
