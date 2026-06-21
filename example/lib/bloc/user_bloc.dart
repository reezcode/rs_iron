import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rs_iron/rs_iron.dart';

import '../repositories/user_repository.dart';

part 'user_event.dart';
part 'user_state.dart';

@Controller(scope: ScopeType.factory)
class UserBloc extends Bloc<UserEvent, UserState> {
  // @Autowired() -> alternative
  final UserRepository userRepository;

  UserBloc(this.userRepository) : super(const UserState()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<CreateUserEvent>(_onCreateUser);
    on<DeleteUserEvent>(_onDeleteUser);
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(status: UserStateStatus.loading));

    try {
      await Future<void>.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate network delay

      // Simulate getting users from repository
      final users = await userRepository.getAllUsers();
      emit(state.copyWith(status: UserStateStatus.loaded, users: users));
    } catch (e) {
      emit(
        state.copyWith(
          status: UserStateStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(status: UserStateStatus.loading));

    try {
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      ); // Simulate network delay

      // Create new user
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: event.name,
        email: event.email,
      );

      // Add to existing users
      final updatedUsers = [...state.users, newUser];

      emit(state.copyWith(status: UserStateStatus.loaded, users: updatedUsers));
    } catch (e) {
      emit(
        state.copyWith(
          status: UserStateStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(state.copyWith(status: UserStateStatus.loading));

    try {
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      ); // Simulate network delay

      // Remove user from list
      final updatedUsers = state.users
          .where((user) => user.id != event.userId)
          .toList();

      emit(state.copyWith(status: UserStateStatus.loaded, users: updatedUsers));
    } catch (e) {
      emit(
        state.copyWith(
          status: UserStateStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
