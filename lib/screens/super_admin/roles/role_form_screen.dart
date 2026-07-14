import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart';

class RoleFormScreen extends StatefulWidget {
  final Map<String, dynamic>? initialRole;
  const RoleFormScreen({super.key, this.initialRole});

  @override
  State<RoleFormScreen> createState() => _RoleFormScreenState();
}

class _RoleFormScreenState extends State<RoleFormScreen> {
  final Map<String, bool> _permissions = {
    "View Dashboard": true,
    "Manage Users": false,
    "Manage Clinics": false,
    "Financial Access": false,
    "System Settings": false,
    "Delete Records": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JivanAppBar(
        title: widget.initialRole == null ? "Create Role" : "Edit Permissions",
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: TextEditingController(
              text: widget.initialRole?['name'],
            ),
            decoration: const InputDecoration(
              labelText: "Role Name",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: TextEditingController(
              text: widget.initialRole?['desc'],
            ),
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: "Description",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            "Permissions",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ..._permissions.keys.map((key) {
            return SwitchListTile(
              title: Text(key),
              value: _permissions[key]!,
              onChanged: (val) => setState(() => _permissions[key] = val),
              contentPadding: EdgeInsets.zero,
            );
          }),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Save Changes"),
        ),
      ),
    );
  }
}
