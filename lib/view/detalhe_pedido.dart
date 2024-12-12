import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roddar_pneus/class/color_config.dart';

class DetalhesPedido extends StatelessWidget {
  final dynamic orcamento;

  const DetalhesPedido({Key? key, required this.orcamento}) : super(key: key);

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
        title: Text(
          'Pedido #${orcamento['numero_pedido']}',
          style: const TextStyle(
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
          _buildClienteInfo(),
          _buildPagamentoInfo(),
          _buildTransporteInfo(),
          _buildValorInfo(),
          const SizedBox(height: 24),
          _buildProdutosSection(),
        ],
      );

  Widget _buildHeaderCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorConfig.amarelo.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ColorConfig.amarelo.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status do Pedido',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusBadge(orcamento['situacao_pedido']),
          ],
        ),
      );

  Widget _buildInfoCard({
    required String title,
    required List<InfoItem> items,
    required IconData icon,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.white.withOpacity(0.05),
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
                    style: const TextStyle(
                      color: Colors.white,
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
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            item.value,
                            style: const TextStyle(
                              color: Colors.white,
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

  Widget _buildClienteInfo() => _buildInfoCard(
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

  Widget _buildPagamentoInfo() => _buildInfoCard(
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

  Widget _buildTransporteInfo() => _buildInfoCard(
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

  Widget _buildValorInfo() => _buildInfoCard(
        title: 'Valor Total',
        icon: Icons.attach_money,
        items: [
          InfoItem(
            'Total',
            _formatCurrency(orcamento['valor_total']),
          ),
        ],
      );

  Widget _buildProdutosSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 16),
            child: Text(
              'Produtos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...List.generate(
            orcamento['itens_pedido'].length,
            (index) => _buildProdutoCard(orcamento['itens_pedido'][index]),
          ),
        ],
      );

  Widget _buildProdutoCard(dynamic item) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: Colors.white.withOpacity(0.05),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildProdutoInfo(
                  'Preço Unit.', _formatCurrency(item['preco_unitario'])),
              _buildProdutoInfo('Quantidade', item['quantidade'].toString()),
              _buildProdutoInfo(
                'Total',
                _formatCurrency(item['preco_unitario'] * item['quantidade']),
              ),
              const Divider(color: Colors.white24),
              _buildProdutoInfo('Lote', item['numero_lote']),
              _buildProdutoInfo('Descrição', item['descricao_produto']),
            ],
          ),
        ),
      );

  Widget _buildProdutoInfo(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '$label:',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );

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
