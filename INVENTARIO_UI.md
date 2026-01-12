# INVENTARIO DE UI - PROYECTO TELMEX INVENTARIOS

## TEMA GLOBAL DE LA APLICACIÓN

### Archivo: lib/app/theme/app_theme.dart
### Widget raíz: ThemeData (lightTheme)

**Configuración del tema:**
- useMaterial3: true
- Brightness: light
- Modo oscuro: Deshabilitado (solo tema claro activo)

**ColorScheme:**
- Primary: Color(0xFF003366) - Azul oscuro Telmex
- Secondary: Color(0xFF0066CC) - Azul secundario
- Tertiary: Color(0xFF4A90E2) - Azul acento
- Surface: Colors.white
- SurfaceVariant: Color(0xFFF8F9FA) - grey100
- Background: Color(0xFFF8F9FA) - grey100
- Error: Color(0xFFDC3545) - errorRed
- OnPrimary: Colors.white
- OnSecondary: Colors.white
- OnSurface: Color(0xFF343A40) - grey800
- OnBackground: Color(0xFF343A40) - grey800
- OnError: Colors.white
- Outline: Color(0xFFDEE2E6) - grey300

**Paleta de colores adicionales:**
- primaryBlue: Color(0xFF003366)
- secondaryBlue: Color(0xFF0066CC)
- accentBlue: Color(0xFF4A90E2)
- lightBlue: Color(0xFFE6F3FF)
- successGreen: Color(0xFF28A745)
- warningOrange: Color(0xFFFF9800)
- errorRed: Color(0xFFDC3545)
- infoBlue: Color(0xFF17A2B8)
- grey100 a grey900: Escala de grises desde #F8F9FA hasta #212529

**AppBar Theme:**
- backgroundColor: Colors.white
- foregroundColor: Color(0xFF343A40) - grey800
- elevation: 1
- shadowColor: Colors.black12
- titleTextStyle: fontSize 20, fontWeight w600, letterSpacing 0.5, color grey800
- centerTitle: true

**Card Theme:**
- elevation: 2
- shadowColor: Colors.black26
- borderRadius: BorderRadius.all(Radius.circular(16))
- surfaceTintColor: Colors.transparent

**ElevatedButton Theme:**
- backgroundColor: Color(0xFF003366) - primaryBlue
- foregroundColor: Colors.white
- elevation: 2
- shadowColor: primaryBlue
- borderRadius: BorderRadius.circular(12)
- padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)
- textStyle: fontSize 16, fontWeight w500, letterSpacing 0.5

**TextButton Theme:**
- foregroundColor: Color(0xFF003366) - primaryBlue
- padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8)
- textStyle: fontSize 16, fontWeight w500

**InputDecoration Theme:**
- border: OutlineInputBorder con borderRadius 12, borderSide grey300 width 1
- enabledBorder: OutlineInputBorder con borderRadius 12, borderSide grey300 width 1
- focusedBorder: OutlineInputBorder con borderRadius 12, borderSide primaryBlue width 2
- errorBorder: OutlineInputBorder con borderRadius 12, borderSide errorRed width 1
- focusedErrorBorder: OutlineInputBorder con borderRadius 12, borderSide errorRed width 2
- filled: true
- fillColor: Colors.white
- contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)

**Tipografía (TextTheme):**
- displayLarge: fontSize 32, fontWeight bold, color grey800, letterSpacing -0.5
- displayMedium: fontSize 28, fontWeight bold, color grey800, letterSpacing -0.25
- displaySmall: fontSize 24, fontWeight w600, color grey800, letterSpacing 0
- headlineLarge: fontSize 22, fontWeight w600, color grey800, letterSpacing 0
- headlineMedium: fontSize 20, fontWeight w600, color grey800, letterSpacing 0.15
- headlineSmall: fontSize 18, fontWeight w600, color grey800, letterSpacing 0.15
- titleLarge: fontSize 18, fontWeight w600, color grey800, letterSpacing 0.15
- titleMedium: fontSize 16, fontWeight w500, color grey800, letterSpacing 0.15
- titleSmall: fontSize 14, fontWeight w500, color grey800, letterSpacing 0.1
- bodyLarge: fontSize 16, fontWeight normal, color grey700, letterSpacing 0.15
- bodyMedium: fontSize 14, fontWeight normal, color grey700, letterSpacing 0.25
- bodySmall: fontSize 12, fontWeight normal, color grey600, letterSpacing 0.4
- labelLarge: fontSize 14, fontWeight w500, color grey700, letterSpacing 0.1
- labelMedium: fontSize 12, fontWeight w500, color grey700, letterSpacing 0.5
- labelSmall: fontSize 11, fontWeight w500, color grey600, letterSpacing 0.5

**Icon Theme:**
- color: Color(0xFF6C757D) - grey600
- size: 24

**FloatingActionButton Theme:**
- backgroundColor: Color(0xFF003366) - primaryBlue
- foregroundColor: Colors.white
- elevation: 3
- borderRadius: BorderRadius.all(Radius.circular(16))

**Divider Theme:**
- color: Color(0xFFE9ECEF) - grey200
- thickness: 1
- space: 1

---

## PANTALLA DE LOGIN

### Archivo: lib/screens/auth/login_screen.dart
### Widget raíz: Scaffold

**Layout:**
- Column principal con SingleChildScrollView
- Padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16)
- mainAxisAlignment: MainAxisAlignment.center
- crossAxisAlignment: CrossAxisAlignment.center

**AppBar:**
- title: 'Inicio de sesión Larga Distancia'
- centerTitle: true
- actions: IconButton con Icons.settings

**Contenido:**
- Icon: Icons.lock_outline, size 84, color Color(0xFF003366)
- SizedBox height 12
- Text 'Ingreso al Sistema': fontSize 24, fontWeight bold, color Color(0xFF003366), textAlign center
- SizedBox height 24
- ConstrainedBox con maxWidth 360
- Form con Column

**Campos de formulario:**
- TextFormField (Correo de usuario):
  - decoration: InputDecoration con labelText 'Correo de usuario', prefixIcon Icons.person_outline, border OutlineInputBorder
  - validator: valida que no esté vacío
- SizedBox height 16
- TextFormField (Contraseña):
  - obscureText: true
  - decoration: InputDecoration con labelText 'Contraseña', prefixIcon Icons.lock_outline, border OutlineInputBorder
  - validator: valida que no esté vacío
- SizedBox height 20
- ElevatedButton (Iniciar sesión):
  - height: 48
  - backgroundColor: Color(0xFF003366)
  - foregroundColor: Colors.white
  - child: CircularProgressIndicator cuando está cargando (strokeWidth 2.5, color blanco) o Text 'Iniciar sesión'
  - disabled cuando _isLoggingIn es true
- SizedBox height 12
- TextButton (Probar Conexión Supabase):
  - textStyle: fontSize 14, fontWeight w500, color primary cuando no está cargando, disabledColor cuando está cargando
  - disabled cuando _isTestingConnection es true

**SnackBar:**
- backgroundColor: Colors.green para éxito, Colors.red para error
- duration: Duration(seconds: 3)
- action: SnackBarAction con label 'Cerrar', textColor Colors.white

---

## PANTALLA WELCOME PAGE (Usuario no admin)

### Archivo: lib/screens/auth/login_screen.dart (clase WelcomePage)
### Widget raíz: Scaffold

**Layout:**
- LayoutBuilder para responsive
- SingleChildScrollView con padding EdgeInsets.all(20)
- Column con crossAxisAlignment CrossAxisAlignment.stretch

**AppBar:**
- title: 'Bienvenido'
- centerTitle: true
- actions: IconButton refresh, IconButton cloud_done, IconButton settings

**Drawer:**
- DrawerHeader:
  - decoration: BoxDecoration con color Theme.of(context).primaryColor
  - child: Column con mainAxisAlignment MainAxisAlignment.end
  - Text 'Menú': headlineSmall, color white, fontWeight bold
  - Row con Icon Icons.person y Text con username (color white70, fontSize 14)
- ListTile items:
  - Inventarios: Icons.inventory_2_outlined, size 24
  - Envíos: Icons.local_shipping_outlined, size 24
  - Solicitud SDR: Icons.description_outlined, size 24
  - Divider height 24
  - Ajustes: Icons.settings_outlined, size 24
  - minVerticalPadding: 16
  - textStyle: titleMedium con fontWeight w500

**Body:**
- Text 'BIENVENIDO AL SISTEMA DE LARGA DISTANCIA': headlineMedium, fontWeight bold, color primary, textAlign center
- SizedBox height 24
- Layout responsive:
  - Si isWideScreen (maxWidth > 800): Row con Expanded flex 2 (ClockWidget, QuickStatsWidget) y Expanded flex 3 (CalendarWidget)
  - Si no: Column con ClockWidget, CalendarWidget, QuickStatsWidget
- SizedBox height 24
- ElevatedButton.icon 'Volver al login':
  - backgroundColor: primaryColor
  - foregroundColor: Colors.white
  - borderRadius: BorderRadius.circular(12)
  - elevation: 4
  - minimumSize: Size(double.infinity, 48)
  - ConstrainedBox maxWidth 280
- SizedBox height 24
- Sección de inventarios guardados (_buildSessionSection)

**Session Cards:**
- Card con margin EdgeInsets.only(bottom: 12)
- ListTile:
  - leading: CircleAvatar con backgroundColor chipColor.withOpacity(0.15), child Icon (Icons.pause_circle_outline o Icons.check_circle_outline) color chipColor
  - title: Text con categoryName, overflow ellipsis, maxLines 1
  - subtitle: Text con fecha actualizada, overflow ellipsis, maxLines 1
  - trailing: Row con Container (chip de estado) e IconButton delete
  - Container chip: padding EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration BoxDecoration con color chipColor.withOpacity(0.15), borderRadius 12, Text con fontSize 11, fontWeight w600, color chipColor
  - IconButton: Icons.delete_outline, size 20, color Colors.red[300], padding zero, constraints BoxConstraints()

**Colores de estado:**
- Pendiente: Colors.orange
- Terminado: Colors.green

---

## PANTALLA ADMIN DASHBOARD

### Archivo: lib/screens/admin/admin_dashboard.dart
### Widget raíz: Scaffold

**Layout:**
- Padding EdgeInsets.all(16.0)
- SingleChildScrollView
- Column con crossAxisAlignment CrossAxisAlignment.start

**AppBar:**
- title: 'Panel de Administración'
- centerTitle: true
- actions: IconButton refresh, IconButton settings

**Drawer:**
- DrawerHeader:
  - decoration: BoxDecoration con color Theme.of(context).colorScheme.primary
  - Text 'Admin': headlineMedium, color onPrimary, fontWeight bold
  - Row con Icon Icons.person y Text username (color onPrimary con opacity 0.7)
- ListTile items:
  - Inventario: Icons.inventory_2_outlined, size 24
  - Envíos: Icons.local_shipping_outlined, size 24
  - Gestión de usuarios: Icons.group_add_outlined, size 24
  - Actividad de usuarios: Icons.analytics_outlined, size 24
  - Solicitud SDR: Icons.description_outlined, size 24
  - Divider height 24
  - Cerrar sesión: Icons.logout, size 24
  - minVerticalPadding: 16

**Body:**
- Text 'Dashboard de Administrador': displaySmall, fontWeight bold
- SizedBox height 16
- LayoutBuilder responsive:
  - Si isWideScreen (maxWidth > 900): Row con Expanded flex 2 (ClockWidget, QuickStatsWidget) y Expanded flex 3 (CalendarWidget)
  - Si no: Column con ClockWidget, CalendarWidget, QuickStatsWidget
- SizedBox height 24
- Sección de inventarios guardados
- SizedBox height 24
- Text 'Accesos Rápidos': titleLarge, fontWeight bold
- SizedBox height 16
- GridView.count responsive:
  - Móvil (maxWidth < 600): crossAxisCount 1, childAspectRatio 2.5
  - Tablet (maxWidth < 900): crossAxisCount 2, childAspectRatio 1.3
  - Desktop: crossAxisCount 3, childAspectRatio 1.1
  - crossAxisSpacing: 12
  - mainAxisSpacing: 12
  - shrinkWrap: true
  - physics: NeverScrollableScrollPhysics

**Stat Cards (_buildStatCard):**
- Card con elevation 3
- InkWell con borderRadius BorderRadius.circular(8)
- Padding EdgeInsets.all(12.0)
- Column con mainAxisAlignment MainAxisAlignment.center:
  - Icon size 32, color personalizado
  - SizedBox height 8
  - Text title: titleMedium, fontWeight bold, fontSize 16, textAlign center, maxLines 1, overflow ellipsis
  - SizedBox height 2
  - Text subtitle: bodySmall, color onSurface con opacity 0.7, fontSize 12, textAlign center, maxLines 2, overflow ellipsis

**Session Cards:**
- Card con margin EdgeInsets.only(bottom: 8)
- InkWell con borderRadius BorderRadius.circular(12)
- Padding EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0)
- Row:
  - CircleAvatar radius 20, backgroundColor chipColor.withOpacity(0.15), child Icon size 20
  - SizedBox width 12
  - Expanded Column:
    - Text categoryName: titleMedium, fontWeight w600, maxLines 1, overflow ellipsis
    - SizedBox height 3
    - Text fecha: bodySmall, color onSurface con opacity 0.7, fontSize 12, maxLines 1, overflow ellipsis
    - Si es pendiente y tiene ownerEmail: Row con Icon Icons.email_outlined size 12 y Text email (fontSize 11, fontStyle italic)
  - SizedBox width 8
  - Container chip: padding EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration BoxDecoration con color chipColor.withOpacity(0.15), borderRadius 12, Text con fontSize 11, fontWeight w600, color chipColor

**Dialog de detalles (_SessionDetailDialog):**
- AlertDialog
- title: 'Detalles del inventario'
- content: SizedBox width double.maxFinite, Column:
  - _buildInfoRow para cada campo
  - SizedBox height 16
  - Text 'Productos capturados': titleMedium
  - SizedBox height 8
  - SizedBox height 200 con ListView de ListTile dense
- actions: TextButton 'Cerrar'

**Info Row:**
- Row con crossAxisAlignment CrossAxisAlignment.start:
  - Text label: bodyMedium, fontWeight w600
  - Expanded Text value: bodyMedium

---

## PANTALLA DE ENVÍOS

### Archivo: lib/screens/shipments/shipments_screen.dart
### Widget raíz: Scaffold

**Layout:**
- Padding EdgeInsets.all(16.0)
- Column con crossAxisAlignment CrossAxisAlignment.center

**AppBar:**
- title: Text 'Envíos' con style TextStyle(color: Colors.white)
- centerTitle: true
- backgroundColor: Color(0xFF003366)
- foregroundColor: Colors.white
- actions: IconButton settings

**Body:**
- Text 'Módulo de Envíos': displaySmall, fontWeight bold, textAlign center
- SizedBox height 8
- Text descriptivo: bodyLarge, color onBackground con opacity 0.7, textAlign center
- SizedBox height 20
- Expanded con LayoutBuilder:
  - Si isMobile (maxWidth < 600): crossAxisCount 1, childAspectRatio 1.2
  - Si no: crossAxisCount 2, maxWidth 600.0, childAspectRatio 1.0
  - GridView.count con crossAxisSpacing 16, mainAxisSpacing 16
  - Center con SizedBox width maxWidth

**Envío Option Cards (_buildEnvioOptionCard):**
- AnimatedCard:
  - padding: EdgeInsets.all(20)
  - borderRadius: BorderRadius.circular(16)
  - child: Column con mainAxisAlignment MainAxisAlignment.center:
    - Container:
      - padding: EdgeInsets.all(16)
      - decoration: BoxDecoration con color primary con opacity 0.1, borderRadius 16
      - child: Icon size 40, color primary
    - SizedBox height 16
    - Text title: titleLarge, fontWeight bold, textAlign center, maxLines 2, overflow ellipsis
    - SizedBox height 8
    - Text subtitle: bodyMedium, color onSurface con opacity 0.7, textAlign center, maxLines 2, overflow ellipsis

**Tracking Dialog (_TrackingDialog):**
- AlertDialog
- title: 'Rastrear Envío'
- content: Form con SingleChildScrollView, Column:
  - Text 'Selecciona la paquetería:': fontSize 14, fontWeight w600
  - SizedBox height 12
  - InkWell opciones de paquetería:
    - borderRadius: BorderRadius.circular(12)
    - Container:
      - padding: EdgeInsets.all(12)
      - decoration: BoxDecoration:
        - border: Border.all con color primary cuando seleccionado (width 2) o grey300 (width 1)
        - borderRadius: BorderRadius.circular(12)
        - color: primary con opacity 0.1 cuando seleccionado o transparent
      - child: Row:
        - Container icon:
          - padding: EdgeInsets.all(8)
          - decoration: BoxDecoration con color específico con opacity 0.2 o grey200, borderRadius 8
          - child: Icon size 24, color específico o grey600
        - SizedBox width 12
        - Expanded Text: fontSize 16, fontWeight w500
        - Si está seleccionado: Icon Icons.check_circle color primary
  - SizedBox height 24
  - Text 'Número de seguimiento:': fontSize 14, fontWeight w600
  - SizedBox height 8
  - TextFormField:
    - decoration: InputDecoration con labelText 'Número de Guía', hintText dinámico, prefixIcon Icons.qr_code_scanner, border OutlineInputBorder
    - validator: valida que no esté vacío
    - autofocus: false
    - textInputAction: TextInputAction.done
- actions:
  - TextButton 'Cancelar'
  - ElevatedButton.icon:
    - icon: Icons.open_in_browser
    - label: Text dinámico según paquetería
    - backgroundColor: Color(0xFF003366)
    - foregroundColor: Colors.white

**Colores de paqueterías:**
- DHL: Colors.yellow[700]
- 3guerras: Colors.orange[700]

---

## PANTALLA DE BITÁCORA

### Archivo: lib/screens/shipments/bitacora_screen.dart
### Widget raíz: Scaffold

**Layout:**
- LayoutBuilder para responsive (móvil vs desktop)
- Column principal

**AppBar:**
- title: 'Bitácora de Envíos'
- centerTitle: true
- actions: IconButton export, IconButton add

**Body móvil:**
- Padding EdgeInsets.all(16)
- Column:
  - Filtros de año (chips horizontales scrollables)
  - SizedBox height 16
  - Expanded con ListView de tarjetas de bitácora

**Body desktop:**
- Padding EdgeInsets.all(24)
- Column:
  - Filtros de año
  - SizedBox height 24
  - Expanded con GridView o ListView según preferencia

**Tarjetas de bitácora (móvil):**
- Card con margin EdgeInsets.only(bottom: 12)
- Padding EdgeInsets.all(16)
- Column:
  - Row:
    - Expanded Text consecutivo: titleMedium, fontWeight bold
    - Row de botones (edit, delete)
  - SizedBox height 8
  - Text fecha: bodySmall
  - SizedBox height 8
  - Divider
  - SizedBox height 8
  - Campos de información en Column

**Tarjetas de bitácora (desktop):**
- Card con margin EdgeInsets.only(bottom: 16)
- Padding EdgeInsets.all(20)
- Layout similar pero con más espacio

**Filtros de año:**
- Wrap o Row con chips
- Chip:
  - backgroundColor: primary cuando seleccionado, grey200 cuando no
  - labelStyle: color primary cuando seleccionado, grey700 cuando no
  - padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
  - borderRadius: BorderRadius.circular(20)

**Botones de acción:**
- IconButton con Icons.edit, Icons.delete
- color: primary para edit, errorRed para delete
- size: 24

**Formulario de bitácora:**
- AlertDialog o BottomSheet
- Form con TextFormField para cada campo
- Botones: TextButton 'Cancelar', ElevatedButton 'Guardar'

---

## PANTALLA DE CONFIGURACIÓN

### Archivo: lib/screens/settings/settings_screen.dart
### Widget raíz: Scaffold

**Layout:**
- SingleChildScrollView
- Padding EdgeInsets.all(16.0)
- Column con crossAxisAlignment CrossAxisAlignment.start

**AppBar:**
- title: 'Configuración'
- elevation: 0

**Body:**
- _buildSectionHeader 'Información': headlineSmall, color onBackground, fontWeight w600
- SizedBox height 16
- AnimatedCard:
  - padding: EdgeInsets.all(16)
  - child: Column:
    - _buildInfoRow 'Versión' '1.0.0'
    - Divider height 20
    - _buildInfoRow 'Desarrollado por' 'Equipo Telmex'
    - Divider height 20
    - _buildInfoRow 'Soporte' 'soporte@telmex.com'
- SizedBox height 24
- _buildSectionHeader 'Acciones': headlineSmall
- SizedBox height 16
- ModernButton:
  - text: 'Cerrar Sesión'
  - icon: Icons.logout
  - backgroundColor: Theme.of(context).colorScheme.error
- SizedBox height 40

**Info Row:**
- Row con mainAxisAlignment MainAxisAlignment.spaceBetween:
  - Text label: bodyMedium
  - Text value: bodyMedium, color onSurface con opacity 0.7

**Logout Dialog:**
- AlertDialog
- title: 'Cerrar Sesión'
- content: Text '¿Estás seguro de que quieres cerrar sesión?'
- actions:
  - TextButton 'Cancelar'
  - ModernButton 'Cerrar Sesión' con backgroundColor error

---

## PANTALLA DE GESTIÓN DE USUARIOS

### Archivo: lib/screens/admin/users_management_screen.dart
### Widget raíz: Scaffold

**Layout:**
- SingleChildScrollView
- Padding EdgeInsets.all(16.0)
- Column

**AppBar:**
- title: 'Gestión de Usuarios'
- actions: IconButton add, IconButton refresh, IconButton settings

**Body:**
- Si _isLoading: Center con CircularProgressIndicator
- Si no: Column con lista de usuarios o GridView

**Tarjetas de usuario:**
- Card con margin EdgeInsets.only(bottom: 12)
- ListTile o custom layout:
  - leading: CircleAvatar o Icon
  - title: Text nombreUsuario
  - subtitle: Text roles y estado
  - trailing: Row con Switch para activo/desactivo y botones de acción

**Formulario de creación:**
- AlertDialog o BottomSheet
- Form con:
  - TextFormField nombreUsuario
  - TextFormField contraseña (obscureText true)
  - TextFormField confirmar contraseña
  - CheckboxListTile para cada rol
  - Botones: TextButton 'Cancelar', ElevatedButton 'Crear'

**Switch de activo:**
- activeColor: successGreen
- inactiveColor: grey400

---

## WIDGET: ANIMATED CARD

### Archivo: lib/widgets/animated_card.dart
### Widget raíz: AnimatedBuilder

**Propiedades:**
- padding: EdgeInsetsGeometry (default EdgeInsets.zero)
- color: Color (opcional, default cardColor del tema)
- elevation: double (default 2)
- borderRadius: BorderRadius (default BorderRadius.circular(16))
- animationDuration: Duration (default 200ms)
- enableHover: bool (default true)

**Layout:**
- Transform.scale con animación de escala (1.0 a 0.98)
- Card:
  - elevation: animado de 2.0 a 6.0
  - color: color personalizado o cardColor del tema
  - shadowColor: shadowColor del tema con opacity 0.1
  - shape: RoundedRectangleBorder con borderRadius personalizado o 16
  - child: Material transparent con Padding y GestureDetector

**Animaciones:**
- Scale animation: Tween 1.0 a 0.98, curve easeInOut
- Elevation animation: Tween elevation a elevation + 4.0, curve easeInOut
- Controller duration: 200ms por defecto

**Estados:**
- _isPressed: bool para controlar animación
- onTapDown: activa animación forward
- onTapUp/onTapCancel: activa animación reverse

---

## WIDGET: MODERN BUTTON

### Archivo: lib/widgets/modern_button.dart
### Widget raíz: ElevatedButton o AnimatedBuilder

**Propiedades:**
- text: String (requerido)
- icon: IconData (opcional)
- backgroundColor: Color (opcional, default primary)
- foregroundColor: Color (opcional, default onPrimary)
- padding: EdgeInsetsGeometry (opcional, default horizontal 24 vertical 12)
- borderRadius: double (opcional, default 12)
- elevation: double (opcional, default 2.0)
- isLoading: bool (default false)
- enableAnimation: bool (default true)
- animationDuration: Duration (opcional, default AppTheme.fastAnimation)

**Layout:**
- ElevatedButton con style personalizado
- Si isLoading: CircularProgressIndicator (height 20, width 20, strokeWidth 2)
- Si no: Row con Icon (size 18) y Text
- Si enableAnimation: AnimatedBuilder con Transform.scale (1.0 a 0.95)

**Estilos:**
- backgroundColor: backgroundColor personalizado o primary
- foregroundColor: foregroundColor personalizado o onPrimary
- elevation: elevation personalizado o 2.0
- shadowColor: backgroundColor con opacity 0.3
- padding: padding personalizado o EdgeInsets.symmetric(horizontal: 24, vertical: 12)
- borderRadius: borderRadius personalizado o 12
- textStyle: fontSize 16, fontWeight w600

**Estados:**
- Disabled: backgroundColor y foregroundColor = disabledColor
- Loading: muestra CircularProgressIndicator
- Pressed: animación de escala a 0.95

**Animación:**
- Scale animation: Tween 1.0 a 0.95, curve AppTheme.easeInOutCurve
- Controller duration: AppTheme.fastAnimation (200ms)

---

## WIDGET: CLOCK WIDGET

### Archivo: lib/widgets/clock_widget.dart
### Widget raíz: Card

**Propiedades:**
- showDate: bool (default true)
- timeStyle: TextStyle (opcional)
- dateStyle: TextStyle (opcional)

**Layout:**
- Card con elevation 2
- Padding EdgeInsets.all(16.0)
- Column con mainAxisSize MainAxisSize.min, crossAxisAlignment CrossAxisAlignment.center:
  - Row con mainAxisAlignment MainAxisAlignment.center:
    - Icon Icons.access_time, color primary, size 24
    - SizedBox width 8
    - Text hora: timeStyle o headlineMedium, fontWeight bold, color primary
  - Si showDate:
    - SizedBox height 8
    - Text fecha: dateStyle o bodyMedium, color onSurface con opacity 0.7, textAlign center

**Formato:**
- Hora: 'HH:mm:ss'
- Fecha: 'EEEE, d \'de\' MMMM \'de\' yyyy' (español)

**Actualización:**
- Timer periódico cada 1 segundo

---

## WIDGET: CALENDAR WIDGET

### Archivo: lib/widgets/calendar_widget.dart
### Widget raíz: Card

**Propiedades:**
- onDaySelected: Function(DateTime)? (opcional)
- selectedDay: DateTime? (opcional)
- focusedDay: DateTime? (opcional)

**Layout:**
- Card con elevation 2
- Padding EdgeInsets.all(12.0)
- Column con mainAxisSize MainAxisSize.min:
  - Row con mainAxisAlignment MainAxisAlignment.spaceBetween:
    - Row con Icon Icons.calendar_today (color primary, size 20) y Text 'Calendario' (titleMedium, fontWeight bold)
    - Row con IconButton chevron_left, Text mes/año, IconButton chevron_right
  - SizedBox height 8
  - TableCalendar
  - SizedBox height 8
  - Row con Text 'Hoy: [fecha]' (bodySmall, color onSurface con opacity 0.6, fontStyle italic)

**TableCalendar:**
- firstDay: DateTime.utc(2020, 1, 1)
- lastDay: DateTime.utc(2030, 12, 31)
- startingDayOfWeek: Monday
- locale: 'es_ES'
- headerVisible: false
- calendarFormat: CalendarFormat.month
- calendarStyle:
  - outsideDaysVisible: false
  - weekendTextStyle: color primary
  - selectedDecoration: BoxDecoration color primary, shape circle
  - todayDecoration: BoxDecoration color primary con opacity 0.3, shape circle
  - markerDecoration: BoxDecoration color secondary, shape circle
- daysOfWeekStyle:
  - weekdayStyle: fontWeight w600, color onSurface con opacity 0.7
  - weekendStyle: fontWeight w600, color primary

---

## WIDGET: QUICK STATS WIDGET

### Archivo: lib/widgets/quick_stats_widget.dart
### Widget raíz: Card

**Layout:**
- Card con elevation 2
- Padding EdgeInsets.all(16.0)
- Column con crossAxisAlignment CrossAxisAlignment.start, mainAxisSize MainAxisSize.min:
  - Row:
    - Icon Icons.analytics_outlined, color primary, size 24
    - SizedBox width 8
    - Expanded Column:
      - Text 'Estadísticas Rápidas': titleMedium, fontWeight bold
      - Si hay userName: Text userName o 'Administrador' (bodySmall, color onSurface con opacity 0.6, fontStyle italic)
  - SizedBox height 16
  - Si isLoading: Center con CircularProgressIndicator (padding 16)
  - Si no: Column con _buildStatRow para cada estadística

**Stat Row:**
- Row:
  - Container:
    - padding: EdgeInsets.all(8)
    - decoration: BoxDecoration con color con opacity 0.1, borderRadius 8
    - child: Icon con color específico, size 20
  - SizedBox width 12
  - Expanded Text label: bodyMedium
  - Text value: titleLarge, fontWeight bold, color específico

**Colores de estadísticas:**
- Pendientes: Colors.orange
- Completados: Colors.green
- Total: primary

---

## PANTALLA DE TRACKING 3GUERRAS

### Archivo: lib/screens/shipments/tresguerras_tracking_screen.dart
### Widget raíz: Scaffold

**Layout:**
- Stack para overlay de loading
- WebViewWidget o mensaje de escritorio

**AppBar:**
- title: 'Rastreo 3guerras'
- backgroundColor: Color(0xFF003366)
- foregroundColor: Colors.white
- actions: IconButton refresh

**Body móvil:**
- WebViewWidget con controller
- Si _isLoading: Center con CircularProgressIndicator

**Body escritorio:**
- Center con Padding EdgeInsets.all(24.0)
- Column:
  - Icon Icons.info_outline, size 64, color Colors.orange
  - SizedBox height 16
  - Text 'WebView no disponible en escritorio': fontSize 18, fontWeight bold
  - SizedBox height 8
  - Text número de guía: fontSize 16, fontWeight w500
  - SizedBox height 24
  - ElevatedButton.icon 'Abrir en navegador': backgroundColor primary, foregroundColor white

**WebView:**
- JavaScriptMode: unrestricted
- NavigationDelegate con callbacks onPageStarted, onPageFinished, onWebResourceError
- JavaScriptChannel 'FlutterChannel' para comunicación

---

## ESTADOS VISUALES GENERALES

**Hover:**
- AnimatedCard: enableHover controla animación (default true)
- ModernButton: no tiene hover específico (solo tap)

**Focus:**
- TextFormField: focusedBorder con primaryBlue width 2
- InputDecoration: focusedErrorBorder con errorRed width 2

**Disabled:**
- ElevatedButton: backgroundColor y foregroundColor = disabledColor
- TextButton: color = disabledColor cuando está deshabilitado
- ModernButton: backgroundColor y foregroundColor = disabledColor

**Error:**
- TextFormField: errorBorder y focusedErrorBorder con errorRed
- SnackBar: backgroundColor Colors.red o Colors.orange según tipo
- Mensajes de error: color errorRed

**Loading:**
- CircularProgressIndicator: strokeWidth 2 o 2.5, color según contexto
- ModernButton: muestra CircularProgressIndicator cuando isLoading = true
- Pantallas: Center con CircularProgressIndicator cuando _isLoading = true

---

## ELEVACIONES Y SOMBRAS

**Cards:**
- Default: elevation 2, shadowColor Colors.black26
- AnimatedCard: elevation animado de 2.0 a 6.0
- Stat Cards: elevation 3

**Buttons:**
- ElevatedButton: elevation 2, shadowColor primaryBlue
- ModernButton: elevation 2.0 (configurable), shadowColor backgroundColor con opacity 0.3
- FAB: elevation 3

**AppBar:**
- elevation 1, shadowColor Colors.black12
- Settings: elevation 0

---

## BORDER RADIUS

**Cards:**
- Default: BorderRadius.circular(16)
- AnimatedCard: BorderRadius.circular(16) (configurable)
- Stat Cards: BorderRadius.circular(8)

**Buttons:**
- ElevatedButton: BorderRadius.circular(12)
- ModernButton: BorderRadius.circular(12) (configurable)
- FAB: BorderRadius.circular(16)

**Inputs:**
- TextFormField: BorderRadius.circular(12)

**Chips:**
- Filtros de año: BorderRadius.circular(20)
- Estado: BorderRadius.circular(12)

**Containers:**
- Icon containers: BorderRadius.circular(8)
- Option cards: BorderRadius.circular(12)

---

## PADDING Y MARGIN

**Pantallas:**
- Login: EdgeInsets.symmetric(horizontal: 24, vertical: 16)
- Welcome/Admin: EdgeInsets.all(20) o EdgeInsets.all(16.0)
- Settings: EdgeInsets.all(16.0)
- Shipments: EdgeInsets.all(16.0)
- Bitácora: EdgeInsets.all(16) móvil, EdgeInsets.all(24) desktop

**Cards:**
- Default: EdgeInsets.all(16.0)
- AnimatedCard: EdgeInsets.all(20) en option cards
- Clock/Calendar/Stats: EdgeInsets.all(16.0) o EdgeInsets.all(12.0)

**Buttons:**
- ElevatedButton: EdgeInsets.symmetric(horizontal: 24, vertical: 12)
- ModernButton: EdgeInsets.symmetric(horizontal: 24, vertical: 12) (configurable)
- TextButton: EdgeInsets.symmetric(horizontal: 16, vertical: 8)

**Inputs:**
- TextFormField: EdgeInsets.symmetric(horizontal: 16, vertical: 12)

**ListTile:**
- minVerticalPadding: 16

**Spacing:**
- SizedBox height común: 8, 12, 16, 20, 24
- SizedBox width común: 8, 12

---

## RESUMEN DE COLORES PRINCIPALES

**Primarios:**
- Primary Blue: #003366
- Secondary Blue: #0066CC
- Accent Blue: #4A90E2
- Light Blue: #E6F3FF

**Estados:**
- Success Green: #28A745
- Warning Orange: #FF9800
- Error Red: #DC3545
- Info Blue: #17A2B8

**Grises:**
- grey100: #F8F9FA
- grey200: #E9ECEF
- grey300: #DEE2E6
- grey400: #CED4DA
- grey500: #ADB5BD
- grey600: #6C757D
- grey700: #495057
- grey800: #343A40
- grey900: #212529

**Específicos:**
- DHL: Colors.yellow[700]
- 3guerras: Colors.orange[700]
- Pendiente: Colors.orange
- Terminado: Colors.green

---

## RESUMEN DE TIPOGRAFÍA

**Títulos grandes:**
- displayLarge: 32px, bold
- displayMedium: 28px, bold
- displaySmall: 24px, w600

**Títulos:**
- headlineLarge: 22px, w600
- headlineMedium: 20px, w600
- headlineSmall: 18px, w600
- titleLarge: 18px, w600
- titleMedium: 16px, w500
- titleSmall: 14px, w500

**Cuerpo:**
- bodyLarge: 16px, normal
- bodyMedium: 14px, normal
- bodySmall: 12px, normal

**Etiquetas:**
- labelLarge: 14px, w500
- labelMedium: 12px, w500
- labelSmall: 11px, w500

**Colores de texto:**
- Principal: grey800 (#343A40)
- Secundario: grey700 (#495057)
- Terciario: grey600 (#6C757D)
- Con opacidad: onSurface con opacity 0.7, 0.6, etc.

---

## ANIMACIONES

**Duración:**
- Fast: 200ms (AppTheme.fastAnimation)
- Medium: 300ms (AppTheme.mediumAnimation)
- Slow: 500ms (AppTheme.slowAnimation)

**Curvas:**
- easeInOut: AppTheme.easeInOutCurve
- elasticOut: AppTheme.elasticCurve
- bounceOut: AppTheme.bounceCurve

**Tipos:**
- Scale: Transform.scale (AnimatedCard, ModernButton)
- Elevation: animación de elevación (AnimatedCard)
- Fade: no usado explícitamente
- Slide: no usado explícitamente

---

## RESPONSIVE DESIGN

**Breakpoints:**
- Móvil: maxWidth < 600
- Tablet: 600 <= maxWidth < 900
- Desktop: maxWidth >= 900

**Adaptaciones:**
- GridView: crossAxisCount 1 móvil, 2 tablet, 3 desktop
- Layout: Column móvil, Row desktop
- Padding: menor en móvil, mayor en desktop
- childAspectRatio: ajustado según tamaño de pantalla

**LayoutBuilder:**
- Usado en WelcomePage, AdminDashboard, ShipmentsScreen, BitacoraScreen
- Detecta isWideScreen o isMobile para cambiar layout

---

Este inventario describe la UI actual del proyecto sin sugerir mejoras ni cambios.








