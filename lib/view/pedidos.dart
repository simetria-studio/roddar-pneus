import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roddar_pneus/class/api_config.dart';
import 'package:roddar_pneus/class/color_config.dart';
import 'package:roddar_pneus/view/detalhe_pedido.dart';
import 'package:roddar_pneus/view/home.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pedido extends StatefulWidget {
  const Pedido({Key? key}) : super(key: key);

  @override
  State<Pedido> createState() => _PedidoState();
}

class _PedidoState extends State<Pedido> {
  bool _isSearching = false;

  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _reloadController = StreamController.broadcast();
  final _searchSubject = BehaviorSubject<String>();

  List<dynamic> _pedidos = [];
  List<dynamic> _filteredPedidos = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _setupReloadListener();
    _setupScrollListener();
    _loadInitialData();
  }

  void _setupReloadListener() {
    _reloadController.stream
        .debounceTime(const Duration(seconds: 4))
        .listen((_) => _fetchPedidos());
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 50 &&
          !_isLoading &&
          _hasMoreData) {
        _loadMoreData();
      }
    });
  }

  void _setupSearchListener() {
    _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen((search) {
      print('Buscando por: $search'); // Log de depuração
      _fetchPedidos(search: search); // Realiza a busca diretamente na API
    });

    _searchController.addListener(() {
      _searchSubject.add(_searchController.text.toLowerCase());
    });
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final codigoEmpresa = prefs.getString('codigo_empresa');

    if (codigoEmpresa == null) {
      _showError(
          'Código da empresa não encontrado. Verifique as configurações.');
      return;
    }

    final savedData = prefs.getString('pedidos');

    if (savedData != null) {
      try {
        final savedPedidos = json.decode(savedData) as List<dynamic>;
        setState(() {
          _pedidos = savedPedidos;
          _filteredPedidos = List.from(savedPedidos);
          _isLoading = false;
        });
      } catch (e) {
        print('Erro ao carregar dados salvos: $e');
      }
    }

    await _fetchPedidos();
  }

  Future<void> _fetchPedidos(
      {bool isLoadingMore = false, String search = ''}) async {
    if (_isLoading || (!isLoadingMore && !_hasMoreData)) return;

    setState(() {
      _isLoading = true;
      _isSearching = true; // Inicia o estado de busca
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final codigoEmpresa = prefs.getString('codigo_empresa');
      final nextPage = isLoadingMore ? _currentPage + 1 : 1;

      print('Carregando página: $nextPage, busca: $search');

      final response = await http
          .post(
            Uri.parse('${ApiConfig.apiUrl}/get-pedidos'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'codigo_empresa': codigoEmpresa,
              'page': nextPage,
              'search': search,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        if (responseData.containsKey('data') && responseData['data'] is List) {
          final List<dynamic> newData = responseData['data'];
          final int currentPage = responseData['current_page'] ?? 1;
          final int lastPage = responseData['last_page'] ?? 1;

          if (mounted) {
            setState(() {
              if (isLoadingMore) {
                _pedidos.addAll(newData);
              } else {
                _pedidos = newData;
              }
              _filteredPedidos = List.from(_pedidos);

              _currentPage = currentPage;
              _hasMoreData = currentPage < lastPage;
            });
          }
        } else {
          throw Exception('Formato de resposta inválido');
        }
      } else {
        throw Exception('Erro ao carregar pedidos: ${response.statusCode}');
      }
    } catch (e) {
      if (e is TimeoutException) {
        _showError('O servidor demorou para responder. Tente novamente.');
      } else {
        _showError('Erro ao carregar pedidos: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSearching = false; // Finaliza o estado de busca
        });
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    print('Tentando carregar mais dados...');
    await _fetchPedidos(isLoadingMore: true);
  }

  Future<void> _retryFetch() async {
    const int maxRetries = 3;
    int retries = 0;
    bool success = false;

    while (!success && retries < maxRetries) {
      try {
        await _fetchPedidos(isLoadingMore: true);
        success = true;
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          _showError(
              'Erro persistente ao carregar dados. Tente novamente mais tarde.');
        } else {
          print('Tentativa ${retries + 1} de $maxRetries');
        }
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
      _pedidos.clear();
      _filteredPedidos.clear();
    });
    await _fetchPedidos();
  }

  void _showError(String message) {
    if (!mounted) return; // Garante que o widget ainda está montado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _reloadController.close();
    _searchSubject.close(); // Fecha o Subject
    super.dispose();
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
          Expanded(
            child: _buildPedidosList(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          ),
        ),
        backgroundColor: ColorConfig.amarelo,
        title: const Text(
          'PEDIDOS',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 2,
      );

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildSearchField()),
            const SizedBox(width: 8),
            _buildSearchButton(),
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

  Widget _buildSearchButton() => ElevatedButton(
        onPressed: _isSearching
            ? null // Desativa o botão enquanto está buscando
            : () {
                final searchValue = _searchController.text.trim();
                if (searchValue.isNotEmpty) {
                  _fetchPedidos(search: searchValue); // Executa a busca
                } else {
                  _showError('Por favor, insira um termo para busca.');
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isSearching ? Colors.grey : ColorConfig.amarelo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: _isSearching
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Buscar',
                style: TextStyle(color: Colors.white),
              ),
      );

  Widget _buildTableHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: ColorConfig.amarelo.withOpacity(0.1),
        child: const Row(
          children: [
            Expanded(child: _HeaderText('Nº Pedido')),
            Expanded(child: _HeaderText('Cliente')),
            Expanded(child: _HeaderText('Valor')),
            Expanded(child: _HeaderText('Status')),
          ],
        ),
      );

  Widget _buildPedidosList() => _isSearching
      ? const Center(
          child: CircularProgressIndicator(),
        )
      : RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _filteredPedidos.length + (_hasMoreData ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _filteredPedidos.length) {
                return _buildPedidoItem(_filteredPedidos[index]);
              }

              if (_hasMoreData) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        );

  Widget _buildPedidoItem(Map<String, dynamic> pedido) => InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetalhesPedido(orcamento: pedido),
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
                child: _buildPedidoInfo(
                  '#${pedido['numero_pedido']}\n${pedido['data_pedido']}',
                ),
              ),
              Expanded(
                child: _buildPedidoInfo(
                  pedido['cliente']['nome_fantasia'],
                  maxLines: 2,
                ),
              ),
              Expanded(
                child: _buildPedidoInfo(
                  _formatValue(pedido['valor_total']),
                ),
              ),
              Expanded(
                child: _buildStatusBadge(pedido['situacao_pedido']),
              ),
            ],
          ),
        ),
      );

  Widget _buildPedidoInfo(String text, {int? maxLines}) => Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: maxLines,
      );

  Widget _buildStatusBadge(String status) {
    final statusInfo = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusInfo.color),
      ),
      child: Text(
        statusInfo.text,
        style: TextStyle(
          color: statusInfo.color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatValue(dynamic value) {
    final valorNumerico = double.tryParse(value.toString()) ?? 0.0;
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
        .format(valorNumerico);
  }

  StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case 'O':
        return StatusInfo('Orçamento', Colors.blue);
      case 'FP':
        return StatusInfo('Faturado Parcial', Colors.orange);
      case 'G':
        return StatusInfo('Gerado OP', Colors.purple);
      case 'A':
        return StatusInfo('Aberto', Colors.green);
      case 'F':
        return StatusInfo('Faturado', ColorConfig.amarelo);
      case 'C':
        return StatusInfo('Cancelado', Colors.red);
      default:
        return StatusInfo('Desconhecido', Colors.grey);
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

class StatusInfo {
  final String text;
  final Color color;
  StatusInfo(this.text, this.color);
}
