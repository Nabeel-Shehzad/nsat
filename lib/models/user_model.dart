class User {
  final String username;
  final String password;
  final String status;
  final String serverIp;
  
  User({
    required this.username,
    required this.password,
    required this.status,
    required this.serverIp,
  });
  
  factory User.fromJson(Map<String, dynamic> json, String username, String password) {
    return User(
      username: username,
      password: password,
      status: json['status'] ?? '',
      serverIp: json['server_ip'] ?? '',
    );
  }
}
