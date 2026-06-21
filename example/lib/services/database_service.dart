import 'package:rs_iron/rs_iron.dart';

@Service()
class DatabaseService {
  void connect() {
    print('DatabaseService: Connected to database');
  }

  void query(String sql) {
    print('DatabaseService: Executing query: $sql');
  }
}

@Service()
class ConfigurationService {
  ConfigurationService() : environment = 'development';
  final String environment;

  String getConnectionString() =>
      'jdbc:mysql://localhost:3306/mydb?env=$environment';
}
