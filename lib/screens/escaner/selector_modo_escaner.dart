import 'package:flutter/material.dart';

import '../../tema/tema_mass.dart';

class SelectorModoEscaner extends StatelessWidget {
  final int indice;
  final ValueChanged<int> alElegir;

  const SelectorModoEscaner({
    super.key,
    required this.indice,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    const modos = [
      (Icons.qr_code_2_rounded, 'QR', 'modo-qr'),
      (Icons.barcode_reader, 'Barras', 'modo-barras'),
      (Icons.folder_outlined, 'Archivos', 'modo-archivos'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tokens.linea),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (var i = 0; i < modos.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: indice == i,
                    label: modos[i].$2,
                    child: Material(
                      color: indice == i ? tokens.accion : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      child: InkWell(
                        key: Key(modos[i].$3),
                        borderRadius: BorderRadius.circular(11),
                        onTap: () => alElegir(i),
                        child: SizedBox(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                modos[i].$1,
                                size: 16,
                                color: indice == i ? Colors.white : tokens.profundo,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  modos[i].$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textoMass(
                                    tamano: 13,
                                    peso: FontWeight.w700,
                                    color: indice == i
                                        ? Colors.white
                                        : tokens.profundo,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
