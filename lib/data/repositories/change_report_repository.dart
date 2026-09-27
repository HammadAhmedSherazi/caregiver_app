import '../api/velora_api.dart';
import '../models/api/velora/velora_models.dart';

/// "Report a change" (`POST /change-reports`) — 🚧 PLANNED — NOT LIVE.
abstract class ChangeReportRepository {
  Future<ChangeReportResultModel> send(ChangeReportRequest request);
}

class ChangeReportRepositoryImpl implements ChangeReportRepository {
  ChangeReportRepositoryImpl({required this._velora});

  final VeloraApi _velora;

  @override
  Future<ChangeReportResultModel> send(ChangeReportRequest request) {
    return _velora.createChangeReport(request);
  }
}
