import 'package:flutter/material.dart';

import '../../models/cupon.dart';
import '../../tema/tema_mass.dart';
import '../../utils/utilidades.dart';

class SeccionAhorro extends StatelessWidget {
  final CuponDescuento? cupon;
  final double descuento;
  final String? aviso;
  final bool aplicando;
  final TextEditingController codigo;
  final VoidCallback alAplicar;
  final VoidCallback alQuitar;
  final VoidCallback alEscanear;

  const SeccionAhorro({
    super.key,
    required this.cupon,
    required this.descuento,
    required this.aviso,
    required this.aplicando,
    required this.codigo,
    required this.alAplicar,
    required this.alQuitar,
    required this.alEscanear,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final activo = cupon != null && descuento > 0;
    final sinCondicion = cupon != null && descuento <= 0;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ahorra en tu compra',
            style: textoMass(
              tamano: 16,
              peso: FontWeight.w800,
              color: tokens.profundo,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ingresa un código o escanea el QR.',
            style: textoMass(tamano: 13, color: tokens.tintaSuave),
          ),
          const SizedBox(height: 12),
          if (cupon != null)
            _CuponActivo(
              cupon: cupon!,
              descuento: descuento,
              cumple: activo,
              sinCondicion: sinCondicion,
              alQuitar: alQuitar,
            )
          else ...[
            TextField(
              controller: codigo,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              scrollPadding: const EdgeInsets.only(bottom: 140),
              decoration: const InputDecoration(
                labelText: 'Código de cupón',
                hintText: 'Ejemplo: MASS10',
                isDense: true,
              ),
              onSubmitted: (_) => alAplicar(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.accion,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: tokens.linea,
                        disabledForegroundColor: tokens.tintaSuave,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            MassRadio.control,
                          ),
                        ),
                      ),
                      onPressed: aplicando ? null : alAplicar,
                      child: Text(aplicando ? 'Comprobando' : 'Aplicar'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton.outlined(
                    tooltip: 'Escanear cupón',
                    onPressed: aplicando ? null : alEscanear,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                  ),
                ),
              ],
            ),
          ],
          if (aviso != null && aviso!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              aviso!,
              style: textoMass(
                tamano: 13,
                peso: FontWeight.w700,
                color: tokens.error,
                alto: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CuponActivo extends StatelessWidget {
  final CuponDescuento cupon;
  final double descuento;
  final bool cumple;
  final bool sinCondicion;
  final VoidCallback alQuitar;

  const _CuponActivo({
    required this.cupon,
    required this.descuento,
    required this.cumple,
    required this.sinCondicion,
    required this.alQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final color = cumple ? tokens.exito : tokens.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MassRadio.control),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            cumple
                ? Icons.local_offer_outlined
                : Icons.error_outline_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cumple ? 'Cupón ${cupon.codigo} aplicado' : cupon.codigo,
                  style: textoMass(
                    tamano: 14,
                    peso: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cumple
                      ? 'Ahorras ${formatoPrecio(descuento)} · ${cupon.etiquetaDescuento}'
                      : sinCondicion
                      ? 'Este código ya no cumple el monto mínimo de ${formatoPrecio(cupon.montoMinimo)}.'
                      : cupon.descripcion,
                  style: textoMass(
                    tamano: 13,
                    color: tokens.tinta,
                    alto: 1.35,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: alQuitar, child: const Text('Quitar')),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Material(
      color: tokens.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MassRadio.tarjeta),
        side: BorderSide(color: tokens.linea),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
