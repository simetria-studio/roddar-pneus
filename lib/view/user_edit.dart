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
  final StreamController<bool> _reloadController =
      StreamController<bool>.broadcast();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _empresas = [];
  String? _empresaSelecionada;
  String? _razaoSocial;
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeData();

    // Verifica a cada 2 segundos se houve alteração na razão social
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _checkRazaoSocialUpdate();
      }
    });
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchEmpresas(),
      _getUserData(),
    ]);
  }

  Future<void> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final razaoSocial = prefs.getString('razao_social');
    setState(() => _razaoSocial = razaoSocial);
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
        final jsonData = jsonDecode(response.body);
        final empresas = jsonData['empresas'] as List;

        setState(() {
          _empresas = empresas
              .map<Map<String, dynamic>>((e) => {
                    'codigo': e['codigo_empresa'].toString(),
                    'nome': e['nome_fantasia'].toString(),
                  })
              .toList();
        });
      } else {
        throw Exception('Erro ao buscar empresas');
      }
    } catch (e) {
      _showError('Erro ao carregar empresas');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmpresaSelection() async {
    if (_empresaSelecionada == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token'); // Recupera o access_token

      if (token == null) {
        throw Exception('Token de acesso não encontrado');
      }

      // URL para o endpoint de atualização da empresa
      final url = Uri.parse('${ApiConfig.apiUrl}/troca-empresa-usuario');

      // Faz a requisição POST
      final response = await http.post(
        url,
        body: {
          'access_token': token,
          'codigo_empresa': _empresaSelecionada,
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          // Atualização bem-sucedida
          _showSuccess('Empresa alterada para com sucesso');

          // Atualiza os dados no SharedPreferences (opcional)
          prefs.setString('codigo_empresa', _empresaSelecionada!);
        } else {
          throw Exception(
              responseData['message'] ?? 'Erro ao atualizar empresa');
        }
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _showError('Erro ao atualizar empresa: $e');
    }
  }

  Future<void> _checkRazaoSocialUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final novaRazaoSocial = prefs.getString('razao_social');

      // Verifica se houve mudança na razão social
      if (novaRazaoSocial != null && novaRazaoSocial != _razaoSocial) {
        setState(() => _razaoSocial = novaRazaoSocial);

        // Recarrega a página para atualizar todos os dados
        await _reloadPage();

        // Mostra mensagem de sucesso
        _showSuccess('Empresa alterada para: $novaRazaoSocial');
      }
    } catch (e) {
      print('Erro ao verificar atualização: $e');
    }
  }

  Future<void> _reloadPage() async {
    setState(() => _isLoading = true);

    try {
      // Recarrega todos os dados necessários
      await Future.wait([
        _fetchEmpresas(),
        _getUserData(),
      ]);

      // Opcional: Navegar para a home após atualização
      if (mounted) {}
    } catch (e) {
      _showError('Erro ao atualizar dados: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reloadController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoading() : _buildBody(),
      floatingActionButton: FloatBtn.build(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FloatBtn.bottomAppBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Editar Usuário',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      elevation: 4,
      backgroundColor: ColorConfig.amarelo,
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentCompany(),
                const SizedBox(height: 16),
                _buildCompanySelector(),
                const SizedBox(height: 24),
                _buildConfirmButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentCompany() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Empresa atual: $_razaoSocial'),
        const SizedBox(height: 16),
        const Text(
          'Selecione a Empresa',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanySelector() {
    return DropdownButtonFormField<String>(
      value: _empresaSelecionada,
      isExpanded: true,
      decoration: InputDecoration(
        focusColor: Colors.white,
        labelText: 'Empresas',
        labelStyle: const TextStyle(color: Colors.white),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      items: _empresas.map((empresa) {
        return DropdownMenuItem<String>(
          value: empresa['codigo'],
          child: Text(
            empresa['nome'],
            style: const TextStyle(fontSize: 16),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _empresaSelecionada = value),
    );
  }

  Widget _buildConfirmButton() {
    return ElevatedButton(
      onPressed: _empresaSelecionada != null ? _handleEmpresaSelection : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConfig.amarelo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: const Text(
        'Confirmar',
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}
