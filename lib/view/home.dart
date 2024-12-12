import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:roddar_pneus/class/api_config.dart';
import 'package:roddar_pneus/class/get_user_info.dart';
import 'package:roddar_pneus/widgets/custom_bottom_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:roddar_pneus/theme/theme_provider.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _updateTimer;
  String? _lastUpdate; // Armazena o último timestamp conhecido

  bool isLoading = true;
  User? userData;
  String? user;
  String? razao_social;
  String? codigo_empresa;
  final StreamController _reloadController = StreamController.broadcast();
  Timer? _timer;
  // Contador de reconstrução
  int _rebuildCounter = 0;

  void getUserData() async {
    setState(() {
      isLoading = true;
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userNome = prefs.getString('nome_usuario');
    String? codigoEmpresa = prefs.getString('codigo_empresa');
    String? razaoSocial = prefs.getString('razao_social');
    String? usuario = prefs.getString('usuario');
    setState(() {
      user = userNome;
      razao_social = razaoSocial;
      codigo_empresa = codigoEmpresa;
      isLoading = false; // Dados carregados
      _rebuildCounter++;
    });
  }

  void getFetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final newUser = await fetchUserData();
      if (newUser != null) {
        setState(() {
          userData = newUser;
          user = newUser.nome_usuario_completo ?? "Usuário Desconhecido";
          razao_social = newUser.razaoSocial ?? "Empresa Desconhecida";
          codigo_empresa = newUser.codigo_empresa ?? "0";

          isLoading = false;
        });
      } else {
        // Sem alterações, apenas pare o loading
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erro ao buscar dados: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData();
    getFetchData();

    // Configura o Timer para verificar atualizações a cada 30 segundos
    _updateTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _checkForUpdates();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkForUpdates() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token de autenticação não encontrado');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/check-updates'),
        body: {'access_token': token},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final String? serverUpdate = jsonData['last_update'];
        print(serverUpdate);
        if (_lastUpdate != serverUpdate) {
          setState(() {
            _lastUpdate = serverUpdate;
          });
          getFetchData();
        }
      } else if (response.statusCode == 429) {
        print('Muitas requisições - aguardando antes de tentar novamente');
        await Future.delayed(const Duration(seconds: 60)); // Aguarda 1 minuto
      } else {
        throw Exception(
            'Erro ao verificar atualizações: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao verificar atualizações: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Bem-vindo ao RODDAR PNEUS')),
        backgroundColor: Theme.of(context).primaryColor,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeProvider>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: const Color.fromARGB(255, 230, 228, 228),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 10),
                          Text(
                            "Carregando...",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.account_circle,
                          color: Color.fromARGB(255, 219, 101, 5),
                          size: 50,
                        ),
                        title: Text(
                          'Olá, ${user ?? "Carregando..."} 👋',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 3, 3, 3),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Empresa atual:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 3, 3, 3),
                              ),
                            ),
                            Text(
                              razao_social ?? "Carregando...",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 3, 3, 3),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Código:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 3, 3, 3),
                              ),
                            ),
                            Text(
                              codigo_empresa ?? "Carregando...",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color.fromARGB(255, 3, 3, 3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
      floatingActionButton: FloatBtn.build(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FloatBtn.bottomAppBar(context),
    );
  }
}
