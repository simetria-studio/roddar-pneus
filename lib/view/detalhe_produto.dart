import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roddar_pneus/class/color_config.dart';

class ProdutoDetalhes extends StatelessWidget {
  final dynamic produto;

  const ProdutoDetalhes({Key? key, required this.produto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.preto,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: ColorConfig.amarelo,
        elevation: 2,
        title: const Text(
          'Detalhes do Produto',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      );

  Widget _buildBody() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildDetailsCard(),
          const SizedBox(height: 16),
          _buildStockCard(),
        ],
      );

  Widget _buildHeaderCard() => Card(
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: ColorConfig.amarelo.withOpacity(0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                'Código',
                produto['codigo_produto'].toString(),
                Icons.qr_code,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Descrição',
                produto['descricao_produto'],
                Icons.description,
              ),
            ],
          ),
        ),
      );

  Widget _buildDetailsCard() => Card(
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: ColorConfig.amarelo.withOpacity(0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informações do Produto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'Preço',
                _formatPreco(),
                Icons.attach_money,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Unidade',
                produto['unidade_medida'] ?? 'N/D',
                Icons.straighten,
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Depósito',
                produto['deposito_padrao'] ?? 'N/D',
                Icons.warehouse,
              ),
            ],
          ),
        ),
      );

  Widget _buildStockCard() => Card(
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: ColorConfig.amarelo.withOpacity(0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estoque',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'Saldo Atual',
                _formatSaldo(),
                Icons.inventory,
              ),
            ],
          ),
        ),
      );

  Widget _buildInfoRow(String label, String value, IconData icon) => Row(
        children: [
          Icon(
            icon,
            color: ColorConfig.amarelo,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  String _formatPreco() {
    if (produto['preco_produto'] != null &&
        produto['preco_produto'].isNotEmpty) {
      final preco = double.tryParse(
              produto['preco_produto'][0]['preco_tabela'].toString()) ??
          0.0;
      return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
          .format(preco);
    }
    return 'R\$ 0,00';
  }

  String _formatSaldo() {
    if (produto['saldo'] != null && produto['saldo'].isNotEmpty) {
      return produto['saldo'][0]['saldo_atual'].toString();
    }
    return '0';
  }
}
