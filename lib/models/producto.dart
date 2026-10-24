import 'package:cloud_firestore/cloud_firestore.dart';

// Módulo 1 - Precios Mass (Catálogo de Bodega Tiendas Mass)
class Producto {
  String id;
  String nombre;
  String descripcion;
  String marca;
  double precio;
  int stock;
  String categoria;
  bool disponible;
  DateTime fechaRegistro;
  List<String> presentaciones;
  double valoracion;
  String imagenUrl;
  String imagenAsset;
  String imagenAutor;
  String imagenLicencia;
  String imagenFuente;
  bool esEjemplo;

  static const categorias = [
    'abarrotes',
    'bebidas',
    'lácteos',
    'limpieza',
    'snacks',
  ];

  Producto({
    this.id = '',
    this.imagenUrl = '',
    this.imagenAsset = '',
    this.imagenAutor = '',
    this.imagenLicencia = '',
    this.imagenFuente = '',
    this.esEjemplo = false,
    required this.nombre,
    required this.descripcion,
    required this.marca,
    required this.precio,
    required this.stock,
    required this.categoria,
    required this.disponible,
    required this.fechaRegistro,
    required this.presentaciones,
    required this.valoracion,
  });

  // Convierte el objeto a Map para guardarlo en Firebase.
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'marca': marca,
      'precio': precio,
      'stock': stock,
      'categoria': categoria,
      'disponible': disponible,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
      'presentaciones': presentaciones,
      'valoracion': valoracion,
      'imagenUrl': imagenUrl,
      'imagenAsset': imagenAsset,
      'imagenAutor': imagenAutor,
      'imagenLicencia': imagenLicencia,
      'imagenFuente': imagenFuente,
      'esEjemplo': esEjemplo,
    };
  }

  // Crea el objeto a partir de los datos leídos de Firebase.
  factory Producto.fromMap(String id, Map datos) {
    final fecha = datos['fechaRegistro'];
    final lista = datos['presentaciones'] ?? datos['tallasDisponibles'] ?? [];
    final cat = (datos['categoria'] ?? '').toString();
    return Producto(
      id: id,
      imagenUrl: (datos['imagenUrl'] ?? '').toString(),
      imagenAsset: (datos['imagenAsset'] ?? '').toString(),
      imagenAutor: (datos['imagenAutor'] ?? '').toString(),
      imagenLicencia: (datos['imagenLicencia'] ?? '').toString(),
      imagenFuente: (datos['imagenFuente'] ?? '').toString(),
      esEjemplo: datos['esEjemplo'] == true,
      nombre: datos['nombre'] ?? '',
      descripcion: datos['descripcion'] ?? '',
      marca: datos['marca'] ?? 'Mass',
      precio: (datos['precio'] ?? 0).toDouble(),
      stock: (datos['stock'] ?? 0).toInt(),
      categoria: categorias.contains(cat) ? cat : categorias.first,
      disponible: datos['disponible'] ?? true,
      fechaRegistro: fecha is Timestamp ? fecha.toDate() : DateTime.now(),
      presentaciones: List<String>.from(lista),
      valoracion: (datos['valoracion'] ?? 5).toDouble(),
    );
  }

  // Productos comerciales verificados. Los precios son referenciales.
  static List<Producto> ejemplos() {
    final hoy = DateTime.now();
    return [
      Producto(
        id: "catalogo_001",
        nombre: "Arroz Extra COSTEÑO Bolsa 5Kg",
        descripcion: "Arroz Extra COSTEÑO Bolsa 5Kg",
        marca: "COSTEÑO",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/27552451-600-600/641425.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_001.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/arroz-extra-costeno-bolsa-5kg/p",
        precio: 20.9,
        stock: 30,
        categoria: "abarrotes",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 5Kg"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_002",
        nombre: "Azúcar Rubia CARTAVIO Bolsa 1Kg",
        descripcion: "Azúcar Rubia CARTAVIO Bolsa 1Kg",
        marca: "CARTAVIO",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/28650077-600-600/20184796.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_002.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/azucar-rubia-cartavio-bolsa-1kg/p",
        precio: 5.1,
        stock: 35,
        categoria: "abarrotes",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 1kg"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_003",
        nombre: "Aceite Vegetal PRIMOR Clásico Botella 900ml",
        descripcion: "Aceite Vegetal PRIMOR Clásico Botella 900ml",
        marca: "PRIMOR",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_003-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/aceite-vegetal-primor-clasico-botella-900ml-20281566/p",
        precio: 8.5,
        stock: 40,
        categoria: "abarrotes",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 900ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_004",
        nombre: "Fideos DON VITTORIO Spaghetti Bolsa 500g",
        descripcion: "Fideos DON VITTORIO Spaghetti Bolsa 500g",
        marca: "DON VITTORIO",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/35462837-600-600/20501452-1.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_004-limpia.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/fideos-don-vittorio-spaghetti-bolsa-500g-20501452/p",
        precio: 3.3,
        stock: 45,
        categoria: "abarrotes",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 500g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_005",
        nombre: "Lenteja COSTEÑO Bolsa 500g",
        descripcion: "Lenteja COSTEÑO Bolsa 500g",
        marca: "COSTEÑO",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/27552452-600-600/995413.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_005.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/lenteja-costeno-bolsa-500g/p",
        precio: 5.5,
        stock: 50,
        categoria: "abarrotes",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 500g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_006",
        nombre: "Avena QUAKER Tradicional Bolsa 500g",
        descripcion: "Avena QUAKER Tradicional Bolsa 500g",
        marca: "QUAKER",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_006-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/avena-quaker-tradicional-bolsa-500g/p",
        precio: 6.5,
        stock: 55,
        categoria: "abarrotes",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 500g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_007",
        nombre: "Sal Marina EMSAL Mesa Bolsa 1Kg",
        descripcion: "Sal Marina EMSAL Mesa Bolsa 1Kg",
        marca: "EMSAL",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/34330762-600-600/20130448.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_007.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/sal-marina-emsal-mesa-bolsa-1kg/p",
        precio: 2.8,
        stock: 60,
        categoria: "abarrotes",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 1kg"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_008",
        nombre: "Harina sin Preparar BLANCA FLOR Bolsa 1kg",
        descripcion: "Harina sin Preparar BLANCA FLOR Bolsa 1kg",
        marca: "BLANCA FLOR",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_008-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/harina-sin-preparar-blanca-flor-bolsa-1kg/p",
        precio: 6.9,
        stock: 65,
        categoria: "abarrotes",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 1kg"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_009",
        nombre: "Agua sin Gas SAN LUIS Botella 750ml",
        descripcion: "Agua sin Gas SAN LUIS Botella 750ml",
        marca: "SAN LUIS",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_009-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/agua-sin-gas-san-luis-botella-750ml-20281279/p",
        precio: 1.7,
        stock: 30,
        categoria: "bebidas",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 750ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_010",
        nombre: "Agua Mineral SAN MATEO Con Gas Botella 600ml",
        descripcion: "Agua Mineral SAN MATEO Con Gas Botella 600ml",
        marca: "SAN MATEO",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_010-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/agua-mineral-san-mateo-con-gas-botella-600ml-737791/p",
        precio: 2.0,
        stock: 35,
        categoria: "bebidas",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 600ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_011",
        nombre: "Gaseosa COCA COLA Sabor Original Botella 500ml",
        descripcion: "Gaseosa COCA COLA Sabor Original Botella 500ml",
        marca: "COCA COLA",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_011-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/gaseosa-coca-cola-botella-500ml/p",
        precio: 3.6,
        stock: 40,
        categoria: "bebidas",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 500ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_012",
        nombre: "Gaseosa INCA KOLA Sabor Original Botella 1L",
        descripcion: "Gaseosa INCA KOLA Sabor Original Botella 1L",
        marca: "INCA KOLA",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_012-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/gaseosa-inca-kola-sabor-original-botella-1l-20111231/p",
        precio: 4.9,
        stock: 45,
        categoria: "bebidas",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 1L"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_013",
        nombre: "Bebida de Durazno FRUGOS Caja 970ml",
        descripcion: "Bebida de Durazno FRUGOS Caja 970ml",
        marca: "FRUGOS",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_013-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/bebida-de-durazno-frugos-caja-970ml/p",
        precio: 3.5,
        stock: 50,
        categoria: "bebidas",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Caja 970ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_014",
        nombre: "Bebida CIFRUT Citrus Punch Botella 350ml",
        descripcion: "Bebida CIFRUT Citrus Punch Botella 350ml",
        marca: "CIFRUT",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/34361877-600-600/20356804.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_014.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/bebida-cifrut-citrus-punch-botella-350ml/p",
        precio: 1.2,
        stock: 55,
        categoria: "bebidas",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 350ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_015",
        nombre: "Bebida Rehidratante GATORADE Tropical Fruit Botella 500ml",
        descripcion:
            "Bebida Rehidratante GATORADE Tropical Fruit Botella 500ml",
        marca: "GATORADE",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_015-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/bebida-rehidratante-gatorade-tropical-fruit-botella-500ml/p",
        precio: 2.0,
        stock: 60,
        categoria: "bebidas",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 500ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_016",
        nombre: "Té Verde FREE TEA Limón Botella 500ml",
        descripcion: "Té Verde FREE TEA Limón Botella 500ml",
        marca: "FREE TEA",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_016-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/te-verde-free-tea-limon-botella-500ml/p",
        precio: 2.0,
        stock: 65,
        categoria: "bebidas",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 500ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_017",
        nombre: "Leche Evaporada Entera GLORIA Lata 390g Paquete 6un",
        descripcion: "Leche Evaporada Entera GLORIA Lata 390g Paquete 6un",
        marca: "GLORIA",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/35081598-600-600/20402648.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_017.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/leche-evaporada-entera-gloria-lata-390g-paquete-6un-20402648/p",
        precio: 21.9,
        stock: 30,
        categoria: "lácteos",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Paquete 6un"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_018",
        nombre: "Leche Entera UHT LAIVE Caja 946ml",
        descripcion: "Leche Entera UHT LAIVE Caja 946ml",
        marca: "LAIVE",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/35081548-600-600/20393011.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_018.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/leche-entera-uht-laive-caja-946ml-20393011/p",
        precio: 6.2,
        stock: 35,
        categoria: "lácteos",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Caja 946ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_019",
        nombre: "Leche Light GLORIA Lata 390g",
        descripcion: "Leche Light GLORIA Lata 390g",
        marca: "GLORIA",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/35081596-600-600/20402653.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_019.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/leche-light-gloria-lata-390g-20402653/p",
        precio: 4.4,
        stock: 40,
        categoria: "lácteos",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Lata 390g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_020",
        nombre: "Leche sin Lactosa UHT LAIVE Caja 946ml",
        descripcion: "Leche sin Lactosa UHT LAIVE Caja 946ml",
        marca: "LAIVE",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_020-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/leche-sin-lactosa-uht-laive-caja-946ml-20393007/p",
        precio: 5.9,
        stock: 45,
        categoria: "lácteos",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Caja 946ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_021",
        nombre: "Yogurt Bebible GLORIA Sabor a Fresa Botella 500g",
        descripcion: "Yogurt Bebible GLORIA Sabor a Fresa Botella 500g",
        marca: "GLORIA",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/36326876-600-600/20326302.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_021.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/yogurt-bebible-gloria-sabor-a-fresa-botella-500g-20326302/p",
        precio: 4.2,
        stock: 50,
        categoria: "lácteos",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 500g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_022",
        nombre: "Yogurt LAIVE Bio Vainilla Francesa Botella 340g",
        descripcion: "Yogurt LAIVE Bio Vainilla Francesa Botella 340g",
        marca: "LAIVE",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/34357852-600-600/20099297.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_022.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/yogurt-laive-bio-vainilla-francesa-botella-370gr/p",
        precio: 3.2,
        stock: 55,
        categoria: "lácteos",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 340g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_023",
        nombre: "Queso Edam LAIVE Paquete 180g",
        descripcion: "Queso Edam LAIVE Paquete 180g",
        marca: "LAIVE",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/28890086-600-600/20047414.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_023.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/queso-edam-laive-paquete-180g/p",
        precio: 10.9,
        stock: 60,
        categoria: "lácteos",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Paquete 180g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_024",
        nombre: "Mantequilla con Sal GLORIA Paquete 180g",
        descripcion: "Mantequilla con Sal GLORIA Paquete 180g",
        marca: "GLORIA",
        imagenUrl:
            "https://metroio.vteximg.com.br/arquivos/ids/607555-600-600/42081-01-29996.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_024-limpia.jpg",
        imagenAutor: "Imagen comercial publicada por Metro",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.metro.pe/mantequilla-con-sal-gloria-180g-42081/p",
        precio: 9.4,
        stock: 65,
        categoria: "lácteos",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Paquete 180g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_025",
        nombre: "Detergente Líquido BOLIVAR Cuidado Total 1.9L",
        descripcion: "Detergente Líquido BOLIVAR Cuidado Total 1.9L",
        marca: "BOLIVAR",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_025-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/detergente-liquido-bolivar-cuidado-total-19l-20464560/p",
        precio: 29.9,
        stock: 30,
        categoria: "limpieza",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Frasco 1.9L"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_026",
        nombre: "Lavavajilla Líquido AYUDIN Lima Limón 900ml",
        descripcion: "Lavavajilla Líquido AYUDIN Lima Limón 900ml",
        marca: "AYUDIN",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/30022031-600-600/20464137.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_026.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/lavavajilla-liquido-ayudin-lima-limon-900ml/p",
        precio: 16.5,
        stock: 35,
        categoria: "limpieza",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Frasco 900ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_027",
        nombre: "Lejía CLOROX Tradicional Botella 2kg",
        descripcion: "Lejía CLOROX Tradicional Botella 2kg",
        marca: "CLOROX",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/31290478-600-600/16469.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_027.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/lejia-clorox-tradicional-galonera-2000-g/p",
        precio: 5.5,
        stock: 40,
        categoria: "limpieza",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 2000g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_028",
        nombre: "Limpiador POETT Frescura de Lavanda Botella 900ml",
        descripcion: "Limpiador POETT Frescura de Lavanda Botella 900ml",
        marca: "POETT",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/32092615/20236178-1.jpg?v=638930556894930000",
        imagenAsset: "assets/productos/marcas/catalogo_028-limpia.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/limpiador-poett-frescura-de-lavanda-botella-900ml/p",
        precio: 4.2,
        stock: 45,
        categoria: "limpieza",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 900ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_029",
        nombre: "Suavizante SUAVITEL Fresca Primavera 1L",
        descripcion: "Suavizante SUAVITEL Fresca Primavera 1L",
        marca: "SUAVITEL",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_029-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/suavizante-suavitel-fresca-primavera-botella-1l/p",
        precio: 11.9,
        stock: 50,
        categoria: "limpieza",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Botella 1000ml"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_030",
        nombre: "Jabón de Lavar BOLÍVAR Cuidado Total Bolsa 190g",
        descripcion: "Jabón de Lavar BOLÍVAR Cuidado Total Bolsa 190g",
        marca: "BOLIVAR",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_030-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/jabon-de-lavar-bolivar-cuidado-total-bolsa-190g-20425167/p",
        precio: 3.2,
        stock: 55,
        categoria: "limpieza",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 190g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_031",
        nombre: "Esponja SCOTCH-BRITE Multiuso Paquete 3un",
        descripcion: "Esponja SCOTCH-BRITE Multiuso Paquete 3un",
        marca: "SCOTCH BRITE",
        imagenUrl:
            "https://metroio.vteximg.com.br/arquivos/ids/238374-600-600/frontal-4159.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_031-limpia.jpg",
        imagenAutor: "Imagen comercial publicada por Metro",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.metro.pe/esponja-2-en-1-multiusos-scotch-brite-pack-3-unid-2/p",
        precio: 13.6,
        stock: 60,
        categoria: "limpieza",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Paquete 3un"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_032",
        nombre:
            "Bolsas para Basura con Aroma Tropical Virutex 35 Litros 10 Unidades",
        descripcion:
            "Bolsas para Basura con Aroma Tropical Virutex 35 Litros 10 Unidades",
        marca: "VIRUTEX",
        imagenUrl:
            "https://metroio.vteximg.com.br/arquivos/ids/648196-600-600/BOLSIRROL-35L-ESEN-TROPI-BLANCA-10U-VTX-1-367724.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_032-limpia.jpg",
        imagenAutor: "Imagen comercial publicada por Metro",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.metro.pe/bolsa-con-aroma-35l-virutex-esencia-tropical-10un-1062249/p",
        precio: 4.5,
        stock: 65,
        categoria: "limpieza",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Paquete 10un"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_033",
        nombre: "Papas Fritas LAY'S Clásicas Sal Bolsa 140g",
        descripcion: "Papas Fritas LAY'S Clásicas Sal Bolsa 140g",
        marca: "LAY'S",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_033-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/papas-fritas-lays-clasicas-sal-bolsa-140g-20355479/p",
        precio: 4.9,
        stock: 30,
        categoria: "snacks",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 140g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_034",
        nombre: "Galletas Saladas FIELD Soda Paquete 6un",
        descripcion: "Galletas Saladas FIELD Soda Paquete 6un",
        marca: "FIELD",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_034-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/galletas-soda-field-bolsa-6un/p",
        precio: 3.9,
        stock: 35,
        categoria: "snacks",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 6un"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_035",
        nombre: "Galletas FIELD ChokoSoda Paquete 6un",
        descripcion: "Galletas FIELD ChokoSoda Paquete 6un",
        marca: "FIELD",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_035-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/galleta-chokosoda-field-paquete-6un/p",
        precio: 6.5,
        stock: 40,
        categoria: "snacks",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Paquete 6un"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_036",
        nombre: "Maní KARINTO Clásico Sal Bolsa 100g",
        descripcion: "Maní KARINTO Clásico Sal Bolsa 100g",
        marca: "KARINTO",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_036-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/mani-karinto-clasico-sal-bolsa-100g-20236194/p",
        precio: 4.2,
        stock: 45,
        categoria: "snacks",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 100g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_037",
        nombre: "Chifles Picantes INKA CHIPS Bolsa 30g",
        descripcion: "Chifles Picantes INKA CHIPS Bolsa 30g",
        marca: "INKA CHIPS",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/31347869-600-600/20501285.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_037.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/chifles-picantes-inka-chips-bolsa-30g/p",
        precio: 2.5,
        stock: 50,
        categoria: "snacks",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 30g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_038",
        nombre: "Maíz Pop Corn COSTEÑO Bolsa 500g",
        descripcion: "Maíz Pop Corn COSTEÑO Bolsa 500g",
        marca: "COSTEÑO",
        imagenUrl:
            "https://plazavea.vteximg.com.br/arquivos/ids/27552448-600-600/998185.jpg",
        imagenAsset: "assets/productos/marcas/catalogo_038.jpg",
        imagenAutor: "Imagen comercial publicada por plazaVea",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/maiz-pop-corn-costeno-bolsa-500g/p",
        precio: 3.4,
        stock: 55,
        categoria: "snacks",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Bolsa 500g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_039",
        nombre: "Galletas OREO Original Taco 135g",
        descripcion: "Galletas OREO Original Taco 135g",
        marca: "OREO",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_039-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente: "https://www.plazavea.com.pe/galleta-oreo-taco-135g/p",
        precio: 3.4,
        stock: 60,
        categoria: "snacks",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Paquete 135g"],
        valoracion: 5,
        esEjemplo: true,
      ),
      Producto(
        id: "catalogo_040",
        nombre: "Chocolate SUBLIME Clásico Tableta 100g",
        descripcion: "Chocolate SUBLIME Clásico Tableta 100g",
        marca: "NESTLE SUBLIME",
        imagenUrl: "",
        imagenAsset: "assets/productos/marcas/catalogo_040-limpia.png",
        imagenAutor:
            "Foto comercial de plazaVea; fondo y paneles exteriores editados con IA",
        imagenLicencia:
            "Imagen comercial del producto; marcas y fotografías de sus respectivos titulares.",
        imagenFuente:
            "https://www.plazavea.com.pe/chocolate-sublime-clasico-paquete-100g/p",
        precio: 10.0,
        stock: 65,
        categoria: "snacks",
        disponible: true,
        fechaRegistro: hoy,
        presentaciones: ["Paquete 100g"],
        valoracion: 5,
        esEjemplo: true,
      ),
    ];
  }
}
