import 'dart:async';

import 'package:flutter/material.dart';
import 'package:roddar_pneus/class/get_user_info.dart';
import 'package:roddar_pneus/widgets/custom_bottom_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:roddar_pneus/theme/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? userData;
  String? user;
  String? razao_social;
  String? codigo_empresa;
  final StreamController _reloadController = StreamController.broadcast();
  Timer? _timer;
  // Contador de reconstrução
  int _rebuildCounter = 0;

  void getFetchData() async {
    try {
      userData = await fetchUserData();
      if (userData != null) {
      } else {}
    } catch (e) {}
  }

  void getUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userNome = prefs.getString('nome_usuario');
    String? codigoEmpresa = prefs.getString('codigo_empresa');
    String? razaoSocial = prefs.getString('razao_social');
    String? usuario = prefs.getString('usuario');
    setState(() {
      user = userNome;
      razao_social = razaoSocial;
      codigo_empresa = codigoEmpresa;

      // Incrementa o contador para forçar a reconstrução
      _rebuildCounter++;
    });
  }

  @override
  void initState() {
    super.initState();
    getUserData();
    getFetchData();

    _reloadController.stream.listen((event) {
      getFetchData();
      getUserData();
    });

    // Configuração do Timer para emitir um evento a cada 4 segundos
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _reloadController.add(true);
    });
  }

  @override
  void dispose() {
    _reloadController.close();
    _timer?.cancel();
    super.dispose();
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.account_circle,
                    color: Color.fromARGB(255, 219, 101, 5),
                    size: 50,
                  ),
                  title: Text(
                    'Olá, $user 👋',
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
                        '$razao_social',
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
                        '$codigo_empresa',
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
      floatingActionButton: FloatBtn.build(
          context), // Chama o FloatingActionButton da classe FloatBtn
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FloatBtn.bottomAppBar(context),
    );
  }
}
