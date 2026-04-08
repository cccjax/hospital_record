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
    final patient = admission == null ? null : state.findPatient(admission.admissionNo);
    final schema = state.schemaOf('daily');

    return Scaffold(
      appBar: _buildAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          if (patient != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                '${patient.values['name'] ?? '-'}  (${patient.admissionNo})',
                style: const TextStyle(
                  color: Color(0xFF24405E),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          SectionCard(
            title: '日常记录详情',
            child: FieldGrid(
              schema: schema,
              values: daily.values,
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
