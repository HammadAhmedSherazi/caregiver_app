import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum ProfileBarStyle { accent, light, primary }

class ProfileDayHours extends Equatable {
  const ProfileDayHours({
    required this.dayLabel,
    required this.hours,
    required this.style,
    this.isToday = false,
  });

  final String dayLabel;
  final double hours;
  final ProfileBarStyle style;
  final bool isToday;

  Color get barColor => switch (style) {
        ProfileBarStyle.accent => AppColors.homeAccent,
        ProfileBarStyle.light => const Color(0xFFDCE5F9),
        ProfileBarStyle.primary => AppColors.homeHeader,
      };

  @override
  List<Object?> get props => [dayLabel, hours, style, isToday];
}

class ProfilePageData extends Equatable {
  const ProfilePageData({
    required this.headerTitle,
    required this.name,
    required this.title,
    required this.avatarUrl,
    required this.experienceYears,
    required this.visitCount,
    required this.hoursThisWeek,
    required this.targetHours,
    required this.weekChangePercent,
    required this.weeklyHours,
    required this.targetLineHours,
    required this.chartMaxHours,
  });

  final String headerTitle;
  final String name;
  final String title;
  final String avatarUrl;
  final int experienceYears;
  final int visitCount;
  final double hoursThisWeek;
  final double targetHours;
  final int weekChangePercent;
  final List<ProfileDayHours> weeklyHours;
  final double targetLineHours;
  final double chartMaxHours;

  @override
  List<Object?> get props => [
        headerTitle,
        name,
        title,
        avatarUrl,
        experienceYears,
        visitCount,
        hoursThisWeek,
        targetHours,
        weekChangePercent,
        weeklyHours,
        targetLineHours,
        chartMaxHours,
      ];
}
