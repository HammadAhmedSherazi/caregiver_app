import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/profile_page_model.dart';
import '../../home/widgets/home_svg_icon.dart';

class ProfileHoursChart extends StatelessWidget {
  const ProfileHoursChart({
    super.key,
    required this.weeklyHours,
    required this.targetLineHours,
    required this.maxHours,
  });

  final List<ProfileDayHours> weeklyHours;
  final double targetLineHours;
  final double maxHours;

  static const _designWidth = 430.0;
  static const _designPlotHeight = 193.0;
  static const _designBarWidth = 32.0;
  static const _designBarRadius = 20.0;
  static const _designXAxisHeight = 28.0;
  static const _yAxisWidth = 40.0;

  @override
  Widget build(BuildContext context) {
    final metrics = _ChartMetrics.of(context);
    final yLabels = List.generate(7, (index) => maxHours - (index * 5));

    return SizedBox(
      height: metrics.totalHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartWidth = constraints.maxWidth;
                final barSpacing =
                    (chartWidth - (weeklyHours.length * metrics.barWidth)) /
                        (weeklyHours.length + 1);

                double hoursToHeight(double hours) {
                  if (maxHours <= 0) return 0;
                  return (hours / maxHours) * metrics.plotHeight;
                }

                return Column(
                  children: [
                    SizedBox(
                      height: metrics.plotHeight,
                      width: chartWidth,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            size: Size(chartWidth, metrics.plotHeight),
                            painter: _ProfileChartGridPainter(
                              maxHours: maxHours,
                              chartHeight: metrics.plotHeight,
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: hoursToHeight(targetLineHours),
                            child: Row(
                              children: [
                                Expanded(
                                  child: CustomPaint(
                                    size: const Size(double.infinity, 1),
                                    painter: _DashedLinePainter(
                                      color: AppColors.homePrimary,
                                    ),
                                  ),
                                ),
                                HomeSvgIcon(
                                  asset: AppAssets.icProfileTrophy,
                                  width: metrics.trophySize,
                                  height: metrics.trophySize,
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: metrics.plotHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (var i = 0; i < weeklyHours.length; i++) ...[
                                  SizedBox(width: barSpacing),
                                  _ProfileBar(
                                    hours: weeklyHours[i].hours,
                                    style: weeklyHours[i].style,
                                    width: metrics.barWidth,
                                    height: hoursToHeight(weeklyHours[i].hours),
                                    radius: metrics.barRadius,
                                  ),
                                ],
                                SizedBox(width: barSpacing),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: metrics.xAxisHeight,
                      child: Row(
                        children: [
                          for (var i = 0; i < weeklyHours.length; i++) ...[
                            SizedBox(width: barSpacing),
                            SizedBox(
                              width: metrics.barWidth,
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: Text(
                                  weeklyHours[i].dayLabel,
                                  style: weeklyHours[i].isToday
                                      ? context.responsiveStyle(
                                          AppTextStyles.profileChartToday,
                                        )
                                      : context.responsiveStyle(
                                          AppTextStyles.profileChartAxis,
                                        ),
                                ),
                              ),
                            ),
                          ],
                          SizedBox(width: barSpacing),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(
            width: _yAxisWidth,
            height: metrics.plotHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final label in yLabels)
                  Text(
                    label.toInt().toString(),
                    style: context.responsiveStyle(
                      AppTextStyles.profileChartAxis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartMetrics {
  const _ChartMetrics({
    required this.plotHeight,
    required this.barWidth,
    required this.barRadius,
    required this.xAxisHeight,
    required this.trophySize,
  });

  final double plotHeight;
  final double barWidth;
  final double barRadius;
  final double xAxisHeight;
  final double trophySize;

  double get totalHeight => plotHeight + xAxisHeight;

  static _ChartMetrics of(BuildContext context) {
    final width = context.screenWidth;
    final scale = (width / ProfileHoursChart._designWidth).clamp(0.72, 1.0);

    return _ChartMetrics(
      plotHeight: ProfileHoursChart._designPlotHeight * scale,
      barWidth: ProfileHoursChart._designBarWidth * scale,
      barRadius: ProfileHoursChart._designBarRadius * scale,
      xAxisHeight: ProfileHoursChart._designXAxisHeight * scale,
      trophySize: 16 * scale,
    );
  }
}

class _ProfileBar extends StatelessWidget {
  const _ProfileBar({
    required this.hours,
    required this.style,
    required this.width,
    required this.height,
    required this.radius,
  });

  final double hours;
  final ProfileBarStyle style;
  final double width;
  final double height;
  final double radius;

  Color get barColor => switch (style) {
        ProfileBarStyle.accent => AppColors.homeAccent,
        ProfileBarStyle.light => const Color(0xFFDCE5F9),
        ProfileBarStyle.primary => AppColors.homeHeader,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: math.max(height, 8),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ProfileChartGridPainter extends CustomPainter {
  _ProfileChartGridPainter({
    required this.maxHours,
    required this.chartHeight,
  });

  final double maxHours;
  final double chartHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFDADADA)
      ..strokeWidth = 1;

    for (var value = 0.0; value <= maxHours; value += 5) {
      final y = chartHeight - ((value / maxHours) * chartHeight);
      _drawDashedLine(
        canvas,
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final distance = (end - start).distance;
    final direction = (end - start) / distance;
    var drawn = 0.0;

    while (drawn < distance) {
      final currentStart = start + direction * drawn;
      final currentEnd =
          start + direction * math.min(drawn + dashWidth, distance);
      canvas.drawLine(currentStart, currentEnd, paint);
      drawn += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _ProfileChartGridPainter oldDelegate) {
    return oldDelegate.maxHours != maxHours ||
        oldDelegate.chartHeight != chartHeight;
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    var startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(math.min(startX + dashWidth, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
