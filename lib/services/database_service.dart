// services/database_service.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/football_item.dart';

class DatabaseService {
  static Future<void> initHive() async {
    await Hive.initFlutter();

    // تسجيل الـ adapter
    Hive.registerAdapter(FootballItemAdapter());

    // فتح الصندوق
    await Hive.openBox<FootballItem>('footballItems');
    
    // إضافة بيانات أولية إذا كان الصندوق فارغاً
    await a();
  }

  static Future<void> a() async {
    final itemsBox = Hive.box<FootballItem>('footballItems');

    await itemsBox.clear();
    if (itemsBox.isEmpty) {
      // قائمة الأسماء
      List<String> initialItems = [
        'ريال مدريد',
        'برشلونة',
        'بايرن ميونخ',
        'يوفنتوس',
        'ليفربول',
        'كريستيانو رونالدو',
        'ليونيل ميسي',
        'محمد صلاح',
        'نيمار',
        'ارسنال',
        'تشيلسى',
        'مانشيستر يونايتد',
        'مانشيستر سيتى',
        'كاكا',
        'زيدان',
        'نيمار',
        'نابولى',
        'روبرت ليفاندوفسكي',
      ];

      // إضافة جميع العناصر باستخدام loop
      for (var item in initialItems) {
        await itemsBox.add(FootballItem(name: item));
        // logo: item['logo']!,
      }
    }
  }

  
  static List<FootballItem> getFootballItems() {
    return Hive.box<FootballItem>('footballItems').values.toList();
  }
  static Future<void> clearAllData() async {
    final itemsBox = Hive.box<FootballItem>('footballItems');
    await itemsBox.clear();
  }

  static Future<void> addFootballItem(String name) async {
    await Hive.box<FootballItem>('footballItems').add(
      FootballItem(
        name: name,
        // logo: logo,
      ),
    );
  }

  static Future<void> addMultipleFootballItems(List<String> items) async {
    final itemsBox = Hive.box<FootballItem>('footballItems');

    for (var item in items) {
      await itemsBox.add(
        FootballItem(
          name: item,
          // logo: item['logo']!,
        ),
      );
    }
  }
}
