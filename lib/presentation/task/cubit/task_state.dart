import 'package:equatable/equatable.dart';

import '../../../data/models/task_page_model.dart';

enum TaskStatus { initial, loading, success, failure }

class TaskState extends Equatable {
  const TaskState({
    this.status = TaskStatus.initial,
    this.data,
    this.filter = TaskFilter.all,
    this.searchQuery = '',
    this.errorMessage,
  });

  final TaskStatus status;
  final TaskPageData? data;
  final TaskFilter filter;
  final String searchQuery;
  final String? errorMessage;

  bool get isLoading => status == TaskStatus.loading;
  bool get hasError => status == TaskStatus.failure;

  List<TaskItem> get visibleTasks {
    final page = data;
    if (page == null) return const [];

    final filtered = page.tasksForFilter(filter);
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return filtered;

    return filtered
        .where(
          (task) =>
              task.title.toLowerCase().contains(query) ||
              task.subtitle.toLowerCase().contains(query) ||
              (task.clientName?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  TaskState copyWith({
    TaskStatus? status,
    TaskPageData? data,
    TaskFilter? filter,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskState(
      status: status ?? this.status,
      data: data ?? this.data,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, data, filter, searchQuery, errorMessage];
}
