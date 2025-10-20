import 'package:flutter/material.dart';
import 'package:roddar_pneus/class/color_config.dart';
import 'package:roddar_pneus/view/home.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../class/api_config.dart';

class ConfirmarPedido extends StatefulWidget {
  final List<Map<String, dynamic>> orcamento;
  final String? numeroPedido;
  final double valorFrete;

  const ConfirmarPedido({
    Key? key, 
    required this.orcamento, 
    this.numeroPedido,
    this.valorFrete = 0.0,
  }) : super(key: key);

  @override
  State<ConfirmarPedido> createState() => _ConfirmarPedidoState();
}

class _ConfirmarPedidoState extends State<ConfirmarPedido> {
  bool _isLoading = false;
  String? _codigoEmpresa;
  Map<String, dynamic>? _dadosPedido;
  List<Map<String, dynamic>>? _itensPedido;

  @override
  void initState() {
    super.initState();
    _inicializarDados();
  }

  Future<void> _inicializarDados() async {
    print('🚀 Inicializando dados...');
    await _carregarCodigoEmpresa();
    if (widget.numeroPedido != null) {
      print('📋 Número do pedido disponível, buscando dados...');
      await _buscarDadosPedido();
    } else {
      print('❌ Número do pedido não disponível');
    }
  }

  Future<void> _carregarCodigoEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    final codigo = prefs.getString('codigo_empresa');
    print('🏢 Código da empresa carregado: $codigo');
    setState(() {
      _codigoEmpresa = codigo;
    });
  }

  Future<void> _buscarDadosPedido() async {
    print('🔍 Iniciando busca do pedido...');
    print('📋 Número do pedido: ${widget.numeroPedido}');
    print('🏢 Código da empresa: $_codigoEmpresa');
    
    if (widget.numeroPedido == null || _codigoEmpresa == null) {
      print('❌ Dados insuficientes para buscar pedido');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🌐 Fazendo requisição para: ${ApiConfig.apiUrl}/get-pedido-roddar');
      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/get-pedido-roddar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo_empresa': _codigoEmpresa,
          'numero_pedido': widget.numeroPedido,
        }),
      );

      print('📡 Status da resposta: ${response.statusCode}');
      print('📄 Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Dados decodificados: $data');
        
        if (data['pedido'] != null && data['pedido'].isNotEmpty) {
          print('✅ Pedido encontrado!');
          print('📦 Dados do pedido: ${data['pedido'][0]}');
          print('🛍️ Itens do pedido: ${data['mpedidos']}');
          
          setState(() {
            _dadosPedido = data['pedido'][0];
            _itensPedido = List<Map<String, dynamic>>.from(data['mpedidos'] ?? []);
          });
          
          print('🎯 Estado atualizado com dados da API');
        } else {
          print('❌ Pedido não encontrado na resposta');
          _mostrarMensagem('Pedido não encontrado', isErro: true);
        }
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        _mostrarMensagem('Erro ao buscar pedido: ${response.statusCode}', isErro: true);
      }
    } catch (e) {
      print('💥 Erro na requisição: $e');
      _mostrarMensagem('Erro ao buscar pedido: $e', isErro: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('🏁 Busca finalizada');
      }
    }
  }

  double get subtotalProdutos {
    if (_dadosPedido != null) {
      return double.parse(_dadosPedido!['valor_produto'].toString());
    }
    return widget.orcamento.fold(
      0,
      (sum, item) => sum + (double.parse(item['valor_produto'].toString())),
    );
  }

  double get valorIpi {
    if (_dadosPedido != null) {
      return double.parse(_dadosPedido!['valor_ipi'].toString());
    }
    return 0.0;
  }

  double get valorFrete {
    if (_dadosPedido != null) {
      return double.parse(_dadosPedido!['valor_frete'].toString());
    }
    return widget.valorFrete;
  }

  double get totalPedido {
    if (_dadosPedido != null) {
      return double.parse(_dadosPedido!['valor_total'].toString());
    }
    return subtotalProdutos + valorFrete;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.preto,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildListaProdutos()),
              _buildResumoValores(),
              _buildFooter(),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(ColorConfig.amarelo),
                ),
              ),
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
          'CONFIRMAR PEDIDO',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 2,
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorConfig.amarelo.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(
              color: ColorConfig.amarelo.withOpacity(0.2),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resumo do Pedido',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                      .format(totalPedido),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorConfig.amarelo,
                  ),
                ),
              ],
            ),
            if (_dadosPedido != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ColorConfig.amarelo.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long,
                          color: ColorConfig.amarelo,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pedido #${_dadosPedido!['numero_pedido']}',
                          style: const TextStyle(
                            color: ColorConfig.amarelo,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dadosPedido!['nome_cliente'] ?? 'Cliente não informado',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Data: ${_dadosPedido!['data_pedido']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.local_shipping,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Transportador: ${_dadosPedido!['codigo_transportador']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildListaProdutos() {
    final produtos = _itensPedido ?? widget.orcamento;
    print('📋 Listando produtos:');
    print('🔄 Usando dados da API: ${_itensPedido != null}');
    print('📦 Quantidade de produtos: ${produtos.length}');
    print('🛍️ Produtos: $produtos');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: produtos.length,
      itemBuilder: (context, index) => _buildProdutoCard(
        produtos[index],
        index,
      ),
    );
  }

  Widget _buildProdutoCard(Map<String, dynamic> item, int index) {
    // Debug: imprimir dados do item para verificar campos disponíveis
    print('Dados do item $index: $item');
    
    return Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: ColorConfig.amarelo.withOpacity(0.2),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: ColorConfig.amarelo,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            'Produto: ${item['codigo_produto']}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                '${item['descricao_produto'] ?? item['produto'] ?? item['descricao'] ?? item['nome_produto'] ?? 'Produto não encontrado'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quantidade: ${item['quantidade']}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Preço: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(double.parse(item['preco_unitario'].toString()))}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'IPI: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(double.tryParse((item['valor_ipi'] ?? 0).toString()) ?? 0)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Frete: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(double.tryParse((item['valor_frete'] ?? 0).toString()) ?? 0)}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Valor total produto: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(double.parse(item['valor_total'].toString()))}',
                style: const TextStyle(
                  color: ColorConfig.amarelo,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildResumoValores() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border(
            top: BorderSide(
              color: ColorConfig.amarelo.withOpacity(0.2),
            ),
            bottom: BorderSide(
              color: ColorConfig.amarelo.withOpacity(0.2),
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal (Produtos):',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                      .format(subtotalProdutos),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (valorIpi > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'IPI:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                        .format(valorIpi),
                    style: const TextStyle(
                      color: ColorConfig.amarelo,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Valor do Frete:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                      .format(valorFrete),
                  style: TextStyle(
                    color: valorFrete > 0 ? ColorConfig.amarelo : Colors.white,
                    fontSize: 16,
                    fontWeight: valorFrete > 0 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: ColorConfig.amarelo.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dadosPedido != null ? 'Total Geral:' : 'Total Geral:',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                      .format(totalPedido),
                  style: const TextStyle(
                    color: ColorConfig.amarelo,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildFooter() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          border: Border(
            top: BorderSide(
              color: ColorConfig.amarelo.withOpacity(0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exibirDialogCancelamento,
                icon: const Icon(Icons.close),
                label: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _confirmarPedido,
                icon: const Icon(Icons.check),
                label: const Text(
                  'Confirmar',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConfig.amarelo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  void _exibirDialogCancelamento() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Cancelar Pedido',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Tem certeza que deseja cancelar este pedido? Esta ação não pode ser desfeita.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Não',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelarPedido();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Sim, Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelarPedido() async {
    if (widget.numeroPedido == null || _codigoEmpresa == null) {
      _mostrarMensagem('Informações do pedido não encontradas', isErro: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/cancelar-pedido'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'codigo_empresa': _codigoEmpresa,
          'numero_pedido': widget.numeroPedido,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          _mostrarMensagem('Pedido cancelado com sucesso');
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          });
        } else {
          _mostrarMensagem(data['message'] ?? 'Erro ao cancelar pedido', isErro: true);
        }
      } else {
        _mostrarMensagem('Erro de conexão: ${response.statusCode}', isErro: true);
      }
    } catch (e) {
      _mostrarMensagem('Erro ao cancelar pedido: $e', isErro: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarMensagem(String mensagem, {bool isErro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isErro ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirmarPedido() async {
    if (_dadosPedido == null) {
      _mostrarMensagem('Aguardando dados do pedido...', isErro: true);
      return;
    }

    if (_codigoEmpresa == null) {
      _mostrarMensagem('Código da empresa não encontrado', isErro: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Limpar cache dos produtos do pedido
      await _limparCacheProdutos();
      
      _mostrarMensagem('Pedido confirmado com sucesso!');
      
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      });
    } catch (e) {
      _mostrarMensagem('Erro ao confirmar pedido: $e', isErro: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _limparCacheProdutos() async {
    final produtos = _itensPedido ?? widget.orcamento;
    
    print('🧹 Iniciando limpeza de cache para ${produtos.length} produtos');
    
    for (final produto in produtos) {
      try {
        final codigoProduto = produto['codigo_produto']?.toString();
        
        if (codigoProduto == null || codigoProduto.isEmpty) {
          print('⚠️ Código do produto não encontrado: $produto');
          continue;
        }
        
        print('🔄 Limpando cache para produto: $codigoProduto');
        
        final response = await http.post(
          Uri.parse('${ApiConfig.apiUrl}/limpar-cache-produtos'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'codigo_empresa': _codigoEmpresa,
            'codigo_produto': codigoProduto,
          }),
        );
        
        print('📡 Resposta para produto $codigoProduto: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print('✅ Cache limpo para produto $codigoProduto: ${data['message'] ?? 'Sucesso'}');
        } else {
          print('❌ Erro ao limpar cache para produto $codigoProduto: ${response.statusCode}');
        }
      } catch (e) {
        print('💥 Erro ao limpar cache para produto ${produto['codigo_produto']}: $e');
      }
    }
    
    print('🏁 Limpeza de cache finalizada');
  }
}
