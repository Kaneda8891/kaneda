import 'package:flutter/material.dart';
import 'package:avance2/models/usuario.dart';
import 'package:avance2/screens/register_screen.dart';
import 'dart:io';

class UsuarioForm extends StatefulWidget {
  final void Function(Usuario) onSubmit;
  final Usuario? usuarioExistente;

  const UsuarioForm({super.key, required this.onSubmit, this.usuarioExistente});

  @override
  State<UsuarioForm> createState() => _UsuarioFormState();
}

class _UsuarioFormState extends State<UsuarioForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _id;
  late TextEditingController _nombre;
  late TextEditingController _correo;
  late TextEditingController _rol;

  bool _rostroRegistrado = false;
  String? _rostroPath;

  @override
  void initState() {
    super.initState();
    final u = widget.usuarioExistente;
    _id = TextEditingController(text: u?.id ?? '');
    _nombre = TextEditingController(text: u?.nombre ?? '');
    _correo = TextEditingController(text: u?.correo ?? '');
    _rol = TextEditingController(text: u?.rol ?? '');
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      final nuevo = Usuario(
        id: _id.text.trim(),
        nombre: _nombre.text.trim(),
        correo: _correo.text.trim(),
        rol: _rol.text.trim(),
      );
      widget.onSubmit(nuevo);
      Navigator.pop(context);
    }
  }

  Future<void> _abrirRegistroRostro() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final path = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterScreen(nombre: _nombre.text.trim()),
      ),
    );
    if (mounted && path != null) {
      setState(() {
        _rostroRegistrado = true;
        _rostroPath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            _campo('ID', _id),
            _campo('Nombre', _nombre),
            _campo('Correo', _correo, tipo: TextInputType.emailAddress),
            _campo('Rol', _rol),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _abrirRegistroRostro,
              icon: const Icon(Icons.face),
              label: const Text('Registrar rostro (opcional)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF074F8A),
              ),
            ),
            if (_rostroRegistrado)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    if (_rostroPath != null)
                      Image.file(
                        File(_rostroPath!),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Rostro registrado',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF074F8A),
              ),
              child: const Text('Guardar Usuario'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(
    String label,
    TextEditingController controller, {
    TextInputType tipo = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Campo requerido' : null,
      ),
    );
  }
}
