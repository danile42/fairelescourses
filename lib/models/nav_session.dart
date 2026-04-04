class NavSession {
  final String listId;
  final String startedBy;
  final DateTime? startedAt;
  const NavSession({
    required this.listId,
    required this.startedBy,
    this.startedAt,
  });
}
