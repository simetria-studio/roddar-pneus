import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roddar_pneus/class/color_config.dart';

class DetalhesPedido extends StatelessWidget {
  final dynamic orcamento;

  const DetalhesPedido({Key? key, required this.orcamento}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? ColorConfig.preto : Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: ColorConfig.amarelo,
        elevation: 2,
        title: Text(
          'Pedido #${orcamento['numero_pedido']}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      );

  Widget _buildBody(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: 16),
          _buildClienteInfo(context),
          _buildPagamentoInfo(context),
          _buildTransporteInfo(context),
          _buildValorInfo(context),
          const SizedBox(height: 24),
          _buildProdutosSection(context),
        ],
      );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? ColorConfig.amarelo.withOpacity(0.1) : ColorConfig.amarelo.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ColorConfig.amarelo.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status do Pedido',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusBadge(orcamento['situacao_pedido']),
          ],
        ),
      );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required List<InfoItem> items,
    required IconData icon,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final cardColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;
    
    return Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: ColorConfig.amarelo.withOpacity(0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: ColorConfig.amarelo),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item.label}:',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.value,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      );
  }

  Widget _buildClienteInfo(BuildContext context) => _buildInfoCard(
        context: context,
        title: 'Informações do Cliente',
        icon: Icons.person_outline,
        items: [
          InfoItem(
            'Nome',
            orcamento['cliente']['razao_social'],
          ),
          InfoItem(
            'Código',
            orcamento['codigo_cliente'],
          ),
          InfoItem(
            'CPF/CNPJ',
            orcamento['cliente']?['cnpj_cpf'] ?? 'Não disponível',
          ),
          InfoItem(
            'Telefone',
            orcamento['telefone_contato'],
          ),
        ],
      );

  Widget _buildPagamentoInfo(BuildContext context) => _buildInfoCard(
        context: context,
        title: 'Informações de Pagamento',
        icon: Icons.payment,
        items: [
          InfoItem(
            'Condição',
            orcamento['condipag']?['descricao'] ?? 'Não disponível',
          ),
          InfoItem(
            'Tipo Doc.',
            orcamento['tipodocumento']?['descricao_tipodoc'] ??
                'Não disponível',
          ),
        ],
      );

  Widget _buildTransporteInfo(BuildContext context) => _buildInfoCard(
        context: context,
        title: 'Informações de Transporte',
        icon: Icons.local_shipping,
        items: [
          InfoItem(
            'Transportador',
            orcamento['transportadora']?['descricao_transportador'] ??
                'Não disponível',
          ),
          InfoItem(
            'Código',
            orcamento['transportadora']?['codigo_transportador'] ??
                'Não disponível',
          ),
        ],
      );

  Widget _buildValorInfo(BuildContext context) => _buildInfoCard(
        context: context,
        title: 'Valor Total',
        icon: Icons.attach_money,
        items: [
          InfoItem(
            'Total',
            _formatCurrency(orcamento['valor_total']),
          ),
        ],
      );

  Widget _buildProdutosSection(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 16),
            child: Text(
              'Produtos',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...List.generate(
            orcamento['itens_pedido'].length,
            (index) => _buildProdutoCard(context, orcamento['itens_pedido'][index]),
          ),
        ],
      );
  }

  Widget _buildProdutoCard(BuildContext context, dynamic item) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white70 : Colors.black54;
    final cardColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;
    final dividerColor = isDarkMode ? Colors.white24 : Colors.black12;
    
    return Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: ColorConfig.amarelo.withOpacity(0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart, color: ColorConfig.amarelo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['descricao_produto'],
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProdutoInfo(context, 'Preço Unit.', _formatCurrency(item['preco_unitario'])),
              _buildProdutoInfo(context, 'Quantidade', item['quantidade'].toString()),
              _buildProdutoInfo(
                context,
                'Total',
                _formatCurrency(item['preco_unitario'] * item['quantidade']),
              ),
              Divider(color: dividerColor),
              _buildProdutoInfo(context, 'Lote', item['numero_lote']),
              _buildProdutoInfo(context, 'Descrição', item['descricao_produto']),
            ],
          ),
        ),
      );
  }

  Widget _buildProdutoInfo(BuildContext context, String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white70 : Colors.black54;
    
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '$label:',
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildStatusBadge(String status) {
    final statusInfo = _getStatusInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusInfo.color),
      ),
      child: Text(
        statusInfo.text,
        style: TextStyle(
          color: statusInfo.color,
          fontSize: 14,
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

class InfoItem {
  final String label;
  final String value;
  InfoItem(this.label, this.value);
}

class StatusInfo {
  final String text;
  final Color color;
  StatusInfo(this.text, this.color);
}
