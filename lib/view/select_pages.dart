import 'package:flutter/material.dart';
import 'package:roddar_pneus/view/cliente.dart';
import 'package:roddar_pneus/view/orcamento.dart';
import 'package:roddar_pneus/view/pedidos.dart';
import 'package:roddar_pneus/view/produtos.dart';
import 'package:roddar_pneus/widgets/custom_bottom_navigation_bar.dart';

class SelectPages extends StatefulWidget {
  const SelectPages({super.key});

  @override
  State<SelectPages> createState() => _SelectPagesState();
}

class _SelectPagesState extends State<SelectPages> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('RODDAR PNEUS'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SizedBox(
        width: double.infinity,
        child: GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          padding: const EdgeInsets.all(20),
          children: [
            // menuButton(
            //   icon: Icons.receipt_long,
            //   label: 'Orçamentos',
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => const Orcamento(),
            //       ),
            //     );
            //   },
            // ),
            menuButton(
              icon: Icons.shopping_bag,
              label: 'Pedidos',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Pedido(),
                  ),
                );
              },
            ),
            menuButton(
              icon: Icons.group,
              label: 'Clientes',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Clientes(),
                  ),
                );
              },
            ),
            menuButton(
              icon: Icons.inventory_2,
              label: 'Produtos',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Produtos(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatBtn.build(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FloatBtn.bottomAppBar(context),
    );
  }

  Widget menuButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 5.0, // Adiciona sombra ao card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Arredonda os cantos do card
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(8), // Arredonda os cantos do botão
            side: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // Aumentado o tamanho da fonte
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
