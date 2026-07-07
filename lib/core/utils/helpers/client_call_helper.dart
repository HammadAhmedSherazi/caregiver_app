import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../di/service_locator.dart';
import '../../network/api_exception.dart';
import '../../../data/repositories/client_repository.dart';
import 'phone_launch_helper.dart';

Future<void> initiateClientCall(
  BuildContext context, {
  required String clientId,
  String? fallbackPhone,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  try {
    final result = await sl<ClientRepository>().initiateCall(int.parse(clientId));

    if (!context.mounted) return;

    if (result.isRingout) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                'Connecting… your phone will ring, then connect to the client.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final tel = result.tel;
    if (tel != null && tel.isNotEmpty) {
      final uri = tel.startsWith('tel:') ? Uri.parse(tel) : Uri(scheme: 'tel', path: tel);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }

    if (fallbackPhone != null && fallbackPhone.isNotEmpty) {
      await launchPhoneCall(fallbackPhone);
    }
  } on ApiException catch (error) {
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error.message.isNotEmpty
              ? error.message
              : 'Unable to place call. Please try again.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (_) {
    if (fallbackPhone != null && fallbackPhone.isNotEmpty) {
      await launchPhoneCall(fallbackPhone);
      return;
    }
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Unable to place call. Please try again.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
