import '../models/care_recipient_model.dart';

abstract class HomeRepository {
  Future<List<CareRecipientModel>> getCareRecipients();
}

class HomeRepositoryImpl implements HomeRepository {
  @override
  Future<List<CareRecipientModel>> getCareRecipients() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));

    return const [
      CareRecipientModel(
        id: 1,
        name: 'Margaret Johnson',
        careType: 'Elderly Care',
        nextVisit: 'Today, 2:00 PM',
      ),
      CareRecipientModel(
        id: 2,
        name: 'Robert Williams',
        careType: 'Post-Surgery Support',
        nextVisit: 'Tomorrow, 10:30 AM',
      ),
      CareRecipientModel(
        id: 3,
        name: 'Emily Davis',
        careType: 'Disability Support',
        nextVisit: 'Mon, 4:15 PM',
      ),
    ];
  }
}
