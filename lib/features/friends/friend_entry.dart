/// One row of the signed-in runner's friend list: a friend, or a request.
class FriendEntry {
  final String friendshipId;
  final String otherId;
  final String name;
  final String status; // 'pending' or 'accepted'
  final bool incoming; // true when the other runner sent the request

  const FriendEntry({
    required this.friendshipId,
    required this.otherId,
    required this.name,
    required this.status,
    required this.incoming,
  });

  bool get accepted => status == 'accepted';

  factory FriendEntry.fromMap(Map<String, dynamic> m) => FriendEntry(
        friendshipId: m['friendship_id'] as String,
        otherId: m['other_id'] as String,
        name: (m['other_name'] as String?) ?? 'Runner',
        status: m['status'] as String,
        incoming: (m['incoming'] as bool?) ?? false,
      );
}
