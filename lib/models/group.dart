class Group {
  Group({required this.id, required this.groupName, required this.groupOwner});

  final String id;
  final String groupName;
  final String groupOwner;

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      groupName: json['group_name'],
      groupOwner: json['group_owner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'group_name': groupName, 'group_owner': groupOwner};
  }
}

class GroupMember {
  GroupMember({
    required this.groupId,
    required this.userId,
    required this.joinedAt,
  });

  final String groupId;
  final String userId;
  final String joinedAt;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      groupId: json['group_id'],
      userId: json['user_id'],
      joinedAt: json['joined_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'group_id': groupId, 'user_id': userId, 'joined_at': joinedAt};
  }
}
