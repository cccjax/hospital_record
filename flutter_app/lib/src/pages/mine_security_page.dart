import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/section_card.dart';

class MineSecurityPage extends StatefulWidget {
  const MineSecurityPage({super.key});

  @override
  State<MineSecurityPage> createState() => _MineSecurityPageState();
}

class _MineSecurityPageState extends State<MineSecurityPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _checkingBiometric = true;
  bool _biometricSupported = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricCapability();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricCapability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      if (!mounted) return;
      setState(() {
        _biometricSupported = canCheck && supported;
        _checkingBiometric = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _biometricSupported = false;
        _checkingBiometric = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final enabled = state.isPasswordEnabled;
    final biometricEnabled = enabled && state.security.biometricEnabled;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: AppBackButton(),
        ),
        title: const Text(
          '密码保护',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          SectionCard(
            title: '安全状态',
            child: Row(
              children: [
                Text(
                  enabled ? '已开启' : '未开启',
                  style: TextStyle(
                    color: enabled ? const Color(0xFF2D8B49) : const Color(0xFF9A5A32),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 12),
                if (enabled)
                  FilledButton.tonal(
                    onPressed: () async {
                      await context.read<HospitalAppState>().disablePassword();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已关闭密码保护')),
                      );
                    },
                    child: const Text('关闭密码'),
                  ),
              ],
            ),
          ),
          SectionCard(
            title: enabled ? '修改密码' : '开启密码',
            child: Column(
              children: [
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: '新密码'),
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmController,
                  decoration: const InputDecoration(labelText: '确认密码'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    final pwd = _passwordController.text.trim();
                    final confirm = _confirmController.text.trim();
                    if (pwd.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('密码不能为空')),
                      );
                      return;
                    }
                    if (pwd != confirm) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('两次密码不一致')),
                      );
                      return;
                    }
                    await context.read<HospitalAppState>().enableOrChangePassword(pwd);
                    if (!context.mounted) return;
                    _passwordController.clear();
                    _confirmController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(enabled ? '密码已更新' : '密码保护已开启')),
                    );
                  },
                  child: Text(enabled ? '更新密码' : '开启密码'),
                ),
              ],
            ),
          ),
          SectionCard(
            title: '指纹解锁',
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: biometricEnabled,
              onChanged: (value) => _toggleBiometric(context, value, enabled),
              title: const Text(
                '启用指纹解锁',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F3149),
                ),
              ),
              subtitle: Text(
                _buildBiometricHint(enabled),
                style: const TextStyle(
                  color: Color(0xFF6E819A),
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildBiometricHint(bool passwordEnabled) {
    if (!passwordEnabled) return '请先开启密码保护，再启用指纹解锁。';
    if (_checkingBiometric) return '正在检测设备指纹能力...';
    if (!_biometricSupported) return '当前设备不支持或未录入指纹，无法启用。';
    return '开启后可在锁屏页通过指纹快速解锁。';
  }

  Future<void> _toggleBiometric(
    BuildContext context,
    bool value,
    bool passwordEnabled,
  ) async {
    if (!passwordEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先开启密码保护')),
      );
      return;
    }
    if (_checkingBiometric) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在检测设备能力，请稍后重试')),
      );
      return;
    }
    if (value && !_biometricSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前设备不支持或未录入指纹')),
      );
      return;
    }
    await context.read<HospitalAppState>().setBiometricEnabled(value);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value ? '已开启指纹解锁' : '已关闭指纹解锁')),
    );
  }
}
