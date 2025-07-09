import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:roddar_pneus/class/api_config.dart';
import 'package:roddar_pneus/class/color_config.dart';
import 'package:roddar_pneus/view/detalhe_pedido.dart';
import 'package:roddar_pneus/view/home.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Orcamentos extends StatefulWidget {
  const Orcamentos({Key? key}) : super(key: key);

  @override
  State<Orcamentos> createState() => _OrcamentosState();
}

class _OrcamentosState extends State<Orcamentos> {
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
    String? orcamentosData = prefs.getString('orcamentos');
    if (orcamentosData != null && orcamentosData.isNotEmpty) {
      try {
        List<dynamic> savedOrcamentos = json.decode(orcamentosData);
        if (savedOrcamentos.isNotEmpty) {
          orcamentos.addAll(savedOrcamentos);
          filteredOrcamentos.addAll(savedOrcamentos);

          _reloadController.add(null);
          setState(() {
            isLoading = false;
          });
        } else {
          sendRequest();
        }
      } catch (e) {
        print('Erro ao carregar dados do SharedPreferences: $e');
        sendRequest();
      }
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

    const url = '${ApiConfig.apiUrl}/get-orcamentos';
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "codigo_empresa": codigoEmpresa,
        "codigo_regiao": codigoRegiao,
        "page": currentPage,
        "search_text": search,
        "situacao": "O", // Filtrar apenas orçamentos
        "data_inicial": startDate != null
            ? DateFormat('yyyy-MM-dd').format(startDate!)
            : null,
        "data_final":
            endDate != null ? DateFormat('yyyy-MM-dd').format(endDate!) : null,
      }),
    );

    if (response.statusCode == 200) {
  
      final responseData = json.decode(response.body);
      var newOrcamentos = (responseData['pedidos'] as List?) ?? [];

      if (newOrcamentos.isNotEmpty) {
        setState(() {
          orcamentos.addAll(newOrcamentos);
          filteredOrcamentos.addAll(newOrcamentos);
          valorTotal = double.parse(responseData['valor_total']?.toString() ?? '0.0');
          totalRegistros = responseData['total_registros'] as int? ?? 0;
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
    _reloadController.close();
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

    const String url = '${ApiConfig.apiUrl}/get-orcamentos';

    final response = await http.post(
      Uri.parse(url),
      body: json.encode({
        "codigo_empresa": codigoEmpresa,
        "codigo_regiao": codigoRegiao,
        "page": currentPage,
        "search_text": search,
        "situacao": "O", // Filtrar apenas orçamentos
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
      var newOrcamentos = (responseData['pedidos'] as List?) ?? [];

      setState(() {
        orcamentos.clear();
        orcamentos.addAll(newOrcamentos);
        filteredOrcamentos.clear();
        filteredOrcamentos.addAll(newOrcamentos);
        valorTotal = double.parse(responseData['valor_total']?.toString() ?? '0.0');
        totalRegistros = responseData['total_registros'] as int? ?? 0;
        isLoading = false;
      });

      if (search.isEmpty && selectedDate == null) {
        prefs.setString('orcamentos', json.encode(newOrcamentos));
      }
    } else {
      setState(() {
        isLoading = false;
      });
      print('Erro na solicitação: ${response.statusCode} ${response.body}');
    }
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
          Expanded(child: _buildOrcamentosList(isDarkMode, textColor, subtextColor, cardColor, cardBorderColor)),
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
          'ORÇAMENTOS',
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
            hintText: 'Pesquisar orçamento',
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
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: startDate != null && endDate != null
          ? DateTimeRange(start: startDate!, end: endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: ColorConfig.amarelo,
              onPrimary: Colors.white,
              surface: isDarkMode ? Colors.grey[900] : Colors.white,
              onSurface: isDarkMode ? Colors.white : Colors.black,
            ),
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
        padding: const EdgeInsets.all(12),
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
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Valor Total: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valorTotal)}',
              style: const TextStyle(
                color: ColorConfig.amarelo,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );

  Widget _buildTableHeader(bool isDarkMode, Color textColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ColorConfig.amarelo.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(
              color: ColorConfig.amarelo.withOpacity(0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.request_quote, color: ColorConfig.amarelo, size: 20),
            const SizedBox(width: 8),
            Text(
              'Lista de Orçamentos',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );

  Widget _buildOrcamentosList(
    bool isDarkMode, 
    Color textColor, 
    Color subtextColor, 
    Color cardColor, 
    Color cardBorderColor
  ) {
    if (isLoading && orcamentos.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorConfig.amarelo),
        ),
      );
    }

    if (orcamentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.request_quote_outlined,
              size: 64,
              color: isDarkMode ? Colors.white54 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum orçamento encontrado',
              style: TextStyle(
                color: isDarkMode ? Colors.white54 : Colors.black38,
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => sendRequest(),
      color: ColorConfig.amarelo,
      child: ListView.builder(
        key: _listKey,
        controller: _scrollController,
        itemCount: filteredOrcamentos.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredOrcamentos.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(ColorConfig.amarelo),
                ),
              ),
            );
          }

          final orcamento = filteredOrcamentos[index];
          return _buildOrcamentoItem(
            orcamento, 
            isDarkMode, 
            textColor, 
            subtextColor, 
            cardColor, 
            cardBorderColor
          );
        },
      ),
    );
  }

  Widget _buildOrcamentoItem(
    Map<String, dynamic> orcamento, 
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
              builder: (context) => DetalhesPedido(orcamento: orcamento),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com número do orçamento e data
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
                        'Orçamento #${orcamento['numero_pedido'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: ColorConfig.amarelo,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _buildStatusBadge(orcamento['situacao_pedido']?.toString()),
                  ],
                ),
                const SizedBox(height: 12),

                // Informações do cliente
                Text(
                  (orcamento['cliente'] != null) 
                    ? orcamento['cliente']['nome_fantasia'] ?? 'Cliente não informado'
                    : 'Cliente não informado',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Informações adicionais
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.calendar_today,
                        'Data',
                        _formatDate(orcamento['data_pedido']?.toString()),
                        subtextColor,
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.attach_money,
                        'Valor',
                        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                            .format(double.parse(orcamento['valor_total']?.toString() ?? '0.0')),
                        subtextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Vendedor
                _buildInfoRow(
                  Icons.person,
                  'Vendedor',
                  (orcamento['vendedor'] != null) 
                    ? orcamento['vendedor']['nome'] ?? 'Não informado'
                    : 'Não informado',
                  subtextColor,
                ),
                
                const SizedBox(height: 12),
                
                // Botões de ação
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botão de PDF
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        child: ElevatedButton.icon(
                          onPressed: () => _generatePdfFromUrl(orcamento),
                          icon: const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Botão de visualizar URL
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 4),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final url = await _buildOrcamentoUrl(orcamento);
                            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          },
                          icon: const Icon(Icons.open_in_browser, size: 18),
                          label: const Text('Abrir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConfig.amarelo,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildStatusBadge(String? situacao) {
    Color backgroundColor;
    String label;
    
    switch (situacao?.toUpperCase()) {
      case 'O':
        backgroundColor = Colors.blue;
        label = 'Orçamento';
        break;
      case 'A':
        backgroundColor = Colors.green;
        label = 'Aprovado';
        break;
      case 'C':
        backgroundColor = Colors.red;
        label = 'Cancelado';
        break;
      default:
        backgroundColor = Colors.grey;
        label = 'Indefinido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color textColor) => Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Não informado';
    
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Data inválida';
    }
  }

  Future<String> _buildOrcamentoUrl(Map<String, dynamic> orcamento) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final numeroPedido = orcamento['numero_pedido']?.toString() ?? '';
      final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0140';
      final nomeUsuario = prefs.getString('usuario') ?? 'ms';
      
      return 'https://www.x-erp.com.br/sis/emissao_pedido_roddar.php?numero_pedido=$numeroPedido&codigo_empresa=$codigoEmpresa&nome_usuario=$nomeUsuario&token_xerp=xerp';
    } catch (e) {
      print('Erro ao construir URL: $e');
      final numeroPedido = orcamento['numero_pedido']?.toString() ?? '';
      return 'https://www.x-erp.com.br/sis/emissao_pedido_roddar.php?numero_pedido=$numeroPedido&codigo_empresa=0140&nome_usuario=ms&token_xerp=xerp';
    }
  }

  Future<void> _generatePdfFromUrl(Map<String, dynamic> orcamento) async {
    try {
      // Mostra loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorConfig.amarelo),
          ),
        ),
      );

      final url = await _buildOrcamentoUrl(orcamento);
      
      // Cria PDF simples com as informações do orçamento
      final pdf = pw.Document();
      
      // Carrega informações do orçamento
      final numeroPedido = orcamento['numero_pedido']?.toString() ?? '';
      final cliente = orcamento['cliente']?['nome_fantasia'] ?? 'Cliente não informado';
      final valor = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
          .format(double.parse(orcamento['valor_total']?.toString() ?? '0.0'));
      final data = _formatDate(orcamento['data_pedido']?.toString());
      final vendedor = orcamento['vendedor']?['nome'] ?? 'Não informado';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FFC107'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'RODDAR PNEUS',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Orçamento #$numeroPedido',
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Informações do cliente
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DADOS DO CLIENTE',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#333333'),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('Cliente: $cliente'),
                      pw.SizedBox(height: 5),
                      pw.Text('Data: $data'),
                      pw.SizedBox(height: 5),
                      pw.Text('Vendedor: $vendedor'),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Valor total
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F5F5F5'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'VALOR TOTAL:',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        valor,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#FFC107'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Link para visualização completa
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'VISUALIZAÇÃO COMPLETA',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Acesse o link abaixo para visualizar o orçamento completo:',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        url,
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.blue,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.Spacer(),
                
                // Rodapé
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F5F5F5'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Este orçamento foi gerado automaticamente pelo sistema Roddar Pneus',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Fecha o dialog de loading
      Navigator.of(context).pop();
      
      // Mostra opções de compartilhamento
      await _showPdfOptions(pdf, numeroPedido);
      
    } catch (e) {
      // Fecha o dialog de loading se ainda estiver aberto
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showPdfOptions(pw.Document pdf, String numeroPedido) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Opções do PDF',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            
            // Visualizar PDF
            ListTile(
              leading: const Icon(Icons.visibility, color: ColorConfig.amarelo),
              title: const Text('Visualizar PDF'),
              onTap: () async {
                Navigator.pop(context);
                await Printing.layoutPdf(onLayout: (format) => pdf.save());
              },
            ),
            
            // Compartilhar PDF
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Compartilhar PDF'),
              onTap: () async {
                Navigator.pop(context);
                await _sharePdf(pdf, numeroPedido);
              },
            ),
            
            // Salvar PDF
            ListTile(
              leading: const Icon(Icons.save, color: Colors.green),
              title: const Text('Salvar PDF'),
              onTap: () async {
                Navigator.pop(context);
                await _savePdf(pdf, numeroPedido);
              },
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePdf(pw.Document pdf, String numeroPedido) async {
    try {
      final bytes = await pdf.save();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/orcamento_$numeroPedido.pdf');
      await file.writeAsBytes(bytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Orçamento #$numeroPedido - Roddar Pneus',
        text: 'Segue em anexo o orçamento solicitado.',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao compartilhar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePdf(pw.Document pdf, String numeroPedido) async {
    try {
      final bytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/orcamento_$numeroPedido.pdf');
      await file.writeAsBytes(bytes);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF salvo em: ${file.path}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 