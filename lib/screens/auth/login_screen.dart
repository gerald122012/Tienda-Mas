import 'package:flutter/material.dart';

import '../../services/dni_service.dart';
import 'acceso_admin.dart';
import 'acceso_cliente.dart';

class LoginScreen extends StatelessWidget {
  final bool soloAdmin;
  final DniService? servicioDni;

  const LoginScreen({super.key, this.soloAdmin = false, this.servicioDni});

  @override
  Widget build(BuildContext context) {
    if (soloAdmin) return const AccesoAdmin();
    return AccesoCliente(servicioDni: servicioDni);
  }
}
