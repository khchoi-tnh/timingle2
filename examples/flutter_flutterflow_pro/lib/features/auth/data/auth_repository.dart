class LoginRequest {
  final String email;
  final String password;
  LoginRequest({required this.email, required this.password});
}

class User {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  User({required this.id, required this.email, required this.name, this.avatar});
}

class AuthRepository {
  Future<User> login(LoginRequest request) async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));

    // Validation
    if (request.email.isEmpty || request.password.isEmpty) {
      throw Exception('이메일과 비밀번호를 입력해주세요.');
    }
    if (!request.email.contains('@')) {
      throw Exception('유효한 이메일 주소를 입력해주세요.');
    }
    if (request.password.length < 6) {
      throw Exception('비밀번호는 최소 6자 이상이어야 합니다.');
    }

    // Mock successful login
    return User(
      id: '123',
      email: request.email,
      name: request.email.split('@')[0],
      avatar: null,
    );
  }
}
