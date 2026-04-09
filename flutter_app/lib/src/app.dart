import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
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
  final LocalAuthentication _localAuth = LocalAuthentication();

  String? _errorText;
  String? _biometricHint;
  bool _biometricChecking = true;
  bool _biometricAvailable = false;
  bool _biometricBusy = false;
  bool _autoTriedBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBiometric();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initBiometric() async {
    final state = context.read<HospitalAppState>();
    if (!state.isBiometricEnabled) {
      if (!mounted) return;
      setState(() {
        _biometricChecking = false;
        _biometricAvailable = false;
        _biometricHint = null;
      });
      return;
    }

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      final available = canCheck && supported;
      if (!mounted) return;
      setState(() {
        _biometricChecking = false;
        _biometricAvailable = available;
        _biometricHint = available ? null : '当前设备不支持指纹解锁';
      });
      if (available && !_autoTriedBiometric) {
        _autoTriedBiometric = true;
        await _unlockByBiometric(showError: false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _biometricChecking = false;
        _biometricAvailable = false;
        _biometricHint = '指纹能力检测失败，请使用密码解锁';
      });
    }
  }

  Future<void> _unlockByBiometric({required bool showError}) async {
    if (_biometricBusy || !_biometricAvailable) return;
    setState(() {
      _biometricBusy = true;
      if (showError) {
        _biometricHint = null;
      }
    });

    try {
      final ok = await _localAuth.authenticate(
        localizedReason: '请验证指纹以解锁应用',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!mounted) return;
      if (ok) {
        context.read<HospitalAppState>().unlockSessionWithBiometric();
        return;
      }
      if (showError) {
        setState(() {
          _biometricHint = '指纹验证未通过，请重试';
        });
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      if (showError) {
        final msg = (error.message ?? '').trim();
        setState(() {
          _biometricHint = msg.isEmpty ? '指纹验证失败，请稍后重试' : msg;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _biometricBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final canUseBiometric = state.isBiometricEnabled;

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
                        fontSize: 18,
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
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _submit(context),
                        child: const Text('解锁进入'),
                      ),
                    ),
                    if (canUseBiometric) ...[
                      const SizedBox(height: 10),
                      if (_biometricChecking)
                        const SizedBox(
                          width: double.infinity,
                          child: LinearProgressIndicator(minHeight: 2),
                        )
                      else if (_biometricAvailable)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _biometricBusy
                                ? null
                                : () => _unlockByBiometric(showError: true),
                            icon: Icon(
                              Icons.fingerprint_rounded,
                              color: _biometricBusy
                                  ? const Color(0xFF8AA0BC)
                                  : const Color(0xFF2F5F96),
                            ),
                            label: Text(_biometricBusy ? '验证中...' : '使用指纹解锁'),
                          ),
                        ),
                      if (_biometricHint != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _biometricHint!,
                          style: const TextStyle(
                            color: Color(0xFF6D7F95),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
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
