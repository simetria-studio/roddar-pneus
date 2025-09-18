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
  final String situacao;

  const CadProduto({required this.numeroPedido, required this.id, required this.situacao, Key? key})
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0';
      final codigoRegiao = prefs.getString('codigo_regiao') ?? '0';

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/get-produtos-with-saldo'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "codigo_empresa": codigoEmpresa,
          "search_text": searchText,
          "codigo_regiao": codigoRegiao,
          "situacao": widget.situacao
        }),
      );

      if (response.statusCode == 200) {
        try {
          // Corrigir JSON potencialmente inválido antes de fazer o parse
          String responseBody = response.body;
          
          // Corrigir problema com preco_venda sem aspas de fechamento
          responseBody = _corrigirJsonInvalido(responseBody);
          
          dynamic responseData;
          try {
            responseData = json.decode(responseBody);
          } catch (jsonError) {
            print('Falha ao decodificar JSON corrigido: $jsonError');
            // Se ainda falhar, tentar extrair dados manualmente
            responseData = _extrairDadosManualmente(responseBody);
          }
          
          print('Dados recebidos da API após correção: ${responseData.runtimeType}');
          
          if (responseData is List<dynamic>) {
            // Processar cada item para garantir valores corretos
            final List<Map<String, dynamic>> produtos = [];
            
            for (var item in responseData) {
              if (item is Map<String, dynamic>) {
                // Corrigir campos numéricos potencialmente problemáticos
                Map<String, dynamic> cleanItem = {...item};
                
                // Processar preço de venda
                if (cleanItem.containsKey('preco_venda')) {
                  try {
                    var preco = cleanItem['preco_venda'];
                    if (preco is num) {
                      // Já é um número, deixa como está
                    } else {
                      // Tenta converter para double
                      var precoStr = preco.toString().replaceAll(',', '.');
                      // Remove possivelmente mais de um ponto decimal
                      if (precoStr.indexOf('.') != precoStr.lastIndexOf('.')) {
                        precoStr = precoStr.replaceAll(RegExp(r'\.'), '');
                        precoStr = precoStr.substring(0, precoStr.length - 2) + '.' + precoStr.substring(precoStr.length - 2);
                      }
                      double? valorNumerico = double.tryParse(precoStr);
                      if (valorNumerico != null) {
                        cleanItem['preco_venda'] = valorNumerico;
                      } else {
                        cleanItem['preco_venda'] = 0.0;
                      }
                    }
                  } catch (e) {
                    print('Erro ao processar preço_venda: $e');
                    cleanItem['preco_venda'] = 0.0;
                  }
                }
                
                // Processar saldo atual
                if (cleanItem.containsKey('saldo_atual')) {
                  try {
                    var saldo = cleanItem['saldo_atual'];
                    if (saldo is num) {
                      // Já é um número, deixa como está
                    } else {
                      int? valorNumerico = int.tryParse(saldo.toString());
                      if (valorNumerico != null) {
                        cleanItem['saldo_atual'] = valorNumerico;
                      } else {
                        cleanItem['saldo_atual'] = 0;
                      }
                    }
                  } catch (e) {
                    print('Erro ao processar saldo_atual: $e');
                    cleanItem['saldo_atual'] = 0;
                  }
                }
                
                produtos.add(cleanItem);
              }
            }
            
            print('Itens processados com segurança: ${produtos.length}');
            if (produtos.isNotEmpty) {
              print('Primeiro produto da lista: ${produtos.first}');
            }
            return produtos;
          } else {
            throw Exception("Falha ao carregar os produtos: dados não são uma lista");
          }
        } catch (e) {
          print('Erro ao processar JSON da resposta: $e');
          // Última tentativa - retornar uma lista vazia mas não quebrar a aplicação
          return [];
        }
      } else {
        throw Exception("Falha ao carregar os produtos: ${response.statusCode}");
      }
    } catch (e) {
      print('Erro geral em _fetchProdutos: $e');
      return [];
    }
  }

  // Função para corrigir problemas comuns de JSON inválido
  String _corrigirJsonInvalido(String json) {
    try {
      // Aplicar tratamentos específicos aos problemas detectados
      
      // 1. Corrigir problema com campos que faltam aspas duplas de fechamento
      final camposComProblema = [
        'preco_venda', 'saldo_atual', 'codigo_produto', 
        'descricao', 'descricao_produto', 'deposito_padrao'
      ];
      
      for (var campo in camposComProblema) {
        // Padrão: "campo:valor, - faltando aspas de fechamento
        final regexFaltaAspas = RegExp('"$campo:([^",}]+)(,|})');
        json = json.replaceAllMapped(regexFaltaAspas, (match) {
          final valor = match.group(1);
          final terminador = match.group(2);
          return '"$campo":"$valor"$terminador';
        });
      }
      
      // 2. Corrigir problema com valores decimais mal formatados (com múltiplos pontos)
      for (var campo in ['preco_venda']) {
        // Encontra valores com múltiplos pontos decimais
        final regexMultiplosPontos = RegExp('"$campo":"([0-9]+)\.([0-9]+)\.([0-9]+)"');
        json = json.replaceAllMapped(regexMultiplosPontos, (match) {
          final inteiro = match.group(1);
          final decimal1 = match.group(2);
          final decimal2 = match.group(3);
          // Concatena os decimais e usa apenas os 2 primeiros dígitos
          final decimais = '$decimal1$decimal2'.substring(0, decimal1!.length + decimal2!.length > 2 ? 2 : decimal1.length + decimal2.length);
          return '"$campo":"$inteiro.$decimais"';
        });
      }
      
      // 3. Corrigir vírgulas extras no final dos objetos
      json = json.replaceAll("},]", "}]");
      
      // 4. Corrigir valores nulos inválidos
      json = json.replaceAll(':"",', ':null,');
      json = json.replaceAll(':""}', ':null}');
      
      // 5. Depuração - Imprimir primeiros caracteres após correção
      if (json.length > 100) {
        print('JSON após correção (primeiros 100 caracteres): ${json.substring(0, 100)}...');
      } else {
        print('JSON após correção: $json');
      }
      
      return json;
    } catch (e) {
      print('Erro ao tentar corrigir JSON: $e');
      return json; // Retorna o JSON original se falhar
    }
  }

  // Extrai dados de um JSON inválido como último recurso
  List<dynamic> _extrairDadosManualmente(String responseBody) {
    try {
      // Verifica se a resposta começa com [ e termina com ]
      if (!responseBody.trim().startsWith('[') || !responseBody.trim().endsWith(']')) {
        print('Resposta da API não é uma lista JSON');
        return [];
      }
      
      // Remove os colchetes externos
      String conteudo = responseBody.trim().substring(1, responseBody.trim().length - 1);
      
      // Lista para armazenar os objetos
      List<Map<String, dynamic>> resultado = [];
      
      // Contador para balancear chaves
      int contador = 0;
      int inicioObjeto = 0;
      
      // Percorre a string procurando objetos JSON individuais
      for (int i = 0; i < conteudo.length; i++) {
        if (conteudo[i] == '{') {
          if (contador == 0) {
            inicioObjeto = i;
          }
          contador++;
        } else if (conteudo[i] == '}') {
          contador--;
          if (contador == 0) {
            // Extraiu um objeto completo
            String objetoJson = conteudo.substring(inicioObjeto, i + 1);
            try {
              // Tenta converter o objeto para Map
              Map<String, dynamic> item = _converterParaMapSimples(objetoJson);
              resultado.add(item);
            } catch (e) {
              print('Erro ao converter objeto individual: $e');
            }
          }
        }
      }
      
      print('Extraídos ${resultado.length} objetos manualmente');
      return resultado;
    } catch (e) {
      print('Erro ao extrair dados manualmente: $e');
      return [];
    }
  }
  
  // Converte uma string de objeto JSON para Map de forma simples
  Map<String, dynamic> _converterParaMapSimples(String objetoJson) {
    // Remove as chaves
    String conteudo = objetoJson.trim().substring(1, objetoJson.trim().length - 1);
    
    Map<String, dynamic> resultado = {};
    
    // Divide em pares chave-valor
    List<String> pares = [];
    int inicioAtual = 0;
    bool dentroString = false;
    
    for (int i = 0; i < conteudo.length; i++) {
      if (conteudo[i] == '"') {
        dentroString = !dentroString;
      } else if (conteudo[i] == ',' && !dentroString) {
        pares.add(conteudo.substring(inicioAtual, i).trim());
        inicioAtual = i + 1;
      }
    }
    // Adiciona o último par
    if (inicioAtual < conteudo.length) {
      pares.add(conteudo.substring(inicioAtual).trim());
    }
    
    // Processa cada par
    for (String par in pares) {
      int separador = par.indexOf(':');
      if (separador > 0) {
        String chave = par.substring(0, separador).trim();
        String valor = par.substring(separador + 1).trim();
        
        // Remove aspas das chaves
        if (chave.startsWith('"') && chave.endsWith('"')) {
          chave = chave.substring(1, chave.length - 1);
        }
        
        // Processa valores
        if (valor == "null") {
          resultado[chave] = null;
        } else if (valor.startsWith('"') && valor.endsWith('"')) {
          resultado[chave] = valor.substring(1, valor.length - 1);
        } else if (valor == "true") {
          resultado[chave] = true;
        } else if (valor == "false") {
          resultado[chave] = false;
        } else {
          // Tenta converter para número
          try {
            if (valor.contains('.')) {
              resultado[chave] = double.tryParse(valor) ?? valor;
            } else {
              resultado[chave] = int.tryParse(valor) ?? valor;
            }
          } catch (e) {
            resultado[chave] = valor;
          }
        }
      }
    }
    
    // Garantir que temos os campos principais, mesmo que vazios
    ['codigo_produto', 'descricao_produto', 'descricao', 'preco_venda', 'saldo_atual'].forEach((campo) {
      if (!resultado.containsKey(campo)) {
        if (campo == 'preco_venda') {
          resultado[campo] = 0.0;
        } else if (campo == 'saldo_atual') {
          resultado[campo] = 0;
        } else {
          resultado[campo] = '';
        }
      }
    });
    
    return resultado;
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
    final url = Uri.parse('${ApiConfig.apiUrl}/store-multiplos-pedidos-roddar');

    // Buscar o valor do frete total do pedido
    double valorFreteTotal = 0.0;
    try {
      valorFreteTotal = await _buscarValorFrete(codigoEmpresa, widget.numeroPedido);
    } catch (_) {}

    // Calcular a quantidade total (para rateio proporcional por unidade)
    final int quantidadeTotal = products
        .map((p) => (p['quantidade'] is num)
            ? (p['quantidade'] as num).toInt()
            : int.tryParse(p['quantidade'].toString()) ?? 0)
        .fold(0, (a, b) => a + b);

    // Evitar divisão por zero
    final double freteUnitarioBase = quantidadeTotal > 0
        ? (valorFreteTotal / quantidadeTotal)
        : 0.0;

    // Format the products data correctly, incluindo rateio do frete por item
    final formattedProducts = products.map((product) {
      final int quantidade = (product['quantidade'] is num)
          ? (product['quantidade'] as num).toInt()
          : int.tryParse(product['quantidade'].toString()) ?? 0;
      final double precoUnitario = double.parse(product['precoUnitario'].toString());
      final double valorTotalItem = quantidade * precoUnitario;
      final double valorFreteRateado = (freteUnitarioBase * quantidade);

      return {
        'codigo_empresa': codigoEmpresa,
        'codigo_produto': product['codigo_produto'] ?? '',
        'produto': product['produto'] ?? '',
        'numero_pedido': product['numero_pedido'],
        'quantidade': quantidade,
        'preco_unitario': precoUnitario,
        'valor_total': valorTotalItem + valorFreteRateado,
        'valor_frete': valorFreteRateado,
        'situacao': widget.situacao,
      };
    }).toList();

    print('Formatted Products: ${formattedProducts}');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'produtos': formattedProducts,
        'numero_pedido': widget.numeroPedido,
        'situacao': widget.situacao,
      }),
    );

    List<String> messages = [];
    print('Resposta do servidor: ${response.body}');

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);

      if (responseBody['success'] == true) {
        messages.add(responseBody['message'] ?? 'Operação realizada com sucesso');

        if (!context.mounted) return messages;

        // Buscar o valor do frete do pedido
        double valorFrete = 0.0;
        try {
          valorFrete = await _buscarValorFrete(codigoEmpresa, widget.numeroPedido);
        } catch (e) {
          print('Erro ao buscar valor do frete: $e');
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmarPedido(
              orcamento: List<Map<String, dynamic>>.from(responseBody['items'] ?? []),
              numeroPedido: widget.numeroPedido,
              valorFrete: valorFrete,
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

  Future<double> _buscarValorFrete(String codigoEmpresa, String numeroPedido) async {
    // Primeiro, tentar buscar do SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final valorFrete = prefs.getDouble('valor_frete_$numeroPedido');
      if (valorFrete != null && valorFrete > 0) {
        print('Valor do frete encontrado no SharedPreferences: $valorFrete');
        return valorFrete;
      }
    } catch (e) {
      print('Erro ao buscar valor do frete do SharedPreferences: $e');
    }

    // Se não encontrar no SharedPreferences, tentar buscar da API
    try {
      final prefs = await SharedPreferences.getInstance();
      final codigoRegiao = prefs.getString('codigo_regiao') ?? '0';
      
      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/get-pedidos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'codigo_empresa': codigoEmpresa,
          'codigo_regiao': codigoRegiao,
          'page': 1,
          'search_text': numeroPedido, // Buscar pelo número do pedido
        }),
      );

      print('Resposta da API get-pedidos: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['pedidos'] != null && (data['pedidos'] as List).isNotEmpty) {
          // Buscar o pedido específico pelo número
          final pedidos = data['pedidos'] as List;
          final pedidoEncontrado = pedidos.firstWhere(
            (pedido) => pedido['numero_pedido']?.toString() == numeroPedido,
            orElse: () => null,
          );
          
          if (pedidoEncontrado != null) {
            final valorFrete = double.tryParse(pedidoEncontrado['valor_frete']?.toString() ?? '0') ?? 0.0;
            print('Valor do frete encontrado pela API: $valorFrete');
            return valorFrete;
          }
        }
      }
    } catch (e) {
      print('Erro ao buscar valor do frete pela API: $e');
    }
    
    print('Valor do frete não encontrado, retornando 0.0');
    return 0.0;
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
                      'PEDIDO #${widget.numeroPedido} - ${widget.situacao}',
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
                      suggestionsCallback: (pattern) {
                        return _fetchProdutos(pattern);
                      },
                      onSelected: _onProdutoSelecionado,
                      itemBuilder: (context, suggestion) => ListTile(
                        title: Text(
                          suggestion['descricao_produto'] ?? suggestion['descricao'] ?? '',
                          style: const TextStyle(color: Colors.black87),
                        ),
                        subtitle: Text(
                          'Código: ${suggestion['codigo_produto']} | Estoque: ${suggestion['saldo_atual'] ?? 0}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      builder: (context, controller, focusNode) {
                        return TextField(
                          controller: _produtoController,
                          focusNode: focusNode,
                          onChanged: (value) {
                            // Ensure controller value is synced
                            controller.text = value;
                          },
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
                      _saldoAtualController.clear();
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

    // Tratamento seguro para o preço de venda
    String precoVenda = '0';
    try {
      // Tenta converter para double, caso seja um número válido
      var preco = produto['preco_venda'];
      if (preco != null) {
        if (preco is num) {
          precoVenda = preco.toStringAsFixed(2);
        } else {
          // Se não for um número, tenta converter a string para um double
          var precoStr = preco.toString().replaceAll(',', '.');
          // Remove possivelmente mais de um ponto decimal
          if (precoStr.indexOf('.') != precoStr.lastIndexOf('.')) {
            precoStr = precoStr.replaceAll(RegExp(r'\.'), '');
            precoStr = precoStr.substring(0, precoStr.length - 2) + '.' + precoStr.substring(precoStr.length - 2);
          }
          precoVenda = double.tryParse(precoStr)?.toStringAsFixed(2) ?? '0.00';
        }
      }
    } catch (e) {
      print('Erro ao processar preço: $e');
      precoVenda = '0.00';
    }

    // Tratamento seguro para o saldo atual
    String saldoAtual = '0';
    try {
      var saldo = produto['saldo_atual'];
      if (saldo != null) {
        if (saldo is num) {
          saldoAtual = saldo.toString();
        } else {
          saldoAtual = int.tryParse(saldo.toString())?.toString() ?? '0';
        }
      }
    } catch (e) {
      print('Erro ao processar saldo: $e');
      saldoAtual = '0';
    }

    setState(() {
      _leituraController.text = descricao;
      _produtoController.text = descricao;
      _precoUnitarioController.text = precoVenda;
      _codigoProduto.text = codigo;
      _saldoAtualController.text = saldoAtual;
    });

    print('Código após setState: ${_codigoProduto.text}');
    print('Preço definido: ${_precoUnitarioController.text}');
    print('Saldo definido: ${_saldoAtualController.text}');
  }
}
