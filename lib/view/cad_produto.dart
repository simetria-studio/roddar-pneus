import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roddar_pneus/class/color_config.dart';
import 'package:roddar_pneus/view/confirmar_pedido.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../class/api_config.dart';

class CadProduto extends StatefulWidget {
  final String numeroPedido;
  final int id;

  const CadProduto({required this.numeroPedido, required this.id, Key? key})
      : super(key: key);

  @override
  _CadProdutoState createState() => _CadProdutoState();
}

class _CadProdutoState extends State<CadProduto> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  bool userDataLoaded = true;
  final TextEditingController _leituraController = TextEditingController();
  final TextEditingController _produtoController = TextEditingController();
  final TextEditingController _quantidadeController = TextEditingController();
  final TextEditingController _codigoProduto = TextEditingController();
  final TextEditingController _precoUnitarioController =
      TextEditingController();
  final TextEditingController _saldoAtualController = TextEditingController();
  List<Map<String, dynamic>> produtos = [];
  List<Map<String, dynamic>> selectedProducts = [];
  String codigo_empresa = '';
  bool isLoading = false;

  Future<List<Map<String, dynamic>>> _fetchProdutos(String searchText) async {
    final prefs = await SharedPreferences.getInstance();
    final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0';
    final codigoRegiao = prefs.getString('codigo_regiao') ?? '0';

    final response = await http.post(
      Uri.parse('${ApiConfig.apiUrl}/get-produtos-with-saldo'),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "codigo_empresa": codigoEmpresa,
        "search_text": searchText,
        "codigo_regiao": codigoRegiao
      }),
    );

    if (response.statusCode == 200) {
      print('Resposta da API: ${response.body}');
      final dynamic responseData = json.decode(response.body);
      if (responseData is List<dynamic>) {
        return List<Map<String, dynamic>>.from(responseData);
      } else {
        throw Exception(
            "Falha ao carregar os produtos: dados não são uma lista");
      }
    } else {
      throw Exception("Falha ao carregar os produtos: ${response.statusCode}");
    }
  }

  // Função para salvar produtos
  Future<void> saveProducts(List<Map<String, dynamic>> products) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = json.encode(products);
    await prefs.setString('products', jsonString);
  }

// Função para carregar produtos
  Future<List<Map<String, dynamic>>> loadProducts() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('products');

    if (jsonString != null && jsonString.isNotEmpty) {
      List<dynamic> jsonData = json.decode(jsonString);
      return jsonData.cast<Map<String, dynamic>>();
    }

    return [];
  }

  Future<List<String>> sendProductsToApi(
      List<Map<String, dynamic>> products, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0';
    final url = Uri.parse('${ApiConfig.apiUrl}/store-orcamento-produtos');

    // Format the products data correctly
    final formattedProducts = products
        .map((product) => {
              'codigo_empresa': codigoEmpresa,
              'codigo_produto': product['codigo_produto'],
              'numero_pedido': product['numero_pedido'],
              'quantidade': product['quantidade'],
              'preco_unitario':
                  double.parse(product['precoUnitario'].toString()),
              'valor_total': product['quantidade'] *
                  double.parse(product['precoUnitario'].toString()),
            })
        .toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'produtos': formattedProducts,
        'numero_pedido': widget.numeroPedido,
      }),
    );

    List<String> messages = [];
    print('Resposta do servidor: ${response.body}');

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);

      if (responseBody['success'] == true) {
        messages
            .add(responseBody['message'] ?? 'Operação realizada com sucesso');

        if (!context.mounted) return messages;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmarPedido(
              orcamento:
                  List<Map<String, dynamic>>.from(responseBody['items'] ?? []),
            ),
          ),
        );
      } else {
        messages.add(responseBody['message'] ?? 'Erro ao salvar pedido');
      }
    } else {
      messages.add('Falha ao enviar produtos: ${response.statusCode}');
    }

    return messages;
  }

  Future<void> initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    codigo_empresa = prefs.getString('codigo_empresa') ??
        '0'; // Atribui o valor do SharedPreferences à variável

    setState(() {
      userDataLoaded = true;
    });
    await _fetchProdutos('');
  }

  @override
  void initState() {
    super.initState();
    _clearProducts(); // Limpa os produtos salvos ao iniciar
    _quantidadeController.text = '1';
    initializeData();
  }

  // Função para limpar os produtos salvos
  Future<void> _clearProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('products'); // Remove os produtos salvos
    produtos.clear(); // Limpa a lista local
    selectedProducts.clear(); // Limpa a lista de produtos selecionados
  }

  @override
  void dispose() {
    _clearProducts(); // Limpa os produtos ao sair da tela
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double calculateTotal() {
      double total = 0.0;

      for (var product in selectedProducts) {
        double quantidade =
            double.tryParse(product['quantidade'].toString()) ?? 0.0;
        double precoUnitario =
            double.tryParse(product['precoUnitario'].toString()) ?? 0.0;

        print(
            'Quantidade: $quantidade, Preço Unitário recuperado: $precoUnitario');

        total += quantidade * precoUnitario;
      }

      print('Total: $total');

      return total;
    }

    return Scaffold(
      key: _scaffoldMessengerKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 70,
              decoration: const BoxDecoration(
                color: ColorConfig.amarelo,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(padding: EdgeInsets.only(top: 20.0)),
                  Text(
                    'PRODUTOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: Text(
                'PEDIDO #${widget.numeroPedido}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 18,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              child: Text(
                'TOTAL: R\$${calculateTotal().toStringAsFixed(2)}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 18,
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  TypeAheadField<Map<String, dynamic>>(
                    textFieldConfiguration: TextFieldConfiguration(
                      controller: _leituraController,
                      enabled:
                          userDataLoaded, // Este campo estará desativado até que os dados sejam carregados
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        // Adicionando um indicador visual para mostrar se está carregando ou não
                        suffixIcon: !userDataLoaded
                            ? const CircularProgressIndicator()
                            : null,
                      ),
                    ),
                    suggestionsCallback: (pattern) async {
                      // Certifique-se de que os dados do usuário estão carregados antes de fazer a chamada API
                      if (userDataLoaded) {
                        final suggestions = await _fetchProdutos(pattern);
                        return suggestions;
                      } else {
                        // Retornar uma lista vazia se os dados do usuário ainda não estiverem carregados
                        return [];
                      }
                    },
                    onSuggestionSelected: (suggestion) {
                      setState(() {
                        _leituraController.text =
                            suggestion['descricao_produto'] ?? '';
                        _produtoController.text =
                            suggestion['descricao_produto'] ?? '';
                        _precoUnitarioController.text =
                            suggestion['preco_venda']?.toString() ?? '0';
                        _codigoProduto.text =
                            suggestion['codigo_produto'] ?? '';
                        _saldoAtualController.text =
                            suggestion['saldo_atual']?.toString() ?? '0';

                        print('Dados do produto: $suggestion');
                        print(
                            'Preço Unitário: ${_precoUnitarioController.text}');
                        print('Saldo Atual: ${_saldoAtualController.text}');
                      });
                    },
                    itemBuilder: (context, Map<String, dynamic> suggestion) {
                      return ListTile(
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ColorConfig.amarelo.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                suggestion['codigo_produto'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child:
                                  Text(suggestion['descricao_produto'] ?? ''),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              NumberFormat.currency(
                                      locale: 'pt_BR', symbol: 'R\$')
                                  .format(suggestion['preco_venda'] ?? 0),
                            ),
                            Text(
                              'Saldo: ${suggestion['saldo_atual'] ?? 0}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _produtoController,
                    label: 'Produto',
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _quantidadeController,
                    label: 'Quantidade',
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      // Verifica se o valor é numérico
                      if (value.isNotEmpty) {
                        final quantidade = int.tryParse(value);
                        final saldoAtual =
                            int.tryParse(_saldoAtualController.text) ?? 0;

                        if (quantidade != null && quantidade > saldoAtual) {
                          // Se a quantidade for maior que o saldo, mostra erro e reseta o valor
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Quantidade não pode ser maior que o saldo disponível'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          // Reseta para o valor máximo disponível
                          setState(() {
                            _quantidadeController.text = saldoAtual.toString();
                            // Posiciona o cursor no final do texto
                            _quantidadeController.selection =
                                TextSelection.fromPosition(
                              TextPosition(
                                  offset: _quantidadeController.text.length),
                            );
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildPrecoField(),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _saldoAtualController,
                    label: 'Saldo Atual',
                    readOnly: true,
                    enabled: false,
                    keyboardType: TextInputType.number,
                  )
                ],
              ),
            ),
            SizedBox(
              width: 300,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Validação da quantidade
                  final quantidade =
                      int.tryParse(_quantidadeController.text) ?? 0;
                  final saldoAtual =
                      int.tryParse(_saldoAtualController.text) ?? 0;

                  if (quantidade <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Quantidade deve ser maior que zero'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (quantidade > saldoAtual) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Quantidade não pode ser maior que o saldo disponível'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  setState(() {
                    double total = double.parse(_precoUnitarioController.text) *
                        double.parse(_quantidadeController.text);
                    selectedProducts.add({
                      'codigo_produto': _codigoProduto.text,
                      'codigo_empresa': codigo_empresa.toString(),
                      'quantidade': quantidade,
                      'numero_pedido': widget.numeroPedido,
                      'total': total,
                      'produto': _produtoController.text,
                      'precoUnitario': _precoUnitarioController.text,
                    });
                    print(
                        'Produto adicionado com preço: ${_precoUnitarioController.text}');
                    _produtoController.clear();
                    _precoUnitarioController.clear();
                    _codigoProduto.clear();
                    _leituraController.clear();
                    _quantidadeController.text =
                        '1'; // Adicionado esta linha para redefinir a quantidade para 1
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // <-- Radius
                  ),
                ),
                child: const Text('Adicionar Produto'),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedProducts.length,
              itemBuilder: (context, index) => _buildSelectedProductItem(
                selectedProducts[index],
                index,
              ),
            ),
            Container(
              width: 300,
              height: 50,
              margin: const EdgeInsets.only(bottom: 40),
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedProducts.isNotEmpty) {
                    try {
                      final responseMessages =
                          await sendProductsToApi(selectedProducts, context);
                      for (var message in responseMessages) {
                        _scaffoldMessengerKey.currentState?.showSnackBar(
                          SnackBar(content: Text(message)),
                        );
                      }
                    } catch (e) {
                      print("Erro ao enviar produtos: $e");
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        SnackBar(content: Text("Erro ao enviar produtos: $e")),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // <-- Radius
                  ),
                ),
                child: const Text('Enviar Pedido'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _atualizarPreco() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0';

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/update-produto-preco'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'codigo_empresa': codigoEmpresa,
          'codigo_produto': _codigoProduto.text,
          'preco_venda': double.parse(
              _precoUnitarioController.text.replaceAll(RegExp(r'[^0-9.]'), '')),
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        // Remove o cache dos produtos para forçar uma atualização na próxima busca
        await prefs.remove('produtos');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preço atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Falha ao atualizar preço');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar preço: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Atualizar o Widget do preço para incluir o botão de atualização
  Widget _buildPrecoField() => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _precoUnitarioController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Preço Unitário',
                  labelStyle: const TextStyle(color: Colors.white),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: ColorConfig.amarelo.withOpacity(0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: ColorConfig.amarelo.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: ColorConfig.amarelo,
                    ),
                  ),
                ),
              ),
            ),
            if (_codigoProduto.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: SizedBox(
                  height: 48,
                  width: 48,
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  ColorConfig.amarelo),
                            ),
                          ),
                        )
                      : Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: _atualizarPreco,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: ColorConfig.amarelo.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.update,
                                color: ColorConfig.amarelo,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
          ],
        ),
      );

  // Método para construir campos de texto padrão
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    bool enabled = true,
    TextInputType? keyboardType,
    void Function(String)? onChanged,
  }) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          enabled: enabled,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.white),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: ColorConfig.amarelo.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: ColorConfig.amarelo.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: ColorConfig.amarelo,
              ),
            ),
          ),
        ),
      );

  Widget _buildSelectedProductItem(Map<String, dynamic> product, int index) {
    TextEditingController quantityController = TextEditingController(
      text: product['quantidade']?.toString() ?? '1',
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.white.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product['produto'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quantidade:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide(
                                color: ColorConfig.amarelo.withOpacity(0.3),
                              ),
                            ),
                          ),
                          onChanged: (value) => _updateQuantity(
                              value, index, product, quantityController),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preço Unitário:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(
                          locale: 'pt_BR',
                          symbol: 'R\$',
                        ).format(
                            double.parse(product['precoUnitario'].toString())),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      selectedProducts.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateQuantity(String value, int index, Map<String, dynamic> product,
      TextEditingController controller) {
    final novaQuantidade = int.tryParse(value) ?? 0;
    final saldoAtual = int.tryParse(_saldoAtualController.text) ?? 0;

    if (novaQuantidade > saldoAtual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantidade não pode ser maior que o saldo disponível'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      controller.text = product['quantidade'].toString();
      return;
    }

    if (novaQuantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantidade deve ser maior que zero'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      controller.text = '1';
      return;
    }

    setState(() {
      selectedProducts[index]['quantidade'] = novaQuantidade;
      selectedProducts[index]['total'] = novaQuantidade *
          double.parse(selectedProducts[index]['precoUnitario'].toString());
    });
  }
}
