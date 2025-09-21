import 'package:hive/hive.dart';

part 'football_item.g.dart';

@HiveType(typeId: 0)
class FootballItem {
  @HiveField(0)
  final String name;

  FootballItem({required this.name});
}
