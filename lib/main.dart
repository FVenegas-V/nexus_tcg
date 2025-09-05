import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/http_service.dart';
import 'core/services/comments_service.dart';
import 'core/services/navigation_service.dart'; // 🚀 NAVIGATION SERVICE
import 'core/services/fcm_service.dart'; // 🔔 FCM SERVICE
import 'core/providers/tab_navigation_provider.dart';
import 'core/providers/notification_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/communities/providers/communities_provider_new.dart';
import 'features/posts/providers/posts_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/posts/providers/comments_provider.dart';
import 'features/reputation/providers/reputation_provider.dart';
import 'features/reputation/providers/ratings_provider.dart';
import 'features/reputation/services/ratings_service.dart';
import 'routes/app_router.dart';

/// Punto de entrada de la aplicación Nexus TCG
void main() async {
  // Asegurar que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar para producción - filtrar mensajes de debug molesto
  FlutterError.onError = (FlutterErrorDetails details) {
    // Filtrar errores de RenderFlex overflow que aparecen como líneas rojas
    final String error = details.exception.toString();
    if (error.contains('RenderFlex overflow') ||
        error.contains('overflowed by') ||
        error.contains('pixels on the')) {
      // Silenciar estos errores específicos en producción
      return;
    }

    // Mostrar otros errores importantes
    if (!details.silent) {
      FlutterError.presentError(details);
    }
  };

  // Inicializar servicios core
  await _initializeServices();

  runApp(const MyApp());
}

/// Inicializar servicios necesarios antes de arrancar la app
Future<void> _initializeServices() async {
  // Inicializar HttpService para APIs
  HttpService().initialize();

  // Inicializar RatingsService para el sistema de valoraciones
  RatingsService.instance.initialize();

  // 🚀 NavigationService ya está configurado globalmente

  // 🔔 Inicializar FCM para notificaciones push
  try {
    await FCMService.initialize();
    debugPrint('🔔 FCM inicializado correctamente');
  } catch (e) {
    debugPrint('❌ Error inicializando FCM: $e');
  }
}

/// Función helper para inicializar notificaciones de manera asíncrona
void _initializeNotificationsAsync(
  NotificationProvider notificationProvider,
) async {
  try {
    final token = await AuthService.getAccessToken();
    if (token != null) {
      debugPrint('🔔 Token disponible, iniciando notificaciones');
      notificationProvider.initialize(token);
    } else {
      debugPrint('❌ No hay token disponible para notificaciones');
    }
  } catch (e) {
    debugPrint('❌ Error obteniendo token para notificaciones: $e');
  }
}

/// Widget raíz de la aplicación
/// Configura los providers, tema y navegación
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Configuración de providers para gestión de estado
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CommunitiesProvider()),
        ChangeNotifierProvider(create: (_) => PostsProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (_) => CommentsProvider(CommentsService(HttpService())),
        ),
        ChangeNotifierProvider(create: (_) => ReputationProvider()),
        ChangeNotifierProvider(create: (_) => RatingsProvider()),
        ChangeNotifierProvider(create: (_) => TabNavigationProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (context, authProvider, notificationProvider) {
            if (notificationProvider != null) {
              // Inicializar notificaciones cuando el usuario se autentica
              if (authProvider.isAuthenticated) {
                debugPrint(
                  '🔔 Usuario autenticado, preparando notificaciones...',
                );
                // Usar un Future para obtener el token de manera asíncrona
                _initializeNotificationsAsync(notificationProvider);
              } else if (!authProvider.isAuthenticated) {
                // Cerrar notificaciones cuando el usuario hace logout
                debugPrint('🔔 Cerrando NotificationProvider...');
                notificationProvider.shutdown();
              }
            }
            return notificationProvider ?? NotificationProvider();
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'Nexus TCG',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
        // Builder personalizado para manejar errores de UI
        builder: (context, child) {
          // Configurar manejo de errores RenderFlex
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child!,
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // Este widget es la página principal de tu aplicación. Es stateful, lo que significa
  // que tiene un objeto State (definido abajo) que contiene campos que afectan
  // cómo se ve.

  // Esta clase es la configuración para el estado. Mantiene los valores (en este
  // caso el título) proporcionados por el padre (en este caso el widget App) y
  // usados por el método build del State. Los campos en una subclase Widget siempre
  // están marcados como "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // Esta llamada a setState le dice al framework de Flutter que algo ha
      // cambiado en este State, lo que hace que vuelva a ejecutar el método build abajo
      // para que la pantalla pueda reflejar los valores actualizados. Si cambiáramos
      // _counter sin llamar setState(), entonces el método build no sería
      // llamado de nuevo, y por lo tanto nada parecería suceder.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Este método se vuelve a ejecutar cada vez que se llama setState, por ejemplo como hace
    // el método _incrementCounter de arriba.
    //
    // El framework de Flutter ha sido optimizado para hacer que volver a ejecutar métodos build
    // sea rápido, para que puedas simplemente reconstruir cualquier cosa que necesite actualizarse en lugar
    // de tener que cambiar individualmente instancias de widgets.
    return Scaffold(
      appBar: AppBar(
        // PRUEBA ESTO: Intenta cambiar el color aquí a un color específico (a
        // Colors.amber, tal vez?) y activa un hot reload para ver el AppBar
        // cambiar de color mientras los otros colores permanecen iguales.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Aquí tomamos el valor del objeto MyHomePage que fue creado por
        // el método App.build, y lo usamos para establecer el título de nuestro appbar.
        title: Text(widget.title),
      ),
      body: Center(
        // Center es un widget de layout. Toma un solo hijo y lo posiciona
        // en el medio del padre.
        child: Column(
          // Column también es un widget de layout. Toma una lista de hijos y
          // los organiza verticalmente. Por defecto, se dimensiona para ajustarse a sus
          // hijos horizontalmente, e intenta ser tan alto como su padre.
          //
          // Column tiene varias propiedades para controlar cómo se dimensiona y
          // cómo posiciona sus hijos. Aquí usamos mainAxisAlignment para
          // centrar los hijos verticalmente; el eje principal aquí es el eje vertical
          // porque las Columns son verticales (el eje cruzado sería
          // horizontal).
          //
          // PRUEBA ESTO: Invoca "debug painting" (elige la acción "Toggle Debug Paint"
          // en el IDE, o presiona "p" en la consola), para ver el
          // wireframe de cada widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Has presionado el botón esta cantidad de veces:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "main_counter_fab",
        onPressed: _incrementCounter,
        tooltip: 'Incrementar',
        child: const Icon(Icons.add),
      ), // Esta coma final hace que el auto-formateo sea más agradable para los métodos build.
    );
  }
}
