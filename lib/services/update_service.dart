import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
// --- FIX 1: Add this import ---
import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  // Replace with your actual JSON URL
  final String versionCheckUrl =
      'https://api-jivan.onrender.com/api/version.json';

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      // 1. Get Current Installed Version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // 2. Get Latest Version from Server
      final response = await http.get(Uri.parse(versionCheckUrl));

      // --- FIX 2: Check if the widget is still on screen ---
      if (!context.mounted) return;

      if (response.statusCode == 200) {
        final serverData = json.decode(response.body);
        String latestVersion = serverData['latestVersion'];
        String downloadUrl = serverData['downloadUrl'];
        bool isRequired = serverData['isRequired'] ?? false;

        // 3. Compare Versions
        if (currentVersion != latestVersion) {
          _showUpdateDialog(context, downloadUrl, isRequired);
        }
      }
    } catch (e) {
      // --- FIX 3: Use debugPrint instead of print ---
      debugPrint("Error checking version: $e");
    }
  }

  void _showUpdateDialog(BuildContext context, String url, bool isRequired) {
    showDialog(
      context: context,
      barrierDismissible: !isRequired,
      builder: (context) => AlertDialog(
        title: const Text("New Update Available"),
        content: Text(
          isRequired
              ? "A critical update is required to continue using Jeevan Healthcare."
              : "A new version of the app is available.",
        ),
        actions: [
          if (!isRequired)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Later"),
            ),
          FilledButton(
            onPressed: () {
              _launchURL(url);
            },
            child: const Text("Update Now"),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
