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

  @override
  void initState() {
    super.initState();
    _carregarCodigoEmpresa();
  }

  Future<void> _carregarCodigoEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _codigoEmpresa = prefs.getString('codigo_empresa');
    });
  }

  double get subtotalProdutos => widget.orcamento.fold(
        0,
        (sum, item) => sum + (double.parse(item['valor_produto'].toString())),
      );

  double get totalPedido => subtotalProdutos + widget.valorFrete;

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
        child: Row(
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
      );

  Widget _buildListaProdutos() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.orcamento.length,
        itemBuilder: (context, index) => _buildProdutoCard(
          widget.orcamento[index],
          index,
        ),
      );

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
                '${item['produto'] ?? item['descricao_produto'] ?? item['descricao'] ?? item['nome_produto'] ?? 'Produto não encontrado'}',
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
                'Total: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(double.parse(item['valor_produto'].toString()))}',
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
                      .format(widget.valorFrete),
                  style: TextStyle(
                    color: widget.valorFrete > 0 ? ColorConfig.amarelo : Colors.white,
                    fontSize: 16,
                    fontWeight: widget.valorFrete > 0 ? FontWeight.bold : FontWeight.normal,
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
                const Text(
                  'Total Geral:',
                  style: TextStyle(
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

  void _confirmarPedido() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }
}
