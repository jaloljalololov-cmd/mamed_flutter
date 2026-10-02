import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Repository _repository = Repository();

  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _dbController = TextEditingController();

  final _backupHostController = TextEditingController();
  final _backupPortController = TextEditingController();
  final _backupDbController = TextEditingController();

  final _userController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hostController.text = prefs.getString('serverHost') ?? '';
      _portController.text = prefs.getString('serverPort') ?? '';
      _dbController.text = prefs.getString('serverDbName') ?? '';

      _backupHostController.text = prefs.getString('backupHost') ?? '';
      _backupPortController.text = prefs.getString('backupPort') ?? '';
      _backupDbController.text = prefs.getString('backupDbName') ?? '';

      _userController.text = prefs.getString('username') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';

      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('serverHost', _hostController.text);
    await prefs.setString('serverPort', _portController.text);
    await prefs.setString('serverDbName', _dbController.text);

    await prefs.setString('backupHost', _backupHostController.text);
    await prefs.setString('backupPort', _backupPortController.text);
    await prefs.setString('backupDbName', _backupDbController.text);

    await prefs.setString('username', _userController.text);
    await prefs.setString('password', _passwordController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Настройки сохранены. Синхронизация...')));
    }

    final msg = await _repository.syncDirectories();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки подключения')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Основной сервер', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 8),
                  TextField(controller: _hostController, decoration: const InputDecoration(labelText: 'Адрес сервера (IP / Хост)', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _portController, decoration: const InputDecoration(labelText: 'Порт', border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _dbController, decoration: const InputDecoration(labelText: 'Имя базы', border: OutlineInputBorder()))),
                    ],
                  ),
                  const Divider(height: 32),

                  const Text('Резервный сервер', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(controller: _backupHostController, decoration: const InputDecoration(labelText: 'Резервный адрес (IP / Хост)', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _backupPortController, decoration: const InputDecoration(labelText: 'Резервный порт', border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: _backupDbController, decoration: const InputDecoration(labelText: 'Резервное имя базы', border: OutlineInputBorder()))),
                    ],
                  ),
                  const Divider(height: 32),

                  const Text('Авторизация', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(controller: _userController, decoration: const InputDecoration(labelText: 'Логин', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder())),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: _saveSettings,
                    child: const Text('Сохранить и синхронизировать', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
