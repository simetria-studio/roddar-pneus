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
  final GlobalKey _listKey = GlobalKey();
  bool isLoading = true;
  List<dynamic> orcamentos = [];
  List<dynamic> filteredOrcamentos = [];
  int codigo_empresa = 0;
  late TextEditingController searchController;
  final ScrollController _scrollController = ScrollController();
  final StreamController _reloadController = StreamController.broadcast();

  int currentPage = 1;
  DateTime? selectedDate;
  double valorTotal = 0;
  int totalRegistros = 0;

  @override
  void initState() {
    super.initState();
    _reloadController.stream
        .debounceTime(const Duration(seconds: 4))
        .listen((event) {
      print("Recarregando a lista de orçamentos...");
      sendRequest();
    });

    _loadDataFromPrefs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        print('chegou ao final da lista');
        _loadMoreData();
      }
    });
    sendRequest();
    searchController = TextEditingController();
  }

  Future<void> _loadDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? orcamentosData = prefs.getString('pedidos');
    if (orcamentosData != null && orcamentosData.isNotEmpty) {
      List<dynamic> savedOrcamentos = json.decode(orcamentosData);
      orcamentos.addAll(savedOrcamentos);
      filteredOrcamentos.addAll(savedOrcamentos);

      _reloadController.add(null);
      setState(() {
        isLoading = false;
      });
    } else {
      sendRequest();
    }
  }

  Future<void> _loadMoreData() async {
    print('Carregando mais dados...');
    if (isLoading) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    currentPage++;
    final prefs = await SharedPreferences.getInstance();
    final codigoEmpresa = prefs.getString('codigo_empresa') ?? 0;
    final codigoRegiao = prefs.getString('codigo_regiao') ?? 0;
    const url = '${ApiConfig.apiUrl}/get-pedidos';
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "codigo_empresa": codigoEmpresa,
        "codigo_regiao": codigoRegiao,
        "page": currentPage,
      }),
    );

    if (response.statusCode == 200) {
      var newOrcamentos = json.decode(response.body);
      if (newOrcamentos.isNotEmpty) {
        setState(() {
          orcamentos.addAll(newOrcamentos);
          filteredOrcamentos.addAll(newOrcamentos);

          isLoading = false;
        });
        _reloadController.add(null);
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
      print('Erro na solicitação: ${response.statusCode} ${response.body}');
    }
  }

  @override
  void dispose() {
    _reloadController.close(); // Adicione esta linha
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> sendRequest() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0';
    final codigoRegiao = prefs.getString('codigo_regiao') ?? '0';
    final search = searchController.text.toLowerCase();

    const String url = '${ApiConfig.apiUrl}/get-pedidos';

    final response = await http.post(
      Uri.parse(url),
      body: json.encode({
        "codigo_empresa": codigoEmpresa,
        "codigo_regiao": codigoRegiao,
        "page": currentPage,
        "search_text": search,
        "data_pedido": selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
            : null,
      }),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      var newOrcamentos = responseData['pedidos'] as List;

      setState(() {
        orcamentos.clear();
        orcamentos.addAll(newOrcamentos);
        filteredOrcamentos.clear();
        filteredOrcamentos.addAll(newOrcamentos);
        valorTotal = double.parse(responseData['valor_total'].toString());
        totalRegistros = responseData['total_registros'] as int;
        isLoading = false;
      });

      if (search.isEmpty && selectedDate == null) {
        prefs.setString('pedidos', json.encode(newOrcamentos));
      }
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception(
          'Erro na solicitação: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _refreshData() async {
    // final prefs = await SharedPreferences.getInstance();
    // prefs.remove('orcamentos');
    // orcamentos.clear();
    // filteredOrcamentos.clear();
    // sendRequest();
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
          Expanded(child: _buildPedidosList()),
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
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSearchField()),
                const SizedBox(width: 8),
                _buildDatePicker(),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: ColorConfig.amarelo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: isLoading
                      ? Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(12),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              isLoading = true; // Ativa o loading
                            });
                            sendRequest().then((_) {
                              if (mounted) {
                                setState(() {
                                  isLoading = false; // Desativa o loading
                                });
                              }
                            }).catchError((error) {
                              if (mounted) {
                                setState(() {
                                  isLoading = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erro na busca: $error'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            });
                          },
                          tooltip: 'Buscar',
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTotals(),
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
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Pesquisar pedido',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.white54),
          ),
        ),
      );

  Widget _buildDatePicker() => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorConfig.amarelo.withOpacity(0.3)),
        ),
        child: IconButton(
          icon: Icon(
            Icons.calendar_today,
            color: selectedDate != null ? ColorConfig.amarelo : Colors.white54,
          ),
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: ColorConfig.amarelo,
                      onPrimary: Colors.white,
                      surface: ColorConfig.preto,
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null && picked != selectedDate) {
              setState(() {
                selectedDate = picked;
              });
              sendRequest();
            }
          },
          tooltip: selectedDate != null
              ? DateFormat('dd/MM/yyyy').format(selectedDate!)
              : 'Selecionar Data',
        ),
      );

  Widget _buildTotals() => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorConfig.amarelo.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total de Registros: $totalRegistros',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              'Valor Total: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valorTotal)}',
              style: const TextStyle(
                color: ColorConfig.amarelo,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );

  Widget _buildTableHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: ColorConfig.amarelo.withOpacity(0.1),
        child: Row(
          children: [
            _buildHeaderCell('Nº Pedido'),
            _buildHeaderCell('Cliente'),
            _buildHeaderCell('Valor'),
            _buildHeaderCell('Status'),
          ],
        ),
      );

  Widget _buildHeaderCell(String text) => Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _buildPedidosList() => RefreshIndicator(
        onRefresh: _refreshData,
        color: ColorConfig.amarelo,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: filteredOrcamentos.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < filteredOrcamentos.length) {
              return _buildPedidoItem(filteredOrcamentos[index]);
            }
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(ColorConfig.amarelo),
                ),
              ),
            );
          },
        ),
      );

  Widget _buildPedidoItem(Map<String, dynamic> pedido) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: ColorConfig.amarelo.withOpacity(0.3),
          ),
        ),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalhesPedido(orcamento: pedido),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com número do pedido e data
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: ColorConfig.amarelo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Pedido #${pedido['numero_pedido']}',
                        style: const TextStyle(
                          color: ColorConfig.amarelo,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _buildStatusBadge(pedido['situacao_pedido']),
                  ],
                ),
                const SizedBox(height: 12),

                // Informações do cliente
                Text(
                  pedido['cliente']['nome_fantasia'] ?? 'Cliente não informado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Data e valor
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Data: ${_formatDate(pedido['data_pedido'])}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      _formatCurrency(pedido['valor_total']),
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

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

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

  String _formatCurrency(dynamic value) {
    final numero = double.tryParse(value.toString()) ?? 0.0;
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(numero);
  }
}

class StatusInfo {
  final String text;
  final Color color;
  StatusInfo(this.text, this.color);
}
