import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_models.dart';

class AssessmentScoreBar extends StatelessWidget {
  const AssessmentScoreBar({
    super.key,
    required this.score,
    required this.rules,
  });

  final double score;
  final List<TemplateGradeRule> rules;

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = List<TemplateGradeRule>.from(rules)
      ..sort((a, b) => a.min.compareTo(b.min));
    final maxScore = sorted.last.max <= 0 ? 100.0 : sorted.last.max;
    final safeScore = score.clamp(sorted.first.min, maxScore);
    final markerFactor = (safeScore - sorted.first.min) / (maxScore - sorted.first.min);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final markerLeft = math.max(0, math.min(width, width * markerFactor));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: math.max(0, markerLeft - 20),
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFD1DEEF)),
                      ),
                      child: Text(
                        score.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF304D6D),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 18,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: const Color(0xFFEAF0F8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Row(
                          children: [
                            for (var i = 0; i < sorted.length; i++)
                              Expanded(
                                flex: _segmentFlex(sorted[i]),
                                child: ColoredBox(color: _segmentColor(i)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: markerLeft - 6,
                    top: 3,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F7FD8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 8,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < sorted.length; i++)
                  Expanded(
                    flex: _segmentFlex(sorted[i]),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        '${sorted[i].level} ${sorted[i].min.toInt()}-${sorted[i].max.toInt()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.15,
                          fontWeight: FontWeight.w600,
                          color: _segmentColor(i).withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  int _segmentFlex(TemplateGradeRule rule) {
    final length = (rule.max - rule.min).abs().round();
    return math.max(1, length);
  }

  Color _segmentColor(int index) {
    const palette = <Color>[
      Color(0xFF86AFE4),
      Color(0xFF9AD8D1),
      Color(0xFFE3CD9C),
      Color(0xFFD9A7B1),
      Color(0xFFC5B1E1),
    ];
    return palette[index % palette.length];
  }
}
