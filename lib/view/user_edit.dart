import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roddar_pneus/class/api_config.dart';
import 'package:roddar_pneus/class/color_config.dart';
import 'package:roddar_pneus/widgets/custom_bottom_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserEdit extends StatefulWidget {
  const UserEdit({Key? key}) : super(key: key);

  @override
  State<UserEdit> createState() => _UserEditState();
}

class _UserEditState extends State<UserEdit> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  List<Map<String, dynamic>> _empresas = [];
  String? _empresaSelecionada;
  String? _razaoSocial;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkRazaoSocialUpdate(),
    );
  }

  Future<void> _initializeData() async {
    try {
      await Future.wait([
        _fetchEmpresas(),
        _getUserData(),
      ]);
    } catch (e) {
      _showMessage('Erro ao carregar dados iniciais: $e', isError: true);
    }
  }

  Future<void> _getUserData() async {
    if (!mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final razaoSocial = prefs.getString('razao_social');
      if (mounted) setState(() => _razaoSocial = razaoSocial);
    } catch (e) {
      _showMessage('Erro ao carregar dados do usuário', isError: true);
    }
  }

  Future<void> _fetchEmpresas() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuario = prefs.getString('usuario');
      if (usuario == null) throw Exception('Usuário não encontrado');

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/get-empresas'),
        body: {'usuario': usuario},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // print('response.body: ${response.body}');
        final jsonData = jsonDecode(response.body);
        final empresas = jsonData['empresas'] as List;

        setState(() {
          _empresas = empresas
              .map<Map<String, dynamic>>((e) => {
                    'codigo': e['codigo_empresa'].toString(),
                    'nome': e['nome_fantasia'].toString(),
                  })
              .toList()
            ..sort((a, b) => a['nome']
                .toString()
                .toLowerCase()
                .compareTo(b['nome'].toString().toLowerCase()));
        });
      } else {
        throw Exception(
            'Erro ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showMessage('Erro ao carregar empresas: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmpresaSelection() async {
    if (_empresaSelecionada == null) {
      _showMessage('Selecione uma empresa', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token não encontrado');

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/troca-empresa-usuario'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'access_token': token,
          'codigo_empresa': _empresaSelecionada,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final novaRazaoSocial =
            responseData['user']?['empresa']?['razao_social'];
        if (novaRazaoSocial == null) {
          throw Exception('Dados inválidos na resposta');
        }

        await _updateLocalData(novaRazaoSocial);
        _showMessage('Empresa alterada com sucesso');
      } else {
        throw Exception(responseData['message'] ?? 'Erro ao atualizar empresa');
      }
    } catch (e) {
      print('Erro ao atualizar empresa: $e');
      _showMessage('Erro ao atualizar empresa: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLocalData(String novaRazaoSocial) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('razao_social', novaRazaoSocial);
    await prefs.setString('codigo_empresa', _empresaSelecionada!);

    if (mounted) setState(() => _razaoSocial = novaRazaoSocial);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Widgets de UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ColorConfig.amarelo.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: _isLoading ? const LoadingIndicator() : _buildBody(),
      ),
      floatingActionButton: FloatBtn.build(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FloatBtn.bottomAppBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: const Text(
          'Editar Usuário',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: ColorConfig.amarelo,
        elevation: 0,
      );

  Widget _buildBody() => Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildCurrentCompany(),
              const SizedBox(height: 24),
              _buildCompanySelector(),
              const SizedBox(height: 24),
              _buildConfirmButton(),
            ],
          ),
        ),
      );

  Widget _buildCurrentCompany() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações Atuais',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<SharedPreferences>(
              future: SharedPreferences.getInstance(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final prefs = snapshot.data!;
                final codigoRegiao = prefs.getString('codigo_regiao') ?? 'N/D';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      'Empresa:',
                      _razaoSocial ?? "Não definida",
                      Icons.business,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Região:',
                      codigoRegiao,
                      Icons.location_on,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );

  Widget _buildInfoRow(String label, String value, IconData icon) => Row(
        children: [
          Icon(
            icon,
            color: ColorConfig.amarelo,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildCompanySelector() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecione a Empresa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _empresaSelecionada,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Empresas',
                labelStyle: const TextStyle(color: Colors.black54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: ColorConfig.amarelo),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                prefixIcon: const Icon(Icons.business_outlined),
              ),
              items: _empresas
                  .map((empresa) => DropdownMenuItem<String>(
                        value: empresa['codigo'],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                empresa['nome'],
                                style: const TextStyle(fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: ColorConfig.amarelo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                empresa['codigo'],
                                style: TextStyle(
                                  color: ColorConfig.amarelo,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _empresaSelecionada = value),
            ),
          ],
        ),
      );

  Widget _buildConfirmButton() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton(
          onPressed: _empresaSelecionada != null ? _handleEmpresaSelection : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConfig.amarelo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 4,
            shadowColor: ColorConfig.amarelo.withOpacity(0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline),
              const SizedBox(width: 8),
              const Text(
                'Confirmar Alteração',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );

  Future<void> _checkRazaoSocialUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final novaRazaoSocial = prefs.getString('razao_social');

      if (novaRazaoSocial != null && novaRazaoSocial != _razaoSocial) {
        if (mounted) {
          setState(() => _razaoSocial = novaRazaoSocial);
          await _fetchEmpresas();
        }
      }
    } catch (e) {
      _showMessage('Erro ao verificar atualização', isError: true);
    }
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(ColorConfig.amarelo),
      ),
    );
  }
}
