// ignore_for_file: unused_import

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:roddar_pneus/view/detalhe_cliente.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../class/api_config.dart';
import '../class/get_user_info.dart';
import '../class/color_config.dart';

class Clientes extends StatefulWidget {
  const Clientes({super.key});

  @override
  State<Clientes> createState() => _ClientesState();
}

class _ClientesState extends State<Clientes> {
  final GlobalKey _listKey = GlobalKey();
  bool isLoading = true;
  List<dynamic> clientes = [];
  List<dynamic> filteredOrcamentos = [];
  int codigo_empresa = 0;
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadDataFromPrefs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent) {
        print('chegou ao final da lista');
        _loadMoreData();
      }
    });
    sendRequest();
  }

  Future<void> _loadDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? clientesData = prefs.getString('clientes');

    if (clientesData != null && clientesData.isNotEmpty) {
      List<dynamic> savedClientes = json.decode(clientesData);
      clientes.addAll(savedClientes);
      filteredOrcamentos.addAll(savedClientes);

      setState(() {
        isLoading = false;
      });
    } else {
      // Carregar dados da API se não houver dados no SharedPreferences
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
    final codigoVendedor = prefs.getString('codigo_vendedor') ?? 0;

    const url = '${ApiConfig.apiUrl}/get-all-clientes';
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "codigo_empresa": codigoEmpresa,
        "codigo_regiao": codigoRegiao,
        "codigo_vendedor": codigoVendedor,
        "page": currentPage
      }),
    );

    if (response.statusCode == 200) {
      var newClientes = json.decode(response.body);

      if (newClientes.isNotEmpty) {
        setState(() {
          clientes.addAll(newClientes);
          filteredOrcamentos.addAll(newClientes);
          isLoading = false;
        });
        print(
            'Dados carregados com sucesso. Total de clientes: ${clientes.length}');
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
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> sendRequest() async {
    setState(() {
      isLoading = true;
    });

    // Limpe os dados antigos de clientes e filteredOrcamentos
    clientes.clear();
    filteredOrcamentos.clear();

    final prefs = await SharedPreferences.getInstance();
    final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0';
    final codigoRegiao = prefs.getString('codigo_regiao') ?? '0';
    final codigoVendedor = prefs.getString('codigo_vendedor') ?? '0';
    final nomeUsuario = prefs.getString('usuario') ?? '0';
    const String url = '${ApiConfig.apiUrl}/get-all-clientes';
    final search = searchController.text.toLowerCase();
    print(codigoVendedor);
    final response = await http.post(
      Uri.parse(url),
      body: json.encode({
        "codigo_empresa": codigoEmpresa,
        "codigo_regiao": codigoRegiao,
        "codigo_vendedor": codigoVendedor,
        "nome_usuario": nomeUsuario,
        "search_text": search
      }),
      headers: {
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      var newClientes = json.decode(response.body);

      // Salve os novos dados no SharedPreferences somente quando a pesquisa estiver vazia
      if (searchController.text.isEmpty) {
        prefs.setString('clientes', json.encode(newClientes));
      }

      clientes.addAll(newClientes);
      filteredOrcamentos.addAll(newClientes);

      setState(() {
        isLoading = false;
      });
    } else {
      throw Exception(
          'Erro na solicitação: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('clientes');
    clientes.clear();
    filteredOrcamentos.clear();
    sendRequest();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? ColorConfig.preto : Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: ColorConfig.amarelo,
        title: const Text(
          'CLIENTES',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: Column(
        children: [
          _buildSearchBar(isDarkMode),
          _buildTableHeader(isDarkMode),
          Expanded(child: _buildClientesList(isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildSearchField(isDarkMode)),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: ColorConfig.amarelo,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  sendRequest(); // Executa a busca
                },
                tooltip: 'Buscar',
              ),
            ),
          ],
        ),
      );

  Widget _buildSearchField(bool isDarkMode) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ColorConfig.amarelo.withOpacity(0.3)),
        ),
        child: TextField(
          controller: searchController,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: 'Pesquisar cliente',
            hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black38),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black38),
          ),
          onSubmitted: (_) => sendRequest(), // Mantém a busca ao pressionar Enter
        ),
      );

  Widget _buildTableHeader(bool isDarkMode) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isDarkMode ? ColorConfig.amarelo.withOpacity(0.1) : ColorConfig.amarelo.withOpacity(0.05),
        child: Row(
          children: [
            _buildHeaderCell('Código', isDarkMode),
            _buildHeaderCell('Razão Social', isDarkMode),
            _buildHeaderCell('Nome Fantasia', isDarkMode),
          ],
        ),
      );

  Widget _buildHeaderCell(String text, bool isDarkMode) => Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _buildClientesList(bool isDarkMode) => RefreshIndicator(
        onRefresh: _refreshData,
        color: ColorConfig.amarelo,
        child: ListView.builder(
          key: _listKey,
          controller: _scrollController,
          itemCount: filteredOrcamentos.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < filteredOrcamentos.length) {
              return _buildClienteItem(filteredOrcamentos[index], isDarkMode);
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

  Widget _buildClienteItem(Map<String, dynamic> cliente, bool isDarkMode) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black54;
    final cardColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;
    
    return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: cardColor,
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
              builder: (context) => ClientesDetalhes(cliente: cliente),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Código do cliente
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
                        'Código: ${cliente['codigo_cliente'] ?? ''}',
                        style: const TextStyle(
                          color: ColorConfig.amarelo,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    // Status do cliente (se houver)
                    if (cliente['ativo'] == 'S')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          'Ativo',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Razão Social
                Text(
                  cliente['razao_social'] ?? 'Razão Social não informada',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Nome Fantasia
                Text(
                  cliente['nome_fantasia'] ?? 'Nome Fantasia não informado',
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Informações de contato
                Row(
                  children: [
                    if (cliente['telefone']?.isNotEmpty ?? false)
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: subtextColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cliente['telefone'] ?? '',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    if (cliente['cidade']?.isNotEmpty ?? false)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: subtextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cliente['cidade']}/${cliente['uf'] ?? ''}',
                              style: TextStyle(
                                color: subtextColor,
                                fontSize: 14,
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
        ),
      );
  }
}
