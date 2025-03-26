import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roddar_pneus/class/color_config.dart';
import 'package:roddar_pneus/view/cad_pedido.dart';
import 'package:roddar_pneus/view/home.dart';
import 'package:roddar_pneus/view/logout.dart';
import 'package:roddar_pneus/view/select_pages.dart';
import 'package:roddar_pneus/view/user_edit.dart';
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CadastroPedido()),
                  );
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
