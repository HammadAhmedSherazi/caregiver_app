import '../api/caregiver_api.dart';
import '../mappers/api_mappers.dart';
import '../models/api/call_model.dart';
import '../models/client_model.dart';

abstract class ClientRepository {
  Future<List<ClientModel>> fetchClients();
  Future<ClientModel?> findByName(String name);
  Future<ClientModel?> findById(String id);
  Future<CallResultModel> initiateCall(int clientId);
}

class ClientRepositoryImpl implements ClientRepository {
  ClientRepositoryImpl({required this._api});

  final CaregiverApi _api;

  @override
  Future<List<ClientModel>> fetchClients() async {
    final assignments = await _api.getAssignments();
    return assignments.map(assignmentToClient).toList();
  }

  @override
  Future<ClientModel?> findByName(String name) async {
    final clients = await fetchClients();
    final normalized = name.trim().toLowerCase();
    for (final client in clients) {
      if (client.name.toLowerCase() == normalized) {
        return client;
      }
    }
    return null;
  }

  @override
  Future<ClientModel?> findById(String id) async {
    final clients = await fetchClients();
    for (final client in clients) {
      if (client.id == id) {
        return client;
      }
    }
    return null;
  }

  @override
  Future<CallResultModel> initiateCall(int clientId) {
    return _api.placeCall(clientId: clientId);
  }
}
