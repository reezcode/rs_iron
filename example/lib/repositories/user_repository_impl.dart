import 'package:rs_iron/rs_iron.dart';
import 'package:rs_iron_example/bloc/user_bloc.dart';

import '../datasources/user_datasources.dart';
import '../services/database_service.dart';
import 'user_repository.dart';

@Repository()
class UserRepositoryImpl implements UserRepository {
  @Autowired()
  late DatabaseService databaseService;

  @Autowired()
  late ConfigurationService configService;

  @Autowired()
  late UserApiDataSource apiDataSource;

  @Autowired()
  late UserLocalDataSource localDataSource;

  @override
  void findUser(String id) {
    databaseService.connect();
    final connectionString = configService.getConnectionString();
    print('UserRepository: Using connection: $connectionString');
    databaseService.query('SELECT * FROM users WHERE id = $id');
  }

  @override
  Future<List<User>> getAllUsers() async {
    databaseService.connect();
    final connectionString = configService.getConnectionString();
    print(
      'UserRepository: Getting all users using connection: $connectionString',
    );
    databaseService.query('SELECT * FROM users');

    // Simulate database response (temporarily without data source)
    return [
      const User(id: '1', name: 'John Doe', email: 'john@example.com'),
      const User(id: '2', name: 'Jane Smith', email: 'jane@example.com'),
    ];
  }

  @override
  Future<User> createUser(String name, String email) async {
    databaseService.connect();
    final connectionString = configService.getConnectionString();
    print(
      'UserRepository: Creating user $name with connection: $connectionString',
    );
    databaseService.query(
      'INSERT INTO users (name, email) VALUES (\'$name\', \'$email\')',
    );

    // Simulate returning created user (temporarily without data source)
    return User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
    );
  }

  @override
  Future<void> deleteUser(String id) async {
    databaseService.connect();
    final connectionString = configService.getConnectionString();
    print(
      'UserRepository: Deleting user $id with connection: $connectionString',
    );
    databaseService.query('DELETE FROM users WHERE id = \'$id\'');
  }
}
