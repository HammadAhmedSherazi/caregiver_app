import '../models/client_model.dart';

abstract class ClientRepository {
  Future<List<ClientModel>> fetchClients();
  Future<ClientModel?> findByName(String name);
}

class ClientRepositoryImpl implements ClientRepository {
  static const _clients = [
    ClientModel(
      id: '0',
      name: 'John Doe',
      listSubtitle: '248 Oak Street, Brooklyn',
      scheduleBadge: 'Today 9:00 AM',
      address: '248 Oak Street, Brooklyn, NY 11201',
      clientPhone: '(718) 555-0101',
      emergencyContact: ClientContact(
        label: 'Emergency · Spouse — Jane Doe',
        phone: '(718) 555-0102',
      ),
      dailyCarePlan: [
        'Morning personal care assistance',
        'Medication reminder at breakfast',
        'Light housekeeping and meal prep',
      ],
      avatarUrl: 'https://i.pravatar.cc/150?u=john-doe-care',
    ),
    ClientModel(
      id: '1',
      name: 'Steven Mark',
      listSubtitle: '248 Oak Street, Brooklyn, NY 11201',
      scheduleBadge: 'Today 2:00 AM',
      address: '248 Oak Street, Brooklyn, NY 11201',
      clientPhone: '(718) 555-0142',
      emergencyContact: ClientContact(
        label: 'Emergency · Daughter — Lisa Doe',
        phone: '(718) 555-0188',
      ),
      dailyCarePlan: [
        'Assist with bathing and dressing each morning',
        'Prepare low-sodium breakfast and lunch',
        'Medication reminder at 10:00 AM and 2:00 PM',
        'Light mobility exercises — use walker at all times',
      ],
      avatarUrl: 'https://i.pravatar.cc/150?u=steven-mark',
    ),
    ClientModel(
      id: '2',
      name: 'Müller James',
      listSubtitle: 'March, 15, 2025',
      scheduleBadge: 'Today 2:00 AM',
      address: '412 Pine Avenue, Brooklyn, NY 11205',
      clientPhone: '(718) 555-0199',
      emergencyContact: ClientContact(
        label: 'Emergency · Son — Mark James',
        phone: '(718) 555-0200',
      ),
      dailyCarePlan: [
        'Morning vitals check and log results',
        'Assist with meal prep and hydration',
        'Afternoon walk in the building courtyard',
      ],
      avatarUrl: 'https://i.pravatar.cc/150?u=muller-james',
    ),
    ClientModel(
      id: '3',
      name: 'Steven Mark',
      listSubtitle: 'Barista',
      scheduleBadge: 'Today 2:00 AM',
      address: '248 Oak Street, Brooklyn, NY 11201',
      clientPhone: '(718) 555-0142',
      emergencyContact: ClientContact(
        label: 'Emergency · Daughter — Lisa Doe',
        phone: '(718) 555-0188',
      ),
      dailyCarePlan: [
        'Assist with bathing and dressing each morning',
        'Prepare low-sodium breakfast and lunch',
      ],
      avatarUrl: 'https://i.pravatar.cc/150?u=steven-mark-2',
    ),
  ];

  @override
  Future<List<ClientModel>> fetchClients() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<ClientModel>.from(_clients);
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
}
