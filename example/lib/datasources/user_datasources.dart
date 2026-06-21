import 'package:rs_iron/rs_iron.dart';

@DataSource()
class UserApiDataSource {
  Future<List<Map<String, dynamic>>> fetchUsersFromApi() async {
    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 800));

    return [
      {'id': '1', 'name': 'John Doe', 'email': 'john@api.com'},
      {'id': '2', 'name': 'Jane Smith', 'email': 'jane@api.com'},
      {'id': '3', 'name': 'Bob Wilson', 'email': 'bob@api.com'},
    ];
  }

  Future<Map<String, dynamic>> createUserOnApi(
    String name,
    String email,
  ) async {
    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 600));

    return {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'email': email,
    };
  }

  Future<void> deleteUserOnApi(String userId) async {
    // Simulate API call
    await Future<void>.delayed(const Duration(milliseconds: 400));
    print('API: User $userId deleted');
  }
}

@DataSource()
class UserLocalDataSource {
  final Map<String, Map<String, dynamic>> _localCache = {};

  Future<List<Map<String, dynamic>>> getUsersFromCache() async {
    // Simulate local storage access
    await Future<void>.delayed(const Duration(milliseconds: 100));

    return _localCache.values.toList();
  }

  Future<void> cacheUser(Map<String, dynamic> userData) async {
    // Simulate local storage write
    await Future<void>.delayed(const Duration(milliseconds: 50));

    _localCache[userData['id']] = userData;
    print('Local: Cached user ${userData['name']}');
  }

  Future<void> removeUserFromCache(String userId) async {
    // Simulate local storage delete
    await Future<void>.delayed(const Duration(milliseconds: 50));

    _localCache.remove(userId);
    print('Local: Removed user $userId from cache');
  }

  Future<Map<String, dynamic>?> getUserFromCache(String userId) async {
    // Simulate local storage read
    await Future<void>.delayed(const Duration(milliseconds: 30));

    return _localCache[userId];
  }
}
