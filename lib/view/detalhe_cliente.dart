import 'package:flutter/material.dart';
import 'package:roddar_pneus/class/color_config.dart';

class ClientesDetalhes extends StatelessWidget {
  final dynamic cliente;

  const ClientesDetalhes({Key? key, required this.cliente}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorConfig.preto,
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
            'Dados Gerais',
            [
              _buildInfoItem(
                  'Código', cliente['codigo_cliente'].toString(), Icons.tag),
              _buildInfoItem(
                  'Razão Social', cliente['razao_social'], Icons.business),
              _buildInfoItem(
                  'Nome Fantasia', cliente['nome_fantasia'], Icons.store),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Endereço',
            [
              _buildInfoItem(
                  'Endereço',
                  '${cliente['endereco']}, ${cliente['numero']}',
                  Icons.location_on),
              _buildInfoItem('CEP', cliente['cep'], Icons.map),
              _buildInfoItem('Bairro', cliente['bairro'], Icons.location_city),
              _buildInfoItem('Cidade/UF',
                  '${cliente['cidade']}/${cliente['uf']}', Icons.location_city),
              _buildInfoItem('País', cliente['pais'], Icons.public),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Contatos',
            [
              _buildInfoItem(
                  'Telefones',
                  '${cliente['telefone']} ${cliente['telefone2'] ?? ''}',
                  Icons.phone),
              _buildInfoItem(
                  'Celulares',
                  '${cliente['celular1']} ${cliente['celular2'] ?? ''}',
                  Icons.phone_android),
              _buildInfoItem('E-mail', cliente['e_mail'], Icons.email),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Financeiro',
            [
              _buildInfoItem('Limite de Crédito',
                  cliente['limite_credito'].toString(), Icons.credit_card),
              _buildInfoItem(
                  'Saldo Devedor',
                  cliente['saldo_devedor_atual'].toString(),
                  Icons.account_balance),
            ],
          ),
        ],
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

  Widget _buildInfoItem(String label, String value, IconData icon) => Padding(
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
