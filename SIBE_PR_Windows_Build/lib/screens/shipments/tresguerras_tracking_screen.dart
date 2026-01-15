import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

/// Pantalla WebView para rastrear envíos de 3guerras
/// Inyecta JavaScript para llenar automáticamente el formulario y ejecutar la búsqueda
class TresguerrasTrackingScreen extends StatefulWidget {
  final String trackingNumber;

  const TresguerrasTrackingScreen({
    super.key,
    required this.trackingNumber,
  });

  @override
  State<TresguerrasTrackingScreen> createState() =>
      _TresguerrasTrackingScreenState();
}

class _TresguerrasTrackingScreenState
    extends State<TresguerrasTrackingScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasInjectedScript = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          debugPrint('📱 Mensaje del WebView: ${message.message}');
          // Mostrar mensajes importantes al usuario
          if (message.message.contains('✅') || message.message.contains('Error')) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message.message),
                  duration: const Duration(seconds: 2),
                  backgroundColor: message.message.contains('✅') ? Colors.green : Colors.red,
                ),
              );
            }
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasInjectedScript = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Inyectar script después de que la página cargue
            if (!_hasInjectedScript) {
              _injectTrackingScript();
              _hasInjectedScript = true;
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Error cargando página: ${error.description}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al cargar la página: ${error.description}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://www.tresguerras.com.mx/3G/tracking.php?guia=${widget.trackingNumber}'),
      );
  }

  /// Inyecta JavaScript para llenar el campo de tracking y ejecutar la búsqueda
  Future<void> _injectTrackingScript() async {
    final trackingNumber = widget.trackingNumber;
    
    // Script mejorado que busca el campo de input y el botón de búsqueda
    // Con múltiples estrategias y verificaciones
    final script = '''
      (function() {
        var trackingNumber = '$trackingNumber';
        var attempts = 0;
        var maxAttempts = 5;
        
        function tryFillInput() {
          attempts++;
          console.log('Intento ' + attempts + ' de llenar el campo');
          
          // Estrategia 1: Buscar todos los inputs y encontrar el campo de texto principal
          var allInputs = document.querySelectorAll('input[type="text"], input:not([type="hidden"]):not([type="submit"]):not([type="button"])');
          var input = null;
          
          // Priorizar inputs que parecen ser el campo de tracking
          for (var i = 0; i < allInputs.length; i++) {
            var inp = allInputs[i];
            var name = (inp.name || '').toLowerCase();
            var id = (inp.id || '').toLowerCase();
            var placeholder = (inp.placeholder || '').toLowerCase();
            
            if (name.includes('guia') || name.includes('tracking') || name.includes('talon') ||
                id.includes('guia') || id.includes('tracking') || id.includes('talon') ||
                placeholder.includes('guia') || placeholder.includes('talon')) {
              input = inp;
              break;
            }
          }
          
          // Si no encontramos uno específico, usar el primer input de texto visible
          if (!input && allInputs.length > 0) {
            for (var i = 0; i < allInputs.length; i++) {
              var inp = allInputs[i];
              var style = window.getComputedStyle(inp);
              if (style.display !== 'none' && style.visibility !== 'hidden' && inp.offsetWidth > 0) {
                input = inp;
                break;
              }
            }
          }
          
          if (input) {
            console.log('Campo encontrado:', input);
            
            // Llenar el campo con múltiples métodos para asegurar que funcione
            input.focus();
            
            // Limpiar el campo primero
            input.value = '';
            
            // Método 1: Asignación directa
            input.value = trackingNumber;
            
            // Método 2: Usar setAttribute (algunos frameworks lo requieren)
            input.setAttribute('value', trackingNumber);
            
            // Disparar eventos de focus primero
            input.dispatchEvent(new Event('focus', { bubbles: true }));
            
            // Disparar eventos de input/change (los más importantes)
            var inputEvent = new Event('input', { bubbles: true, cancelable: true });
            input.dispatchEvent(inputEvent);
            
            var changeEvent = new Event('change', { bubbles: true, cancelable: true });
            input.dispatchEvent(changeEvent);
            
            // También disparar keyup (algunos formularios lo escuchan)
            var keyupEvent = new KeyboardEvent('keyup', { 
              key: 'Enter', 
              bubbles: true, 
              cancelable: true 
            });
            input.dispatchEvent(keyupEvent);
            
            // Forzar actualización del valor usando el setter nativo si está disponible
            try {
              var descriptor = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value');
              if (descriptor && descriptor.set) {
                descriptor.set.call(input, trackingNumber);
              }
            } catch (e) {
              console.log('No se pudo usar setter nativo:', e);
            }
            
            // Verificar que el valor se insertó
            if (input.value === trackingNumber || input.value.includes(trackingNumber)) {
              console.log('✅ Valor insertado correctamente:', input.value);
              try {
                FlutterChannel.postMessage('✅ Valor insertado: ' + input.value);
              } catch (e) {
                console.log('No se pudo enviar mensaje al canal:', e);
              }
              
              // Buscar el botón de búsqueda
              var button = null;
              
              // Buscar por texto en todos los botones y enlaces
              var allButtons = document.querySelectorAll('button, a, input[type="submit"], input[type="button"]');
              for (var i = 0; i < allButtons.length; i++) {
                var btn = allButtons[i];
                var text = (btn.textContent || btn.innerText || btn.value || '').toUpperCase();
                if (text.includes('RASTREAR') || text.includes('>>') || 
                    (text.includes('RASTRE') && text.length < 20)) {
                  button = btn;
                  console.log('Botón encontrado:', button);
                  break;
                }
              }
              
              // Si no encontramos el botón, buscar el formulario y hacer submit
              if (!button) {
                var form = input.closest('form');
                if (form) {
                  console.log('Formulario encontrado, haciendo submit');
                  setTimeout(function() {
                    form.submit();
                  }, 300);
                  return;
                }
              }
              
              // Hacer clic en el botón después de un pequeño delay
              if (button) {
                setTimeout(function() {
                  console.log('Haciendo clic en el botón');
                  button.click();
                }, 500);
              }
            } else {
              console.log('❌ El valor no se insertó correctamente. Valor actual:', input.value);
              try {
                FlutterChannel.postMessage('❌ Error: Valor no insertado. Actual: ' + input.value);
              } catch (e) {
                console.log('No se pudo enviar mensaje al canal:', e);
              }
              if (attempts < maxAttempts) {
                setTimeout(tryFillInput, 1000);
              }
            }
          } else {
            console.log('❌ No se encontró el campo de input. Intentos:', attempts);
            try {
              FlutterChannel.postMessage('❌ Error: Campo de input no encontrado');
            } catch (e) {
              console.log('No se pudo enviar mensaje al canal:', e);
            }
            if (attempts < maxAttempts) {
              setTimeout(tryFillInput, 1500);
            }
          }
        }
        
        // Intentar inmediatamente
        tryFillInput();
        
        // También intentar después de que la página cargue completamente
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', function() {
            setTimeout(tryFillInput, 500);
          });
        } else {
          setTimeout(tryFillInput, 500);
        }
        
        // Último intento después de un delay más largo
        setTimeout(tryFillInput, 2000);
      })();
    ''';

    try {
      await _controller.runJavaScript(script);
      debugPrint('✅ Script inyectado para número de guía: $trackingNumber');
      
      // Hacer un segundo intento después de 2 segundos por si acaso
      Future.delayed(const Duration(seconds: 2), () async {
        if (mounted) {
          try {
            await _controller.runJavaScript(script);
            debugPrint('✅ Script re-inyectado (segundo intento)');
          } catch (e) {
            debugPrint('⚠️ Error en segundo intento: $e');
          }
        }
      });
    } catch (e) {
      debugPrint('❌ Error inyectando script: $e');
      // Si falla, intentar de nuevo después de un delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_hasInjectedScript) {
          _injectTrackingScript();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // En escritorio, WebView no está disponible, mostrar mensaje
    if (!Platform.isAndroid && !Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rastreo 3guerras'),
          backgroundColor: const Color(0xFF003366),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'WebView no disponible en escritorio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Número de guía: ${widget.trackingNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Abrir en navegador externo
                    final url = Uri.parse(
                      'https://www.tresguerras.com.mx/3G/tracking.php?guia=${widget.trackingNumber}',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Abrir en navegador'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003366),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rastreo 3guerras'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _hasInjectedScript = false;
              _controller.reload();
            },
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

