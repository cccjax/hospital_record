import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/hospital_app_state.dart';
import '../widgets/app_back_button.dart';
import '../widgets/field_grid.dart';
import '../widgets/section_card.dart';

class DailyDetailPage extends StatelessWidget {
  const DailyDetailPage({
    super.key,
    required this.dailyId,
  });

  final String dailyId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<HospitalAppState>();
    final daily = state.findDaily(dailyId);
    if (daily == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: Text('日常记录不存在')),
      );
    }
    final admission = state.findAdmission(daily.admissionId);
    final patient =
        admission == null ? null : state.findPatient(admission.admissionNo);
    final schema = state.schemaOf('daily');
    final patientName = (patient?.values['name'] ?? '-').toString().trim();
    final admissionNo = admission?.admissionNo ?? '-';
    final admitDate = (admission?.values['admitDate'] ?? '-').toString().trim();

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _HeroSummary(
            patientName: patientName.isEmpty ? '-' : patientName,
            admissionNo: admissionNo,
            admitDate: admitDate.isEmpty ? '-' : admitDate,
          ),
          const SizedBox(height: 10),
          SectionCard(
            title: '日常记录详情',
            child: FieldGrid(
              schema: schema,
              values: daily.values,
              variant: FieldGridVariant.table,
              compact: true,
              showColumnDivider: false,
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
        '日常详情',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.patientName,
    required this.admissionNo,
    required this.admitDate,
  });

  final String patientName;
  final String admissionNo;
  final String admitDate;

  @override
  Widget build(BuildContext context) {
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_rounded,
              size: 18,
              color: Color(0xFF3F6E9F),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F3149),
                    ),
                  ),
                  _HeroChip(
                    icon: Icons.badge_outlined,
                    text: '住院号 $admissionNo',
                  ),
                  _HeroChip(
                    icon: Icons.calendar_month_outlined,
                    text: '住院日期 $admitDate',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD9E5F4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF5A7091)),
            const SizedBox(width: 5),
            Text(
              text,
              style: const TextStyle(
                color: Color(0xFF4E627D),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
