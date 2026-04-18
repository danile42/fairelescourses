enum HouseholdEventType {
  listItemAdded,
  listUpdated,
  tourFinished;

  String get wireName {
    switch (this) {
      case HouseholdEventType.listItemAdded:
        return 'list_item_added';
      case HouseholdEventType.listUpdated:
        return 'list_updated';
      case HouseholdEventType.tourFinished:
        return 'tour_finished';
    }
  }

  static HouseholdEventType? fromWireName(String? value) {
    switch (value) {
      case 'list_item_added':
        return HouseholdEventType.listItemAdded;
      case 'list_updated':
        return HouseholdEventType.listUpdated;
      case 'tour_finished':
        return HouseholdEventType.tourFinished;
      default:
        return null;
    }
  }
}

class HouseholdEvent {
  final String id;
  final HouseholdEventType type;
  final String listId;
  final String actorUid;
  final DateTime createdAt;
  final int? itemCount;

  const HouseholdEvent({
    required this.id,
    required this.type,
    required this.listId,
    required this.actorUid,
    required this.createdAt,
    this.itemCount,
  });
}
