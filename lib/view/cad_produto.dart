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

  Future<List<Map<String, dynamic>>> _fetchProdutos(String searchText) async {
    // Verificar se os produtos já estão salvos no SharedPreferences
    if (searchText.isEmpty) {
      List<Map<String, dynamic>> savedProducts = await loadProducts();
      if (savedProducts.isNotEmpty) {
        return savedProducts;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0';

    final response = await http.post(
      Uri.parse('${ApiConfig.apiUrl}/get-produtos'),
      body: json
          .encode({"codigo_empresa": codigoEmpresa, "search_text": searchText}),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      print(response.body);
      final dynamic responseData = json.decode(response.body);
      if (responseData is List<dynamic>) {
        final List<Map<String, dynamic>> produtos =
            List<Map<String, dynamic>>.from(responseData);

        // Salvar produtos no SharedPreferences
        if (searchText.isEmpty) {
          saveProducts(produtos);
        }

        return produtos;
      } else {
        throw Exception(
            "Falha ao carregar os clientes: dados não são uma lista");
      }
    } else {
      throw Exception("Falha ao carregar os clientes");
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
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(products),
    );

    List<String> messages = [];

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      print('Resposta do servidor: ${response.body}');
      if (responseBody is List) {
        messages = responseBody
            .map((item) =>
                item['message']?.toString() ?? 'Mensagem não disponível')
            .toList();
        // Adicionando a navegação para a nova página aqui
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ConfirmarPedido(orcamento: selectedProducts)),
        );
      } else {
        messages.add('Resposta inesperada da API.');
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
    _quantidadeController.text = '1';
// Define o valor padrão para 1
    initializeData();
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
                        _precoUnitarioController.text =
                            suggestion['preco_venda']?.toString() ?? '0';
                        _saldoAtualController.text = suggestion['saldo']?[0]
                                    ['saldo_atual']
                                ?.toString() ??
                            '0';
                        print(
                            'Preço Unitário Controller: ${_precoUnitarioController.text}');
                      });
                    },
                    itemBuilder: (context, Map<String, dynamic> suggestion) {
                      // Renderize a sugestão aqui
                      return ListTile(
                        title: Text(suggestion['descricao_produto'] ?? ''),
                        subtitle: Text(NumberFormat.currency(
                                    locale: 'pt_BR', symbol: 'R\$')
                                .format(double.parse(
                                    suggestion['preco_venda'].toString())) ??
                            ''),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _produtoController,
                    decoration: const InputDecoration(
                      labelText: 'Produto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _quantidadeController,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _precoUnitarioController,
                    decoration: const InputDecoration(
                      labelText: 'Preço Unitário',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _saldoAtualController,
                    decoration: const InputDecoration(
                      labelText: 'Saldo Atual',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    readOnly: true, // Define o campo como somente leitura
                  )
                ],
              ),
            ),
            SizedBox(
              width: 300,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    double total = double.parse(_precoUnitarioController.text) *
                        double.parse(_quantidadeController.text);
                    selectedProducts.add({
                      'codigo_produto': _codigoProduto.text,
                      'codigo_empresa': codigo_empresa.toString(),
                      'quantidade': int.parse(_quantidadeController.text),
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
              shrinkWrap: true, // Use isso para evitar erros de renderização
              itemCount: selectedProducts.length,
              itemBuilder: (context, index) {
                final product = selectedProducts[index];
                TextEditingController quantityController =
                    TextEditingController(
                        text: product['quantidade']?.toString() ?? '1');
                return ListTile(
                  title: Text(product['produto'] ?? ''),
                  subtitle: Row(
                    children: [
                      const Text('Quantidade: '),
                      SizedBox(
                        width: 50, // Ajuste a largura conforme necessário
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          onSubmitted: (newValue) {
                            setState(() {
                              selectedProducts[index]['quantidade'] = newValue;
                            });
                          },
                        ),
                      ),
                      Text(', Preço Unitário: ${product['precoUnitario']}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        selectedProducts.removeAt(index);
                      });
                    },
                  ),
                );
              },
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
}
