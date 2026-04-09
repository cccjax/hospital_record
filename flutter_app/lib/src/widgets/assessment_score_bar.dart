import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/app_models.dart';

class AssessmentScoreBar extends StatelessWidget {
  const AssessmentScoreBar({
    super.key,
    required this.score,
    required this.rules,
    this.compact = false,
  });

  final double score;
  final List<TemplateGradeRule> rules;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (rules.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = List<TemplateGradeRule>.from(rules)
      ..sort((a, b) => a.min.compareTo(b.min));
    final minScore = sorted.first.min;
    final rawMax =
        sorted.fold<double>(minScore, (acc, rule) => math.max(acc, rule.max));
    final maxScore = rawMax <= minScore ? minScore + 1 : rawMax;
    final safeScore = score.clamp(minScore, maxScore).toDouble();
    final markerFactor = (safeScore - minScore) / (maxScore - minScore);
    final markerRuleIndex = _resolveRuleIndex(sorted, safeScore);
    final markerColor =
        _segmentColor(markerRuleIndex < 0 ? 0 : markerRuleIndex);
    final segmentFlexes = <int>[for (final rule in sorted) _segmentFlex(rule)];
    final scoreText = _formatNumber(score);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final markerLeft = (width * markerFactor).clamp(0.0, width).toDouble();
        final markerSize = compact ? 10.0 : 12.0;
        final scoreBubbleWidth = compact ? 40.0 : 48.0;
        final scoreBubbleLeft = (markerLeft - (scoreBubbleWidth / 2))
            .clamp(0.0, math.max(0.0, width - scoreBubbleWidth))
            .toDouble();
        final boundaries = _buildBoundaries(segmentFlexes, width);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: compact ? 20 : 26,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: scoreBubbleLeft,
                    top: compact ? 1 : 0,
                    child: Container(
                      width: scoreBubbleWidth,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 6 : 8,
                        vertical: compact ? 1.5 : 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFD1DEEF)),
                      ),
                      child: Text(
                        scoreText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 11.5 : 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF304D6D),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: compact ? 14 : 18,
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
                                flex: segmentFlexes[i],
                                child: ColoredBox(color: _segmentColor(i)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  for (final offset in boundaries)
                    Positioned(
                      left: offset - 0.5,
                      top: 1,
                      bottom: 1,
                      child: Container(
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.94),
                      ),
                    ),
                  Positioned(
                    left: markerLeft - (markerSize / 2),
                    top: compact ? 2 : 3,
                    child: Container(
                      width: markerSize,
                      height: markerSize,
                      decoration: BoxDecoration(
                        color: markerColor,
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
            SizedBox(height: compact ? 6 : 8),
            if (compact)
              _CompactSummary(
                rule: markerRuleIndex >= 0 ? sorted[markerRuleIndex] : null,
                color: markerColor,
              )
            else
              Row(
                children: [
                  for (var i = 0; i < sorted.length; i++)
                    Expanded(
                      flex: segmentFlexes[i],
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          '${sorted[i].level} ${_formatNumber(sorted[i].min)}-${_formatNumber(sorted[i].max)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.15,
                            fontWeight: FontWeight.w700,
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
    final length = (rule.max - rule.min).abs();
    if (length == 0) return 1;
    return math.max(1, (length * 100).round());
  }

  int _resolveRuleIndex(List<TemplateGradeRule> sorted, double value) {
    for (var i = 0; i < sorted.length; i++) {
      final rule = sorted[i];
      if (value >= rule.min && value <= rule.max) {
        return i;
      }
    }
    if (value < sorted.first.min) return 0;
    return sorted.length - 1;
  }

  List<double> _buildBoundaries(List<int> flexes, double width) {
    final offsets = <double>[];
    final totalFlex = flexes.fold<int>(0, (sum, value) => sum + value);
    if (totalFlex <= 0) return offsets;
    var current = 0;
    for (var i = 0; i < flexes.length - 1; i++) {
      current += flexes[i];
      offsets.add(width * (current / totalFlex));
    }
    return offsets;
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  Color _segmentColor(int index) {
    const palette = <Color>[
      Color(0xFF34A074),
      Color(0xFF2F7FD8),
      Color(0xFFF29F23),
      Color(0xFFE45C63),
      Color(0xFF8D67C8),
    ];
    return palette[index % palette.length];
  }
}

class _CompactSummary extends StatelessWidget {
  const _CompactSummary({
    required this.rule,
    required this.color,
  });

  final TemplateGradeRule? rule;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (rule == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${rule!.level}  ${_formatNumber(rule!.min)}-${_formatNumber(rule!.max)} 分',
            style: const TextStyle(
              color: Color(0xFF4D647F),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value == value.toInt()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
