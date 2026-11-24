import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../services/formato_recorrido.dart';
import '../../services/routing_service.dart';
import '../../tema/tema_mass.dart';

enum ClaseDestino { ninguno, tienda, ejemplo, mapa }

class DestinoReferencia {
  final String nombre;
  final String detalle;
  final LatLng coordenada;
  final ClaseDestino clase;

  const DestinoReferencia({
    required this.nombre,
    required this.coordenada,
    this.detalle = '',
    this.clase = ClaseDestino.ejemplo,
  });
}

class PanelRutaMass extends StatelessWidget {
  final ScrollController scroll;
  final bool expandido;
  final ClaseDestino clase;
  final String nombreDestino;
  final String detalleDestino;
  final bool destinoInvalido;
  final bool tieneOrigen;
  final double? precisionMetros;
  final bool obteniendo;
  final bool calculando;
  final ResultadoRuta? ruta;
  final String? mensaje;
  final String? distanciaRecta;
  final ModoRuta modo;
  final bool volverAlCarrito;
  final VoidCallback alVerEjemplos;
  final VoidCallback alAmpliar;
  final VoidCallback alUsarUbicacion;
  final VoidCallback alCalcular;
  final ValueChanged<ModoRuta> alCambiarModo;
  final VoidCallback alCompartir;
  final VoidCallback alAdjuntar;
  final VoidCallback alAbrirMapas;

  const PanelRutaMass({
    super.key,
    required this.scroll,
    required this.expandido,
    required this.clase,
    required this.nombreDestino,
    required this.detalleDestino,
    required this.destinoInvalido,
    required this.tieneOrigen,
    required this.precisionMetros,
    required this.obteniendo,
    required this.calculando,
    required this.ruta,
    required this.mensaje,
    required this.distanciaRecta,
    required this.modo,
    required this.volverAlCarrito,
    required this.alVerEjemplos,
    required this.alAmpliar,
    required this.alUsarUbicacion,
    required this.alCalcular,
    required this.alCambiarModo,
    required this.alCompartir,
    required this.alAdjuntar,
    required this.alAbrirMapas,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return Material(
      color: tokens.superficie,
      elevation: 8,
      shadowColor: tokens.profundo.withValues(alpha: 0.12),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        children: [
          Center(
            child: ExcludeSemantics(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.linea,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _destino(tokens)),
              IconButton(
                key: const Key('ampliar-panel'),
                tooltip: expandido ? 'Contraer panel' : 'Ampliar información',
                onPressed: alAmpliar,
                icon: Icon(
                  expandido ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                  color: tokens.profundo,
                ),
              ),
            ],
          ),
          Text(
            _estado,
            style: textoMass(
              tamano: 13,
              peso: FontWeight.w700,
              color: _colorEstado(tokens),
              alto: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          _acciones(tokens),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('ver-ejemplos'),
              onPressed: alVerEjemplos,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: const Text('Ver recorridos de ejemplo'),
            ),
          ),
          if (expandido) _detalle(tokens),
        ],
      ),
    );
  }

  String get _estado {
    if (destinoInvalido) return 'El destino no tiene coordenadas válidas.';
    if (obteniendo) return 'Obteniendo tu ubicación…';
    if (calculando) return 'Calculando la ruta…';
    if (mensaje != null) return mensaje!;
    if (ruta != null) return 'Recorrido calculado. No es el seguimiento de un pedido.';
    if (clase == ClaseDestino.ninguno) {
      return 'Mapa de referencia. Elige un destino para planificar el recorrido.';
    }
    return 'Listo para calcular la ruta cuando uses tu ubicación.';
  }

  Color _colorEstado(TokensMass tokens) {
    if (destinoInvalido || (mensaje != null && ruta == null && !calculando)) {
      return tokens.error;
    }
    if (ruta != null) return tokens.exito;
    return tokens.tintaSuave;
  }

  Widget _destino(TokensMass tokens) {
    final kicker = destinoInvalido
        ? 'Destino no disponible'
        : switch (clase) {
            ClaseDestino.tienda => 'Establecimiento',
            ClaseDestino.ejemplo => 'Ejemplo de recorrido',
            ClaseDestino.mapa => 'Punto elegido en el mapa',
            ClaseDestino.ninguno => 'Sin destino',
          };
    final nombre = destinoInvalido
        ? (nombreDestino.isEmpty ? 'Sin coordenadas' : nombreDestino)
        : clase == ClaseDestino.ninguno
        ? 'Elige un destino'
        : nombreDestino;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: textoMass(tamano: 12, peso: FontWeight.w800, color: tokens.accion),
          ),
          const SizedBox(height: 2),
          Text(
            nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textoMass(tamano: 18, peso: FontWeight.w800, color: tokens.profundo),
          ),
        ],
      ),
    );
  }

  Widget _acciones(TokensMass tokens) {
    final ubicacion = OutlinedButton.icon(
      key: const Key('usar-ubicacion-delivery'),
      onPressed: obteniendo ? null : alUsarUbicacion,
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.accion,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: tokens.linea),
      ),
      icon: const Icon(Icons.my_location_outlined, size: 18),
      label: Text(tieneOrigen ? 'Actualizar ubicación' : 'Usar mi ubicación'),
    );
    final calcular = FilledButton.icon(
      key: const Key('calcular-ruta'),
      onPressed: calculando || destinoInvalido ? null : alCalcular,
      style: FilledButton.styleFrom(
        backgroundColor: tokens.accion,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        textStyle: textoMass(tamano: 14, peso: FontWeight.w800, color: Colors.white),
      ),
      icon: const Icon(Icons.route_rounded, size: 18),
      label: Text(calculando ? 'Calculando…' : 'Calcular ruta'),
    );
    return LayoutBuilder(
      builder: (context, limites) {
        if (limites.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ubicacion,
              const SizedBox(height: 8),
              calcular,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: ubicacion),
            const SizedBox(width: 8),
            Expanded(child: calcular),
          ],
        );
      },
    );
  }

  Widget _detalle(TokensMass tokens) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        key: const Key('detalle-recorrido'),
        children: [
          Text(
            'Planificación de un recorrido. No es el seguimiento de un pedido.',
            style: textoMass(tamano: 12, color: tokens.tintaSuave, alto: 1.35),
          ),
          const SizedBox(height: 12),
          _Ficha(
            icono: Icons.near_me_rounded,
            titulo: 'Origen',
            valor: tieneOrigen ? 'Tu ubicación' : 'Sin ubicación',
            detalle: tieneOrigen
                ? precisionMetros == null
                      ? 'Posición del dispositivo. No es un punto elegido en el mapa.'
                      : 'Posición del dispositivo. Precisión ± ${precisionMetros!.round()} m.'
                : 'Puedes continuar sin compartir tu ubicación.',
          ),
          const SizedBox(height: 8),
          _Ficha(
            icono: Icons.storefront_rounded,
            titulo: 'Destino',
            valor: clase == ClaseDestino.ninguno ? 'Sin destino' : nombreDestino,
            detalle: _detalleDestino(),
          ),
          if (ruta != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Metrica(
                    titulo: 'Recorrido',
                    valor: textoDistanciaRecorrido(ruta!.distanciaMetros),
                    detalle: 'Por carretera',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Metrica(
                    titulo: 'Tiempo estimado',
                    valor: textoDuracionEstimada(ruta!.duracionSegundos),
                    detalle: 'No está garantizado',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'No es un tiempo de entrega garantizado. No hay una tarifa de entrega calculada.',
              style: textoMass(tamano: 12, color: tokens.tintaSuave, alto: 1.35),
            ),
          ] else if (distanciaRecta != null) ...[
            const SizedBox(height: 12),
            _Metrica(
              titulo: 'En línea recta',
              valor: distanciaRecta!,
              detalle: 'Aproximada. No es el recorrido por carretera.',
            ),
          ],
          const SizedBox(height: 14),
          SegmentedButton<ModoRuta>(
            segments: const [
              ButtonSegment(
                value: ModoRuta.carro,
                icon: Icon(Icons.directions_car_outlined),
                label: Text('Vehículo'),
              ),
              ButtonSegment(
                value: ModoRuta.caminando,
                icon: Icon(Icons.directions_walk_rounded),
                label: Text('Caminando'),
              ),
            ],
            selected: {modo},
            onSelectionChanged: (valor) => alCambiarModo(valor.first),
          ),
          if (ruta != null && ruta!.pasos.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Pasos del recorrido',
              style: textoMass(tamano: 14, peso: FontWeight.w800, color: tokens.profundo),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < ruta!.pasos.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${i + 1}. ${ruta!.pasos[i].instruccion}',
                  style: textoMass(tamano: 13, color: tokens.tinta, alto: 1.35),
                ),
              ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: tieneOrigen && clase != ClaseDestino.ninguno && !destinoInvalido
                  ? alAbrirMapas
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.accion,
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: tokens.linea),
              ),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Abrir en Google Maps'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('compartir-ruta'),
              onPressed: ruta == null ? null : alCompartir,
              style: OutlinedButton.styleFrom(
                foregroundColor: tokens.accion,
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: tokens.linea),
              ),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Compartir'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('adjuntar-ruta'),
              onPressed: ruta == null ? null : alAdjuntar,
              style: FilledButton.styleFrom(
                backgroundColor: tokens.accion,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                textStyle: textoMass(
                  tamano: 14,
                  peso: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: Text(
                volverAlCarrito ? 'Adjuntar y volver al carrito' : 'Adjuntar al carrito',
              ),
            ),
          ),
          if (ruta == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Calcula una ruta para poder compartirla o adjuntarla.',
                style: textoMass(tamano: 12, color: tokens.tintaSuave, alto: 1.35),
              ),
            ),
        ],
      ),
    );
  }

  String _detalleDestino() {
    if (clase == ClaseDestino.ejemplo) {
      return 'No es un establecimiento registrado.';
    }
    if (clase == ClaseDestino.mapa) {
      return 'No corresponde a una tienda registrada.';
    }
    if (destinoInvalido) return 'No hay coordenadas para este destino.';
    if (detalleDestino.trim().isNotEmpty) return detalleDestino.trim();
    if (clase == ClaseDestino.ninguno) {
      return 'Toca el mapa o elige un ejemplo.';
    }
    return 'Destino seleccionado.';
  }
}

class _Ficha extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final String detalle;

  const _Ficha({
    required this.icono,
    required this.titulo,
    required this.valor,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.fondo,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: tokens.accion, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: textoMass(tamano: 12, peso: FontWeight.w800, color: tokens.accion),
                  ),
                  Text(
                    valor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textoMass(tamano: 15, peso: FontWeight.w800, color: tokens.tinta),
                  ),
                  Text(
                    detalle,
                    style: textoMass(tamano: 12, color: tokens.tintaSuave, alto: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  final String titulo;
  final String valor;
  final String detalle;

  const _Metrica({
    required this.titulo,
    required this.valor,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = TokensMass.de(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.linea),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: textoMass(tamano: 12, peso: FontWeight.w700, color: tokens.tintaSuave),
            ),
            const SizedBox(height: 2),
            Text(
              valor,
              style: textoMass(tamano: 18, peso: FontWeight.w800, color: tokens.profundo),
            ),
            Text(
              detalle,
              style: textoMass(tamano: 12, color: tokens.tinta, alto: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
