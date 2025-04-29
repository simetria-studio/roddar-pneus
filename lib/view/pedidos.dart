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
  DateTime? startDate;
  DateTime? endDate;

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
    final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0';
    final codigoRegiao = prefs.getString('codigo_regiao') ?? '0';
    final search = searchController.text.toLowerCase();

    const url = '${ApiConfig.apiUrl}/get-pedidos';
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "codigo_empresa": codigoEmpresa,
        "codigo_regiao": codigoRegiao,
        "page": currentPage,
        "search_text": search,
        "data_inicial": startDate != null
            ? DateFormat('yyyy-MM-dd').format(startDate!)
            : null,
        "data_final":
            endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      var newOrcamentos = responseData['pedidos'] as List;

      if (newOrcamentos.isNotEmpty) {
        setState(() {
          orcamentos.addAll(newOrcamentos);
          filteredOrcamentos.addAll(newOrcamentos);
          valorTotal = double.parse(responseData['valor_total'].toString());
          totalRegistros = responseData['total_registros'] as int;
          isLoading = false;
        });
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
        "data_inicial": startDate != null
            ? DateFormat('yyyy-MM-dd').format(startDate!)
            : null,
        "data_final":
            endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? ColorConfig.preto : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final cardColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;
    final cardBorderColor = ColorConfig.amarelo.withOpacity(0.3);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(isDarkMode, textColor),
          _buildTableHeader(isDarkMode, textColor),
          Expanded(child: _buildPedidosList(isDarkMode, textColor, subtextColor, cardColor, cardBorderColor)),
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

  Widget _buildSearchBar(bool isDarkMode, Color textColor) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSearchField(isDarkMode, textColor)),
                const SizedBox(width: 8),
                _buildDateRangePicker(isDarkMode),
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
                          onPressed: () => sendRequest(),
                          tooltip: 'Buscar',
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTotals(isDarkMode, textColor),
          ],
        ),
      );

  Widget _buildSearchField(bool isDarkMode, Color textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorConfig.amarelo.withOpacity(0.3)),
        ),
        child: TextField(
          controller: searchController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Pesquisar pedido',
            hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black38),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black38),
          ),
        ),
      );

  Widget _buildDateRangePicker(bool isDarkMode) => Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorConfig.amarelo.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: Icon(
                Icons.date_range,
                color: startDate != null ? ColorConfig.amarelo : isDarkMode ? Colors.white54 : Colors.black38,
              ),
              onPressed: () => _showDateRangePicker(),
              tooltip: _getDateRangeText(),
            ),
          ),
          if (startDate != null || endDate != null)
            IconButton(
              icon: Icon(Icons.clear, color: isDarkMode ? Colors.white54 : Colors.black38),
              onPressed: () {
                setState(() {
                  startDate = null;
                  endDate = null;
                });
                sendRequest();
              },
              tooltip: 'Limpar datas',
            ),
        ],
      );

  String _getDateRangeText() {
    if (startDate == null && endDate == null) return 'Selecionar período';
    if (startDate == null) {
      return 'Até ${DateFormat('dd/MM/yyyy').format(endDate!)}';
    }
    if (endDate == null) {
      return 'De ${DateFormat('dd/MM/yyyy').format(startDate!)}';
    }
    return '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}';
  }

  Future<void> _showDateRangePicker() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDarkMode 
                ? const ColorScheme.dark(
                    primary: ColorConfig.amarelo,
                    onPrimary: Colors.white,
                    surface: ColorConfig.preto,
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: ColorConfig.amarelo,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
            dialogBackgroundColor: isDarkMode ? ColorConfig.preto : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
      sendRequest();
    }
  }

  Widget _buildTotals(bool isDarkMode, Color textColor) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorConfig.amarelo.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total de Registros: $totalRegistros',
              style: TextStyle(
                color: textColor,
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

  Widget _buildTableHeader(bool isDarkMode, Color textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isDarkMode ? ColorConfig.amarelo.withOpacity(0.1) : ColorConfig.amarelo.withOpacity(0.05),
        child: Row(
          children: [
            _buildHeaderCell('Nº Pedido', textColor),
            _buildHeaderCell('Cliente', textColor),
            _buildHeaderCell('Valor', textColor),
            _buildHeaderCell('Status', textColor),
          ],
        ),
      );

  Widget _buildHeaderCell(String text, Color textColor) => Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _buildPedidosList(
    bool isDarkMode, 
    Color textColor, 
    Color subtextColor, 
    Color cardColor, 
    Color cardBorderColor
  ) => RefreshIndicator(
        onRefresh: _refreshData,
        color: ColorConfig.amarelo,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: filteredOrcamentos.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < filteredOrcamentos.length) {
              return _buildPedidoItem(
                filteredOrcamentos[index], 
                isDarkMode, 
                textColor, 
                subtextColor, 
                cardColor, 
                cardBorderColor
              );
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

  Widget _buildPedidoItem(
    Map<String, dynamic> pedido, 
    bool isDarkMode, 
    Color textColor, 
    Color subtextColor, 
    Color cardColor, 
    Color cardBorderColor
  ) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: cardBorderColor,
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
                  style: TextStyle(
                    color: textColor,
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
                        color: subtextColor,
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
