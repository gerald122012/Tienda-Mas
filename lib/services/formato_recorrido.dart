import 'routing_service.dart';

String textoDistanciaRecorrido(double metros) {
  if (!metros.isFinite || metros < 0) return 'No disponible';
  if (metros < 1000) return '${metros.round()} m';
  final kilometros = metros / 1000;
  final texto = kilometros >= 10
      ? kilometros.toStringAsFixed(0)
      : kilometros.toStringAsFixed(1);
  return '$texto km';
}

String textoDistanciaAproximada(double metros) {
  return 'Aprox. ${textoDistanciaRecorrido(metros)} en línea recta';
}

String textoDuracionEstimada(double segundos) {
  if (!segundos.isFinite || segundos < 0) return 'No disponible';
  final totalMinutos = (segundos / 60).ceil().clamp(1, 9999);
  if (totalMinutos < 60) return '$totalMinutos min';
  final horas = totalMinutos ~/ 60;
  final minutos = totalMinutos % 60;
  if (minutos == 0) return '$horas h';
  return '$horas h $minutos min';
}

String resumenRutaParaCarrito({
  required String nombreDestino,
  required ModoRuta modo,
  required ResultadoRuta ruta,
}) {
  final modoTexto = modo == ModoRuta.carro ? 'En vehículo' : 'Caminando';
  return '$nombreDestino · $modoTexto · '
      '${textoDistanciaRecorrido(ruta.distanciaMetros)} · '
      '${textoDuracionEstimada(ruta.duracionSegundos)}';
}
