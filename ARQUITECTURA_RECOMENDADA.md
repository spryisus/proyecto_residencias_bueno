lib/
├── app/
│   ├── config/           # Configuraciones globales
│   ├── theme/            # Temas y estilos
│   └── routes/           # Rutas de navegación
├── core/
│   ├── constants/        # Constantes globales
│   ├── errors/          # Manejo de errores
│   ├── network/         # Configuración de red
│   └── utils/           # Utilidades generales
├── data/
│   ├── datasources/     # Fuentes de datos (Supabase, APIs)
│   ├── models/          # Modelos de datos
│   ├── repositories/    # Implementación de repositorios
│   └── services/        # Servicios externos
├── domain/
│   ├── entities/        # Entidades de negocio
│   ├── repositories/    # Interfaces de repositorios
│   └── usecases/        # Casos de uso (lógica de negocio)
├── presentation/
│   ├── pages/           # Pantallas
│   ├── widgets/         # Widgets reutilizables
│   └── controllers/     # Controladores (Provider, Bloc, etc.)
└── main.dart
