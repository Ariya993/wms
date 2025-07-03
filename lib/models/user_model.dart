class WMSUser {
  final int id;
  final String username;
  final String name; // Asumsi ada field nama juga

  WMSUser({required this.id, required this.username, required this.name});

  factory WMSUser.fromJson(Map<String, dynamic> json) {
    return WMSUser(
      id: json['id'] as int,
      username: json['username'] as String,
      name: json['name'] as String,
    );
  }

  // Untuk ditampilkan di dropdown
  @override
  String toString() => name;
 @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WMSUser &&
          runtimeType == other.runtimeType &&
          id == other.id; // Bandingkan berdasarkan ID unik (atau username)

  @override
  int get hashCode => id.hashCode; // Hash code berdasarkan ID unik (atau username)
}