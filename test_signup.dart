import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() async {
  final email = 'test${Random().nextInt(10000)}@college.edu';
  final password = 'Password@123';
  
  print('Signing up with $email...');
  final signupRes = await http.post(
    Uri.parse('https://frnd-api-n3hv.onrender.com/api/auth/signup'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );
  print('Signup status: ${signupRes.statusCode}');
  print('Signup body: ${signupRes.body}');
  
  final rawCookie = signupRes.headers['set-cookie'];
  print('Cookie: $rawCookie');
  
  if (rawCookie != null) {
    final index = rawCookie.indexOf(';');
    final cookie = (index == -1) ? rawCookie : rawCookie.substring(0, index);
    
    print('Fetching profile...');
    final profileRes = await http.get(
      Uri.parse('https://frnd-api-n3hv.onrender.com/api/users/me'),
      headers: {'cookie': cookie},
    );
    print('Profile status: ${profileRes.statusCode}');
    print('Profile body: ${profileRes.body}');
  }
}
