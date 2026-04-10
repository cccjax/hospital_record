import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/dynamic_form_dialog.dart';
import '../widgets/field_grid.dart';
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
          return ResponsiveBody(
            layout: layout,
            child: ListView(
              padding: layout.listPadding(bottom: 100),
              children: [
                SectionCard(
                  title: '病种模板中心',
                  action: FilledButton(
                    onPressed: () => _openDiseaseDialog(context),
                    child: const Text('新增病种'),
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
                  layout.useTwoPane
                      ? _BundleGrid(
                          bundles: bundles,
                          state: state,
                          onOpen: (bundle) =>
                              _openDetailPage(context, bundle.key),
                          onEdit: (bundle) =>
                              _openDiseaseDialog(context, editing: bundle),
                          onDelete: (bundle) => _deleteDisease(context, bundle),
                        )
                      : Column(
                          children: [
                            for (final bundle in bundles)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _BundleCard(
                                  state: state,
                                  bundle: bundle,
                                  onOpen: () =>
                                      _openDetailPage(context, bundle.key),
                                  onEdit: () => _openDiseaseDialog(context,
                                      editing: bundle),
                                  onDelete: () =>
                                      _deleteDisease(context, bundle),
                                ),
                              ),
                          ],
                        ),
              ],
            ),
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
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TemplateDiseaseBundle> bundles;
  final HospitalAppState state;
  final ValueChanged<TemplateDiseaseBundle> onOpen;
  final ValueChanged<TemplateDiseaseBundle> onEdit;
  final ValueChanged<TemplateDiseaseBundle> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = (width - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final bundle in bundles)
              SizedBox(
                width: cardWidth,
                child: _BundleCard(
                  state: state,
                  bundle: bundle,
                  onOpen: () => onOpen(bundle),
                  onEdit: () => onEdit(bundle),
                  onDelete: () => onDelete(bundle),
                ),
              ),
          ],
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

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F3149),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          bundle.diseaseCode.trim().isEmpty
                              ? '病种编码：未设置'
                              : '病种编码：${bundle.diseaseCode}',
                          style: const TextStyle(
                            color: Color(0xFF5A6F8A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TinyAction(
                    title: '编辑',
                    color: const Color(0xFF2B88D8),
                    onTap: onEdit,
                  ),
                  _TinyAction(
                    title: '删除',
                    color: const Color(0xFFD34E66),
                    onTap: onDelete,
                  ),
                  const SizedBox(
                    width: 20,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFF7E95B3),
                    ),
                  ),
                ],
              ),
              if (diseaseSchema.isNotEmpty) ...[
                const SizedBox(height: 10),
                FieldGrid(
                  schema: diseaseSchema,
                  values: values,
                  compact: true,
                  columns: 2,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  const _TinyAction({
    required this.title,
    required this.color,
    required this.onTap,
  });

  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
