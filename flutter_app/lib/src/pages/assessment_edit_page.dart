import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/assessment_score_bar.dart';
import '../widgets/section_card.dart';

class AssessmentEditPage extends StatefulWidget {
  const AssessmentEditPage({
    super.key,
    required this.admissionId,
    this.editingAssessmentId,
  });

  final String admissionId;
  final String? editingAssessmentId;

  @override
  State<AssessmentEditPage> createState() => _AssessmentEditPageState();
}

class _AssessmentEditPageState extends State<AssessmentEditPage> {
  String _diseaseId = '';
  String _versionId = '';
  Map<String, String> _selections = <String, String>{};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _initDraft();
  }

  void _initDraft() {
    final state = context.read<HospitalAppState>();
    final diseases = state.data.templates;

    if (widget.editingAssessmentId != null) {
      final editing = state
          .assessmentsOf(widget.admissionId)
          .where((e) => e.id == widget.editingAssessmentId)
          .toList();
      if (editing.isNotEmpty) {
        _diseaseId = editing.first.diseaseId;
        _versionId = editing.first.versionId;
        _selections = Map<String, String>.from(editing.first.selections);
      }
    }

    if (_diseaseId.isEmpty && diseases.isNotEmpty) {
      _diseaseId = diseases.first.id;
    }

    final version = _currentVersion(state);
    if (version == null && diseases.isNotEmpty) {
      final firstDisease = diseases.firstWhere(
        (d) => d.id == _diseaseId,
        orElse: () => diseases.first,
      );
      if (firstDisease.versions.isNotEmpty) {
        _versionId = firstDisease.versions.first.id;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final disease = state.findDisease(_diseaseId);
    final version = _currentVersion(state);
    final score = version == null
        ? 0.0
        : state.calculateAssessmentScore(version, _selections);
    final selectedCount = version == null
        ? 0
        : version.items
            .where((item) => (_selections[item.id] ?? '').isNotEmpty)
            .length;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: AppBackButton(),
        ),
        title: Text(
          widget.editingAssessmentId == null ? '新增测评' : '编辑测评',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _AssessmentHeaderCard(
            selectedCount: selectedCount,
            totalCount: version?.items.length ?? 0,
            score: score,
            hasVersion: version != null,
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: '模板选择',
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _diseaseId.isEmpty ? null : _diseaseId,
                  decoration: const InputDecoration(labelText: '病种模板'),
                  items: state.data.templates
                      .map(
                        (disease) => DropdownMenuItem<String>(
                          value: disease.id,
                          child: Text(disease.diseaseName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    final nextDisease = state.findDisease(value);
                    setState(() {
                      _diseaseId = value;
                      _selections = <String, String>{};
                      _versionId = nextDisease?.versions.isNotEmpty == true
                          ? nextDisease!.versions.first.id
                          : '';
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _versionId.isEmpty ? null : _versionId,
                  decoration: const InputDecoration(labelText: '模板版本'),
                  items: (disease?.versions ?? const <TemplateVersion>[])
                      .map(
                        (version) => DropdownMenuItem<String>(
                          value: version.id,
                          child: Text(version.versionName),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _versionId = value;
                      _selections = <String, String>{};
                    });
                  },
                ),
                const SizedBox(height: 10),
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
              title: '评分选项（均为必填）',
              child: Column(
                children: [
                  for (final item in version.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ItemOptionsCard(
                        item: item,
                        selectedOptionId: _selections[item.id],
                        onChanged: (optionId) {
                          setState(() {
                            _selections[item.id] = optionId;
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: version == null ? null : () => _save(context, version),
              icon: const Icon(Icons.check_rounded),
              label: const Text('保存测评'),
            ),
          ),
        ],
      ),
    );
  }

  TemplateVersion? _currentVersion(HospitalAppState state) {
    if (_diseaseId.isEmpty || _versionId.isEmpty) return null;
    return state.findVersion(_diseaseId, _versionId);
  }

  Future<void> _save(BuildContext context, TemplateVersion version) async {
    for (final item in version.items) {
      if ((_selections[item.id] ?? '').isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请完成「${item.name}」的评分选项')),
        );
        return;
      }
    }

    final state = context.read<HospitalAppState>();
    final record = AssessmentRecord(
      id: widget.editingAssessmentId ?? state.createRuntimeId('asmt'),
      diseaseId: _diseaseId,
      versionId: _versionId,
      selections: Map<String, String>.from(_selections),
      createdAt: DateTime.now(),
    );
    state.upsertAssessment(
      admissionId: widget.admissionId,
      record: record,
      editingId: widget.editingAssessmentId,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

class _AssessmentHeaderCard extends StatelessWidget {
  const _AssessmentHeaderCard({
    required this.selectedCount,
    required this.totalCount,
    required this.score,
    required this.hasVersion,
  });

  final int selectedCount;
  final int totalCount;
  final double score;
  final bool hasVersion;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF0F8FF)],
        ),
        border: Border.all(color: const Color(0xFFE4EDF9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F2744),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '住院测评录入',
              style: TextStyle(
                color: Color(0xFF1F3149),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '选择模板后勾选评分选项，系统会自动计算分值与区间',
              style: TextStyle(
                color: Color(0xFF627892),
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _HeaderMetric(
                    label: '完成项',
                    value: hasVersion ? '$selectedCount/$totalCount' : '--',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeaderMetric(
                    label: '当前得分',
                    value: hasVersion ? _formatScore(score) : '--',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatScore(double value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE7F6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF60758F),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1D3149),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemOptionsCard extends StatelessWidget {
  const _ItemOptionsCard({
    required this.item,
    required this.selectedOptionId,
    required this.onChanged,
  });

  final TemplateItem item;
  final String? selectedOptionId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    TemplateOption? selectedOption;
    for (final option in item.options) {
      if (option.id == selectedOptionId) {
        selectedOption = option;
        break;
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFDCE8F6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F3149),
                    ),
                  ),
                ),
                if (selectedOption != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5FF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFC9DEF8)),
                    ),
                    child: Text(
                      '${selectedOption.label} · ${_formatScore(selectedOption.score)}分',
                      style: const TextStyle(
                        color: Color(0xFF2B5E96),
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                for (var i = 0; i < item.options.length; i++) ...[
                  _OptionRow(
                    option: item.options[i],
                    selected: selectedOptionId == item.options[i].id,
                    onTap: () => onChanged(item.options[i].id),
                  ),
                  if (i != item.options.length - 1) const SizedBox(height: 6),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatScore(double score) {
    if (score == score.toInt()) return score.toInt().toString();
    return score.toStringAsFixed(1);
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final TemplateOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 46),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F3FF) : const Color(0xFFF6FAFF),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? const Color(0xFF79A7E2) : const Color(0xFFD9E5F4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 15,
              color:
                  selected ? const Color(0xFF2A5E98) : const Color(0xFF8A9CB2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                option.label,
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF2A5E98)
                      : const Color(0xFF617992),
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFDDEEFF)
                    : const Color(0xFFEAF1FA),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFA8CBF0)
                      : const Color(0xFFD2DEEE),
                ),
              ),
              child: Text(
                '${_formatScore(option.score)}分',
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF2A5E98)
                      : const Color(0xFF617992),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatScore(double score) {
    if (score == score.toInt()) return score.toInt().toString();
    return score.toStringAsFixed(1);
  }
}
