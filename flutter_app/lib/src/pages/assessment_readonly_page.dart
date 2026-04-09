import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/assessment_score_bar.dart';
import '../widgets/section_card.dart';

class AssessmentReadonlyPage extends StatelessWidget {
  const AssessmentReadonlyPage({
    super.key,
    required this.admissionId,
    required this.assessmentId,
  });

  final String admissionId;
  final String assessmentId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    AssessmentRecord? record;
    for (final row in state.assessmentsOf(admissionId)) {
      if (row.id == assessmentId) {
        record = row;
        break;
      }
    }

    final current = record;
    if (current == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: Text('测评记录不存在')),
      );
    }

    final disease = state.findDisease(current.diseaseId);
    final version = state.findVersion(current.diseaseId, current.versionId);
    final score = version == null ? 0.0 : state.calculateAssessmentScore(version, current.selections);
    final level = version == null ? '-' : state.resolveAssessmentLevel(version, score);
    final itemTotal = version?.items.length ?? 0;
    final selectedTotal = version == null
        ? 0
        : version.items.where((item) => (current.selections[item.id] ?? '').isNotEmpty).length;
    final measuredAt = DateFormat('yyyy-MM-dd HH:mm').format(current.createdAt);

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _SummaryPanel(
            diseaseName: disease?.diseaseName ?? '-',
            versionName: version?.versionName ?? '-',
            level: level,
            score: score,
            measuredAt: measuredAt,
            selectedTotal: selectedTotal,
            itemTotal: itemTotal,
            scoreBar: version == null
                ? null
                : AssessmentScoreBar(
                    score: score,
                    rules: version.gradeRules,
                  ),
          ),
          const SizedBox(height: 10),
          if (version != null)
            SectionCard(
              title: '评分选项',
              action: _StatCapsule(text: '$selectedTotal/$itemTotal'),
              child: Column(
                children: [
                  for (var i = 0; i < version.items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReadonlyItemCard(
                        index: i + 1,
                        item: version.items[i],
                        selectedOptionId: current.selections[version.items[i].id],
                      ),
                    ),
                ],
              ),
            )
          else
            const SectionCard(
              title: '评分选项',
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '模板版本不可用，无法展示选项明细。',
                  style: TextStyle(color: Color(0xFF7388A4)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: const Padding(
        padding: EdgeInsets.only(left: 12),
        child: AppBackButton(),
      ),
      title: const Text(
        '测评详情',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.diseaseName,
    required this.versionName,
    required this.level,
    required this.score,
    required this.measuredAt,
    required this.selectedTotal,
    required this.itemTotal,
    required this.scoreBar,
  });

  final String diseaseName;
  final String versionName;
  final String level;
  final double score;
  final String measuredAt;
  final int selectedTotal;
  final int itemTotal;
  final Widget? scoreBar;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFEEF5FF), Color(0xFFF8FBFF)],
        ),
        border: Border.all(color: const Color(0xFFD8E5F6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diseaseName,
                        style: const TextStyle(
                          color: Color(0xFF1F3651),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        versionName,
                        style: const TextStyle(
                          color: Color(0xFF5D7694),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4EFFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCADEF7)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      children: [
                        const Text(
                          '得分',
                          style: TextStyle(color: Color(0xFF6982A1), fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          score.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF1F4F89),
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatCapsule(text: '等级 $level'),
                _StatCapsule(text: '已选 $selectedTotal/$itemTotal'),
                _StatCapsule(text: measuredAt),
              ],
            ),
            if (scoreBar != null) ...[
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD9E5F5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: scoreBar!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReadonlyItemCard extends StatelessWidget {
  const _ReadonlyItemCard({
    required this.index,
    required this.item,
    required this.selectedOptionId,
  });

  final int index;
  final TemplateItem item;
  final String? selectedOptionId;

  @override
  Widget build(BuildContext context) {
    TemplateOption? selected;
    for (final option in item.options) {
      if (option.id == selectedOptionId) {
        selected = option;
        break;
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7F5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6EFFD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Color(0xFF2A5F99),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF22364F),
                    ),
                  ),
                ),
                if (selected != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4EFFC),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFCDE0F8)),
                    ),
                    child: Text(
                      '${selected.score}分',
                      style: const TextStyle(
                        color: Color(0xFF1F4F89),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              selected == null ? '未选择' : '已选：${selected.label}',
              style: TextStyle(
                color: selected == null ? const Color(0xFF8C9CB0) : const Color(0xFF2A5E98),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final option in item.options)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: option.id == selectedOptionId
                          ? const Color(0xFFE7F1FE)
                          : const Color(0xFFF1F5FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: option.id == selectedOptionId
                            ? const Color(0xFF77A9E8)
                            : const Color(0xFFD5E0EF),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      child: Text(
                        '${option.label} (${option.score})',
                        style: TextStyle(
                          color: option.id == selectedOptionId
                              ? const Color(0xFF2A5E98)
                              : const Color(0xFF617992),
                          fontWeight:
                              option.id == selectedOptionId ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCapsule extends StatelessWidget {
  const _StatCapsule({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD7E4F5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF5D7593),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
