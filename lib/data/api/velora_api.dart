import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../../core/network/api_exception.dart';
import '../local/token_storage.dart';
import '../models/api/compliance_form_model.dart';
import '../models/api/velora/velora_models.dart';

/// Endpoints added by `MOBILE_API_VELORA.md`.
///
/// **🚧 PLANNED — NOT LIVE.** Every method checks
/// [ApiConfig.veloraApiEnabled] first and throws [ApiNotLiveException]
/// without making a request while it is off. Paths and payloads follow the
/// contract exactly; nothing here invents a response.
///
/// Same transport as [CaregiverApi]: the shared [ApiClient] adds the bearer
/// token and `Accept-Language`, and maps 401/403/404/409/422/429 errors.
class VeloraApi {
  VeloraApi({
    required this._apiClient,
    required this._tokenStorage,
  });

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  /// Group 1 endpoints — live on the server ([ApiConfig.veloraGroup1Enabled]).
  static const _group1 = {
    'POST /auth/phone/send-code',
    'POST /auth/phone/verify',
    'POST /auth/invite/check',
    'POST /auth/invite/confirm',
    'PUT /me/settings',
    'POST /me/info-change',
    'POST /privacy/data-request',
    'POST /devices',
    'DELETE /devices/{id}',
    'DELETE /account',
  };

  static void _ensureLive(String endpoint) {
    final live = _group1.contains(endpoint)
        ? ApiConfig.veloraGroup1Enabled
        : ApiConfig.veloraApiEnabled;
    if (!live) throw ApiNotLiveException(endpoint);
  }

  Future<Json> _send(
    String endpoint,
    Future<dynamic> Function() request,
  ) async {
    _ensureLive(endpoint);
    try {
      final response = await request();
      final data = response.data;
      return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  Future<List<int>> _download(String endpoint, String path) async {
    _ensureLive(endpoint);
    try {
      final response = await _apiClient.downloadBytes(path);
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) throw ApiException('Empty file');
      return bytes;
    } catch (error) {
      ApiClient.rethrowAsApiException(error);
    }
  }

  // ---------------------------------------------------------------- §1 Auth

  /// 1. `POST /auth/phone/send-code` (unauthenticated).
  Future<PhoneCodeSentModel> sendPhoneCode({required String phone}) async {
    final json = await _send('POST /auth/phone/send-code', () {
      return _apiClient.post<Map<String, dynamic>>(
        '/auth/phone/send-code',
        data: {'phone': phone},
      );
    });
    return PhoneCodeSentModel.fromJson(json);
  }

  /// 2. `POST /auth/phone/verify` — stores the token like `POST /login`.
  Future<PhoneVerifyResultModel> verifyPhoneCode({
    required String phone,
    required String code,
    required String deviceName,
  }) async {
    final json = await _send('POST /auth/phone/verify', () {
      return _apiClient.post<Map<String, dynamic>>(
        '/auth/phone/verify',
        data: {'phone': phone, 'code': code, 'device_name': deviceName},
      );
    });
    final result = PhoneVerifyResultModel.maybeFromJson(json);
    if (result == null) throw ApiException('Invalid sign-in response');
    await _tokenStorage.saveToken(result.token);
    return result;
  }

  /// 3. `POST /auth/invite/check`.
  Future<InviteDetailsModel> checkInvite({required String code}) async {
    final json = await _send('POST /auth/invite/check', () {
      return _apiClient.post<Map<String, dynamic>>(
        '/auth/invite/check',
        data: {'code': code},
      );
    });
    return InviteDetailsModel.fromJson(json);
  }

  /// 4. `POST /auth/invite/confirm` — then call [verifyPhoneCode].
  Future<PhoneCodeSentModel> confirmInvite({
    required String code,
    required String phone,
  }) async {
    final json = await _send('POST /auth/invite/confirm', () {
      return _apiClient.post<Map<String, dynamic>>(
        '/auth/invite/confirm',
        data: {'code': code, 'phone': phone},
      );
    });
    return PhoneCodeSentModel.fromJson(json);
  }

  // ------------------------------------------------- §10 Profile / privacy

  /// 5. `PUT /me/settings`.
  Future<CaregiverSettingsModel> updateSettings(CaregiverSettingsModel settings) async {
    settings.validate();
    final json = await _send('PUT /me/settings', () {
      return _apiClient.put<Map<String, dynamic>>('/me/settings', data: settings.toJson());
    });
    return CaregiverSettingsModel.maybeFromJson(json['data']) ?? settings;
  }

  /// 6. `POST /me/info-change` — result is **pending** office approval.
  Future<InfoChangeResultModel> requestInfoChange(InfoChangeRequest request) async {
    request.validate();
    final json = await _send('POST /me/info-change', () {
      return _apiClient.post<Map<String, dynamic>>('/me/info-change', data: request.toJson());
    });
    final result = InfoChangeResultModel.maybeFromJson(json);
    if (result == null) throw ApiException('Invalid info-change response');
    return result;
  }

  /// 7. `POST /privacy/data-request` (no payload).
  Future<PrivacyRequestResultModel> requestDataCopy() async {
    final json = await _send('POST /privacy/data-request', () {
      return _apiClient.post<Map<String, dynamic>>('/privacy/data-request');
    });
    final result = PrivacyRequestResultModel.maybeFromJson(json);
    if (result == null) throw ApiException('Invalid data-request response');
    return result;
  }

  /// 23. `DELETE /account` (§10a) — permanent; required by Apple / Google.
  /// The server revokes every token and push registration. Wrong password is
  /// a `422` with `errors.password`. Returns the server's message.
  Future<String> deleteAccount({required String password}) async {
    if (password.isEmpty) {
      throw RequestValidationException({
        'password': ['Enter your password.'],
      });
    }
    final json = await _send('DELETE /account', () {
      return _apiClient.delete<Map<String, dynamic>>(
        '/account',
        data: {'password': password},
      );
    });
    final message = json['message'];
    return message is String && message.isNotEmpty
        ? message
        : 'Your account has been deleted.';
  }

  // -------------------------------------------------------------- §11 Push

  /// 8. `POST /devices` — idempotent per token. Returns the device id.
  Future<int> registerDevice(DeviceRegistrationRequest request) async {
    request.validate();
    final json = await _send('POST /devices', () {
      return _apiClient.post<Map<String, dynamic>>('/devices', data: request.toJson());
    });
    final id = intOrNull(jsonMap(json['data'])?['id']);
    if (id == null) throw ApiException('Invalid device response');
    return id;
  }

  /// 9. `DELETE /devices/{id}` — on sign-out.
  Future<void> unregisterDevice(int id) async {
    await _send('DELETE /devices/{id}', () {
      return _apiClient.delete<Map<String, dynamic>>('/devices/$id');
    });
  }

  // -------------------------------------------------------------- §3 Time

  /// 10. `GET /time/week` — [date] is any day of the week (default today).
  Future<TimeWeekModel> getTimeWeek({DateTime? date}) async {
    final json = await _send('GET /time/week', () {
      return _apiClient.get<Map<String, dynamic>>(
        '/time/week',
        queryParameters: {if (date != null) 'date': formatDate(date)},
      );
    });
    return TimeWeekModel.fromJson(json);
  }

  /// 11. `GET /time/month` — [month] as `YYYY-MM` (default current).
  Future<TimeMonthModel> getTimeMonth({String? month}) async {
    final json = await _send('GET /time/month', () {
      return _apiClient.get<Map<String, dynamic>>(
        '/time/month',
        queryParameters: {'month': ?month},
      );
    });
    return TimeMonthModel.fromJson(json);
  }

  /// 22. `GET /services/catalog` — services to tick at clock-out.
  Future<ServiceCatalogModel> getServiceCatalog() async {
    final json = await _send('GET /services/catalog', () {
      return _apiClient.get<Map<String, dynamic>>('/services/catalog');
    });
    return ServiceCatalogModel.fromJson(json);
  }

  // ------------------------------------------------ §4 Fix a clock-out

  /// 12. `GET /visits/{schedule}`.
  Future<VisitDetailModel> getVisitDetail(int scheduleId) async {
    final json = await _send('GET /visits/{schedule}', () {
      return _apiClient.get<Map<String, dynamic>>('/visits/$scheduleId');
    });
    return VisitDetailModel.fromJson(json);
  }

  /// 13. `POST /visits/{schedule}/fix-clockout` (201, pending review).
  Future<FixClockoutResultModel> fixClockout(int scheduleId, FixClockoutRequest request) async {
    request.validate();
    final json = await _send('POST /visits/{schedule}/fix-clockout', () {
      return _apiClient.post<Map<String, dynamic>>(
        '/visits/$scheduleId/fix-clockout',
        data: request.toJson(),
      );
    });
    return FixClockoutResultModel.fromJson(json);
  }

  // ------------------------------------------------ §5 Report a change

  /// 14. `POST /change-reports`.
  Future<ChangeReportResultModel> createChangeReport(ChangeReportRequest request) async {
    request.validate();
    final json = await _send('POST /change-reports', () {
      return _apiClient.post<Map<String, dynamic>>('/change-reports', data: request.toJson());
    });
    return ChangeReportResultModel.fromJson(json);
  }

  // -------------------------------------------------------------- §6 Docs

  /// 15. `GET /documents/required`.
  Future<RequiredDocumentsModel> getRequiredDocuments() async {
    final json = await _send('GET /documents/required', () {
      return _apiClient.get<Map<String, dynamic>>('/documents/required');
    });
    return RequiredDocumentsModel.fromJson(json);
  }

  /// 16. `GET /documents/office`.
  Future<List<OfficeDocumentModel>> getOfficeDocuments() async {
    final json = await _send('GET /documents/office', () {
      return _apiClient.get<Map<String, dynamic>>('/documents/office');
    });
    return jsonList(json['data']).map(OfficeDocumentModel.fromJson).toList();
  }

  /// 17. `GET /documents/office/{id}/download` → PDF bytes.
  Future<List<int>> downloadOfficeDocument(String id) {
    return _download(
      'GET /documents/office/{id}/download',
      '/documents/office/${Uri.encodeComponent(id)}/download',
    );
  }

  // ------------------------------------------------------------- §7 Inbox

  /// 18. `GET /inbox/office-thread` (created on first call).
  Future<OfficeThreadModel> getOfficeThread() async {
    final json = await _send('GET /inbox/office-thread', () {
      return _apiClient.get<Map<String, dynamic>>('/inbox/office-thread');
    });
    return OfficeThreadModel.fromJson(json);
  }

  // ---------------------------------------------------------- §8 Check-in

  /// 19. `PUT /compliance-forms/{id}/draft` ("Save & exit").
  Future<ComplianceFormDetailModel> saveCheckInDraft(int formId, CheckInDraftRequest request) async {
    final json = await _send('PUT /compliance-forms/{id}/draft', () {
      return _apiClient.put<Map<String, dynamic>>(
        '/compliance-forms/$formId/draft',
        data: request.toJson(),
      );
    });
    final data = jsonMap(json['data']);
    if (data == null) throw ApiException('Invalid draft response');
    return ComplianceFormDetailModel.fromJson(data);
  }

  /// Extended `POST /compliance-forms/{id}/submit` — typed-name signature.
  /// (The drawn-signature form stays in [CaregiverApi.submitComplianceForm].)
  Future<ComplianceFormDetailModel> submitCheckIn(int formId, CheckInSubmitRequest request) async {
    request.validate();
    final json = await _send('POST /compliance-forms/{id}/submit (typed name)', () {
      return _apiClient.post<Map<String, dynamic>>(
        '/compliance-forms/$formId/submit',
        data: request.toJson(),
      );
    });
    final data = jsonMap(json['data']);
    if (data == null) throw ApiException('Invalid check-in response');
    return ComplianceFormDetailModel.fromJson(data);
  }

  /// 20. `GET /compliance-forms/{id}/receipt` → PDF bytes (404 until submitted).
  Future<List<int>> downloadCheckInReceipt(int formId) {
    return _download(
      'GET /compliance-forms/{id}/receipt',
      '/compliance-forms/$formId/receipt',
    );
  }

  // --------------------------------------------------------------- §9 Pay

  /// 21. `GET /pay/next`.
  Future<PayNextModel> getPayNext() async {
    final json = await _send('GET /pay/next', () {
      return _apiClient.get<Map<String, dynamic>>('/pay/next');
    });
    return PayNextModel.fromJson(json);
  }
}
