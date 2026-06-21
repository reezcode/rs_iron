import '../bloc/user_bloc.dart';

abstract class UserRepository {
  void findUser(String id);
  Future<List<User>> getAllUsers();
  Future<User> createUser(String name, String email);
  Future<void> deleteUser(String id);
}
