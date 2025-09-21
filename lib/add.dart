import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/models/football_item.dart';

import 'services/database_service.dart';

class Add extends StatefulWidget {
  const Add({super.key});

  @override
  AddState createState() => AddState();
}

class AddState extends State<Add> {
  TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<FootballItem>('footballItems');

    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة جديد'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'أدخل اسم العنصر',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await DatabaseService.addFootballItem(nameController.text);
                  nameController.clear();
                }
              },
              child: const Text("إضافة"),
            ),
            const SizedBox(height: 20),
            const Text(
              'العناصر الحالية:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: box.listenable(),
                builder: (context, Box<FootballItem> itemsBox, _) {
                  final items = itemsBox.values.toList();

                  if (items.isEmpty) {
                    return const Center(child: Text("لا توجد عناصر بعد"));
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(item.name),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
