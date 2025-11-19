import 'package:flutter/material.dart';

class LayananScreen extends StatefulWidget {
  const LayananScreen({super.key});

  @override
  State<LayananScreen> createState() => _LayananScreenState();
}

class _LayananScreenState extends State<LayananScreen> {
  final List<Map<String, String>> services = [
    {'name': 'Service 1', 'description': 'Description of Service 1'},
    {'name': 'Service 2', 'description': 'Description of Service 2'},
  ];

  void _addService() {
    // Implement add service functionality
  }

  void _editService(int index) {
    // Implement edit service functionality
  }

  void _deleteService(int index) {
    setState(() {
      services.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CRUD Service')),
      body: ListView.builder(
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Card(
            child: ListTile(
              title: Text(service['name']!),
              subtitle: Text(service['description']!),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _editService(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteService(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addService,
        child: const Icon(Icons.add),
      ),
    );
  }
}
