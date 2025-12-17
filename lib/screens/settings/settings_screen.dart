import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme/theme_provider.dart';
import '../../widgets/animated_card.dart';
import '../../widgets/modern_button.dart';

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
            // Sección de Apariencia
            _buildSectionHeader(context, 'Apariencia'),
            const SizedBox(height: 16),
            
            // Tema
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return AnimatedCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () => _showThemeSelector(context, themeProvider),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            themeProvider.themeIcon,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tema',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  themeProvider.themeModeName,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
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

  void _showThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              'Elegir Tema',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            
            // Opción Claro
            _buildThemeOption(
              context,
              themeProvider,
              ThemeMode.light,
              'Claro',
              Icons.light_mode,
              'Usar tema claro en toda la aplicación',
            ),
            
            const SizedBox(height: 12),
            
            // Opción Oscuro
            _buildThemeOption(
              context,
              themeProvider,
              ThemeMode.dark,
              'Oscuro',
              Icons.dark_mode,
              'Usar tema oscuro en toda la aplicación',
            ),
            
            const SizedBox(height: 12),
            
            // Opción Sistema
            _buildThemeOption(
              context,
              themeProvider,
              ThemeMode.system,
              'Sistema',
              Icons.brightness_6,
              'Seguir la configuración del dispositivo',
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeProvider themeProvider,
    ThemeMode mode,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = themeProvider.themeMode == mode;
    
    return AnimatedCard(
      onTap: () {
        switch (mode) {
          case ThemeMode.light:
            themeProvider.setLightTheme();
            break;
          case ThemeMode.dark:
            themeProvider.setDarkTheme();
            break;
          case ThemeMode.system:
            themeProvider.setSystemTheme();
            break;
        }
        Navigator.pop(context);
      },
      color: isSelected 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : null,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            ),
        ],
      ),
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implementar lógica de logout
            },
          ),
        ],
      ),
    );
  }
}

