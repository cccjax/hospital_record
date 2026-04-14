import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_add_button.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/dynamic_form_dialog.dart';
import '../widgets/paged_card_grid.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/section_card.dart';
import 'template_disease_detail_page.dart';

class TemplateTabPage extends StatefulWidget {
  const TemplateTabPage({super.key});

  @override
  State<TemplateTabPage> createState() => _TemplateTabPageState();
}

class _TemplateTabPageState extends State<TemplateTabPage> {
  late final TextEditingController _searchController;
  PagedCardPageState _bundleCardPageState = const PagedCardPageState(
    pageCount: 0,
    currentPage: 0,
  );

  @override
  void initState() {
    super.initState();
    final state = context.read<HospitalAppState>();
    _searchController = TextEditingController(text: state.templateSearchQuery);
    _searchController.addListener(() {
      state.setTemplateSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBundlePageStateChanged(PagedCardPageState next) {
    if (_bundleCardPageState.pageCount == next.pageCount &&
        _bundleCardPageState.currentPage == next.currentPage) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _bundleCardPageState = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final bundles = state.filteredTemplateDiseaseBundles;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '模板',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = ResponsiveLayout.fromWidth(constraints.maxWidth);
          return Stack(
            children: [
              ResponsiveBody(
                layout: layout,
                child: ListView(
                  padding: layout.listPadding(bottom: 24),
                  children: [
                    SectionCard(
                      title: '病种模板中心',
                      action: AppAddIconButton(
                        tooltip: '新增病种',
                        onPressed: () => _openDiseaseDialog(context),
                        size: 40,
                        iconSize: 20,
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: '搜索病种名称或编码',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (bundles.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          '暂无病种模板，请先新增病种',
                          style: TextStyle(color: Color(0xFF7588A1)),
                        ),
                      ),
                    if (bundles.isNotEmpty)
                      _BundleGrid(
                        bundles: bundles,
                        state: state,
                        viewportHeight: constraints.maxHeight,
                        onPageStateChanged: _onBundlePageStateChanged,
                        onOpen: (bundle) =>
                            _openDetailPage(context, bundle.key),
                        onEdit: (bundle) =>
                            _openDiseaseDialog(context, editing: bundle),
                        onDelete: (bundle) => _deleteDisease(context, bundle),
                      ),
                  ],
                ),
              ),
              if (_bundleCardPageState.pageCount > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: IgnorePointer(
                    child: ResponsiveBody(
                      layout: layout,
                      child: PagedCardPageIndicator(
                        pageCount: _bundleCardPageState.pageCount,
                        currentPage: _bundleCardPageState.currentPage,
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

  Future<void> _openDetailPage(BuildContext context, String bundleKey) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateDiseaseDetailPage(bundleKey: bundleKey),
      ),
    );
  }

  Future<void> _openDiseaseDialog(
    BuildContext context, {
    TemplateDiseaseBundle? editing,
  }) async {
    final state = context.read<HospitalAppState>();
    final moduleSchema = state
        .schemaOf('templateDisease')
        .where((field) => !field.computed && field.key != 'diseaseName')
        .toList();
    final dialogSchema = <FieldSchema>[
      const FieldSchema(
        key: 'diseaseName',
        label: '病种名称',
        type: FieldType.text,
        required: true,
        locked: false,
        showInList: true,
        computed: false,
        options: <String>[],
      ),
      ...moduleSchema,
    ];

    final initialValues = <String, dynamic>{
      for (final field in dialogSchema)
        field.key: field.type == FieldType.select && field.options.isNotEmpty
            ? field.options.first
            : '',
    };

    if (editing != null) {
      initialValues['diseaseName'] = editing.diseaseName;
      final primary = editing.primary;
      for (final field in moduleSchema) {
        initialValues[field.key] = primary == null
            ? ''
            : state.templateDiseaseFieldValue(primary, field.key) ?? '';
      }
    }

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return DynamicFormDialog(
          title: editing == null ? '新增病种' : '编辑病种',
          schema: dialogSchema,
          initialValues: initialValues,
          onSubmit: (values) async {
            final ok = state.upsertTemplateDiseaseLinked(
              assessmentEditingId: editing?.assessment?.id,
              diagnosisEditingId: editing?.diagnosis?.id,
              values: values,
            );
            return ok ? null : (state.takeLastErrorMessage() ?? '保存失败');
          },
        );
      },
    );
  }

  Future<void> _deleteDisease(
    BuildContext context,
    TemplateDiseaseBundle bundle,
  ) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: '删除病种',
      content: '确认删除该病种及其病情评估模板、诊断模板全部版本与配置吗？',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context.read<HospitalAppState>().deleteTemplateDiseaseLinked(
          assessmentId: bundle.assessment?.id,
          diagnosisId: bundle.diagnosis?.id,
          diseaseName: bundle.diseaseName,
          diseaseCode: bundle.diseaseCode,
        );
  }
}

class _BundleGrid extends StatelessWidget {
  const _BundleGrid({
    required this.bundles,
    required this.state,
    required this.viewportHeight,
    required this.onPageStateChanged,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TemplateDiseaseBundle> bundles;
  final HospitalAppState state;
  final double viewportHeight;
  final ValueChanged<PagedCardPageState> onPageStateChanged;
  final ValueChanged<TemplateDiseaseBundle> onOpen;
  final ValueChanged<TemplateDiseaseBundle> onEdit;
  final ValueChanged<TemplateDiseaseBundle> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width = constraints.maxWidth;
        final visibleFieldCount = state
            .listSchemaOf('templateDisease')
            .where((field) => field.key != 'diseaseName')
            .length;
        final minCardWidth = width >= 900
            ? 260.0
            : width >= 640
                ? 220.0
                : 180.0;
        final maxColumns = width >= 1200
            ? 4
            : width >= 900
                ? 3
                : 2;
        final crossAxisCount =
            ((width + gap) / (minCardWidth + gap)).floor().clamp(1, maxColumns);
        final cardWidth = (width - gap * (crossAxisCount - 1)) / crossAxisCount;
        final baseAspectRatio = cardWidth >= 300
            ? 1.95
            : cardWidth >= 240
                ? 1.75
                : cardWidth >= 200
                    ? 1.58
                    : 1.38;
        final extraRowPenalty =
            (visibleFieldCount - 3).clamp(0, 8).toDouble() * 0.16;
        final cardAspectRatio =
            (baseAspectRatio - extraRowPenalty).clamp(1.16, 2.0);
        final estimatedMinHeight = 92.0 + visibleFieldCount * 27.0;
        final measuredHeight = cardWidth / cardAspectRatio;
        final cardHeight = measuredHeight < estimatedMinHeight
            ? estimatedMinHeight
            : measuredHeight;
        const estimatedHeaderHeight = 132.0;
        final availableGridHeight =
            (viewportHeight - estimatedHeaderHeight).clamp(220.0, 1500.0);
        final rowsPerPage =
            ((availableGridHeight + gap) / (cardHeight + gap)).floor().clamp(
                  width >= 1000 ? 2 : 1,
                  width >= 1000 ? 5 : 4,
                );
        return PagedCardGrid(
          itemCount: bundles.length,
          crossAxisCount: crossAxisCount,
          rowsPerPage: rowsPerPage,
          spacing: gap,
          runSpacing: gap,
          itemHeight: cardHeight,
          showInlineIndicator: false,
          onPageStateChanged: onPageStateChanged,
          itemBuilder: (context, index) {
            final bundle = bundles[index];
            return _BundleCard(
              state: state,
              bundle: bundle,
              onOpen: () => onOpen(bundle),
              onEdit: () => onEdit(bundle),
              onDelete: () => onDelete(bundle),
            );
          },
        );
      },
    );
  }
}

class _BundleCard extends StatelessWidget {
  const _BundleCard({
    required this.state,
    required this.bundle,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final HospitalAppState state;
  final TemplateDiseaseBundle bundle;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final primary = bundle.primary;
    final diseaseSchema = state.listSchemaOf('templateDisease');
    final values = <String, dynamic>{
      for (final field in diseaseSchema)
        field.key: primary == null
            ? ''
            : state.templateDiseaseFieldValue(primary, field.key),
    };
    final infoRows = _buildInfoRows(diseaseSchema, values);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDCE7F5)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 24, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                              bundle.diseaseName.isEmpty
                                  ? '未命名病种'
                                  : bundle.diseaseName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F3149),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TinyAction(
                        title: '编辑病种',
                        icon: Icons.edit_rounded,
                        color: const Color(0xFF2B88D8),
                        onTap: onEdit,
                      ),
                      _TinyAction(
                        title: '删除病种',
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFD34E66),
                        onTap: onDelete,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE4EBF6),
                  ),
                  const SizedBox(height: 6),
                  for (var i = 0; i < infoRows.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == infoRows.length - 1 ? 0 : 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 68,
                            child: Text(
                              infoRows[i].label,
                              style: const TextStyle(
                                color: Color(0xFF6D829E),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.28,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              infoRows[i].value,
                              style: const TextStyle(
                                color: Color(0xFF20364F),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.28,
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

  List<_BundleInfoRow> _buildInfoRows(
    List<FieldSchema> diseaseSchema,
    Map<String, dynamic> values,
  ) {
    final rows = <_BundleInfoRow>[];
    for (final field in diseaseSchema) {
      if (field.key == 'diseaseName') continue;
      final text = (values[field.key] ?? '-').toString().trim();
      rows.add(
        _BundleInfoRow(
          label: field.label,
          value: text.isEmpty ? '-' : text,
        ),
      );
    }
    if (rows.isEmpty) {
      return const <_BundleInfoRow>[
        _BundleInfoRow(label: '字段', value: '暂无可视字段'),
      ];
    }
    return rows;
  }
}

class _BundleInfoRow {
  const _BundleInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class _TinyAction extends StatelessWidget {
  const _TinyAction({
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
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        visualDensity: VisualDensity.compact,
        color: color,
      ),
    );
  }
}
