import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NetworkErrorDialog {
  static Future<void> show(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text(
          'You are not connected to the Internet. Please connect first in the mobile Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              AppSettings.openAppSettings(type: AppSettingsType.wifi);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Returns true if [error] is a network connectivity failure.
  static bool isNetworkError(Object error) {
    if (error is SocketException) return true;
    if (error is PlatformException && error.code == 'network_error') return true;
    final msg = error.toString().toLowerCase();
    return msg.contains('network_error') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('socketexception');
  }
}
