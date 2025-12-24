class MaterialItem {
  final String id;
  final String name;
  final String description;

  const MaterialItem({
    required this.id,
    required this.name,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
