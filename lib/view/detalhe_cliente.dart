import 'package:flutter/material.dart';
import 'package:roddar_pneus/class/color_config.dart';

class ClientesDetalhes extends StatelessWidget {
  final dynamic cliente;

  const ClientesDetalhes({Key? key, required this.cliente}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? ColorConfig.preto : Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: ColorConfig.amarelo,
        elevation: 2,
        title: const Text(
          'Detalhes do Cliente',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(
            context,
            'Dados Gerais',
            [
              _buildInfoItem(
                  context, 'Código', cliente['codigo_cliente'].toString(), Icons.tag),
              _buildInfoItem(
                  context, 'Razão Social', cliente['razao_social'], Icons.business),
              _buildInfoItem(
                  context, 'Nome Fantasia', cliente['nome_fantasia'], Icons.store),
              _buildInfoItem(
                  context,
                  'Código Região',
                  cliente['codigo_regiao']?.toString() ?? 'N/D',
                  Icons.location_searching),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            'Endereço',
            [
              _buildInfoItem(
                  context,
                  'Endereço',
                  '${cliente['endereco']}, ${cliente['numero']}',
                  Icons.location_on),
              _buildInfoItem(context, 'CEP', cliente['cep'], Icons.map),
              _buildInfoItem(context, 'Bairro', cliente['bairro'], Icons.location_city),
              _buildInfoItem(context, 'Cidade/UF',
                  '${cliente['cidade']}/${cliente['uf']}', Icons.location_city),
              _buildInfoItem(context, 'País', cliente['pais'], Icons.public),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            'Contatos',
            [
              _buildInfoItem(
                  context,
                  'Telefones',
                  '${cliente['telefone']} ${cliente['telefone2'] ?? ''}',
                  Icons.phone),
              _buildInfoItem(
                  context,
                  'Celulares',
                  '${cliente['celular1']} ${cliente['celular2'] ?? ''}',
                  Icons.phone_android),
              _buildInfoItem(context, 'E-mail', cliente['e_mail'], Icons.email),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            context,
            'Financeiro',
            [
              _buildInfoItem(context, 'Limite de Crédito',
                  cliente['limite_credito'].toString(), Icons.credit_card),
              _buildInfoItem(
                  context,
                  'Saldo Devedor',
                  cliente['saldo_devedor_atual'].toString(),
                  Icons.account_balance),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, List<Widget> children) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cardColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;
    
    return Card(
        color: cardColor,
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
                style: TextStyle(
                  color: textColor,
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
  }

  Widget _buildInfoItem(BuildContext context, String label, String value, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtextColor = isDarkMode ? Colors.white.withOpacity(0.7) : Colors.black54;
    
    return Padding(
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
                icon,
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
                      color: subtextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: textColor,
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
}
