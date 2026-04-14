import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_add_button.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_dropdown_form_field.dart';
import '../widgets/assessment_score_bar.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/section_card.dart';

class AssessmentEditPage extends StatefulWidget {
  const AssessmentEditPage({
    super.key,
    required this.admissionId,
    this.editingAssessmentId,
    this.initialCatalog,
  });

  final String admissionId;
  final String? editingAssessmentId;
  final TemplateCatalogType? initialCatalog;

  @override
  State<AssessmentEditPage> createState() => _AssessmentEditPageState();
}

class _AssessmentEditPageState extends State<AssessmentEditPage> {
  TemplateCatalogType _catalog = TemplateCatalogType.assessment;
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

    if (widget.editingAssessmentId != null) {
      final editing = state
          .assessmentsOf(widget.admissionId)
          .where((e) => e.id == widget.editingAssessmentId)
          .toList();
      if (editing.isNotEmpty) {
        _catalog = editing.first.catalog;
        _diseaseId = editing.first.diseaseId;
        _versionId = editing.first.versionId;
        _selections = Map<String, String>.from(editing.first.selections);
      }
    } else if (widget.initialCatalog != null) {
      _catalog = widget.initialCatalog!;
    }

    final diseases = state.templatesOf(_catalog);
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
    final templates = state.templatesOf(_catalog);
    final disease = state.findDisease(_diseaseId, catalog: _catalog);
    final version = _currentVersion(state);
    final score = version == null
        ? 0.0
        : state.calculateAssessmentScore(version, _selections);
    final templateSection = _TemplatePickerCard(
      diseaseId: _diseaseId,
      versionId: _versionId,
      catalog: _catalog,
      disease: disease,
      templates: templates,
      score: score,
      version: version,
      catalogLocked: widget.editingAssessmentId != null,
      onCatalogChanged: (value) {
        if (value == _catalog) return;
        final nextTemplates = state.templatesOf(value);
        final nextDiseaseId =
            nextTemplates.isNotEmpty ? nextTemplates.first.id : '';
        final nextVersionId =
            nextTemplates.isNotEmpty && nextTemplates.first.versions.isNotEmpty
                ? nextTemplates.first.versions.first.id
                : '';
        setState(() {
          _catalog = value;
          _diseaseId = nextDiseaseId;
          _versionId = nextVersionId;
          _selections = <String, String>{};
        });
      },
      onDiseaseChanged: (value) {
        if (value == null) return;
        final nextDisease = state.findDisease(value, catalog: _catalog);
        setState(() {
          _diseaseId = value;
          _selections = <String, String>{};
          _versionId = nextDisease?.versions.isNotEmpty == true
              ? nextDisease!.versions.first.id
              : '';
        });
      },
      onVersionChanged: (value) {
        if (value == null) return;
        setState(() {
          _versionId = value;
          _selections = <String, String>{};
        });
      },
    );

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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = ResponsiveLayout.fromWidth(constraints.maxWidth);
          return ResponsiveBody(
            layout: layout,
            child: ListView(
              padding: layout.listPadding(),
              children: [
                templateSection,
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
                  child: AppSaveButton(
                    onPressed:
                        version == null ? null : () => _save(context, version),
                    label: '保存测评',
                    expand: true,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  TemplateVersion? _currentVersion(HospitalAppState state) {
    if (_diseaseId.isEmpty || _versionId.isEmpty) return null;
    return state.findVersion(_diseaseId, _versionId, catalog: _catalog);
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
      catalog: _catalog,
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

class _TemplatePickerCard extends StatelessWidget {
  const _TemplatePickerCard({
    required this.catalog,
    required this.catalogLocked,
    required this.diseaseId,
    required this.versionId,
    required this.disease,
    required this.templates,
    required this.score,
    required this.version,
    required this.onCatalogChanged,
    required this.onDiseaseChanged,
    required this.onVersionChanged,
  });

  final TemplateCatalogType catalog;
  final bool catalogLocked;
  final String diseaseId;
  final String versionId;
  final TemplateDisease? disease;
  final List<TemplateDisease> templates;
  final double score;
  final TemplateVersion? version;
  final ValueChanged<TemplateCatalogType> onCatalogChanged;
  final ValueChanged<String?> onDiseaseChanged;
  final ValueChanged<String?> onVersionChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: '模板选择',
      child: Column(
        children: [
          if (!catalogLocked) ...[
            SizedBox(
              height: 42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD3E0F1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _CatalogTabButton(
                          label: '病情测评',
                          icon: Icons.monitor_heart_outlined,
                          selected: catalog == TemplateCatalogType.assessment,
                          onTap: () =>
                              onCatalogChanged(TemplateCatalogType.assessment),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: _CatalogTabButton(
                          label: '诊断测评',
                          icon: Icons.fact_check_outlined,
                          selected: catalog == TemplateCatalogType.diagnosis,
                          onTap: () =>
                              onCatalogChanged(TemplateCatalogType.diagnosis),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          AppDropdownFormField<String>(
            selectedValue: diseaseId.isEmpty ? null : diseaseId,
            hintText: '病种模板（可搜索）',
            searchable: true,
            searchHintText: '输入病种名称或编码',
            emptySearchText: '未找到匹配病种',
            isEnabled: templates.isNotEmpty,
            items: templates
                .map(
                  (diseaseItem) => AppDropdownOption<String>(
                    value: diseaseItem.id,
                    label: diseaseItem.diseaseName,
                    subtitle: diseaseItem.diseaseCode.trim().isEmpty
                        ? null
                        : '编码 ${diseaseItem.diseaseCode}',
                    searchKeywords: <String>[
                      diseaseItem.diseaseName,
                      diseaseItem.diseaseCode,
                    ],
                  ),
                )
                .toList(),
            onChanged: onDiseaseChanged,
          ),
          const SizedBox(height: 10),
          AppDropdownFormField<String>(
            selectedValue: versionId.isEmpty ? null : versionId,
            hintText: '模板版本',
            isEnabled:
                (disease?.versions ?? const <TemplateVersion>[]).isNotEmpty,
            items: (disease?.versions ?? const <TemplateVersion>[])
                .map(
                  (versionItem) => AppDropdownOption<String>(
                    value: versionItem.id,
                    label: versionItem.versionName,
                  ),
                )
                .toList(),
            onChanged: onVersionChanged,
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
                  rules: version!.gradeRules,
                ),
              ),
            ),
        ],
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

class _CatalogTabButton extends StatelessWidget {
  const _CatalogTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground =
        selected ? const Color(0xFF2E5F92) : const Color(0xFF5F738D);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: selected ? const Color(0xFFDDEEFF) : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
