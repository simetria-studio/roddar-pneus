import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

Future<User?> fetchUserData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');

  if (token != null) {
    final response = await http.post(
      Uri.parse('${ApiConfig.apiUrl}/get-user-info'),
      body: {
        'access_token': token,
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData['codigo_empresa'] != null &&
          jsonData['codigo_empresa'].toString().isNotEmpty) {
        final user = User.fromJson(jsonData);
        prefs.setString('codigo_empresa', user.codigo_empresa!);
        prefs.setString('nome_usuario', user.nome_usuario_completo!);
        prefs.setString('razao_social', user.razaoSocial!);
        prefs.setString('usuario', user.usuario!);
        prefs.setString('codigo_vendedor', user.codigo_vendedor!); // Novo
        prefs.setString('codigo_regiao', user.codigo_regiao!); // Novo
        return user;
      } else {
        throw Exception('codigo_empresa está vazio ou nulo');
      }
    } else {
      throw Exception(
        'Falha ao buscar dados do usuário',
      );
    }
  } else {
    throw Exception('Token de autenticação não encontrado');
  }
}

class User {
  final String? codigo_empresa;
  final String? usuario;
  final String? email;
  final String? nome_usuario_completo;
  final String? razaoSocial;
  final String? codigo_vendedor; // Novo campo
  final String? codigo_regiao; // Novo campo

  User({
    required this.codigo_empresa,
    required this.usuario,
    this.email,
    this.nome_usuario_completo,
    this.razaoSocial,
    this.codigo_vendedor, // Novo campo
    this.codigo_regiao, // Novo campo
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      codigo_empresa: json['codigo_empresa']?.toString(),
      email: json['email']?.toString(),
      usuario: json['nome_usuario']?.toString(),
      nome_usuario_completo: json['nome_usuario_completo']?.toString(),
      razaoSocial: json['empresa']['razao_social']?.toString(),
      codigo_vendedor: json['vendedor']?['codigo_vendedor']
          ?.toString(), // Trate a possibilidade de "vendedor" ou "codigo_vendedor" serem nulos
      codigo_regiao: json['regiao']?['codigo_regiao']
          ?.toString(), // Trate a possibilidade de "regiao" ou "codigo_regiao" serem nulos
    );
  }

  Future<void> updateUser(User updatedUser) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('codigo_empresa', updatedUser.codigo_empresa ?? '0');
    prefs.setString('nome_usuario', updatedUser.nome_usuario_completo ?? '0');
    prefs.setString('razao_social', updatedUser.razaoSocial ?? '0');
    if (updatedUser.codigo_vendedor != null) {
      // Verifique se é nulo antes de salvar
      prefs.setString('codigo_vendedor', updatedUser.codigo_vendedor!);
    }
    if (updatedUser.codigo_regiao != null) {
      // Verifique se é nulo antes de salvar
      prefs.setString('codigo_regiao', updatedUser.codigo_regiao!);
    }
  }

  Future<void> refreshUserInfo() async {
    final newUser = await fetchUserData();
    if (newUser != null) {
      await updateUser(newUser);
    }
  }
}
