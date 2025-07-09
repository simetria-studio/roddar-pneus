import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:roddar_pneus/class/api_config.dart';
import 'package:roddar_pneus/class/color_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String? _codigoEmpresa;

  @override
  void initState() {
    super.initState();
    _precoController.text = widget.produto['preco_venda'].toString();
    _loadCodigoEmpresa();
  }

  Future<void> _loadCodigoEmpresa() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _codigoEmpresa = prefs.getString('codigo_empresa') ?? '0140';
    });
  }

  String _buildImageUrl() {
    if (_codigoEmpresa == null) return '';
    
    final codigoProduto = widget.produto['codigo_produto']?.toString() ?? '';
    if (codigoProduto.isEmpty) return '';
    
    // Estrutura: https://www.x-erp.com.br/sis/arquivo/0140/imagens_p/012987/0140012987-1.jpg
    return 'https://www.x-erp.com.br/sis/arquivo/$_codigoEmpresa/imagens_p/$codigoProduto/$_codigoEmpresa$codigoProduto-1.jpg';
  }

  Widget _buildProductImage() {
    final imageUrl = _buildImageUrl();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (imageUrl.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade200,
              Colors.grey.shade300,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ColorConfig.amarelo.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 80,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              'Imagem não disponível',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 300,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: ColorConfig.amarelo.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey.shade200,
                        Colors.grey.shade300,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(ColorConfig.amarelo),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Carregando imagem...',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.red.shade100,
                        Colors.red.shade200,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 50,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Erro ao carregar imagem',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Botão de zoom
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: () => _showImageFullScreen(imageUrl),
                icon: const Icon(
                  Icons.zoom_in,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          
          // Botão de compartilhamento
          Positioned(
            top: 12,
            right: 60, // Posicionar ao lado do botão de zoom
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF25D366), // Cor verde do WhatsApp
                borderRadius: BorderRadius.circular(20),
              ),
              child: IconButton(
                onPressed: _shareOnWhatsApp,
                icon: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 20,
                ),
                tooltip: 'Compartilhar no WhatsApp',
              ),
            ),
          ),
          
          // Gradiente inferior para melhor legibilidade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.produto['descricao_produto'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorConfig.amarelo.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Cod: ${widget.produto['codigo_produto'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageFullScreen(String imageUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 3.0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(ColorConfig.amarelo),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 80,
                                color: Colors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Erro ao carregar imagem',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            
            // Botão de compartilhamento no modal
            Positioned(
              top: 20,
              right: 80, // Posicionar ao lado do botão de fechar
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366), // Cor verde do WhatsApp
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fecha o modal
                    _shareOnWhatsApp(); // Compartilha
                  },
                  icon: const Icon(
                    Icons.share,
                    color: Colors.white,
                    size: 24,
                  ),
                  tooltip: 'Compartilhar no WhatsApp',
                ),
              ),
            ),
            
            // Informações do produto na parte inferior
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.produto['descricao_produto'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Código: ${widget.produto['codigo_produto'] ?? ''}',
                      style: TextStyle(
                        color: ColorConfig.amarelo,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Future<void> _shareOnWhatsApp() async {
    try {
      final codigoProduto = widget.produto['codigo_produto'] ?? '';
      final descricaoProduto = widget.produto['descricao_produto'] ?? '';
      final precoVenda = widget.produto['preco_venda'] ?? 0;
      final saldoAtual = widget.produto['saldo_atual'] ?? 0;
      final depositoPadrao = widget.produto['deposito_padrao'] ?? '';
      final imageUrl = _buildImageUrl();

      final preco = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
          .format(precoVenda);

      String message = '🛞 *PRODUTO DISPONÍVEL* 🛞\n';
      message += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
      message += '📋 *Código:* `$codigoProduto`\n';
      message += '📝 *Descrição:* $descricaoProduto\n';
      message += '💰 *Preço:* *$preco*\n';
      message += '📦 *Saldo disponível:* $saldoAtual unidades\n';
      
      if (depositoPadrao.isNotEmpty) {
        message += '🏪 *Depósito:* $depositoPadrao\n';
      }
      
      message += '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
      
      if (imageUrl.isNotEmpty) {
        message += '🖼️ *Veja a imagem do produto:*\n';
        message += imageUrl + '\n';
        message += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
      }
      
      message += '\n📞 *Entre em contato para mais informações!*\n';
      message += '🚀 *Entrega rápida e segura*\n';
      message += '✨ *RODDAR PNEUS* - Sua loja de confiança!\n\n';
      message += '📍 Visite nossa loja ou entre em contato via WhatsApp!';

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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp não está instalado ou não foi possível abrir'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Mostra mensagem de sucesso
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compartilhamento enviado para o WhatsApp!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erro ao compartilhar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao compartilhar produto'),
          backgroundColor: Colors.red,
        ),
      );
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
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
              onPressed: _shareOnWhatsApp,
              tooltip: 'Compartilhar no WhatsApp',
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do produto
            _buildProductImage(),
            const SizedBox(height: 16),
            
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
