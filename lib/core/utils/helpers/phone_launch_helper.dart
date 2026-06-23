import 'package:url_launcher/url_launcher.dart';

Future<bool> launchPhoneCall(String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
  final uri = Uri(scheme: 'tel', path: digits);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri);
  }
  return false;
}

Future<bool> launchMapSearch(String address) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
  );
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}
