import 'item.dart';
import 'material.dart';

class Recipe {
  final String id;
  final Item resultItem;
  final Map<MaterialItem, int> requiredMaterials;
  final int craftTimeSeconds;

  const Recipe({
    required this.id,
    required this.resultItem,
    required this.requiredMaterials,
    this.craftTimeSeconds = 5,
  });
}
