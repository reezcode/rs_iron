import 'package:rs_iron/rs_iron.dart';

import '../bloc/user_bloc.dart';
import '../repositories/user_repository.dart';

@UseCase()
class GetAllUsersUseCase {
  @Autowired()
  late UserRepository userRepository;

  Future<List<User>> execute() async {
    return await userRepository.getAllUsers();
  }
}

@UseCase()
class CreateUserUseCase {
  @Autowired()
  late UserRepository userRepository;

  Future<User> execute(String name, String email) async {
    return await userRepository.createUser(name, email);
  }
}

@UseCase()
class DeleteUserUseCase {
  @Autowired()
  late UserRepository userRepository;

  Future<void> execute(String userId) async {
    await userRepository.deleteUser(userId);
  }
}
