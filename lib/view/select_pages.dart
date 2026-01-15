import 'package:flutter/material.dart';
import 'package:roddar_pneus/view/cliente.dart';
import 'package:roddar_pneus/view/orcamentos.dart';
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
          childAspectRatio: 1.5,
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
              icon: Icons.receipt_long,
              label: 'Orçamentos',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Orcamentos(),
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
    final Color primary = Theme.of(context).primaryColor;
    final Color primaryDarker = Theme.of(context).primaryColor.withOpacity(0.85);

    return Card(
      elevation: 6.0,
      shadowColor: primary.withOpacity(0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        splashColor: Colors.white.withOpacity(0.15),
        highlightColor: Colors.white.withOpacity(0.05),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary,
                primaryDarker,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
