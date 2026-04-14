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
        final scoreMarks =
            _buildScoreMarks(sorted, boundaries, width, maxScore);
        final boundaryLabelWidth = compact ? 34.0 : 40.0;

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
                        border: Border.all(
                          color: const Color(0xFFAFC1D6),
                          width: 1.1,
                        ),
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
                      left: offset - 1,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: const Color(0xFF4E657F).withValues(alpha: 0.65),
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
            SizedBox(height: compact ? 5 : 7),
            SizedBox(
              height: compact ? 16 : 18,
              child: Stack(
                children: [
                  for (final mark in scoreMarks)
                    Positioned(
                      left: (width * mark.factor - (boundaryLabelWidth / 2))
                          .clamp(
                            0.0,
                            math.max(0.0, width - boundaryLabelWidth),
                          )
                          .toDouble(),
                      child: SizedBox(
                        width: boundaryLabelWidth,
                        child: Text(
                          mark.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF5F7591),
                            fontSize: compact ? 10 : 10.5,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: compact ? 4 : 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < sorted.length; i++)
                  Expanded(
                    flex: segmentFlexes[i],
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        compact
                            ? '${sorted[i].level}\n${_formatNumber(sorted[i].min)}-${_formatNumber(sorted[i].max)}'
                            : '${sorted[i].level} ${_formatNumber(sorted[i].min)}-${_formatNumber(sorted[i].max)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 10.5 : 12.5,
                          height: compact ? 1.15 : 1.15,
                          fontWeight: FontWeight.w700,
                          color: i == markerRuleIndex
                              ? _segmentColor(i).withValues(alpha: 0.96)
                              : _segmentColor(i).withValues(alpha: 0.86),
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

  List<_ScoreMark> _buildScoreMarks(
    List<TemplateGradeRule> sorted,
    List<double> boundaries,
    double width,
    double maxScore,
  ) {
    final marks = <_ScoreMark>[
      _ScoreMark(factor: 0.0, text: _formatNumber(sorted.first.min))
    ];
    for (var i = 0; i < boundaries.length; i++) {
      final factor =
          width <= 0 ? 0.0 : (boundaries[i] / width).clamp(0.0, 1.0).toDouble();
      marks.add(
        _ScoreMark(
          factor: factor,
          text: _formatNumber(sorted[i].max),
        ),
      );
    }
    marks.add(_ScoreMark(factor: 1.0, text: _formatNumber(maxScore)));

    final deduped = <_ScoreMark>[];
    for (final mark in marks) {
      if (deduped.isNotEmpty &&
          (mark.factor - deduped.last.factor).abs() < 0.001 &&
          mark.text == deduped.last.text) {
        continue;
      }
      deduped.add(mark);
    }
    return deduped;
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

class _ScoreMark {
  const _ScoreMark({
    required this.factor,
    required this.text,
  });

  final double factor;
  final String text;
}
