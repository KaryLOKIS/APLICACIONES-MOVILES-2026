import 'package:flutter/material.dart';
import 'pet_detail_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  // Lista de mascotas
  final List<Map<String, String>> mascotas = [
    {
      'nombre': 'NIR',
      'especie': 'Perro',
      'raza': 'Labrador',
      'edad': '3 años',
    },
  ];

  // Color principal de la aplicación
  final Color colorPrincipal = Colors.teal;

  // =========================================================
  // AGREGAR MASCOTA
  // =========================================================

  void mostrarFormularioMascota() {
    final nombreController = TextEditingController();
    final razaController = TextEditingController();
    final edadController = TextEditingController();

    String especieSeleccionada = 'Perro';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.pets,
                    color: Colors.teal,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Agregar mascota',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Ej. Max',
                        prefixIcon: const Icon(Icons.badge),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: especieSeleccionada,
                      decoration: InputDecoration(
                        labelText: 'Especie',
                        prefixIcon: const Icon(Icons.pets),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Perro',
                          child: Text('🐶 Perro'),
                        ),
                        DropdownMenuItem(
                          value: 'Gato',
                          child: Text('🐱 Gato'),
                        ),
                        DropdownMenuItem(
                          value: 'Otro',
                          child: Text('🐾 Otro'),
                        ),
                      ],
                      onChanged: (valor) {
                        setDialogState(() {
                          especieSeleccionada = valor ?? 'Perro';
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: razaController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Raza',
                        hintText: 'Ej. Labrador',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: edadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Edad',
                        hintText: 'Ej. 3',
                        suffixText: 'años',
                        prefixIcon: const Icon(Icons.cake),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actionsPadding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                15,
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),

                ElevatedButton(
                  onPressed: () {
                    final nombre =
                        nombreController.text.trim();

                    final raza =
                        razaController.text.trim();

                    final edad =
                        edadController.text.trim();

                    if (nombre.isEmpty ||
                        raza.isEmpty ||
                        edad.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Completa todos los campos para continuar.',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      mascotas.add({
                        'nombre': nombre,
                        'especie': especieSeleccionada,
                        'raza': raza,
                        'edad': '$edad años',
                      });
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$nombre fue agregado correctamente 🐾',
                        ),
                        backgroundColor: Colors.teal,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // ELIMINAR MASCOTA
  // =========================================================

  void eliminarMascota(int index) {
    final nombre = mascotas[index]['nombre'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Eliminar mascota',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar a $nombre?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  mascotas.removeAt(index);
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Mascota eliminada correctamente.',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // ABRIR DETALLE DE MASCOTA
  // =========================================================

  void abrirDetalleMascota(Map<String, String> mascota) {
    final nombre = mascota['nombre'] ?? 'Mascota';
    final especie = mascota['especie'] ?? 'Desconocida';
    final raza = mascota['raza'] ?? 'Sin raza';

    final edadTexto = mascota['edad'] ?? '0 años';

    // Extraemos solamente el número de la edad.
    final edadNumero =
        int.tryParse(edadTexto.split(' ').first) ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetDetailScreen(
          nombre: nombre,
          especie: especie,
          raza: raza,
          edad: edadNumero,
        ),
      ),
    );
  }

  // =========================================================
  // ICONO SEGÚN ESPECIE
  // =========================================================

  IconData obtenerIcono(String especie) {
    if (especie == 'Gato') {
      return Icons.pets;
    }

    if (especie == 'Perro') {
      return Icons.pets;
    }

    return Icons.pets;
  }

  // =========================================================
  // INTERFAZ
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,

      // ==============================
      // APP BAR
      // ==============================

      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Mis mascotas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ==============================
      // CUERPO
      // ==============================

      body: mascotas.isEmpty
          ? _pantallaSinMascotas()
          : Column(
              children: [
                _encabezado(),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      5,
                      20,
                      100,
                    ),
                    itemCount: mascotas.length,
                    itemBuilder: (context, index) {
                      final mascota = mascotas[index];

                      return _tarjetaMascota(
                        mascota,
                        index,
                      );
                    },
                  ),
                ),
              ],
            ),

      // ==============================
      // BOTÓN AGREGAR
      // ==============================

      floatingActionButton: FloatingActionButton(
        onPressed: mostrarFormularioMascota,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(
          Icons.add,
          size: 30,
        ),
      ),
    );
  }

  // =========================================================
  // PANTALLA SIN MASCOTAS
  // =========================================================

  Widget _pantallaSinMascotas() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.pets,
                size: 70,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Aún no tienes mascotas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Agrega tu primera mascota para comenzar a registrar su información de salud.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: mostrarFormularioMascota,
              icon: const Icon(Icons.add),
              label: const Text(
                'Agregar mascota',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ENCABEZADO
  // =========================================================

  Widget _encabezado() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        10,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite,
              color: Colors.teal,
              size: 28,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tus compañeros 🐾',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${mascotas.length} mascota'
                  '${mascotas.length == 1 ? '' : 's'} '
                  'registrada'
                  '${mascotas.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TARJETA DE MASCOTA
  // =========================================================

  Widget _tarjetaMascota(
    Map<String, String> mascota,
    int index,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),

        // AQUÍ ABRIMOS EL DETALLE
        onTap: () {
          abrirDetalleMascota(mascota);
        },

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  obtenerIcono(
                    mascota['especie'] ?? '',
                  ),
                  color: Colors.teal,
                  size: 38,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      mascota['nombre'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${mascota['especie']} • '
                      '${mascota['raza']}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Edad: ${mascota['edad']}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Toca para ver su ficha →',
                      style: TextStyle(
                        color: Colors.teal,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // MENÚ ELIMINAR
              PopupMenuButton<String>(
                onSelected: (opcion) {
                  if (opcion == 'eliminar') {
                    eliminarMascota(index);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}