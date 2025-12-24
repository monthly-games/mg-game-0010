enum CustomerState { entering, browsing, buying, leaving }

class Customer {
  final String id;
  final String name;
  CustomerState state;
  int? targetSlotIndex;
  // Position for visualization (0.0 to 1.0 relative to shop floor)
  // For simplicity, we just track 'walking progress' or abstract state.
  // Actually, let's track a simple progress value (0.0 to 1.0) for the current state animation.
  double actionProgress = 0.0;

  Customer({
    required this.id,
    required this.name,
    this.state = CustomerState.entering,
  });
}
