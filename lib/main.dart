import 'package:flutter/material.dart';
import 'package:mac_dock/dock.dart';

/// Entrypoint of the application.
void main() {
  runApp(MacDockApp());
}

/// [Widget] building the [MaterialApp].
class MacDockApp extends StatelessWidget {
  final List<DockItem> dockItems = [
    DockItem(Icons.person, 'Person'),
    DockItem(Icons.message, 'Message'),
    DockItem(Icons.call, 'Call'),
    DockItem(Icons.camera, 'Camera'),
    DockItem(Icons.photo, 'Photo'),
  ];
  MacDockApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.blue[200],
        body: Center(
          child: Dock(
            items: dockItems,
            builder: (item) {
              return Container(
                constraints: const BoxConstraints(minWidth: 48),
                height: 48,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:
                      Colors.primaries[item.hashCode % Colors.primaries.length],
                ),
                child: Center(child: Icon(item.icon, color: Colors.white)),
              );
            },
          ),
        ),
      ),
    );
  }
}
