import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const DeltaAuthApp());
}

class DeltaAuthApp extends StatelessWidget {
  const DeltaAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Delta Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.indigo.shade400,
          secondary: Colors.green.shade400,
          surface: const Color(0xFF1a1a2e),
        ),
        scaffoldBackgroundColor: const Color(0xFF0f0f1a),
        cardTheme: CardTheme(
          color: const Color(0xFF1a1a2e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2a2a3e)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1a1a2e),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2a2a3e)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2a2a3e)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
          ),
          labelStyle: const TextStyle(color: Color(0xFF888888)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎮 Delta Auth'),
        backgroundColor: const Color(0xFF0f0f1a),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.indigo,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF888888),
          tabs: const [
            Tab(text: '获取凭证', icon: Icon(Icons.download, size: 20)),
            Tab(text: '应用凭证', icon: Icon(Icons.power_settings_new, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          CredentialPage(),
          ApplyPage(),
        ],
      ),
    );
  }
}

// ==================== Tab 1: 获取凭证 ====================
class CredentialPage extends StatefulWidget {
  const CredentialPage({super.key});
  @override
  State<CredentialPage> createState() => _CredentialPageState();
}

class _CredentialPageState extends State<CredentialPage> {
  final _apiUrlCtrl = TextEditingController(text: 'http://10.0.2.2:8000');
  final _codeCtrl = TextEditingController();
  String _status = '';
  bool _loading = false;
  String? _credential;

  Future<void> fetchToken() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _status = '请输入授权码');
      return;
    }

    setState(() { _loading = true; _status = '正在获取凭证...'; _credential = null; });

    try {
      final baseUrl = _apiUrlCtrl.text.trim().replaceAll(RegExp(r'/+$'), '');
      final secR = await http.get(Uri.parse('$baseUrl/api/auth/secret'))
          .timeout(const Duration(seconds: 10));
      if (secR.statusCode != 200) {
        setState(() { _status = '连接服务器失败'; _loading = false; });
        return;
      }
      final secD = jsonDecode(secR.body);
      final tkR = await http.get(Uri.parse('$baseUrl/api/auth/token/$code?secret=${secD['secret']}'))
          .timeout(const Duration(seconds: 10));

      if (tkR.statusCode == 200) {
        final tkD = jsonDecode(tkR.body);
        setState(() {
          _credential = tkD['credential'].toString();
          _status = '\u2705 授权成功！凭证已获取';
          _loading = false;
        });
      } else {
        final err = jsonDecode(tkR.body);
        setState(() {
          _status = '\u274c ${err['error'] ?? '获取失败'}';
          _loading = false;
        });
      }
    } on SocketException {
      setState(() { _status = '\u274c 无法连接到服务器'; _loading = false; });
    } on TimeoutException {
      setState(() { _status = '\u274c 连接超时'; _loading = false; });
    } catch (e) {
      setState(() { _status = '\u274c 错误: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _apiUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'API 服务器地址',
              prefixIcon: Icon(Icons.link, size: 18),
            ),
            style: const TextStyle(fontSize: 13, color: Colors.white),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeCtrl,
            decoration: InputDecoration(
              labelText: '授权码',
              prefixIcon: const Icon(Icons.qr_code, size: 18),
              suffixIcon: _codeCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () { _codeCtrl.clear(); setState(() {}); },
                    )
                  : null,
            ),
            style: const TextStyle(fontSize: 16, color: Colors.white, letterSpacing: 2),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : fetchToken,
              child: _loading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 10),
                        Text('获取中...'),
                      ],
                    )
                  : const Text('获取授权凭证'),
            ),
          ),

          if (_status.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _status.contains('\u2705') ? Icons.check_circle : Icons.info,
                      color: _status.contains('\u2705') ? Colors.green : (_status.contains('\u274c') ? Colors.red : Colors.amber),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_status, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
          ],

          if (_credential != null) ...[
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFF0d2e1a),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF166534)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 8),
                        Text('凭证内容', style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0a1f12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _credential!,
                        style: const TextStyle(
                          color: Color(0xFF86efac),
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Copy to clipboard
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('复制凭证'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Color(0xFF166534)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================== Tab 2: 应用凭证 ====================
class ApplyPage extends StatefulWidget {
  const ApplyPage({super.key});
  @override
  State<ApplyPage> createState() => _ApplyPageState();
}

class _ApplyPageState extends State<ApplyPage> {
  String _status = '准备就绪';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          // 说明卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.indigo.shade300, size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    '将授权凭证应用到游戏',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '确保您已获取授权凭证，并已安装三角洲行动游戏。\n点击下方按钮将凭证写入游戏登录模块。',
                    style: TextStyle(fontSize: 13, color: Color(0xFF888888), height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 应用按钮
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: 应用凭证到游戏登录
              },
              icon: const Icon(Icons.power_settings_new),
              label: const Text('应用授权登录游戏'),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: 清除已应用的凭证
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('清除凭证'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 状态
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.green, size: 10),
                  const SizedBox(width: 10),
                  Text(_status, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
