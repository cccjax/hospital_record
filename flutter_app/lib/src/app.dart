import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/shell_page.dart';
import 'state/hospital_app_state.dart';
import 'theme/app_theme.dart';

class HospitalApp extends StatelessWidget {
  const HospitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '住院管理系统',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Consumer<HospitalAppState>(
        builder: (context, state, _) {
          if (!state.initialized) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (state.isPasswordEnabled && !state.sessionUnlocked) {
            return const _UnlockPage();
          }
          return const ShellPage();
        },
      ),
    );
  }
}

class _UnlockPage extends StatefulWidget {
  const _UnlockPage();

  @override
  State<_UnlockPage> createState() => _UnlockPageState();
}

class _UnlockPageState extends State<_UnlockPage> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Card(
              margin: const EdgeInsets.all(18),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 34, color: Color(0xFF3A648D)),
                    const SizedBox(height: 8),
                    const Text(
                      '请输入访问密码',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D324A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: '密码',
                        errorText: _errorText,
                      ),
                      onSubmitted: (_) => _submit(context),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => _submit(context),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('解锁'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final ok = context.read<HospitalAppState>().verifyPassword(_controller.text.trim());
    if (ok) return;
    setState(() {
      _errorText = '密码错误，请重试';
    });
  }
}
