/// Enum que representa los estados posibles de un envío
enum EstadoEnvio {
  enviado,
  enTransito,
  recibido;

  /// Convierte el enum a string para almacenar en la base de datos
  String toDbString() {
    switch (this) {
      case EstadoEnvio.enviado:
        return 'ENVIADO';
      case EstadoEnvio.enTransito:
        return 'EN_TRANSITO';
      case EstadoEnvio.recibido:
        return 'RECIBIDO';
    }
  }

  /// Crea un enum desde un string de la base de datos
  static EstadoEnvio fromDbString(String? estado) {
    if (estado == null || estado.isEmpty) {
      return EstadoEnvio.recibido; // Por defecto
    }
    
    switch (estado.toUpperCase()) {
      case 'ENVIADO':
        return EstadoEnvio.enviado;
      case 'EN_TRANSITO':
        return EstadoEnvio.enTransito;
      case 'RECIBIDO':
      case 'FINALIZADO': // Compatibilidad con registros antiguos
        return EstadoEnvio.recibido;
      default:
        return EstadoEnvio.recibido;
    }
  }

  /// Obtiene el nombre legible del estado
  String get nombre {
    switch (this) {
      case EstadoEnvio.enviado:
        return 'Enviado';
      case EstadoEnvio.enTransito:
        return 'En Tránsito';
      case EstadoEnvio.recibido:
        return 'Recibido';
    }
  }

  /// Obtiene el color asociado al estado
  int get colorValue {
    switch (this) {
      case EstadoEnvio.enviado:
        return 0xFF2196F3; // Azul
      case EstadoEnvio.enTransito:
        return 0xFFFFC107; // Amarillo
      case EstadoEnvio.recibido:
        return 0xFF4CAF50; // Verde
    }
  }

  /// Obtiene el icono asociado al estado
  String get icono {
    switch (this) {
      case EstadoEnvio.enviado:
        return 'send';
      case EstadoEnvio.enTransito:
        return 'local_shipping';
      case EstadoEnvio.recibido:
        return 'check_circle';
    }
  }

  /// Verifica si el estado es activo (no recibido)
  bool get esActivo => this != EstadoEnvio.recibido;
}

