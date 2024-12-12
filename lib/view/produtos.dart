import 'dart:convert';

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
      _fetchProdutos(_searchController.text);
    }
  }

  Future<void> _fetchProdutos([String search = '']) async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final codigoEmpresa = prefs.getString('codigo_empresa');
      final codigoRegiao = prefs.getString('codigo_regiao');

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/get-all-produtos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo_empresa': codigoEmpresa,
          'search_text': search,
          'codigo_regiao': codigoRegiao,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          _produtos = data;
          _filteredProdutos = data;
          _isLoading = false;
        });
        await prefs.setString('produtos', json.encode(data));
      } else {
        throw Exception('Erro ao carregar produtos');
      }
    } catch (e) {
      _showError('Erro ao carregar produtos: $e');
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
            _buildFilterButton(),
            const SizedBox(width: 16),
            Expanded(child: _buildSearchField()),
          ],
        ),
      );

  Widget _buildFilterButton() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorConfig.amarelo.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Filtros',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );

  Widget _buildSearchField() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorConfig.amarelo.withOpacity(0.3)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Pesquisar',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.white54),
          ),
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

  Widget _buildProdutoItem(Map<String, dynamic> produto) => InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProdutoDetalhes(produto: produto),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: ColorConfig.amarelo.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  produto['codigo_produto'] ?? '',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Expanded(
                child: Text(
                  produto['descricao_produto'] ?? '',
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Text(
                  _formatCurrency(produto['preco_tabela']),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              Expanded(
                child: Text(
                  produto['saldo_atual']?.toString() ?? 'N/D',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );

  String _formatCurrency(dynamic value) {
    final numero = double.tryParse(value.toString()) ?? 0.0;
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(numero);
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
