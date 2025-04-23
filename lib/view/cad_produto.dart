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
      final dynamic responseData = json.decode(response.body);
      print('Dados recebidos da API: $responseData');
      
      if (responseData is List<dynamic>) {
        final produtos = List<Map<String, dynamic>>.from(responseData);
        print('Primeiro produto da lista: ${produtos.isNotEmpty ? produtos.first : null}');
        return produtos;
      } else {
        throw Exception("Falha ao carregar os produtos: dados não são uma lista");
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
              'codigo_produto': product['codigo_produto'] ?? '',
              'numero_pedido': product['numero_pedido'],
              'quantidade': product['quantidade'],
              'preco_unitario': double.parse(product['precoUnitario'].toString()),
              'valor_total': product['quantidade'] *
                  double.parse(product['precoUnitario'].toString()),
            })
        .toList();

    print('Formatted Products: ${formattedProducts}');

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
        messages.add(responseBody['message'] ?? 'Operação realizada com sucesso');

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
        double quantidade = double.tryParse(product['quantidade'].toString()) ?? 0.0;
        double precoUnitario = double.tryParse(product['precoUnitario'].toString()) ?? 0.0;
        total += quantidade * precoUnitario;
      }
      return total;
    }

    return Scaffold(
      key: _scaffoldMessengerKey,
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
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: ColorConfig.amarelo,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'PRODUTOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PEDIDO #${widget.numeroPedido}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TOTAL: R\$${calculateTotal().toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
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
                  children: [
                    TypeAheadField<Map<String, dynamic>>(
                      suggestionsCallback: (pattern) => _fetchProdutos(pattern),
                      onSelected: _onProdutoSelecionado,
                      itemBuilder: (context, suggestion) => ListTile(
                        title: Text(
                          suggestion['descricao_produto'] ?? suggestion['descricao'] ?? '',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        subtitle: Text(
                          'Código: ${suggestion['codigo_produto']}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: _produtoController,
                          focusNode: focusNode,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            labelText: 'Produto',
                            hintText: 'Digite para buscar',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: ColorConfig.amarelo),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _produtoController,
                      label: 'Produto',
                      icon: Icons.shopping_cart,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _quantidadeController,
                      label: 'Quantidade',
                      keyboardType: TextInputType.number,
                      icon: Icons.numbers,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          final quantidade = int.tryParse(value);
                          final saldoAtual = int.tryParse(_saldoAtualController.text) ?? 0;

                          if (quantidade != null && quantidade > saldoAtual) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Quantidade não pode ser maior que o saldo disponível'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                            setState(() {
                              _quantidadeController.text = saldoAtual.toString();
                              _quantidadeController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _quantidadeController.text.length),
                              );
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildPrecoField(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _saldoAtualController,
                      label: 'Saldo Atual',
                      readOnly: true,
                      enabled: false,
                      keyboardType: TextInputType.number,
                      icon: Icons.inventory_2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final quantidade = int.tryParse(_quantidadeController.text) ?? 0;
                    final saldoAtual = int.tryParse(_saldoAtualController.text) ?? 0;

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
                          content: Text('Quantidade não pode ser maior que o saldo disponível'),
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
                      _produtoController.clear();
                      _precoUnitarioController.clear();
                      _codigoProduto.clear();
                      _leituraController.clear();
                      _quantidadeController.text = '1';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConfig.amarelo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    shadowColor: ColorConfig.amarelo.withOpacity(0.3),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline),
                      SizedBox(width: 8),
                      Text(
                        'Adicionar Produto',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (selectedProducts.isNotEmpty)
                Container(
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
                    children: [
                      const Text(
                        'Produtos Selecionados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...selectedProducts.asMap().entries.map((entry) => 
                        _buildSelectedProductItem(entry.value, entry.key)
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              if (selectedProducts.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedProducts.isNotEmpty) {
                        try {
                          final responseMessages = await sendProductsToApi(selectedProducts, context);
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
                      backgroundColor: ColorConfig.amarelo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: ColorConfig.amarelo.withOpacity(0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline),
                        SizedBox(width: 8),
                        Text(
                          'Enviar Pedido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _atualizarPreco() async {
    setState(() {
      isLoading = true;
    });

    
  }

  // Atualizar o Widget do preço para formatar para 00.00
  Widget _buildPrecoField() => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: TextFormField(
          controller: _precoUnitarioController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.black87),
          onChanged: (value) {
            if (value.isNotEmpty) {
              // Remove formatação existente
              String numericValue = value.replaceAll(RegExp(r'[^0-9]'), '');
              
              // Converte para valor numérico com duas casas decimais
              double doubleValue = numericValue.isEmpty ? 0.0 : int.parse(numericValue) / 100;
              
              // Formata para exibir sempre com duas casas decimais
              String formattedValue = doubleValue.toStringAsFixed(2);
              
              // Atualiza o controller com o valor formatado
              _precoUnitarioController.value = TextEditingValue(
                text: formattedValue,
                selection: TextSelection.collapsed(offset: formattedValue.length),
              );
            }
          },
          decoration: InputDecoration(
            labelText: 'Preço Unitário (R\$)',
            labelStyle: const TextStyle(color: Colors.black54),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: ColorConfig.amarelo),
            ),
            prefixIcon: const Icon(Icons.attach_money),
            hintText: '00.00',
          ),
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
    IconData? icon,
  }) =>
      TextField(
        controller: controller,
        readOnly: readOnly,
        enabled: enabled,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ColorConfig.amarelo),
          ),
        ),
      );

  Widget _buildSelectedProductItem(Map<String, dynamic> product, int index) {
    TextEditingController quantityController = TextEditingController(
      text: product['quantidade']?.toString() ?? '1',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product['produto'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quantidade',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
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
                        'Preço Unitário',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(
                          locale: 'pt_BR',
                          symbol: 'R\$',
                        ).format(double.parse(product['precoUnitario'].toString())),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
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

  void _onProdutoSelecionado(Map<String, dynamic> produto) {
    print('Produto selecionado completo: $produto');
    
    final codigo = produto['codigo_produto']?.toString() ?? '';
    final descricao = produto['descricao_produto'] ?? produto['descricao'] ?? '';
    
    print('Código extraído: $codigo');
    print('Descrição extraída: $descricao');

    setState(() {
      _leituraController.text = descricao;
      _produtoController.text = descricao;
      _precoUnitarioController.text = produto['preco_venda']?.toString() ?? '0';
      _codigoProduto.text = codigo;
      _saldoAtualController.text = produto['saldo_atual']?.toString() ?? '0';
    });

    print('Código após setState: ${_codigoProduto.text}');
  }
}
