// models/football_item.dart
import 'package:hive/hive.dart';

part 'football_item.g.dart';

@HiveType(typeId: 0)
class FootballItem {
  @HiveField(0)
  final String name;

  // @HiveField(1)
  // final String logo;

  FootballItem({
    required this.name,
    // required this.logo,
  });
}
