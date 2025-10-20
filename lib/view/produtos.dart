import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:roddar_pneus/class/api_config.dart';
import 'package:roddar_pneus/class/color_config.dart';
import 'package:roddar_pneus/view/detalhe_produto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Set<String> _produtosSelecionados = <String>{};
  bool _modoSelecao = false;

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

  Future<void> _shareOnWhatsApp(Map<String, dynamic> produto) async {
    try {
      final codigo = produto['codigo_produto'] ?? '';
      final descricao = produto['descricao_produto'] ?? '';
      final preco = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
          .format(produto['preco_venda'] ?? 0);
      
      final message = '🛞 *PRODUTO DISPONÍVEL*\n\n'
          '📋 *Código:* $codigo\n'
          '📝 *Descrição:* $descricao\n'
          '💰 *Preço:* $preco\n\n'
          '📞 Entre em contato para mais informações!';
      
      final encodedMessage = Uri.encodeComponent(message);
      
      // Tenta várias URLs do WhatsApp
      final whatsappUrls = [
        'whatsapp://send?text=$encodedMessage',
        'https://wa.me/?text=$encodedMessage',
        'https://api.whatsapp.com/send?text=$encodedMessage',
      ];
      
      bool launched = false;
      
      for (final url in whatsappUrls) {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            launched = true;
            break;
          }
        } catch (e) {
          print('Erro ao tentar abrir URL: $url - $e');
          continue;
        }
      }
      
      if (!launched) {
        _showError('WhatsApp não está instalado ou não foi possível abrir');
      }
    } catch (e) {
      print('Erro completo: $e');
      _showError('Erro ao compartilhar produto');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? ColorConfig.preto : Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(isDarkMode),
          _buildTableHeader(isDarkMode),
          Expanded(child: _buildProdutosList(isDarkMode)),
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
        actions: [
          if (_modoSelecao) ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelarSelecao,
              tooltip: 'Cancelar seleção',
            ),
            if (_produtosSelecionados.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _compartilharProdutosSelecionados,
                tooltip: 'Compartilhar selecionados',
              ),
          ] else
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _ativarModoSelecao,
              tooltip: 'Selecionar produtos',
            ),
        ],
      );

  Widget _buildSearchBar(bool isDarkMode) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: ColorConfig.amarelo.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Buscar por código ou descrição',
                    hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black38),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: isDarkMode ? Colors.white54 : Colors.black38),
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

  Widget _buildTableHeader(bool isDarkMode) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isDarkMode ? ColorConfig.amarelo.withOpacity(0.1) : ColorConfig.amarelo.withOpacity(0.05),
        child: Row(
          children: [
            Expanded(child: _HeaderText('Código', isDarkMode)),
            Expanded(child: _HeaderText('Descrição', isDarkMode)),
            Expanded(child: _HeaderText('Valor', isDarkMode)),
            Expanded(child: _HeaderText('Estoque', isDarkMode)),
          ],
        ),
      );

  Widget _buildProdutosList(bool isDarkMode) => _isLoading
      ? const Center(child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(ColorConfig.amarelo),
        ))
      : ListView.builder(
          itemCount: _filteredProdutos.length,
          itemBuilder: (context, index) =>
              _buildProdutoItem(_filteredProdutos[index], isDarkMode),
        );

  Widget _buildProdutoItem(Map<String, dynamic> produto, bool isDarkMode) {
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
          onTap: () async {
            if (_modoSelecao) {
              _toggleProdutoSelecao(produto);
            } else {
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
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com código e checkbox
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ColorConfig.amarelo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Código: ${produto['codigo_produto'] ?? ''}',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : ColorConfig.amarelo.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (_modoSelecao) ...[
                      const SizedBox(width: 8),
                      Checkbox(
                        value: _produtosSelecionados.contains(produto['codigo_produto']?.toString()),
                        onChanged: (value) => _toggleProdutoSelecao(produto),
                        activeColor: ColorConfig.amarelo,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                // Descrição do produto
                Text(
                  produto['descricao_produto'] ?? '',
                  style: TextStyle(
                    color: textColor,
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo: ${produto['saldo_atual']}',
                          style: TextStyle(
                            color: subtextColor,
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
                    // Botão de compartilhar no WhatsApp (só aparece fora do modo de seleção)
                    if (!_modoSelecao)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366), // Cor verde do WhatsApp
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.share,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _shareOnWhatsApp(produto),
                          tooltip: 'Compartilhar no WhatsApp',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
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
        return _sortByPriceAsc
            ? precoA.compareTo(precoB)
            : precoB.compareTo(precoA);
      });
    });
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

  void _ativarModoSelecao() {
    setState(() {
      _modoSelecao = true;
      _produtosSelecionados.clear();
    });
  }

  void _cancelarSelecao() {
    setState(() {
      _modoSelecao = false;
      _produtosSelecionados.clear();
    });
  }

  void _toggleProdutoSelecao(Map<String, dynamic> produto) {
    final codigoProduto = produto['codigo_produto']?.toString();
    if (codigoProduto == null) return;

    setState(() {
      if (_produtosSelecionados.contains(codigoProduto)) {
        _produtosSelecionados.remove(codigoProduto);
      } else {
        _produtosSelecionados.add(codigoProduto);
      }
    });
  }

  Future<void> _compartilharProdutosSelecionados() async {
    if (_produtosSelecionados.isEmpty) {
      _showError('Nenhum produto selecionado');
      return;
    }

    try {
      // Buscar os produtos selecionados
      final produtosParaCompartilhar = _filteredProdutos.where((produto) {
        return _produtosSelecionados.contains(produto['codigo_produto']?.toString());
      }).toList();

      if (produtosParaCompartilhar.isEmpty) {
        _showError('Produtos selecionados não encontrados');
        return;
      }

      // Construir mensagem com múltiplos produtos
      String message = '🛞 *PRODUTOS DISPONÍVEIS*\n\n';
      
      for (int i = 0; i < produtosParaCompartilhar.length; i++) {
        final produto = produtosParaCompartilhar[i];
        final codigo = produto['codigo_produto'] ?? '';
        final descricao = produto['descricao_produto'] ?? '';
        final preco = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
            .format(produto['preco_venda'] ?? 0);
        
        message += '📋 *Código:* $codigo\n';
        message += '📝 *Descrição:* $descricao\n';
        message += '💰 *Preço:* $preco\n';
        
        if (i < produtosParaCompartilhar.length - 1) {
          message += '─' * 20 + '\n';
        }
      }
      
      message += '\n📞 Entre em contato para mais informações!';
      
      final encodedMessage = Uri.encodeComponent(message);
      
      // Tenta várias URLs do WhatsApp
      final whatsappUrls = [
        'whatsapp://send?text=$encodedMessage',
        'https://wa.me/?text=$encodedMessage',
        'https://api.whatsapp.com/send?text=$encodedMessage',
      ];
      
      bool launched = false;
      
      for (final url in whatsappUrls) {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            launched = true;
            break;
          }
        } catch (e) {
          print('Erro ao tentar abrir URL: $url - $e');
          continue;
        }
      }
      
      if (!launched) {
        _showError('WhatsApp não está instalado ou não foi possível abrir');
      } else {
        // Limpar seleção após compartilhamento bem-sucedido
        _cancelarSelecao();
      }
    } catch (e) {
      print('Erro completo: $e');
      _showError('Erro ao compartilhar produtos');
    }
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final bool isDarkMode;
  
  const _HeaderText(this.text, this.isDarkMode);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black87,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
