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
  String? _codigoVendedor;
  String? _codigoRegiao;

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
      _codigoVendedor = prefs.getString('codigo_vendedor') ?? '0';
      _codigoRegiao = prefs.getString('codigo_regiao') ?? '0';
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
          'codigo_regiao': _codigoRegiao,
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
        'cond_pag': _controllers.codigoCondPag.text,
        'tipo_doc': _controllers.codigoTipoDoc.text,
        'codigo_transportador': _controllers.codigoTransportador.text,
        'tipo_frete': _controllers.codigoTipoFrete.text,
        'codigo_cliente': _controllers.codigoCliente.text,
        'codigo_vendedor': _codigoVendedor,
        'codigo_regiao': _codigoRegiao,
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
        elevation: 0,
      ),
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
        child: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pedido novo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              'Total: R\$ 0,00',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorConfig.amarelo,
              ),
            ),
          ],
        ),
      );

  Widget _buildClienteSection() => _buildSection(
        title: 'Cliente',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TypeAheadField<Map<String, dynamic>>(
              suggestionsCallback: (pattern) {
                return _fetchData('get-clientes', pattern);
              },
              onSelected: _onClienteSelecionado,
              itemBuilder: (context, suggestion) => ListTile(
                title: Text(
                  suggestion['razao_social'] ?? '',
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: _controllers.cliente,
                  focusNode: focusNode,
                  onChanged: (value) {
                    // Ensure controller value is synced
                    controller.text = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Cliente',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers.cpfCnpj,
              decoration: InputDecoration(
                labelText: 'CPF/CNPJ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controllers.telefone,
              decoration: InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              readOnly: true,
            ),
          ],
        ),
      );

  Widget _buildDocumentoSection() => _buildSection(
        title: 'Documento',
        child: Column(
          children: [
            TypeAheadField<Map<String, dynamic>>(
              suggestionsCallback: (pattern) {
                return _fetchData('get-tipodoc', pattern);
              },
              onSelected: (suggestion) {
                setState(() {
                  _controllers.tipoDoc.text = suggestion['value'] ?? '';
                  _controllers.codigoTipoDoc.text = suggestion['codigo_tipodoc']?.toString() ?? '';
                });
              },
              itemBuilder: (context, suggestion) => ListTile(
                title: Text(
                  suggestion['value'] ?? '',
                  style: const TextStyle(color: Colors.black87),
                ),
                subtitle: Text(
                  'Código: ${suggestion['codigo_tipodoc'] ?? ''}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: _controllers.tipoDoc,
                  focusNode: focusNode,
                  onChanged: (value) {
                    // Ensure controller value is synced
                    controller.text = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Tipo de Documento',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TypeAheadField<Map<String, dynamic>>(
              suggestionsCallback: (pattern) {
                return _fetchData('get-transportadora', pattern);
              },
              onSelected: (suggestion) {
                setState(() {
                  _controllers.transportador.text = suggestion['value'] ?? '';
                  _controllers.codigoTransportador.text = suggestion['codigo_transportador']?.toString() ?? '';
                });
              },
              itemBuilder: (context, suggestion) => ListTile(
                title: Text(
                  suggestion['value'] ?? '',
                  style: const TextStyle(color: Colors.black87),
                ),
                subtitle: Text(
                  'Código: ${suggestion['codigo_transportador'] ?? ''}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: _controllers.transportador,
                  focusNode: focusNode,
                  onChanged: (value) {
                    // Ensure controller value is synced
                    controller.text = value;
                  },
                  decoration: InputDecoration(
                    labelText: 'Transportador',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                );
              },
            ),
          ],
        ),
      );

  Widget _buildPagamentoSection() => _buildSection(
        title: 'Pagamento',
        child: TypeAheadField<Map<String, dynamic>>(
          suggestionsCallback: (pattern) {
            return _fetchData('get-condpag', pattern);
          },
          onSelected: (suggestion) {
            setState(() {
              _controllers.condipag.text = suggestion['value'] ?? '';
              _controllers.codigoCondPag.text = suggestion['codigo_condicao_pagamento']?.toString() ?? '';
            });
          },
          itemBuilder: (context, suggestion) => ListTile(
            title: Text(
              suggestion['value'] ?? '',
              style: const TextStyle(color: Colors.black87),
            ),
            subtitle: Text(
              'Código: ${suggestion['codigo_condicao_pagamento'] ?? ''}',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          builder: (context, controller, focusNode) {
            return TextField(
              controller: _controllers.condipag,
              focusNode: focusNode,
              onChanged: (value) {
                // Ensure controller value is synced
                controller.text = value;
              },
              decoration: InputDecoration(
                labelText: 'Condição de Pagamento',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            );
          },
        ),
      );

  Widget _buildFreteSection() => _buildSection(
        title: 'Frete',
        child: TypeAheadField<Map<String, dynamic>>(
          suggestionsCallback: (pattern) {
            return _fetchData('get-tipofrete', pattern);
          },
          onSelected: (suggestion) {
            setState(() {
              _controllers.tipoFrete.text = suggestion['value'] ?? '';
              _controllers.codigoTipoFrete.text = suggestion['codigo']?.toString() ?? '';
            });
          },
          itemBuilder: (context, suggestion) => ListTile(
            title: Text(
              suggestion['value'] ?? '',
              style: const TextStyle(color: Colors.black87),
            ),
            subtitle: Text(
              'Código: ${suggestion['codigo'] ?? ''}',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          builder: (context, controller, focusNode) {
            return TextField(
              controller: _controllers.tipoFrete,
              focusNode: focusNode,
              onChanged: (value) {
                // Ensure controller value is synced
                controller.text = value;
              },
              decoration: InputDecoration(
                labelText: 'Tipo de Frete',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            );
          },
        ),
      );

  Widget _buildObservacaoSection() => _buildSection(
        title: 'Observação',
        child: TextFormField(
          controller: _controllers.observacao,
          decoration: InputDecoration(
            labelText: 'Observação',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          maxLines: 3,
        ),
      );

  Widget _buildSection({required String title, required Widget child}) => Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );

  Widget _buildActionButtons() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                  elevation: 0,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _salvarPedido,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Salvar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConfig.amarelo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: ColorConfig.amarelo.withOpacity(0.5),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
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
  final codigoCondPag = TextEditingController();
  final tipoDoc = TextEditingController();
  final codigoTipoDoc = TextEditingController();
  final tipoFrete = TextEditingController();
  final codigoTipoFrete = TextEditingController();
  final transportador = TextEditingController();
  final codigoTransportador = TextEditingController();
  final codigoCliente = TextEditingController();
  final observacao = TextEditingController();

  void dispose() {
    cliente.dispose();
    cpfCnpj.dispose();
    telefone.dispose();
    condipag.dispose();
    codigoCondPag.dispose();
    tipoDoc.dispose();
    codigoTipoDoc.dispose();
    tipoFrete.dispose();
    codigoTipoFrete.dispose();
    transportador.dispose();
    codigoTransportador.dispose();
    codigoCliente.dispose();
    observacao.dispose();
  }
}
