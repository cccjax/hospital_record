import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/hospital_app_state.dart';
import 'field_config_page.dart';
import 'mine_migration_page.dart';
import 'mine_security_page.dart';

class MineTabPage extends StatelessWidget {
  const MineTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '我的',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        children: [
          _MenuCard(
            title: '数据迁移',
            subtitle: '导入/导出离线数据，用于设备间转移',
            tag: '离线转移',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MineMigrationPage()),
            ),
          ),
          _MenuCard(
            title: '密码保护',
            subtitle: '开启后每次打开应用都需要输入密码',
            tag: state.isPasswordEnabled ? '已开启' : '未开启',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MineSecurityPage()),
            ),
          ),
          _MenuCard(
            title: '字段配置',
            subtitle: '统一配置病人/入院/日常字段并同步模块显示',
            tag: '模块联动',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FieldConfigPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF22364E),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FB),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFD9E4F3)),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Color(0xFF5D728C),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF71849D),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 28,
                  color: Color(0xFF607A98),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
