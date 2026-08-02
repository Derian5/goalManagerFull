// Классы запросов и ответов для аутентификации
class LoginRequest {
  final String username; // вместо email
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'username': username, // ключ изменён
      'password': password,
    };
  }
}

class RegisterRequest {
  final String username; // вместо email
  final String password;
  final String name;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'name': name,
    };
  }
}

class LoginResponse {
  final String token;
  final UserDto user;

  LoginResponse({required this.token, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      user: UserDto.fromJson(json['user']),
    );
  }
}

class RegisterResponse {
  final String token;
  final UserDto user;

  RegisterResponse({required this.token, required this.user});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      token: json['token'],
      user: UserDto.fromJson(json['user']),
    );
  }
}

class UserDto {
  final String id;
  final String username; // вместо email
  final String name;

  UserDto({required this.id, required this.username, required this.name});

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'],
      username: json['username'], // поле изменено
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
    };
  }
}