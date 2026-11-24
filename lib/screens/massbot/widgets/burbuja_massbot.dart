import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../models/producto.dart';
import '../../../models/respuesta_massbot.dart';
import '../../../services/catalogo_visual.dart';
import '../../../utils/utilidades.dart';
import 'tema_massbot.dart';

class BurbujaMassBot extends StatelessWidget {
  final bool usuario;
  final String texto;

  const BurbujaMassBot({super.key, required this.usuario, required this.texto});

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    return Align(
      alignment: usuario ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ancho - 64),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: usuario ? kAzulBot : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(usuario ? 18 : 6),
              bottomRight: Radius.circular(usuario ? 6 : 18),
            ),
            border: usuario
                ? null
                : const Border(left: BorderSide(color: kAmarilloBot, width: 3)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Text(
              texto,
              style: textoMassBot(
                color: usuario ? Colors.white : kTintaBot,
                peso: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TarjetasMassBot extends StatelessWidget {
  final List<ProductoMassBot> productos;
  final VoidCallback? alVerCatalogo;

  const TarjetasMassBot({
    super.key,
    required this.productos,
    this.alVerCatalogo,
  });

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) return const SizedBox.shrink();
    final ancho = (MediaQuery.sizeOf(context).width - 78).clamp(240.0, 320.0);
    return SizedBox(
      height: 168,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 10),
        itemCount: productos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, indice) {
          return _TarjetaProducto(
            producto: productos[indice],
            ancho: ancho,
            alVerCatalogo: alVerCatalogo,
          );
        },
      ),
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  final ProductoMassBot producto;
  final double ancho;
  final VoidCallback? alVerCatalogo;

  const _TarjetaProducto({
    required this.producto,
    required this.ancho,
    this.alVerCatalogo,
  });

  @override
  Widget build(BuildContext context) {
    final disponible = producto.disponible && producto.stock > 0;
    return SizedBox(
      width: ancho,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3E7F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 6),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                height: 132,
                child: Center(child: _Foto(producto: producto)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      producto.marca.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textoMassBot(
                        tamano: 10,
                        peso: FontWeight.w700,
                        color: kAzulBot,
                        espaciado: 0.4,
                      ),
                    ),
                    if (producto.similar)
                      Text(
                        'Similar',
                        style: textoMassBot(
                          tamano: 10,
                          peso: FontWeight.w700,
                          color: kAzulProfundoBot,
                          alto: 1.1,
                        ),
                      ),
                    Text(
                      producto.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textoMassBot(
                        tamano: 13,
                        peso: FontWeight.w700,
                        alto: 1.15,
                      ),
                    ),
                    if (producto.presentaciones.isNotEmpty)
                      Text(
                        producto.presentaciones.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textoMassBot(tamano: 11, color: kTintaSuaveBot),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      formatoPrecio(producto.precio),
                      style: textoMassBot(
                        tamano: 16,
                        peso: FontWeight.w700,
                        color: kAzulBot,
                        alto: 1.1,
                      ),
                    ),
                    Text(
                      disponible ? 'Disponible · ${producto.stock}' : 'Agotado',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textoMassBot(
                        tamano: 11,
                        peso: FontWeight.w600,
                        alto: 1.1,
                        color: disponible
                            ? const Color(0xFF0E7A43)
                            : const Color(0xFFB42318),
                      ),
                    ),
                    TextButton(
                      onPressed: alVerCatalogo,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(
                        'Ver en catálogo',
                        style: textoMassBot(
                          tamano: 12.5,
                          peso: FontWeight.w700,
                          color: kAzulBot,
                          alto: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListaCompraMassBot extends StatelessWidget {
  final List<ProductoMassBot> productos;
  final VoidCallback? alVerCatalogo;

  const ListaCompraMassBot({
    super.key,
    required this.productos,
    this.alVerCatalogo,
  });

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE3E7F0)),
        ),
        child: Column(
          children: [
            for (var indice = 0; indice < productos.length; indice++) ...[
              if (indice > 0)
                const Divider(height: 1, color: Color(0xFFE3E7F0)),
              _FilaCompra(
                producto: productos[indice],
                alVerCatalogo: alVerCatalogo,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilaCompra extends StatelessWidget {
  final ProductoMassBot producto;
  final VoidCallback? alVerCatalogo;

  const _FilaCompra({required this.producto, this.alVerCatalogo});

  @override
  Widget build(BuildContext context) {
    final subtotal = producto.subtotal ?? producto.precio * producto.cantidad;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 52, height: 52, child: _Foto(producto: producto)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textoMassBot(peso: FontWeight.w700, alto: 1.2),
                ),
                Text(
                  '${producto.cantidad} un. × ${formatoPrecio(producto.precio)}',
                  style: textoMassBot(tamano: 12, color: kTintaSuaveBot),
                ),
                TextButton(
                  onPressed: alVerCatalogo,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 26),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(
                    'Ver en catálogo',
                    style: textoMassBot(
                      tamano: 12.5,
                      peso: FontWeight.w700,
                      color: kAzulBot,
                      alto: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatoPrecio(subtotal),
            style: textoMassBot(peso: FontWeight.w800, color: kAzulBot),
          ),
        ],
      ),
    );
  }
}

class _Foto extends StatefulWidget {
  final ProductoMassBot producto;

  const _Foto({required this.producto});

  @override
  State<_Foto> createState() => _FotoState();
}

class _FotoState extends State<_Foto> {
  @override
  void initState() {
    super.initState();
    CatalogoVisual.instancia.asegurar(widget.producto.id);
  }

  @override
  void didUpdateWidget(covariant _Foto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.producto.id != widget.producto.id) {
      CatalogoVisual.instancia.asegurar(widget.producto.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CatalogoVisual.instancia,
      builder: (context, _) {
        final catalogo = CatalogoVisual.instancia.buscar(widget.producto.id);
        final bytes = catalogo == null
            ? null
            : decodificarImagenProducto(catalogo.imagenBase64);
        if (bytes != null) return _memoria(bytes);
        final url = catalogo?.imagenUrl.trim() ?? '';
        if (url.isNotEmpty) {
          return Image.network(
            url,
            fit: BoxFit.contain,
            width: double.infinity,
            errorBuilder: (_, _, _) => _assetOMarcador(catalogo),
          );
        }
        return _assetOMarcador(catalogo);
      },
    );
  }

  Widget _memoria(Uint8List bytes) {
    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      width: double.infinity,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _assetOMarcador(null),
    );
  }

  Widget _assetOMarcador(Producto? catalogo) {
    final delCatalogo = catalogo?.imagenAsset.trim() ?? '';
    final ruta = delCatalogo.startsWith('assets/')
        ? delCatalogo
        : widget.producto.imagenAsset.trim();
    if (ruta.startsWith('assets/')) {
      return Image.asset(
        ruta,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (_, _, _) => const _MarcadorImagen(),
      );
    }
    return const _MarcadorImagen();
  }
}

class _MarcadorImagen extends StatelessWidget {
  const _MarcadorImagen();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFEEF2FF),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Center(
        child: Icon(Icons.shopping_bag_outlined, color: kAzulBot, size: 28),
      ),
    );
  }
}

class FichaPresupuesto extends StatelessWidget {
  final double presupuesto;
  final double total;
  final double restante;

  const FichaPresupuesto({
    super.key,
    required this.presupuesto,
    required this.total,
    required this.restante,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kAzulProfundoBot,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _linea('Presupuesto', presupuesto, Colors.white70),
              _linea('Total de la lista', total, kAmarilloBot),
              _linea('Te queda', restante, Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linea(String etiqueta, double monto, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(etiqueta, style: textoMassBot(color: Colors.white70)),
          ),
          Text(
            formatoPrecio(monto),
            style: textoMassBot(peso: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class CuponesMassBot extends StatelessWidget {
  final List<CuponMassBot> cupones;

  const CuponesMassBot({super.key, required this.cupones});

  @override
  Widget build(BuildContext context) {
    if (cupones.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final cupon in cupones)
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF0E2A0)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  '${cupon.codigo} · ${cupon.etiqueta}',
                  style: textoMassBot(
                    tamano: 12,
                    peso: FontWeight.w700,
                    color: kAzulBot,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
