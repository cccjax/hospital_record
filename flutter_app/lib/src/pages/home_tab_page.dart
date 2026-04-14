import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_add_button.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/dynamic_form_dialog.dart';
import '../widgets/paged_card_grid.dart';
import '../widgets/responsive_layout.dart';
import 'patient_detail_page.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

enum _HomeCardDensity {
  standard,
  compact,
}

class _CardDensitySpec {
  const _CardDensitySpec({
    required this.baseExtentPhone,
    required this.baseExtentTablet,
    required this.extentPerField,
    required this.cardVerticalPadding,
    required this.dividerTopGap,
    required this.contentTopGap,
    required this.rowSpacing,
    required this.rowLineHeight,
    required this.labelWidth,
    required this.nameFontSize,
    required this.chipVerticalPadding,
  });

  final double baseExtentPhone;
  final double baseExtentTablet;
  final double extentPerField;
  final double cardVerticalPadding;
  final double dividerTopGap;
  final double contentTopGap;
  final double rowSpacing;
  final double rowLineHeight;
  final double labelWidth;
  final double nameFontSize;
  final double chipVerticalPadding;

  static const standard = _CardDensitySpec(
    baseExtentPhone: 136,
    baseExtentTablet: 150,
    extentPerField: 6.5,
    cardVerticalPadding: 12,
    dividerTopGap: 8,
    contentTopGap: 7,
    rowSpacing: 5.5,
    rowLineHeight: 1.28,
    labelWidth: 64,
    nameFontSize: 16,
    chipVerticalPadding: 5,
  );

  static const compact = _CardDensitySpec(
    baseExtentPhone: 152,
    baseExtentTablet: 166,
    extentPerField: 8.0,
    cardVerticalPadding: 10,
    dividerTopGap: 6,
    contentTopGap: 4,
    rowSpacing: 2.0,
    rowLineHeight: 1.16,
    labelWidth: 56,
    nameFontSize: 15,
    chipVerticalPadding: 4,
  );

  static _CardDensitySpec of(_HomeCardDensity density) {
    switch (density) {
      case _HomeCardDensity.compact:
        return compact;
      case _HomeCardDensity.standard:
        return standard;
    }
  }
}

class _HomeTabPageState extends State<HomeTabPage> {
  late final TextEditingController _searchController;
  _HomeCardDensity _cardDensity = _HomeCardDensity.standard;
  bool _bulkDeleteMode = false;
  final Set<String> _selectedPatientNos = <String>{};
  PagedCardPageState _patientCardPageState = const PagedCardPageState(
    pageCount: 0,
    currentPage: 0,
  );

  @override
  void initState() {
    super.initState();
    final state = context.read<HospitalAppState>();
    _searchController = TextEditingController(text: state.patientSearchQuery);
    _searchController.addListener(() {
      state.setPatientSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setCardDensity(_HomeCardDensity density) {
    if (_cardDensity == density) return;
    setState(() => _cardDensity = density);
  }

  void _onPatientPageStateChanged(PagedCardPageState next) {
    if (_patientCardPageState.pageCount == next.pageCount &&
        _patientCardPageState.currentPage == next.currentPage) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _patientCardPageState = next;
    });
  }

  void _toggleBulkDeleteMode() {
    setState(() {
      if (_bulkDeleteMode) {
        _bulkDeleteMode = false;
        _selectedPatientNos.clear();
      } else {
        _bulkDeleteMode = true;
      }
    });
  }

  void _togglePatientSelection(String admissionNo) {
    if (!_bulkDeleteMode) return;
    setState(() {
      if (_selectedPatientNos.contains(admissionNo)) {
        _selectedPatientNos.remove(admissionNo);
      } else {
        _selectedPatientNos.add(admissionNo);
      }
    });
  }

  Future<void> _confirmBulkDelete(
    BuildContext context,
    List<PatientRecord> visiblePatients,
  ) async {
    final visibleSet = visiblePatients.map((e) => e.admissionNo).toSet();
    final targetNos = _selectedPatientNos
        .where((admissionNo) => visibleSet.contains(admissionNo))
        .toList();
    if (targetNos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择要删除的病人')),
      );
      return;
    }

    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '批量删除病人',
      content: '将删除已选择的 ${targetNos.length} 位病人及关联数据，是否继续？',
    );
    if (!confirmed || !context.mounted) return;
    final state = context.read<HospitalAppState>();
    for (final admissionNo in targetNos) {
      state.deletePatient(admissionNo);
    }

    if (!mounted) return;
    setState(() {
      _bulkDeleteMode = false;
      _selectedPatientNos.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final density = _CardDensitySpec.of(_cardDensity);
    final listSchema = state
        .listSchemaOf('patient')
        .where((field) => field.key != 'name')
        .toList();
    final visibleFieldCount = listSchema
        .where((field) => field.key != 'nursingLevel')
        .length
        .clamp(3, 10);
    final patients = state.filteredPatients;
    final visiblePatientNoSet = patients.map((e) => e.admissionNo).toSet();
    final selectedVisibleCount = _selectedPatientNos
        .where((admissionNo) => visiblePatientNoSet.contains(admissionNo))
        .length;
    final nursingLevels = state.patientNursingLevels;
    final nursingLevelFilter = state.patientNursingLevelFilter;
    final nursingLevelCounts = state.patientNursingLevelCounts;
    final nursingLevelColors = state.patientNursingLevelColors;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '首页',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = ResponsiveLayout.fromWidth(constraints.maxWidth);
          final isCompactToolbar = constraints.maxWidth < 560;
          Widget buildDensitySwitch() {
            Widget buildOption({
              required _HomeCardDensity value,
              required IconData icon,
              required String label,
            }) {
              final selected = _cardDensity == value;
              final foreground =
                  selected ? const Color(0xFF2E5F92) : const Color(0xFF5F738D);
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => _setCardDensity(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: selected
                            ? const Color(0xFFDDEEFF)
                            : Colors.transparent,
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
                              fontSize: 13,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return SizedBox(
              height: 44,
              width: 178,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD3E0F1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    buildOption(
                      value: _HomeCardDensity.standard,
                      icon: Icons.view_agenda_outlined,
                      label: '标准',
                    ),
                    const SizedBox(width: 3),
                    buildOption(
                      value: _HomeCardDensity.compact,
                      icon: Icons.density_small,
                      label: '紧凑',
                    ),
                  ],
                ),
              ),
            );
          }

          Widget buildSearchField() {
            return SizedBox(
              height: 44,
              child: TextField(
                controller: _searchController,
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  hintText: '输入住院号/姓名搜索',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            );
          }

          Widget buildAddButton() {
            return AppAddIconButton(
              tooltip: '新增病人',
              onPressed:
                  _bulkDeleteMode ? null : () => _openPatientDialog(context),
              size: 44,
              iconSize: 22,
              borderRadius: 12,
            );
          }

          Widget buildDeleteButton() {
            return _HomeDeleteButton(
              mode: _bulkDeleteMode,
              selectionCount: selectedVisibleCount,
              onPressed: patients.isEmpty
                  ? null
                  : () {
                      if (_bulkDeleteMode) {
                        _confirmBulkDelete(context, patients);
                      } else {
                        _toggleBulkDeleteMode();
                      }
                    },
            );
          }

          Widget buildCancelDeleteButton() {
            return AppToneIconButton(
              icon: Icons.close_rounded,
              tooltip: '退出删除模式',
              onPressed: _bulkDeleteMode ? _toggleBulkDeleteMode : null,
              size: 44,
              iconSize: 21,
              borderRadius: 12,
            );
          }

          return Stack(
            children: [
              ResponsiveBody(
                layout: layout,
                child: ListView(
                  padding: layout.listPadding(bottom: 24),
                  children: [
                    _HeroCard(
                      patientCount: state.patientCount,
                      inHospitalCount: state.inHospitalCount,
                      filterActive: state.patientInHospitalOnly,
                      onToggleFilter: state.toggleInHospitalFilter,
                      nursingLevels: nursingLevels,
                      activeNursingLevel: nursingLevelFilter,
                      nursingLevelCounts: nursingLevelCounts,
                      nursingLevelColors: nursingLevelColors,
                      onSelectNursingLevel: state.setPatientNursingLevelFilter,
                    ),
                    const SizedBox(height: 12),
                    if (isCompactToolbar) ...[
                      Row(
                        children: [
                          buildDensitySwitch(),
                          const Spacer(),
                          if (_bulkDeleteMode) ...[
                            buildCancelDeleteButton(),
                            const SizedBox(width: 8),
                          ],
                          buildAddButton(),
                          const SizedBox(width: 8),
                          buildDeleteButton(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      buildSearchField(),
                    ] else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          buildDensitySwitch(),
                          const SizedBox(width: 8),
                          Expanded(child: buildSearchField()),
                          const SizedBox(width: 8),
                          if (_bulkDeleteMode) ...[
                            buildCancelDeleteButton(),
                            const SizedBox(width: 8),
                          ],
                          buildAddButton(),
                          const SizedBox(width: 8),
                          buildDeleteButton(),
                        ],
                      ),
                    if (_bulkDeleteMode) ...[
                      const SizedBox(height: 8),
                      Text(
                        selectedVisibleCount == 0
                            ? '已进入删除模式，请点击卡片进行多选'
                            : '已选择 $selectedVisibleCount 位病人，点击删除按钮确认',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5E7088),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (patients.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Center(
                          child: Text(
                            '暂无病人记录',
                            style: TextStyle(color: Color(0xFF7488A4)),
                          ),
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, box) {
                          const gap = 10.0;
                          final baseExtent = (layout.isTablet
                                  ? density.baseExtentTablet
                                  : density.baseExtentPhone) +
                              visibleFieldCount * density.extentPerField;
                          final maxColumns = layout.isTablet ? 5 : 3;
                          final columnUpperBound =
                              patients.length.clamp(1, maxColumns);
                          var crossAxisCount =
                              ((box.maxWidth + gap) / (baseExtent + gap))
                                  .floor()
                                  .clamp(1, columnUpperBound);
                          final minCardWidth = layout.isTablet ? 220.0 : 176.0;
                          while (crossAxisCount > 1) {
                            final cardWidth =
                                (box.maxWidth - (crossAxisCount - 1) * gap) /
                                    crossAxisCount;
                            if (cardWidth >= minCardWidth) break;
                            crossAxisCount--;
                          }
                          final infoRowCount = listSchema
                              .where((field) => field.key != 'nursingLevel')
                              .length
                              .clamp(1, 18);
                          final estimatedCardHeight =
                              _estimatePatientCardHeight(
                            density: density,
                            infoRowCount: infoRowCount,
                          );
                          final estimatedHeaderHeight =
                              _estimateHomeHeaderHeight(
                            viewportWidth: constraints.maxWidth,
                            compactToolbar: isCompactToolbar,
                            nursingLevelCount: nursingLevels.length,
                          );
                          final availableGridHeight =
                              (constraints.maxHeight - estimatedHeaderHeight)
                                  .clamp(220.0, 1600.0);
                          final rowsPerPage = ((availableGridHeight + gap) /
                                  (estimatedCardHeight + gap))
                              .floor()
                              .clamp(layout.isTablet ? 2 : 1,
                                  layout.isTablet ? 6 : 5);

                          return PagedCardGrid(
                            itemCount: patients.length,
                            crossAxisCount: crossAxisCount,
                            rowsPerPage: rowsPerPage,
                            spacing: gap,
                            runSpacing: gap,
                            itemHeight: estimatedCardHeight,
                            showInlineIndicator: false,
                            onPageStateChanged: _onPatientPageStateChanged,
                            itemBuilder: (context, index) {
                              final patient = patients[index];
                              return _PatientCard(
                                patient: patient,
                                listSchema: listSchema,
                                density: density,
                                nursingLevelColors: nursingLevelColors,
                                selectionMode: _bulkDeleteMode,
                                selected: _selectedPatientNos
                                    .contains(patient.admissionNo),
                                onToggleSelection: () =>
                                    _togglePatientSelection(
                                        patient.admissionNo),
                                onOpen: () => _openPatientDetail(
                                    context, patient.admissionNo),
                                onEdit: () => _openPatientDialog(context,
                                    editing: patient),
                              );
                            },
                          );
                        },
                      )
                  ],
                ),
              ),
              if (_patientCardPageState.pageCount > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: IgnorePointer(
                    child: ResponsiveBody(
                      layout: layout,
                      child: PagedCardPageIndicator(
                        pageCount: _patientCardPageState.pageCount,
                        currentPage: _patientCardPageState.currentPage,
                        backgroundColor: const Color(0xA6FFFFFF),
                        borderColor: const Color(0xB7C6DBED),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openPatientDetail(
      BuildContext context, String admissionNo) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PatientDetailPage(admissionNo: admissionNo),
      ),
    );
  }

  Future<void> _openPatientDialog(
    BuildContext context, {
    PatientRecord? editing,
  }) async {
    final state = context.read<HospitalAppState>();
    final schema = state.schemaOf('patient');
    final initial = _buildInitialValues(
        schema, editing?.values ?? const <String, dynamic>{});

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return DynamicFormDialog(
          title: editing == null ? '新增病人' : '编辑病人',
          schema: schema,
          initialValues: initial,
          onSubmit: (values) async {
            final ok = state.upsertPatient(
              values: values,
              editingAdmissionNo: editing?.admissionNo,
            );
            return ok ? null : (state.takeLastErrorMessage() ?? '保存失败');
          },
        );
      },
    );
  }

  Map<String, dynamic> _buildInitialValues(
    List<FieldSchema> schema,
    Map<String, dynamic> seed,
  ) {
    final next = <String, dynamic>{};
    for (final field in schema) {
      final raw = seed[field.key];
      if (raw != null) {
        next[field.key] = raw;
      } else if (field.type == FieldType.select) {
        next[field.key] = field.options.isNotEmpty ? field.options.first : '';
      } else {
        next[field.key] = '';
      }
    }
    return next;
  }

  double _estimatePatientCardHeight({
    required _CardDensitySpec density,
    required int infoRowCount,
  }) {
    final safeRowCount = infoRowCount.clamp(1, 18).toDouble();
    final lineBlock = 13.5 * density.rowLineHeight;
    final contentHeight =
        safeRowCount * lineBlock + (safeRowCount - 1) * density.rowSpacing;
    final estimated = density.cardVerticalPadding * 2 +
        35 +
        density.dividerTopGap +
        1 +
        density.contentTopGap +
        contentHeight +
        11;
    final minHeight = density == _CardDensitySpec.compact ? 132.0 : 142.0;
    return estimated < minHeight ? minHeight : estimated;
  }

  double _estimateHomeHeaderHeight({
    required double viewportWidth,
    required bool compactToolbar,
    required int nursingLevelCount,
  }) {
    final chipsPerRow = viewportWidth >= 820
        ? 5
        : viewportWidth >= 620
            ? 4
            : 3;
    final nursingRows =
        ((nursingLevelCount + 1 + chipsPerRow - 1) / chipsPerRow)
            .floor()
            .clamp(1, 6);
    final heroHeight = 144.0 + (nursingRows - 1) * 34.0;
    final toolbarHeight = compactToolbar ? 96.0 : 44.0;
    return heroHeight + 12.0 + toolbarHeight + 12.0;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.patientCount,
    required this.inHospitalCount,
    required this.filterActive,
    required this.onToggleFilter,
    required this.nursingLevels,
    required this.activeNursingLevel,
    required this.nursingLevelCounts,
    required this.nursingLevelColors,
    required this.onSelectNursingLevel,
  });

  final int patientCount;
  final int inHospitalCount;
  final bool filterActive;
  final VoidCallback onToggleFilter;
  final List<String> nursingLevels;
  final String activeNursingLevel;
  final Map<String, int> nursingLevelCounts;
  final Map<String, String> nursingLevelColors;
  final ValueChanged<String> onSelectNursingLevel;

  @override
  Widget build(BuildContext context) {
    void setInHospitalFilter(bool active) {
      if (filterActive != active) {
        onToggleFilter();
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF8FBFF),
        border: Border.all(color: const Color(0xFFE7EEF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2744),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.flash_on_rounded,
                  size: 18,
                  color: Color(0xFF2F74B8),
                ),
                SizedBox(width: 6),
                Text(
                  '快捷筛选',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F3149),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _FilterSectionLabel(
              icon: Icons.apartment_rounded,
              text: '在院状态',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickFilterChoice(
                  text: '全部 $patientCount',
                  active: !filterActive,
                  icon: Icons.people_alt_outlined,
                  onTap: () => setInHospitalFilter(false),
                ),
                _QuickFilterChoice(
                  text: '仅在院 $inHospitalCount',
                  active: filterActive,
                  icon: Icons.local_hospital_rounded,
                  onTap: () => setInHospitalFilter(true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _FilterSectionLabel(
              icon: Icons.bookmark_border_rounded,
              text: '护理等级',
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _NursingFilterChip(
                  text: '全部 $patientCount',
                  active: activeNursingLevel.isEmpty,
                  color: null,
                  onTap: () => onSelectNursingLevel(''),
                ),
                for (final level in nursingLevels)
                  _NursingFilterChip(
                    text: '$level ${nursingLevelCounts[level] ?? 0}',
                    active: activeNursingLevel == level,
                    color: _parseHexColor(nursingLevelColors[level]),
                    onTap: () => onSelectNursingLevel(level),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NursingFilterChip extends StatelessWidget {
  const _NursingFilterChip({
    required this.text,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String text;
  final bool active;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final toneColor = color ?? const Color(0xFF8FA6C2);
    final background = active
        ? Color.alphaBlend(
            toneColor.withValues(alpha: 0.20), const Color(0xFFF5F9FF))
        : const Color(0xFFFFFFFF);
    final border =
        active ? toneColor.withValues(alpha: 0.55) : const Color(0xFFDCE7F5);
    final textColor =
        active ? const Color(0xFF243B57) : const Color(0xFF5A6A7E);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: toneColor.withValues(alpha: active ? 1 : 0.7),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSectionLabel extends StatelessWidget {
  const _FilterSectionLabel({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: const Color(0xFF6A819E),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF6A819E),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuickFilterChoice extends StatelessWidget {
  const _QuickFilterChoice({
    required this.text,
    required this.active,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        active ? const Color(0xFFE8F3FF) : const Color(0xFFFFFFFF);
    final border = active ? const Color(0xFF7FB1EA) : const Color(0xFFDCE7F5);
    final foreground =
        active ? const Color(0xFF2D5F95) : const Color(0xFF5A6A7E);
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  const _PatientCard({
    required this.patient,
    required this.listSchema,
    required this.density,
    required this.nursingLevelColors,
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelection,
    required this.onOpen,
    required this.onEdit,
  });

  final PatientRecord patient;
  final List<FieldSchema> listSchema;
  final _CardDensitySpec density;
  final Map<String, String> nursingLevelColors;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelection;
  final VoidCallback onOpen;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final nursingLevel =
        (patient.values['nursingLevel'] ?? '').toString().trim();
    final nursingColor = _parseHexColor(nursingLevelColors[nursingLevel]);
    final infoRows = _buildInfoRows();
    final name = (patient.values['name'] ?? '-').toString();
    final lineColor =
        selected ? const Color(0xFF78AEE6) : const Color(0xFFDCE7F5);
    final backgroundColor =
        selected ? const Color(0xFFF4FAFF) : const Color(0xFFFFFFFF);

    Widget buildNursingChip() {
      return Container(
        constraints: const BoxConstraints(maxWidth: 106),
        padding: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: density.chipVerticalPadding,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: nursingColor == null
              ? const Color(0xFFF5F9FF)
              : Color.alphaBlend(
                  nursingColor.withValues(alpha: 0.20),
                  const Color(0xFFF5F9FF),
                ),
          border: Border.all(
            color: nursingColor == null
                ? const Color(0xFFD9E5F4)
                : nursingColor.withValues(alpha: 0.58),
          ),
        ),
        child: Text(
          nursingLevel,
          style: TextStyle(
            color: nursingColor == null
                ? const Color(0xFF4E627D)
                : const Color(0xFF314560),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    Widget buildLeadingAction() {
      if (selectionMode) {
        return _SelectionToggle(
          selected: selected,
          onTap: onToggleSelection,
        );
      }
      return _ActionText(
        title: '编辑病人',
        icon: Icons.edit_rounded,
        color: const Color(0xFF2C89D8),
        onTap: onEdit,
      );
    }

    return Card(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: lineColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: selectionMode ? onToggleSelection : onOpen,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                density.cardVerticalPadding,
                24,
                density.cardVerticalPadding,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: density.nameFontSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F3149),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (nursingLevel.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        buildNursingChip(),
                      ],
                      const SizedBox(width: 4),
                      buildLeadingAction(),
                    ],
                  ),
                  SizedBox(height: density.dividerTopGap),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE4EBF6),
                  ),
                  SizedBox(height: density.contentTopGap),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < infoRows.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                              bottom: i == infoRows.length - 1
                                  ? 0
                                  : density.rowSpacing),
                          child: Row(
                            children: [
                              SizedBox(
                                width: density.labelWidth,
                                child: Text(
                                  infoRows[i].label,
                                  style: TextStyle(
                                    color: const Color(0xFF6D829E),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    height: density.rowLineHeight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  infoRows[i].value,
                                  style: TextStyle(
                                    color: const Color(0xFF20364F),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    height: density.rowLineHeight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Positioned(
              right: 2,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFF7E95B3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_InfoRow> _buildInfoRows() {
    final rows = <_InfoRow>[];
    for (final field in listSchema) {
      if (field.key == 'nursingLevel') continue;
      final raw = field.key == 'admissionNo'
          ? patient.admissionNo
          : patient.values[field.key];
      final text = (raw ?? '-').toString().trim();
      rows.add(
        _InfoRow(
          label: field.label,
          value: text.isEmpty ? '-' : text,
        ),
      );
    }
    if (rows.isEmpty) {
      return const <_InfoRow>[
        _InfoRow(label: '字段', value: '暂无可视字段'),
      ];
    }
    return rows;
  }
}

class _InfoRow {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

Color? _parseHexColor(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;
  var hex = value.replaceAll('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8) return null;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}

class _HomeDeleteButton extends StatelessWidget {
  const _HomeDeleteButton({
    required this.mode,
    required this.selectionCount,
    required this.onPressed,
  });

  final bool mode;
  final int selectionCount;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tooltip = mode
        ? (selectionCount > 0 ? '确认删除已选($selectionCount)' : '确认删除已选')
        : '进入删除模式';
    final bg = mode ? const Color(0xFFFDECEE) : const Color(0xFFFFF4F6);
    final bgPressed = mode ? const Color(0xFFFADCE0) : const Color(0xFFFCE3E7);
    const bgDisabled = Color(0xFFF6F0F1);
    final fg = mode ? const Color(0xFFB63A49) : const Color(0xFFC94A59);
    const fgDisabled = Color(0xFFA79FA3);
    final border = mode ? const Color(0xFFF0B7BF) : const Color(0xFFF0CDD3);
    final borderPressed =
        mode ? const Color(0xFFE79DA8) : const Color(0xFFEAB4BC);
    return AppToneIconButton(
      icon: mode ? Icons.delete_sweep_rounded : Icons.delete_outline_rounded,
      onPressed: onPressed,
      tooltip: tooltip,
      size: 44,
      iconSize: 21,
      borderRadius: 12,
      backgroundColor: bg,
      backgroundPressedColor: bgPressed,
      backgroundDisabledColor: bgDisabled,
      foregroundColor: fg,
      foregroundDisabledColor: fgDisabled,
      borderColor: border,
      borderPressedColor: borderPressed,
      shadowColor: const Color(0x22C36A79),
      overlayPressedColor: const Color(0x12B74757),
      overlayHoverColor: const Color(0x0DB74757),
    );
  }
}

class _SelectionToggle extends StatelessWidget {
  const _SelectionToggle({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selected ? '取消选择' : '选择病人',
      child: SizedBox(
        width: 28,
        height: 28,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(
            selected
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            size: 19,
          ),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          color: selected ? const Color(0xFF3A83CE) : const Color(0xFF8AA2C0),
        ),
      ),
    );
  }
}

class _ActionText extends StatelessWidget {
  const _ActionText({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: title,
      child: SizedBox(
        width: 28,
        height: 28,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 17),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          color: color,
        ),
      ),
    );
  }
}
