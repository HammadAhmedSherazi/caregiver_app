import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../models/api/assignment_model.dart';
import '../models/api/caregiver_profile_model.dart';
import '../models/api/conversation_model.dart';
import '../models/api/notification_item_model.dart';
import '../models/api/paginated_response.dart';
import '../models/api/pay_item_model.dart';
import '../models/api/schedule_item_model.dart';
import '../models/api/visit_model.dart';
import '../models/user_model.dart';
import '../local/token_storage.dart';

class LoginResult {
  const LoginResult({
    required this.token,
    required this.user,
  });

  final String token;
  final UserModel user;
}

class CaregiverApi {
  CaregiverApi({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/login',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );

      final body = response.data ?? const {};
      final token = body['token'] as String?;
      final userJson = body['user'] as Map<String, dynamic>?;

      if (token == null || userJson == null) {
        throw ApiException('Invalid login response');
      }

      await _tokenStorage.saveToken(token);

      return LoginResult(
        token: token,
        user: UserModel.fromJson(userJson),
      );
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<void> logout() async {
    try {
      await _apiClient.post<void>('/logout');
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    } finally {
      await _tokenStorage.clearToken();
    }
  }

  Future<CaregiverProfileModel> getMe() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/me');
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw ApiException('Invalid profile response');
      }
      return CaregiverProfileModel.fromJson(data);
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<List<AssignmentModel>> getAssignments() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/assignments');
      final data = response.data?['data'] as List<dynamic>? ?? const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(AssignmentModel.fromJson)
          .toList();
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<VisitModel?> getActiveVisit() async {
    try {
      final response =
          await _apiClient.get<Map<String, dynamic>>('/visits/active');
      final data = response.data?['data'];
      if (data == null || data is! Map<String, dynamic>) {
        return null;
      }
      final visit = VisitModel.fromJson(data);
      return visit.isActive ? visit : null;
    } catch (error) {
      if (error is DioException && error.error is NotFoundException) {
        return null;
      }
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<VisitModel> clockIn({
    int? clientId,
    int? scheduleId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (clientId != null) payload['client_id'] = clientId;
      if (scheduleId != null) payload['schedule_id'] = scheduleId;
      if (latitude != null) payload['latitude'] = latitude;
      if (longitude != null) payload['longitude'] = longitude;

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/visits/clock-in',
        data: payload,
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw ApiException('Invalid clock-in response');
      }
      return VisitModel.fromJson(data);
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<VisitModel> clockOut({
    int? scheduleId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (scheduleId != null) payload['schedule_id'] = scheduleId;
      if (latitude != null) payload['latitude'] = latitude;
      if (longitude != null) payload['longitude'] = longitude;
      if (notes != null && notes.isNotEmpty) payload['notes'] = notes;

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/visits/clock-out',
        data: payload,
      );

      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw ApiException('Invalid clock-out response');
      }
      return VisitModel.fromJson(data);
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<PaginatedResponse<VisitModel>> getVisits({
    int perPage = ApiConfig.defaultPerPage,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/visits',
        queryParameters: {'per_page': perPage},
      );
      return _parsePaginated(response.data, VisitModel.fromJson);
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<PaginatedResponse<ScheduleItemModel>> getSchedule({
    String? from,
    String? to,
    String? status,
    bool upcoming = true,
    int perPage = ApiConfig.defaultPerPage,
  }) async {
    try {
      final query = <String, dynamic>{
        'per_page': perPage,
        if (upcoming) 'upcoming': 1,
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (status != null) 'status': status,
      };

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/schedule',
        queryParameters: query,
      );
      return _parsePaginated(response.data, ScheduleItemModel.fromJson);
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<PaginatedResponse<PayItemModel>> getPay({
    String? periodKey,
    int perPage = ApiConfig.payPerPage,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/pay',
        queryParameters: {
          'per_page': perPage,
          if (periodKey != null) 'period_key': periodKey,
        },
      );
      return _parsePaginated(response.data, PayItemModel.fromJson);
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<List<int>> downloadPayStub(int id) async {
    try {
      final response = await _apiClient.downloadBytes('/pay/$id/stub');
      return response.data ?? const [];
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<PaginatedResponse<NotificationItemModel>> getNotifications({
    bool unreadOnly = false,
    int perPage = 25,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {
          'per_page': perPage,
          if (unreadOnly) 'unread': 1,
        },
      );
      return _parsePaginated(response.data, NotificationItemModel.fromJson);
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<int> getNotificationsUnreadCount() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/notifications/unread-count',
      );
      return response.data?['count'] as int? ?? 0;
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<void> markNotificationRead(int id) async {
    try {
      await _apiClient.post<void>('/notifications/$id/read');
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<int> markAllNotificationsRead() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/notifications/read-all',
      );
      return response.data?['updated'] as int? ?? 0;
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<void> deleteNotification(int id) async {
    try {
      await _apiClient.delete<void>('/notifications/$id');
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<PaginatedResponse<ConversationSummaryModel>> getConversations({
    bool unreadOnly = false,
    String? search,
    int perPage = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/conversations',
        queryParameters: {
          'per_page': perPage,
          if (unreadOnly) 'unread': 1,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return _parsePaginated(response.data, ConversationSummaryModel.fromJson);
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<int> getConversationsUnreadCount() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/conversations/unread-count',
      );
      return response.data?['count'] as int? ?? 0;
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<ConversationDetailModel> getConversation(int id) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/conversations/$id',
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw ApiException('Invalid conversation response');
      }
      return ConversationDetailModel.fromJson(data);
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<ConversationMessageModel> sendConversationMessage({
    required int conversationId,
    required String body,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/conversations/$conversationId/messages',
        data: {'body': body},
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw ApiException('Invalid message response');
      }
      return ConversationMessageModel.fromJson(data);
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<ConversationSummaryModel> startConversation({
    required String subject,
    required String body,
    required List<int> participantIds,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/conversations',
        data: {
          'subject': subject,
          'body': body,
          'participant_ids': participantIds,
        },
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) {
        throw ApiException('Invalid conversation response');
      }
      return ConversationSummaryModel.fromJson(data);
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  PaginatedResponse<T> _parsePaginated<T>(
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final data = body?['data'] as List<dynamic>? ?? const [];
    return PaginatedResponse<T>(
      data: data
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(),
      links: body?['links'] as Map<String, dynamic>? ?? const {},
      meta: body?['meta'] as Map<String, dynamic>? ?? const {},
    );
  }
}
