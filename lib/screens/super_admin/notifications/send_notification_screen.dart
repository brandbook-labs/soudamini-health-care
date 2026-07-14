import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  String _targetAudience = "All Users";
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JivanAppBar(title: "Push Notifications", showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Audience Selector
            Text(
              "Target Audience",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children:
                  [
                        "All Users",
                        "Patients Only",
                        "Doctors Only",
                        "Specific City",
                      ]
                      .map(
                        (audience) => ChoiceChip(
                          label: Text(audience),
                          selected: _targetAudience == audience,
                          onSelected: (val) =>
                              setState(() => _targetAudience = audience),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 24),

            // Content Form
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Notification Title",
                hintText: "e.g., Update Available!",
                border: OutlineInputBorder(),
                prefixIcon: Icon(LucideIcons.type),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Message Body",
                hintText: "Type your message here...",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),

            // Preview Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.bell,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleController.text.isEmpty
                              ? "Title Preview"
                              : _titleController.text,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _bodyController.text.isEmpty
                              ? "Message body preview..."
                              : _bodyController.text,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  // API Call to FCM
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Notification Sent Successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(LucideIcons.send),
                label: const Text("Send Notification"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
