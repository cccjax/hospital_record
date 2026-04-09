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
    final score = version == null ? 0.0 : state.calculateAssessmentScore(version, _selections);

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
          SectionCard(
            title: '住院测评录入',
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
          FilledButton(
            onPressed: version == null ? null : () => _save(context, version),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('保存测评'),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFEFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE8F6)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F3149),
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final option in item.options)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onChanged(option.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: selectedOptionId == option.id
                            ? const Color(0xFFE7F1FE)
                            : const Color(0xFFF5F9FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedOptionId == option.id
                              ? const Color(0xFF77A9E8)
                              : const Color(0xFFD9E5F4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selectedOptionId == option.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 14,
                            color: selectedOptionId == option.id
                                ? const Color(0xFF2A5E98)
                                : const Color(0xFF8A9CB2),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            option.label,
                            style: TextStyle(
                              color: selectedOptionId == option.id
                                  ? const Color(0xFF2A5E98)
                                  : const Color(0xFF617992),
                              fontSize: 12,
                              fontWeight: selectedOptionId == option.id
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${option.score}分',
                            style: TextStyle(
                              color: selectedOptionId == option.id
                                  ? const Color(0xFF2A5E98)
                                  : const Color(0xFF617992),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
