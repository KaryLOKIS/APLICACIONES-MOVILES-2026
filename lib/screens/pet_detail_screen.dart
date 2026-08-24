import 'package:flutter/material.dart';

class PetDetailScreen extends StatelessWidget {
  final String nombre;
  final String especie;
  final String raza;
  final int edad;

  const PetDetailScreen({
    super.key,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.edad,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,

      // ==============================
      // BARRA SUPERIOR
      // ==============================
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Ficha de mi mascota',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ==============================
      // CONTENIDO
      // ==============================
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ==============================
            // ENCABEZADO DE LA MASCOTA
            // ==============================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [

                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 58,
                      color: Colors.teal,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    '$especie • $raza',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==============================
            // INFORMACIÓN BÁSICA
            // ==============================
            _tituloSeccion(
              'Información básica',
              Icons.info_outline,
            ),

            const SizedBox(height: 10),

            Row(
              children: [

                Expanded(
                  child: _tarjetaInformacion(
                    icono: Icons.pets,
                    titulo: 'Especie',
                    valor: especie,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _tarjetaInformacion(
                    icono: Icons.category,
                    titulo: 'Raza',
                    valor: raza,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _tarjetaInformacion(
              icono: Icons.cake,
              titulo: 'Edad',
              valor: '$edad años',
            ),

            const SizedBox(height: 25),

            // ==============================
            // SALUD
            // ==============================
            _tituloSeccion(
              'Salud',
              Icons.favorite,
            ),

            const SizedBox(height: 10),

            _opcionSalud(
              context: context,
              icono: Icons.vaccines,
              titulo: 'Vacunas',
              descripcion: 'Consulta y registra las vacunas.',
              color: Colors.blue,
            ),

            const SizedBox(height: 12),

            _opcionSalud(
              context: context,
              icono: Icons.medication,
              titulo: 'Desparasitación',
              descripcion: 'Controla las fechas de desparasitación.',
              color: Colors.orange,
            ),

            const SizedBox(height: 12),

            _opcionSalud(
              context: context,
              icono: Icons.medical_services,
              titulo: 'Historial de salud',
              descripcion: 'Información médica de tu mascota.',
              color: Colors.red,
            ),

            const SizedBox(height: 25),

            // ==============================
            // CUIDADOS
            // ==============================
            _tituloSeccion(
              'Cuidados',
              Icons.favorite_border,
            ),

            const SizedBox(height: 10),

            _opcionSalud(
              context: context,
              icono: Icons.notifications,
              titulo: 'Recordatorios',
              descripcion: 'Próximamente podrás crear recordatorios.',
              color: Colors.purple,
            ),

            const SizedBox(height: 12),

            _opcionSalud(
              context: context,
              icono: Icons.calendar_month,
              titulo: 'Citas veterinarias',
              descripcion: 'Organiza las próximas consultas.',
              color: Colors.teal,
            ),

            const SizedBox(height: 25),

            // ==============================
            // BOTÓN EDITAR
            // ==============================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'La edición de la mascota estará disponible próximamente. ✏️',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text(
                  'Editar información',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TÍTULO DE SECCIÓN
  // =========================================================

  Widget _tituloSeccion(
    String titulo,
    IconData icono,
  ) {
    return Row(
      children: [
        Icon(
          icono,
          color: Colors.teal,
          size: 23,
        ),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TARJETA DE INFORMACIÓN
  // =========================================================

  Widget _tarjetaInformacion({
    required IconData icono,
    required String titulo,
    required String valor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Icon(
            icono,
            color: Colors.teal,
            size: 28,
          ),

          const SizedBox(height: 8),

          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            valor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // OPCIONES DE SALUD
  // =========================================================

  Widget _opcionSalud({
    required BuildContext context,
    required IconData icono,
    required String titulo,
    required String descripcion,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),

        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icono,
            color: color,
          ),
        ),

        title: Text(
          titulo,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            descripcion,
          ),
        ),

        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 17,
        ),

        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$titulo: función disponible próximamente 🐾',
              ),
            ),
          );
        },
      ),
    );
  }
}