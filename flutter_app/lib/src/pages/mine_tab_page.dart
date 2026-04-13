import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/hospital_app_state.dart';
import '../widgets/responsive_layout.dart';
import 'field_config_page.dart';
import 'mine_migration_page.dart';
import 'mine_security_page.dart';

class MineTabPage extends StatelessWidget {
  const MineTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final groups = <_MineMenuGroup>[
      _MineMenuGroup(
        title: '数据管理',
        items: [
          _MineMenuItem(
            title: '数据迁移',
            subtitle: '导入/导出离线数据，用于设备间转移',
            tag: '离线转移',
            color: const Color(0xFF2F7FD8),
            icon: Icons.sync_alt_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MineMigrationPage(),
              ),
            ),
          ),
        ],
      ),
      _MineMenuGroup(
        title: '安全与隐私',
        items: [
          _MineMenuItem(
            title: '密码保护',
            subtitle: '开启后每次打开应用都需要输入密码',
            tag: state.isPasswordEnabled ? '已开启' : '未开启',
            color: const Color(0xFF14A085),
            icon: Icons.lock_outline_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MineSecurityPage(),
              ),
            ),
          ),
        ],
      ),
      _MineMenuGroup(
        title: '系统配置',
        items: [
          _MineMenuItem(
            title: '字段配置',
            subtitle: '统一配置病人/入院/日常/模板字段并控制列表显示',
            tag: '模块联动',
            color: const Color(0xFF7A63D1),
            icon: Icons.tune_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FieldConfigPage(),
              ),
            ),
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '我的',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = ResponsiveLayout.fromWidth(constraints.maxWidth);
          return ResponsiveBody(
            layout: layout,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                layout.horizontalPadding,
                12,
                layout.horizontalPadding,
                94,
              ),
              children: [
                for (var groupIndex = 0;
                    groupIndex < groups.length;
                    groupIndex++) ...[
                  _SectionHeader(
                    title: groups[groupIndex].title,
                  ),
                  const SizedBox(height: 8),
                  for (var itemIndex = 0;
                      itemIndex < groups[groupIndex].items.length;
                      itemIndex++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: itemIndex == groups[groupIndex].items.length - 1
                            ? 0
                            : 10,
                      ),
                      child:
                          _MenuTile(item: groups[groupIndex].items[itemIndex]),
                    ),
                  if (groupIndex < groups.length - 1)
                    const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF0E7EEF8),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFD3DFED), width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2E4868),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _MineMenuGroup {
  const _MineMenuGroup({
    required this.title,
    required this.items,
  });

  final String title;
  final List<_MineMenuItem> items;
}

class _MineMenuItem {
  const _MineMenuItem({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String tag;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.item,
  });

  final _MineMenuItem item;

  @override
  Widget build(BuildContext context) {
    final badgeBackground = Color.alphaBlend(
      item.color.withValues(alpha: 0.14),
      const Color(0xFFF4F8FF),
    );
    final iconBackground = Color.alphaBlend(
      item.color.withValues(alpha: 0.16),
      Colors.white,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4E1EF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x13183B58),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.color.withValues(alpha: 0.40),
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F334B),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: badgeBackground,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: item.color.withValues(alpha: 0.36),
                              ),
                            ),
                            child: Text(
                              item.tag,
                              style: TextStyle(
                                color: item.color,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF6E839F),
                          fontSize: 13,
                          height: 1.32,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const SizedBox(
                  width: 16,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFF748BA8),
                    ),
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
