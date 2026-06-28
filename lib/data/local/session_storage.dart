import '../models/user_model.dart';

abstract class SessionStorage {
  Future<UserModel?> loadUser();
  Future<void> saveUser(UserModel user);
  Future<void> clearUser();
}
