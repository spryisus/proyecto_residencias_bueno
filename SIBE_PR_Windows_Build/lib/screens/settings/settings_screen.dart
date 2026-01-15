import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/modern_button.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de Información de la Aplicación
            _buildSectionHeader(context, 'Información'),
            const SizedBox(height: 16),
            
            AnimatedCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(context, 'Versión', '1.0.0'),
                  const Divider(height: 20),
                  _buildInfoRow(context, 'Desarrollado por', 'Equipo Telmex'),
                  const Divider(height: 20),
                  _buildInfoRow(context, 'Soporte', 'soporte@telmex.com'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sección de Acciones
            _buildSectionHeader(context, 'Acciones'),
            const SizedBox(height: 16),
            
            ModernButton(
              text: 'Cerrar Sesión',
              icon: Icons.logout,
              backgroundColor: Theme.of(context).colorScheme.error,
              onPressed: () => _showLogoutDialog(context),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: Theme.of(context).colorScheme.onBackground,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ModernButton(
            text: 'Cerrar Sesión',
            backgroundColor: Theme.of(context).colorScheme.error,
            onPressed: () async {
              Navigator.pop(context);
              await _logout(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Limpiar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('id_empleado');
      await prefs.remove('nombre_usuario');
      await prefs.setBool('is_logged_in', false);
      
      // Navegar al login y limpiar el stack de navegación
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

