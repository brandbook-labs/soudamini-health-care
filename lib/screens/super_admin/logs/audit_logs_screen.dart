import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JivanAppBar(title: "System Logs", showBack: true),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Column(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.fileText, size: 20),
                title: Text("Action #${1000 + index}"),
                subtitle: const Text("Admin updated Clinic Profile [ID: 204]"),
                trailing: Text(
                  "10:4${index} AM",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
              const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }
}
