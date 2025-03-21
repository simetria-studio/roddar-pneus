import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

Future<void> saveUserHash(User user) async {
  final prefs = await SharedPreferences.getInstance();

  print('Salvando dados:'); // Debug logs
  print('codigo_regiao: ${user.codigo_regiao}');
  print('codigo_vendedor: ${user.codigo_vend}');

  await prefs.setString('user_hash', user.codigo_empresa ?? '');
  await prefs.setString('codigo_empresa', user.codigo_empresa ?? '0');
  await prefs.setString(
      'nome_usuario', user.nome_usuario_completo ?? 'Usuário Desconhecido');
  await prefs.setString(
      'razao_social', user.razaoSocial ?? 'Empresa Desconhecida');
  await prefs.setString('usuario', user.usuario ?? 'usuário_indefinido');
  await prefs.setString('codigo_vendedor', user.codigo_vend ?? '0');
  await prefs.setString('codigo_regiao', user.codigo_regiao ?? '0');

  // Verificar se foi salvo
  final savedRegiao = prefs.getString('codigo_regiao');
  print('Código região salvo no prefs: $savedRegiao');
}

Future<String?> getUserHash() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_hash');
}

Future<User?> fetchUserData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('token');
  print(token);
  if (token != null) {
    final response = await http.post(
      Uri.parse('${ApiConfig.apiUrl}/get-user-info'),
      body: {
        'access_token': token,
      },
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      // print('Dados recebidos: $jsonData'); // Log para debug

      if (jsonData['codigo_empresa'] != null &&
          jsonData['codigo_empresa'].toString().isNotEmpty) {
        final user = User.fromJson(jsonData);

        // Remova a verificação de hash para garantir que sempre atualize
        await saveUserHash(user);

        // Log para debug
        // print('Salvando código região: ${user.codigo_regiao}');
        // print('Salvando código vendedor: ${user.codigo_vend}');

        return user;
      } else {
        throw Exception('codigo_empresa está vazio ou nulo');
      }
    } else {
      throw Exception('Falha ao buscar dados do usuário');
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
  final String? codigo_vend; // Novo campo
  final String? codigo_regiao; // Novo campo

  User({
    required this.codigo_empresa,
    required this.usuario,
    this.email,
    this.nome_usuario_completo,
    this.razaoSocial,
    this.codigo_vend, // Novo campo
    this.codigo_regiao, // Novo campo
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // print('Dados da região: ${json['regiao']}'); // Debug log
    return User(
      codigo_empresa: json['codigo_empresa']?.toString(),
      email: json['email']?.toString(),
      usuario: json['nome_usuario']?.toString(),
      nome_usuario_completo: json['nome_usuario_completo']?.toString(),
      razaoSocial: json['empresa']?['razao_social']?.toString(),
      codigo_vend: json['vendedor']?['codigo_vend']?.toString(),
      codigo_regiao: json['regiao']?['codigo_regiao']
          ?.toString(), // Acesso correto ao campo aninhado
    );
  }

  Future<void> updateUser(User updatedUser) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('codigo_empresa', updatedUser.codigo_empresa ?? '0');
    await prefs.setString(
        'nome_usuario', updatedUser.nome_usuario_completo ?? '0');
    await prefs.setString('razao_social', updatedUser.razaoSocial ?? '0');
    await prefs.setString('codigo_vendedor', updatedUser.codigo_vend ?? '0');
    await prefs.setString('codigo_regiao', updatedUser.codigo_regiao ?? '0');
  }

  Future<void> refreshUserInfo() async {
    final newUser = await fetchUserData();
    if (newUser != null) {
      await updateUser(newUser);
    }
  }
}
