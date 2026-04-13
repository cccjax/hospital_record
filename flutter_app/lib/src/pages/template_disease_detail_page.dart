import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/dialog_utils.dart';
import '../widgets/dynamic_form_dialog.dart';
import '../widgets/field_grid.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/section_card.dart';
import 'template_version_page.dart';

class TemplateDiseaseDetailPage extends StatefulWidget {
  const TemplateDiseaseDetailPage({
    super.key,
    required this.bundleKey,
  });

  final String bundleKey;

  @override
  State<TemplateDiseaseDetailPage> createState() =>
      _TemplateDiseaseDetailPageState();
}

class _TemplateDiseaseDetailPageState extends State<TemplateDiseaseDetailPage> {
  TemplateCatalogType _catalog = TemplateCatalogType.assessment;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final bundle = state.findTemplateDiseaseBundleByKey(widget.bundleKey);
    if (bundle == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leadingWidth: 56,
          leading: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: AppBackButton(),
          ),
          title: const Text(
            '病种模板',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: const Center(
          child: Text('病种不存在或已被删除'),
        ),
      );
    }

    final disease = _catalog == TemplateCatalogType.assessment
        ? bundle.assessment
        : bundle.diagnosis;
    final versions = disease?.versions ?? const <TemplateVersion>[];
    final versionListSchema = state
        .listSchemaOf('templateVersion')
        .where((field) => field.key != 'versionName')
        .toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 56,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: AppBackButton(),
        ),
        title: Text(
          bundle.diseaseName.isEmpty ? '病种模板' : bundle.diseaseName,
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
                _CatalogSwitch(
                  selected: _catalog,
                  onChanged: (next) {
                    if (next == _catalog) return;
                    setState(() {
                      _catalog = next;
                    });
                  },
                ),
                const SizedBox(height: 10),
                _VersionSection(
                  state: state,
                  catalog: _catalog,
                  versions: versions,
                  versionListSchema: versionListSchema,
                  onAddVersion: () =>
                      _addVersionForBundle(context, bundle, _catalog),
                  onOpenVersion: (version) {
                    if (disease == null) return;
                    _openVersionPage(
                      context,
                      catalog: _catalog,
                      diseaseId: disease.id,
                      versionId: version.id,
                    );
                  },
                  onEditVersion: (version) {
                    if (disease == null) return;
                    _openVersionDialog(
                      context,
                      catalog: _catalog,
                      diseaseId: disease.id,
                      editing: version,
                    );
                  },
                  onDeleteVersion: (version) {
                    if (disease == null) return;
                    _deleteVersion(
                      context,
                      catalog: _catalog,
                      diseaseId: disease.id,
                      versionId: version.id,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openVersionPage(
    BuildContext context, {
    required TemplateCatalogType catalog,
    required String diseaseId,
    required String versionId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TemplateVersionPage(
          diseaseId: diseaseId,
          versionId: versionId,
          catalog: catalog,
        ),
      ),
    );
  }

  Future<void> _openVersionDialog(
    BuildContext context, {
    required TemplateCatalogType catalog,
    required String diseaseId,
    TemplateVersion? editing,
  }) async {
    final state = context.read<HospitalAppState>();
    final isDiagnosis = catalog == TemplateCatalogType.diagnosis;
    final moduleSchema = state
        .schemaOf('templateVersion')
        .where((field) => !field.computed && field.key != 'versionName')
        .toList();
    final dialogSchema = <FieldSchema>[
      const FieldSchema(
        key: 'versionName',
        label: '版本名称',
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
      initialValues['versionName'] = editing.versionName;
      for (final field in moduleSchema) {
        initialValues[field.key] =
            state.templateVersionFieldValue(editing, field.key) ?? '';
      }
    }

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return DynamicFormDialog(
          title: editing == null
              ? (isDiagnosis ? '新增诊断版本' : '新增评估版本')
              : (isDiagnosis ? '编辑诊断版本' : '编辑评估版本'),
          schema: dialogSchema,
          initialValues: initialValues,
          onSubmit: (values) async {
            final ok = state.upsertTemplateVersion(
              catalog: catalog,
              diseaseId: diseaseId,
              editingId: editing?.id,
              values: values,
            );
            return ok ? null : (state.takeLastErrorMessage() ?? '保存失败');
          },
        );
      },
    );
  }

  Future<void> _addVersionForBundle(
    BuildContext context,
    TemplateDiseaseBundle bundle,
    TemplateCatalogType catalog,
  ) async {
    final diseaseId = await _ensureDiseaseForCatalog(context, bundle, catalog);
    if (!context.mounted || diseaseId == null) return;
    await _openVersionDialog(
      context,
      catalog: catalog,
      diseaseId: diseaseId,
    );
  }

  Future<String?> _ensureDiseaseForCatalog(
    BuildContext context,
    TemplateDiseaseBundle bundle,
    TemplateCatalogType catalog,
  ) async {
    final current = catalog == TemplateCatalogType.assessment
        ? bundle.assessment
        : bundle.diagnosis;
    if (current != null) {
      return current.id;
    }

    final state = context.read<HospitalAppState>();
    final ok = state.upsertTemplateDiseaseLinked(
      assessmentEditingId: bundle.assessment?.id,
      diagnosisEditingId: bundle.diagnosis?.id,
      values: <String, dynamic>{
        'diseaseName': bundle.diseaseName,
        'diseaseCode': bundle.diseaseCode,
        'description': bundle.description,
      },
    );

    if (!ok) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.takeLastErrorMessage() ?? '创建病种失败')),
      );
      return null;
    }

    final source = state.templatesOf(catalog);
    for (final row in source) {
      if (_sameDisease(bundle, row)) {
        return row.id;
      }
    }
    return null;
  }

  bool _sameDisease(TemplateDiseaseBundle bundle, TemplateDisease disease) {
    final leftCode = bundle.diseaseCode.trim().toLowerCase();
    final rightCode = disease.diseaseCode.trim().toLowerCase();
    if (leftCode.isNotEmpty && rightCode.isNotEmpty) {
      return leftCode == rightCode;
    }
    final leftName = bundle.diseaseName.trim().toLowerCase();
    final rightName = disease.diseaseName.trim().toLowerCase();
    return leftName == rightName;
  }

  Future<void> _deleteVersion(
    BuildContext context, {
    required TemplateCatalogType catalog,
    required String diseaseId,
    required String versionId,
  }) async {
    final isDiagnosis = catalog == TemplateCatalogType.diagnosis;
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: isDiagnosis ? '删除诊断版本' : '删除评估版本',
      content: isDiagnosis ? '确认删除该诊断版本吗？' : '确认删除该评估版本吗？',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    context.read<HospitalAppState>().deleteTemplateVersion(
          diseaseId,
          versionId,
          catalog: catalog,
        );
  }
}

class _CatalogSwitch extends StatelessWidget {
  const _CatalogSwitch({
    required this.selected,
    required this.onChanged,
  });

  final TemplateCatalogType selected;
  final ValueChanged<TemplateCatalogType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF5)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _SwitchButton(
              active: selected == TemplateCatalogType.assessment,
              title: '病情评估版本',
              onTap: () => onChanged(TemplateCatalogType.assessment),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SwitchButton(
              active: selected == TemplateCatalogType.diagnosis,
              title: '诊断模板版本',
              onTap: () => onChanged(TemplateCatalogType.diagnosis),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  const _SwitchButton({
    required this.active,
    required this.title,
    required this.onTap,
  });

  final bool active;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFFFFFFF) : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Text(
            title,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? const Color(0xFF1E324B) : const Color(0xFF59708B),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionSection extends StatelessWidget {
  const _VersionSection({
    required this.state,
    required this.catalog,
    required this.versions,
    required this.versionListSchema,
    required this.onAddVersion,
    required this.onOpenVersion,
    required this.onEditVersion,
    required this.onDeleteVersion,
  });

  final HospitalAppState state;
  final TemplateCatalogType catalog;
  final List<TemplateVersion> versions;
  final List<FieldSchema> versionListSchema;
  final VoidCallback onAddVersion;
  final ValueChanged<TemplateVersion> onOpenVersion;
  final ValueChanged<TemplateVersion> onEditVersion;
  final ValueChanged<TemplateVersion> onDeleteVersion;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: catalog == TemplateCatalogType.assessment ? '病情评估版本' : '诊断模板版本',
      action: Tooltip(
        message:
            catalog == TemplateCatalogType.assessment ? '新增评估版本' : '新增诊断版本',
        child: FilledButton(
          onPressed: onAddVersion,
          child: const Icon(Icons.add_rounded),
        ),
      ),
      child: Column(
        children: [
          if (versions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                catalog == TemplateCatalogType.assessment
                    ? '暂无病情评估版本，请先新增'
                    : '暂无诊断模板版本，请先新增',
                style: const TextStyle(color: Color(0xFF7588A1)),
              ),
            ),
          for (final version in versions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VersionCard(
                state: state,
                version: version,
                schema: versionListSchema,
                onOpen: () => onOpenVersion(version),
                onEdit: () => onEditVersion(version),
                onDelete: () => onDeleteVersion(version),
              ),
            ),
        ],
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.state,
    required this.version,
    required this.schema,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final HospitalAppState state;
  final TemplateVersion version;
  final List<FieldSchema> schema;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final values = <String, dynamic>{
      for (final field in schema)
        field.key: state.templateVersionFieldValue(version, field.key),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE8F6)),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      version.versionName.isEmpty
                          ? '未命名版本'
                          : version.versionName,
                      style: const TextStyle(
                        color: Color(0xFF1F3149),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _TinyAction(
                    title: '编辑版本',
                    icon: Icons.edit_rounded,
                    color: const Color(0xFF2C88D8),
                    onTap: onEdit,
                  ),
                  _TinyAction(
                    title: '删除版本',
                    icon: Icons.delete_outline_rounded,
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
              if (schema.isNotEmpty) ...[
                const SizedBox(height: 8),
                FieldGrid(
                  schema: schema,
                  values: values,
                  compact: true,
                  columns: 3,
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
