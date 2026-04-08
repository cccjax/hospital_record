import 'package:flutter/material.dart';
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
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final enabled = state.isPasswordEnabled;

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
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 12),
                if (enabled)
                  FilledButton.tonal(
                    onPressed: () async {
                      await context.read<HospitalAppState>().disablePassword();
                      if (!mounted) return;
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
                    if (!mounted) return;
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
        ],
      ),
    );
  }
}
