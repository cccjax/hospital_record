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
            subtitle: '统一配置病人/入院/日常/模板字段并控制列表显示',
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
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F3149),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F9FF),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFD9E5F4)),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Color(0xFF5D728C),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
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
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 18,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Color(0xFF7E95B3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
