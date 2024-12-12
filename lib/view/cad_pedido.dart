import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:roddar_pneus/view/cad_produto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../class/api_config.dart';
import '../class/color_config.dart';
import '../class/get_user_info.dart';

class CadastroPedido extends StatefulWidget {
  const CadastroPedido({super.key});

  @override
  State<CadastroPedido> createState() => _CadastroPedidoState();
}

class _CadastroPedidoState extends State<CadastroPedido> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = _FormControllers();
  bool _isLoading = true;
  String? _codigoEmpresa;
  String? _numeroPedido;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _codigoEmpresa = prefs.getString('codigo_empresa');
      await _gerarNumeroPedido();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      _showMessage('Erro ao carregar dados iniciais: $e', isError: true);
    }
  }

  Future<void> _gerarNumeroPedido() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/gerar-numero-pedido'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'codigo_empresa': _codigoEmpresa}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _numeroPedido = data['numero_pedido'];
      }
    } catch (e) {
      _showMessage('Erro ao gerar número do pedido', isError: true);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchData(
      String endpoint, String searchText) async {
    if (_codigoEmpresa == null) return [];

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo_empresa': _codigoEmpresa,
          'search_text': searchText,
        }),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      throw Exception('Erro ${response.statusCode}');
    } catch (e) {
      _showMessage('Erro ao carregar dados: $e', isError: true);
      return [];
    }
  }

  Future<void> _salvarPedido() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/store-orcamentos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(_montarDadosPedido()),
      );

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        _navegarParaProdutos(dados['numero_pedido'], dados['id']);
      } else {
        throw Exception('Erro ao salvar pedido');
      }
    } catch (e) {
      _showMessage('Erro ao salvar pedido: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _montarDadosPedido() => {
        'codigo_empresa': _codigoEmpresa,
        'razao_social': _controllers.cliente.text,
        'valor_total': 0.0,
        'cond_pag': _controllers.condipag.text,
        'tipo_doc': _controllers.tipoDoc.text,
        'codigo_transportador': _controllers.transportador.text,
        'tipo_frete': _controllers.tipoFrete.text,
        'codigo_cliente': _controllers.codigoCliente.text,
        'observacao': _controllers.observacao.text,
      };

  void _navegarParaProdutos(String numeroPedido, int id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CadProduto(numeroPedido: numeroPedido, id: id),
      ),
    );
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('NOVO PEDIDO'),
        backgroundColor: ColorConfig.amarelo,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildClienteSection(),
                const SizedBox(height: 24),
                _buildPagamentoSection(),
                const SizedBox(height: 24),
                _buildDocumentoSection(),
                const SizedBox(height: 24),
                _buildFreteSection(),
                const SizedBox(height: 24),
                _buildObservacaoSection(),
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pedido novo'),
            Text('Total: R\$ 0,00'),
          ],
        ),
      );

  Widget _buildClienteSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TypeAheadField<Map<String, dynamic>>(
            textFieldConfiguration: TextFieldConfiguration(
              controller: _controllers.cliente,
              decoration: const InputDecoration(labelText: 'Cliente'),
            ),
            suggestionsCallback: (pattern) =>
                _fetchData('get-clientes', pattern),
            onSuggestionSelected: _onClienteSelecionado,
            itemBuilder: (context, suggestion) => ListTile(
              title: Text(suggestion['razao_social'] ?? ''),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controllers.cpfCnpj,
            decoration: const InputDecoration(labelText: 'CPF/CNPJ'),
            readOnly: true,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _controllers.telefone,
            decoration: const InputDecoration(labelText: 'Telefone'),
            readOnly: true,
          ),
        ],
      );

  Widget _buildDocumentoSection() => Column(
        children: [
          TypeAheadField<Map<String, dynamic>>(
            textFieldConfiguration: TextFieldConfiguration(
              controller: _controllers.tipoDoc,
              decoration: const InputDecoration(labelText: 'Tipo de Documento'),
            ),
            suggestionsCallback: (pattern) =>
                _fetchData('get-tipodoc', pattern),
            onSuggestionSelected: (suggestion) {
              _controllers.tipoDoc.text = suggestion['codigo_tipodoc'];
            },
            itemBuilder: (context, suggestion) => ListTile(
              title: Text(suggestion['value'] ?? ''),
            ),
          ),
          const SizedBox(height: 16),
          TypeAheadField<Map<String, dynamic>>(
            textFieldConfiguration: TextFieldConfiguration(
              controller: _controllers.transportador,
              decoration: const InputDecoration(labelText: 'Transportador'),
            ),
            suggestionsCallback: (pattern) =>
                _fetchData('get-transportadora', pattern),
            onSuggestionSelected: (suggestion) {
              _controllers.transportador.text =
                  suggestion['codigo_transportador'];
            },
            itemBuilder: (context, suggestion) => ListTile(
              title: Text(suggestion['value'] ?? ''),
            ),
          ),
        ],
      );

  Widget _buildPagamentoSection() => Column(
        children: [
          TypeAheadField<Map<String, dynamic>>(
            textFieldConfiguration: TextFieldConfiguration(
              controller: _controllers.condipag,
              decoration:
                  const InputDecoration(labelText: 'Condição de Pagamento'),
            ),
            suggestionsCallback: (pattern) =>
                _fetchData('get-condpag', pattern),
            onSuggestionSelected: (suggestion) {
              _controllers.condipag.text =
                  suggestion['codigo_condicao_pagamento'];
            },
            itemBuilder: (context, suggestion) => ListTile(
              title: Text(suggestion['value'] ?? ''),
            ),
          ),
        ],
      );

  Widget _buildFreteSection() => Column(
        children: [
          TypeAheadField<Map<String, dynamic>>(
            textFieldConfiguration: TextFieldConfiguration(
              controller: _controllers.tipoFrete,
              decoration: const InputDecoration(labelText: 'Tipo de Frete'),
            ),
            suggestionsCallback: (pattern) =>
                _fetchData('get-tipofrete', pattern),
            onSuggestionSelected: (suggestion) {
              _controllers.tipoFrete.text = suggestion['codigo'];
            },
            itemBuilder: (context, suggestion) => ListTile(
              title: Text(suggestion['value'] ?? ''),
            ),
          ),
        ],
      );

  Widget _buildObservacaoSection() => TextFormField(
        controller: _controllers.observacao,
        decoration: const InputDecoration(labelText: 'Observação'),
        maxLines: 3,
      );

  Widget _buildActionButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _salvarPedido,
            style:
                ElevatedButton.styleFrom(backgroundColor: ColorConfig.amarelo),
            child: const Text('Salvar'),
          ),
        ],
      );

  void _onClienteSelecionado(Map<String, dynamic> cliente) {
    setState(() {
      _controllers.cliente.text = cliente['razao_social'] ?? '';
      _controllers.cpfCnpj.text = cliente['cnpj_cpf'] ?? '';
      _controllers.telefone.text = cliente['telefone'] ?? '';
      _controllers.codigoCliente.text = cliente['codigo_cliente'] ?? '';
    });
  }
}

class _FormControllers {
  final cliente = TextEditingController();
  final cpfCnpj = TextEditingController();
  final telefone = TextEditingController();
  final condipag = TextEditingController();
  final tipoDoc = TextEditingController();
  final tipoFrete = TextEditingController();
  final transportador = TextEditingController();
  final codigoCliente = TextEditingController();
  final observacao = TextEditingController();

  void dispose() {
    cliente.dispose();
    cpfCnpj.dispose();
    telefone.dispose();
    condipag.dispose();
    tipoDoc.dispose();
    tipoFrete.dispose();
    transportador.dispose();
    codigoCliente.dispose();
    observacao.dispose();
  }
}
