import 'package:flutter/material.dart';

import '../../tema/tema_mass.dart';

class FiltroCiudades extends StatelessWidget {
  final List<String> ciudades;
  final String seleccion;
  final ValueChanged<String> alElegir;

  const FiltroCiudades({
    super.key,
    required this.ciudades,
    required this.seleccion,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    if (ciudades.isEmpty) return const SizedBox.shrink();
    if (ciudades.length > 4) {
      return _Selector(
        ciudades: ciudades,
        seleccion: seleccion,
        alElegir: alElegir,
      );
    }
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ciudades.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, indice) {
          final ciudad = indice == 0 ? 'Todas' : ciudades[indice - 1];
          return _ChipCiudad(
            ciudad: ciudad,
            activa: seleccion == ciudad,
            alElegir: () => alElegir(ciudad),
          );
        },
      ),
    );
  }
}

class _Selector extends StatelessWidget {
  final List<String> ciudades;
  final String seleccion;
  final ValueChanged<String> alElegir;

  const _Selector({
    required this.ciudades,
    required this.seleccion,
    required this.alElegir,
  });

  Future<void> _abrir(BuildContext context) async {
    final tokens = TokensMass.de(context);
    final elegida = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: tokens.superficie,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final opciones = ['Todas', ...ciudades];
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            itemCount: opciones.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, indice) {
              if (indice == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Text(
                    'Ciudad',
                    style: textoMass(
                      tamano: 16,
                      peso: FontWeight.w800,
                      color: tokens.profundo,
                    ),
                  ),
                );
              }
              final ciudad = opciones[indice - 1];
              final activa = seleccion == ciudad;
              final etiqueta = ciudad == 'Todas' ? 'Todas las ciudades' : ciudad;
              return ListTile(
                key: Key('ciudad-$ciudad'),
                minTileHeight: 48,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                selected: activa,
                title: Text(
                  etiqueta,
                  style: textoMass(
                    tamano: 15,
                    peso: FontWeight.w700,
                    color: activa ? tokens.accion : tokens.tinta,
                  ),
                ),
                trailing: activa
                    ? Icon(Icons.check_rounded, color: tokens.accion)
                    : null,
                onTap: () => Navigator.pop(ctx, ciudad),
              );
            },
          ),
        );
      },
    );
    if (elegida != null) alElegir(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final etiqueta = seleccion == 'Todas' ? 'Todas las ciudades' : seleccion;
    return Semantics(
      button: true,
      label: 'Filtrar por ciudad, $etiqueta',
      child: Material(
        key: const Key('selector-ciudad'),
        color: tokens.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: tokens.linea),
        ),
        child: InkWell(
          onTap: () => _abrir(context),
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.location_city_outlined, color: tokens.accion, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      etiqueta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textoMass(
                        tamano: 14,
                        peso: FontWeight.w700,
                        color: tokens.tinta,
                      ),
                    ),
                  ),
                  Icon(Icons.expand_more_rounded, color: tokens.tintaSuave),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipCiudad extends StatelessWidget {
  final String ciudad;
  final bool activa;
  final VoidCallback alElegir;

  const _ChipCiudad({
    required this.ciudad,
    required this.activa,
    required this.alElegir,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    final etiqueta = ciudad == 'Todas' ? 'Todas' : ciudad;
    return Semantics(
      button: true,
      selected: activa,
      label: etiqueta,
      child: Material(
        key: Key('ciudad-$ciudad'),
        color: activa ? tokens.accion : tokens.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: activa ? tokens.accion : tokens.linea),
        ),
        child: InkWell(
          onTap: alElegir,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (activa) ...[
                  const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Text(
                  etiqueta,
                  style: textoMass(
                    tamano: 14,
                    peso: FontWeight.w700,
                    color: activa ? Colors.white : tokens.tinta,
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
