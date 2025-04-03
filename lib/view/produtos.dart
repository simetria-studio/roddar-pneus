import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roddar_pneus/class/api_config.dart';
import 'package:roddar_pneus/class/color_config.dart';
import 'package:roddar_pneus/view/detalhe_produto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Produtos extends StatefulWidget {
  const Produtos({super.key});

  @override
  State<Produtos> createState() => _ProdutosState();
}

class _ProdutosState extends State<Produtos> {
  final _searchController = TextEditingController();
  List<dynamic> _produtos = [];
  List<dynamic> _filteredProdutos = [];
  bool _isLoading = true;
  final bool _showOnlyWithStock = false;
  final bool _sortByPriceAsc = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _searchController.addListener(_onSearchChanged);
    await _fetchProdutos();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      _fetchProdutos();
    } else {
      _filterProducts();
    }
  }

  Future<void> _fetchProdutos([String search = '']) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0';
      final codigoRegiao = prefs.getString('codigo_regiao') ?? '0';

      print(
          'Fazendo requisição com: empresa=$codigoEmpresa, regiao=$codigoRegiao, search=$search');

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/get-produtos-with-saldo'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'codigo_empresa': codigoEmpresa,
          'search_text': search,
          'codigo_regiao': codigoRegiao,
          'search_by_code': true,
        }),
      );

      print('Status code: ${response.statusCode}');
      print(
          'Response body preview: ${response.body.substring(0, min(200, response.body.length))}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body) as List;
          print('Produtos encontrados: ${data.length}');

          // Ordena os produtos por descrição
          data.sort((a, b) => (a['descricao_produto'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo(
                  (b['descricao_produto'] ?? '').toString().toLowerCase()));

          setState(() {
            _produtos = data;
            _filteredProdutos = data;
            _isLoading = false;
          });

          if (search.isEmpty) {
            await prefs.setString('produtos', json.encode(data));
          }
        } catch (e) {
          print('Erro ao processar dados: $e');
          print('Response completa: ${response.body}');
          _showError('Erro ao processar dados dos produtos');
        }
      } else {
        throw Exception('Erro ao carregar produtos: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro na requisição: $e');
      _showError('Erro ao carregar produtos');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.preto,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTableHeader(),
          Expanded(child: _buildProdutosList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: const Text(
          'PRODUTOS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorConfig.amarelo,
        centerTitle: true,
        elevation: 2,
      );

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: ColorConfig.amarelo.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por código ou descrição',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.white54),
                  ),
                  onSubmitted: (value) {
                    _fetchProdutos(_searchController.text);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: ColorConfig.amarelo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  _fetchProdutos(_searchController.text);
                },
                tooltip: 'Buscar',
              ),
            ),
          ],
        ),
      );

  Widget _buildTableHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: ColorConfig.amarelo.withOpacity(0.1),
        child: const Row(
          children: [
            Expanded(child: _HeaderText('Código')),
            Expanded(child: _HeaderText('Descrição')),
            Expanded(child: _HeaderText('Valor')),
            Expanded(child: _HeaderText('Estoque')),
          ],
        ),
      );

  Widget _buildProdutosList() => _isLoading
      ? const Center(child: CircularProgressIndicator())
      : ListView.builder(
          itemCount: _filteredProdutos.length,
          itemBuilder: (context, index) =>
              _buildProdutoItem(_filteredProdutos[index]),
        );

  Widget _buildProdutoItem(Map<String, dynamic> produto) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: ColorConfig.amarelo.withOpacity(0.3),
          ),
        ),
        child: InkWell(
          onTap: () async {
            final needsRefresh = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => DetalheProduto(produto: produto),
              ),
            );
            
            if (needsRefresh == true) {
              setState(() {
                _produtos.clear();
                _isLoading = true;
              });
              await sendRequest();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Código do produto
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorConfig.amarelo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Código: ${produto['codigo_produto'] ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Descrição do produto
                Text(
                  produto['descricao_produto'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Informações adicionais
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo: ${produto['saldo_atual']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                          .format(produto['preco_venda'] ?? 0),
                      style: const TextStyle(
                        color: ColorConfig.amarelo,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  String _formatCurrency(dynamic value) {
    final numero = double.tryParse(value.toString()) ?? 0.0;
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(numero);
  }

  void _filterProducts() {
    if (_produtos.isEmpty) return;

    setState(() {
      _filteredProdutos = _produtos.where((produto) {
        final searchMatch = _searchController.text.isEmpty ||
            produto['descricao_produto']
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase());

        final hasStock = !_showOnlyWithStock || _getProductStock(produto) > 0;

        return searchMatch && hasStock;
      }).toList();

      _filteredProdutos.sort((a, b) => (a['descricao_produto'] ?? '')
          .toString()
          .compareTo((b['descricao_produto'] ?? '').toString()));

      _filteredProdutos.sort((a, b) {
        final precoA = double.tryParse(a['preco_venda'].toString()) ?? 0.0;
        final precoB = double.tryParse(b['preco_venda'].toString()) ?? 0.0;
        return (_sortByPriceAsc ?? false)
            ? precoA.compareTo(precoB)
            : precoB.compareTo(precoA);
      });
    });
  }

  double _getProductStock(Map<String, dynamic> produto) {
    if (produto['saldo_atual'] != null) {
      return double.tryParse(produto['saldo_atual'].toString()) ?? 0.0;
    }

    if (produto['saldo'] != null && produto['saldo'] is Map) {
      return double.tryParse(
              produto['saldo']['saldo_atual']?.toString() ?? '0') ??
          0.0;
    }

    return 0.0;
  }

  Future<void> sendRequest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0';
      final search = _searchController.text.toLowerCase();

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/get-produtos-with-saldo'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "codigo_empresa": codigoEmpresa,
          "search_text": search,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> newProdutos = json.decode(response.body);
        
        if (search.isEmpty) {
          await prefs.setString('produtos', json.encode(newProdutos));
        }

        setState(() {
          _produtos = newProdutos;
          _filteredProdutos = newProdutos;
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar produtos');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar produtos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
