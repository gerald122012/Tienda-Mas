import 'package:flutter/material.dart';

import '../../tema/tema_mass.dart';

class MarcadorMass extends StatelessWidget {
  final String etiqueta;
  final String descripcion;
  final bool destino;

  const MarcadorMass({
    super.key,
    required this.etiqueta,
    required this.descripcion,
    required this.destino,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Semantics(
      label: descripcion,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.superficie,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tokens.linea),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                etiqueta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textoMass(
                  tamano: 11,
                  peso: FontWeight.w800,
                  color: tokens.profundo,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          destino ? _PinDestino(tokens: tokens) : _MarcaOrigen(tokens: tokens),
        ],
      ),
    );
  }
}

class _PinDestino extends StatelessWidget {
  final TokensMass tokens;

  const _PinDestino({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.profundo,
            shape: BoxShape.circle,
            border: Border.all(color: tokens.sello, width: 3),
          ),
          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 16),
        ),
        Container(width: 3, height: 8, color: tokens.profundo),
      ],
    );
  }
}

class _MarcaOrigen extends StatelessWidget {
  final TokensMass tokens;

  const _MarcaOrigen({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.superficie,
        shape: BoxShape.circle,
        border: Border.all(color: tokens.accion, width: 3),
      ),
      child: Icon(Icons.near_me_rounded, color: tokens.accion, size: 14),
    );
  }
}
