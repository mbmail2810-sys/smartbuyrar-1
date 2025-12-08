import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings ⚙️")),
      body: ListView(
        children: [
          const ListTile(
            title: Text("App Version"),
            subtitle: Text("v1.0.0"),
            leading: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}
