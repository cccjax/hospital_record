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

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          SectionCard(
            title: '测评明细',
            child: Column(
              children: [
                _InfoRow(label: '病种模板', value: disease?.diseaseName ?? '-'),
                _InfoRow(label: '模板版本', value: version?.versionName ?? '-'),
                _InfoRow(
                  label: '测评时间',
                  value: DateFormat('yyyy-MM-dd HH:mm').format(current.createdAt),
                ),
                _InfoRow(label: '评分等级', value: level),
                if (version != null)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD8E4F3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: AssessmentScoreBar(
                        score: score,
                        rules: version.gradeRules,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (version != null)
            SectionCard(
              title: '评分选项',
              child: Column(
                children: [
                  for (final item in version.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReadonlyItemCard(
                        title: item.name,
                        options: item.options
                            .map((option) => '${option.label} (${option.score})')
                            .toList(),
                        selectedValue: () {
                          for (final option in item.options) {
                            if (option.id == current.selections[item.id]) {
                              return '${option.label} (${option.score})';
                            }
                          }
                          return '-';
                        }(),
                      ),
                    ),
                ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6C809A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF22364F),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadonlyItemCard extends StatelessWidget {
  const _ReadonlyItemCard({
    required this.title,
    required this.options,
    required this.selectedValue,
  });

  final String title;
  final List<String> options;
  final String selectedValue;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7F5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF22364F),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: option == selectedValue
                          ? const Color(0xFFE6F0FD)
                          : const Color(0xFFF1F5FA),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: option == selectedValue
                            ? const Color(0xFF76A8E7)
                            : const Color(0xFFD5E0EF),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text(
                        option,
                        style: TextStyle(
                          color: option == selectedValue
                              ? const Color(0xFF2A5E98)
                              : const Color(0xFF617992),
                          fontWeight: option == selectedValue ? FontWeight.w700 : FontWeight.w500,
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
