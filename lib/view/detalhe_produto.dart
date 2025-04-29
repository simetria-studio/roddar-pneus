import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:roddar_pneus/class/api_config.dart';
import 'package:roddar_pneus/class/color_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetalheProduto extends StatefulWidget {
  final Map<String, dynamic> produto;

  const DetalheProduto({Key? key, required this.produto}) : super(key: key);

  @override
  State<DetalheProduto> createState() => _DetalheProdutoState();
}

class _DetalheProdutoState extends State<DetalheProduto> {
  final _precoController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _precoController.text = widget.produto['preco_venda'].toString();
  }

  Future<void> _atualizarPreco() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0';

      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/update-produto-preco'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'codigo_empresa': codigoEmpresa,
          'codigo_produto': widget.produto['codigo_produto'],
          'preco_venda': double.parse(_precoController.text),
        }),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        setState(() {
          widget.produto['preco_venda'] = double.parse(_precoController.text);
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preço atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Falha ao atualizar preço');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar preço: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPrecoField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _precoController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: ColorConfig.amarelo.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isLoading
              ? const CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(ColorConfig.amarelo),
                )
              : IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: _atualizarPreco,
                ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() {
                _isEditing = false;
                _precoController.text =
                    widget.produto['preco_venda'].toString();
              });
            },
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                .format(widget.produto['preco_venda']),
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, color: ColorConfig.amarelo),
          onPressed: () {
            setState(() => _isEditing = true);
          },
        ),
      ],
    );
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
                _buildInfoRow('Código', widget.produto['codigo_produto'] ?? ''),
                _buildInfoRow(
                    'Descrição', widget.produto['descricao_produto'] ?? ''),
                _buildInfoRow('Preço', '', customWidget: _buildPrecoField()),
                _buildInfoRow('Saldo', '${widget.produto['saldo_atual'] ?? 0}'),
                _buildInfoRow(
                    'Depósito', widget.produto['deposito_padrao'] ?? ''),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
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

  Widget _buildInfoRow(String label, String value, {Widget? customWidget}) {
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
              child: const Icon(
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
                      color: subtextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  customWidget ??
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
