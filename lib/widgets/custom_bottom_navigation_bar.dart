import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roddar_pneus/class/color_config.dart';
import 'package:roddar_pneus/view/cad_pedido.dart';
import 'package:roddar_pneus/view/home.dart';
import 'package:roddar_pneus/view/logout.dart';
import 'package:roddar_pneus/view/select_pages.dart';
import 'package:roddar_pneus/view/user_edit.dart';
import 'package:roddar_pneus/view/orcamento.dart';
// Importe a tela HomePage aqui

class FloatBtn {
  static Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final prefs = snapshot.data!;
        final codigoEmpresa = prefs.getString('codigo_empresa') ?? '0';
        final empresaFaturamento =
            prefs.getString('empresa_faturamento') ?? '0';
        final isEmpresaPermitida = codigoEmpresa == empresaFaturamento;

        return FloatingActionButton(
          onPressed: isEmpresaPermitida
              ? () {
                  _showOptionsDialog(context);
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Por favor, troque para a empresa $empresaFaturamento para cadastrar pedidos'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
          backgroundColor:
              isEmpresaPermitida ? ColorConfig.amarelo : Colors.grey,
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        );
      },
    );
  }

  static void _showOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecione uma opção',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Opção Orçamento
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const Orcamento()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConfig.amarelo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.request_quote, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Orçamento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Opção Pedido
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CadastroPedido()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConfig.amarelo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Pedido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botão Cancelar
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget bottomAppBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 4.0,
      color: ColorConfig.amarelo,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            color: ColorConfig.preto,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_sharp),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const SelectPages()));
            },
            color: ColorConfig.preto,
          ),
          const SizedBox(width: 48), // O espaço para o FloatingActionButton
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserEdit()),
              );
            },
            color: ColorConfig.preto,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Logout()),
              );
            },
            color: ColorConfig.preto,
          ),
        ],
      ),
    );
  }
}
