import 'package:flutter/material.dart';

class CampoLista extends StatefulWidget {
  final String etiqueta;
  final List<String> items;

  const CampoLista({super.key, required this.etiqueta, required this.items});

  @override
  State<CampoLista> createState() => _CampoListaState();
}

class _CampoListaState extends State<CampoLista> {
  final _controller = TextEditingController();

  void _agregar() {
    final texto = _controller.text.trim();
    if (texto.isEmpty || widget.items.contains(texto)) return;
    setState(() => widget.items.add(texto));
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.etiqueta,
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _agregar,
            ),
          ),
          onSubmitted: (_) => _agregar(),
        ),
        Wrap(
          spacing: 6,
          children: widget.items
              .map(
                (item) => Chip(
                  label: Text(item),
                  onDeleted: () => setState(() => widget.items.remove(item)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
