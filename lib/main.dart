import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/communities/providers/communities_provider.dart';
import 'features/posts/providers/posts_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'routes/app_router.dart';

/// Punto de entrada de la aplicación Nexus TCG
void main() {
  runApp(const MyApp());
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
      ],
      child: MaterialApp.router(
        title: 'Nexus TCG',
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
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
        onPressed: _incrementCounter,
        tooltip: 'Incrementar',
        child: const Icon(Icons.add),
      ), // Esta coma final hace que el auto-formateo sea más agradable para los métodos build.
    );
  }
}
