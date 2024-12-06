import 'package:flutter/material.dart';
import 'package:roddar_pneus/class/api_config.dart';
import 'package:roddar_pneus/view/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:roddar_pneus/class/color_config.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String apiUrl = ApiConfig.apiUrl;
  final highlightColor = const Color.fromARGB(255, 240, 118, 5);
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  Future<void> _login() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? existingToken = prefs.getString('token');
    if (existingToken != null) {
      // Já existe um token salvo, redirecione para a tela Home ou faça qualquer ação necessária

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      return; // Encerra a função para evitar a execução do login novamente
    }
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final String usuario = _usuarioController.text;
    final String password = _passwordController.text;

    // Aqui você fará a chamada para a sua API com os dados do login
    final response = await http.post(
      Uri.parse('${ApiConfig.apiUrl}/login-app'),
      body: {
        'usuario': usuario,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      // O login foi bem-sucedido
      // Você pode redirecionar o usuário para a próxima tela ou fazer qualquer ação necessária

      final responseData = json.decode(response.body);
      final String token = responseData['access_token'];

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
      print('Login bem-sucedido!');
      print('Token: $token');
    } else {
      // O login falhou
      // Você pode exibir uma mensagem de erro para o usuário ou fazer quaslquer tratamento necessário
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha no login. Tente novamente.'),
        ),
      );
      print('Falha no login. Tente novamente.');
    }
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.preto,
      body: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 219, 101, 5),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 360,
                        height: 115,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Seja bem vindo(a)',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Faça login para acessar sua conta',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ),
              Container(
                child: Column(
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      margin: const EdgeInsets.only(top: 80.0),
                      child: Image.asset(
                        "assets/img/RODDAR.png",
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin:
                    const EdgeInsets.only(top: 35.0, left: 16.0, right: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    // ignore: prefer_const_literals_to_create_immutables
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _usuarioController,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Usuário',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _passwordController,
                          keyboardType: TextInputType.text,
                          validator: (senha) {
                            if (senha == null || senha.isEmpty) {
                              return 'Por favor, digite sua senha!';
                            } else if (senha.length < 5) {
                              return 'Por favor, senha maior que 5 caracteres';
                            }
                            return null;
                          },
                          obscureText: _obscureText,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            focusColor: Colors.white,
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            labelText: 'Senha',
                            labelStyle: const TextStyle(color: Colors.white),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin:
                    const EdgeInsets.only(top: 20.0, left: 12.0, right: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 80,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 219, 101, 5),
                      ),
                      onPressed: _login,
                      child: const Text(
                        'ENTRAR',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 10.0, right: 18.0),
                          child: GestureDetector(
                            onTap: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //       builder: (context) =>
                              //           const RecuperarSenhaPage()),
                              // );
                            },
                            child: const Text(
                              'Esqueceu sua senha?',
                              style: TextStyle(
                                color: Color.fromARGB(255, 219, 101, 5),
                                fontSize: 14,
                                fontFamily: 'Outfit',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
