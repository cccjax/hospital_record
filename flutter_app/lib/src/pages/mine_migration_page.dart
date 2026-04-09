import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/section_card.dart';

class MineMigrationPage extends StatefulWidget {
  const MineMigrationPage({super.key});

  @override
  State<MineMigrationPage> createState() => _MineMigrationPageState();
}

class _MineMigrationPageState extends State<MineMigrationPage> {
  final TextEditingController _jsonController = TextEditingController();

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: AppBackButton(),
        ),
        title: const Text(
          '数据迁移',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          SectionCard(
            title: '导出数据',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '将当前本机离线数据导出为 JSON 字符串，可用于跨设备迁移。',
                  style: TextStyle(color: Color(0xFF6E819A)),
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: () {
                    final text = context.read<HospitalAppState>().exportDataJson();
                    _jsonController.text = text;
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('导出成功，已复制到剪贴板')),
                    );
                  },
                  child: const Text('导出并复制'),
                ),
              ],
            ),
          ),
          SectionCard(
            title: '导入数据',
            child: Column(
              children: [
                TextField(
                  controller: _jsonController,
                  minLines: 10,
                  maxLines: 16,
                  decoration: const InputDecoration(
                    hintText: '请粘贴导出的 JSON 数据',
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () async {
                    final ok = await context
                        .read<HospitalAppState>()
                        .importDataFromJson(_jsonController.text);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(ok ? '导入成功' : '导入失败，请检查数据')),
                    );
                  },
                  child: const Text('执行导入'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
