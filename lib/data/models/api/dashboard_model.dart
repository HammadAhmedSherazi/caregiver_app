import '../base_model.dart';
import 'schedule_item_model.dart';
import 'visit_model.dart';

class DashboardCaregiverModel extends BaseModel {
  const DashboardCaregiverModel({
    required this.id,
    required this.name,
    this.firstName,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String? firstName;
  final String? avatarUrl;

  factory DashboardCaregiverModel.fromJson(Map<String, dynamic> json) {
    return DashboardCaregiverModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      firstName: json['first_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'first_name': firstName,
        'avatar_url': avatarUrl,
      };

  @override
  List<Object?> get props => [id, name, firstName, avatarUrl];
}

class DashboardTodayModel extends BaseModel {
  const DashboardTodayModel({
    required this.date,
    required this.weekday,
    required this.label,
  });

  final String date;
  final String weekday;
  final String label;

  factory DashboardTodayModel.fromJson(Map<String, dynamic> json) {
    return DashboardTodayModel(
      date: json['date'] as String? ?? '',
      weekday: json['weekday'] as String? ?? '',
      label: json['label'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'date': date,
        'weekday': weekday,
        'label': label,
      };

  @override
  List<Object?> get props => [date, weekday, label];
}

class DashboardNextShiftModel extends BaseModel {
  const DashboardNextShiftModel({
    required this.visit,
    required this.startsInMinutes,
  });

  final ScheduleItemModel visit;
  final int startsInMinutes;

  factory DashboardNextShiftModel.fromJson(Map<String, dynamic> json) {
    return DashboardNextShiftModel(
      visit: ScheduleItemModel.fromJson(
        json['visit'] as Map<String, dynamic>? ?? const {},
      ),
      startsInMinutes: json['starts_in_minutes'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'visit': visit.toJson(),
        'starts_in_minutes': startsInMinutes,
      };

  @override
  List<Object?> get props => [visit, startsInMinutes];
}

class DashboardTasksModel extends BaseModel {
  const DashboardTasksModel({
    required this.done,
    required this.total,
    required this.remainingHours,
  });

  final int done;
  final int total;
  final double remainingHours;

  factory DashboardTasksModel.fromJson(Map<String, dynamic> json) {
    return DashboardTasksModel(
      done: json['done'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      remainingHours: (json['remaining_hours'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'done': done,
        'total': total,
        'remaining_hours': remainingHours,
      };

  @override
  List<Object?> get props => [done, total, remainingHours];
}

class DashboardPayModel extends BaseModel {
  const DashboardPayModel({
    required this.ytdGross,
    required this.ytdHours,
    required this.paystubCount,
  });

  final double ytdGross;
  final double ytdHours;
  final int paystubCount;

  factory DashboardPayModel.fromJson(Map<String, dynamic> json) {
    return DashboardPayModel(
      ytdGross: (json['ytd_gross'] as num?)?.toDouble() ?? 0,
      ytdHours: (json['ytd_hours'] as num?)?.toDouble() ?? 0,
      paystubCount: json['paystub_count'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'ytd_gross': ytdGross,
        'ytd_hours': ytdHours,
        'paystub_count': paystubCount,
      };

  @override
  List<Object?> get props => [ytdGross, ytdHours, paystubCount];
}

class DashboardBadgesModel extends BaseModel {
  const DashboardBadgesModel({
    required this.unreadNotifications,
    required this.unreadConversations,
  });

  final int unreadNotifications;
  final int unreadConversations;

  factory DashboardBadgesModel.fromJson(Map<String, dynamic> json) {
    return DashboardBadgesModel(
      unreadNotifications: json['unread_notifications'] as int? ?? 0,
      unreadConversations: json['unread_conversations'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'unread_notifications': unreadNotifications,
        'unread_conversations': unreadConversations,
      };

  @override
  List<Object?> get props => [unreadNotifications, unreadConversations];
}

class DashboardModel extends BaseModel {
  const DashboardModel({
    required this.caregiver,
    required this.today,
    this.activeVisit,
    this.nextShift,
    required this.todaySchedule,
    required this.tasks,
    required this.hoursThisWeek,
    required this.pay,
    required this.badges,
  });

  final DashboardCaregiverModel caregiver;
  final DashboardTodayModel today;
  final VisitModel? activeVisit;
  final DashboardNextShiftModel? nextShift;
  final List<ScheduleItemModel> todaySchedule;
  final DashboardTasksModel tasks;
  final double hoursThisWeek;
  final DashboardPayModel pay;
  final DashboardBadgesModel badges;

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final activeRaw = json['active_visit'];
    final nextRaw = json['next_shift'];
    final scheduleRaw = json['today_schedule'] as List<dynamic>? ?? const [];

    return DashboardModel(
      caregiver: DashboardCaregiverModel.fromJson(
        json['caregiver'] as Map<String, dynamic>? ?? const {},
      ),
      today: DashboardTodayModel.fromJson(
        json['today'] as Map<String, dynamic>? ?? const {},
      ),
      activeVisit: activeRaw is Map<String, dynamic>
          ? VisitModel.fromJson(activeRaw)
          : null,
      nextShift: nextRaw is Map<String, dynamic>
          ? DashboardNextShiftModel.fromJson(nextRaw)
          : null,
      todaySchedule: scheduleRaw
          .whereType<Map<String, dynamic>>()
          .map(ScheduleItemModel.fromJson)
          .toList(),
      tasks: DashboardTasksModel.fromJson(
        json['tasks'] as Map<String, dynamic>? ?? const {},
      ),
      hoursThisWeek: (json['hours_this_week'] as num?)?.toDouble() ?? 0,
      pay: DashboardPayModel.fromJson(
        json['pay'] as Map<String, dynamic>? ?? const {},
      ),
      badges: DashboardBadgesModel.fromJson(
        json['badges'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'caregiver': caregiver.toJson(),
        'today': today.toJson(),
        'active_visit': activeVisit?.toJson(),
        'next_shift': nextShift?.toJson(),
        'today_schedule': todaySchedule.map((s) => s.toJson()).toList(),
        'tasks': tasks.toJson(),
        'hours_this_week': hoursThisWeek,
        'pay': pay.toJson(),
        'badges': badges.toJson(),
      };

  @override
  List<Object?> get props => [
        caregiver,
        today,
        activeVisit,
        nextShift,
        todaySchedule,
        tasks,
        hoursThisWeek,
        pay,
        badges,
      ];
}
