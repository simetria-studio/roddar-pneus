import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roddar_pneus/class/color_config.dart';

class DetalheProduto extends StatelessWidget {
  final Map<String, dynamic> produto;

  const DetalheProduto({Key? key, required this.produto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.preto,
      appBar: AppBar(
        backgroundColor: ColorConfig.amarelo,
        title: const Text(
          'Detalhes do Produto',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              'Informações do Produto',
              [
                _buildInfoRow('Código', produto['codigo_produto'] ?? ''),
                _buildInfoRow('Descrição', produto['descricao_produto'] ?? ''),
                _buildInfoRow(
                  'Preço',
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                      .format(produto['preco_venda'] ?? 0),
                ),
                _buildInfoRow('Saldo', '${produto['saldo_atual'] ?? 0}'),
                _buildInfoRow('Depósito', produto['deposito_padrao'] ?? ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) => Card(
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
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorConfig.amarelo.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline,
                color: ColorConfig.amarelo,
                size: 20,
              ),
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
        ),
      );
}
