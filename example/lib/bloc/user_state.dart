part of 'user_bloc.dart';

enum UserStateStatus { initial, loading, loaded, error }

class User extends Equatable {
  final String id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  @override
  List<Object?> get props => [id, name, email];
}

class UserState extends Equatable {
  final UserStateStatus status;
  final List<User> users;
  final String? errorMessage;

  const UserState({
    this.status = UserStateStatus.initial,
    this.users = const [],
    this.errorMessage,
  });

  UserState copyWith({
    UserStateStatus? status,
    List<User>? users,
    String? errorMessage,
  }) {
    return UserState(
      status: status ?? this.status,
      users: users ?? this.users,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, users, errorMessage];
}
