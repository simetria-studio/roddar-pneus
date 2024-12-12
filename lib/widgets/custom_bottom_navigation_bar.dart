import 'package:flutter/material.dart';

import 'package:roddar_pneus/class/color_config.dart';
import 'package:roddar_pneus/view/cad_pedido.dart';
import 'package:roddar_pneus/view/home.dart';
import 'package:roddar_pneus/view/select_pages.dart';
import 'package:roddar_pneus/view/user_edit.dart';
// Importe a tela HomePage aqui

class FloatBtn {
  static Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CadastroPedido()),
        );
      },
      backgroundColor: ColorConfig.amarelo,
      shape: const CircleBorder(),
      child: const Icon(Icons.add),
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
            onPressed: () {},
            color: ColorConfig.preto,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserEdit()),
              );
            },
            color: ColorConfig.preto,
          ),
        ],
      ),
    );
  }
}
