import 'dart:convert';
import 'package:http/http.dart' as http;

import 'user_model.dart';

class ApiService {
  static const String _baseUrl = 'https://reqres.in/api/users?page=2';

  static Future<List<User>> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('data')) {
          final List<dynamic> userData = jsonResponse['data'];
          return userData.map((json) => User.fromJson(json)).toList();
        } else {
          throw Exception('Invalid API response: "data" key not found');
        }
      } else {
        throw Exception(
            'Failed to fetch users. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }
}
