const express = require('express');
const cors = require('cors');
const puppeteer = require('puppeteer-extra');
const StealthPlugin = require('puppeteer-extra-plugin-stealth');
require('dotenv').config();

// Usar el plugin stealth para evitar detección de bots
puppeteer.use(StealthPlugin());

const app = express();
const PORT = process.env.PORT || 3000;

// User-Agents realistas y estables (Chrome 122 es más estable y menos sospechoso)
const USER_AGENTS = [
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
];

// Función para obtener un User-Agent aleatorio
function getRandomUserAgent() {
  return USER_AGENTS[Math.floor(Math.random() * USER_AGENTS.length)];
}

// Función para delay aleatorio (simula comportamiento humano)
function randomDelay(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

// Sistema de cookies persistentes para mantener sesiones
const fs = require('fs');
const path = require('path');
const COOKIES_FILE = path.join(__dirname, '.dhl-cookies.json');

function loadCookies() {
  try {
    if (fs.existsSync(COOKIES_FILE)) {
      const data = fs.readFileSync(COOKIES_FILE, 'utf8');
      return JSON.parse(data);
    }
  } catch (e) {
    console.log('⚠️ No se pudieron cargar cookies guardadas');
  }
  return [];
}

function saveCookies(cookies) {
  try {
    fs.writeFileSync(COOKIES_FILE, JSON.stringify(cookies, null, 2));
  } catch (e) {
    console.log('⚠️ No se pudieron guardar cookies');
  }
}

// Sistema de rate limiting más agresivo
let lastRequestTime = 0;
const MIN_REQUEST_INTERVAL = 45000; // 45 segundos mínimo entre requests (aumentado para evitar detección)

function canMakeRequest() {
  const now = Date.now();
  const timeSinceLastRequest = now - lastRequestTime;
  
  if (timeSinceLastRequest < MIN_REQUEST_INTERVAL) {
    const waitTime = MIN_REQUEST_INTERVAL - timeSinceLastRequest;
    console.log(`⏳ Rate limiting: esperando ${Math.ceil(waitTime / 1000)} segundos...`);
    return false;
  }
  
  lastRequestTime = now;
  return true;
}

// Habilitar CORS para que Flutter pueda hacer peticiones
app.use(cors());
app.use(express.json());

// Variables globales para navegador y página precargada
let preloadedBrowser = null;
let preloadedPage = null;
let isPreloading = false;
let preloadPromise = null;
const PRELOAD_TRACKING_NUMBER = '9068591556'; // Número de guía para precarga

// Variable global para rastrear si Chrome ya se está descargando
let chromeDownloading = false;
let chromeDownloadPromise = null;

// Función para asegurar que Chrome esté disponible
// Función para buscar Chrome en diferentes ubicaciones
function findChromeExecutable() {
  const fs = require('fs');
  const path = require('path');
  
  // 1. Buscar Chrome descargado por @puppeteer/browsers (ubicación común)
  const chromeDir = path.join(process.cwd(), 'chrome');
  if (fs.existsSync(chromeDir)) {
    try {
      const dirs = fs.readdirSync(chromeDir);
      for (const dir of dirs) {
        if (dir.startsWith('linux-')) {
          const chromePath = path.join(chromeDir, dir, 'chrome-linux64', 'chrome');
          if (fs.existsSync(chromePath)) {
            return chromePath;
          }
        }
      }
    } catch (e) {
      // Continuar buscando
    }
  }
  
  // 2. Intentar la ruta por defecto de Puppeteer
  try {
    const defaultPath = puppeteer.executablePath();
    if (defaultPath && fs.existsSync(defaultPath)) {
      return defaultPath;
    }
  } catch (e) {
    // Continuar
  }
  
  // 3. Buscar en node_modules/puppeteer/.local-chromium
  try {
    const puppeteerChromiumDir = path.join(process.cwd(), 'node_modules', 'puppeteer', '.local-chromium');
    if (fs.existsSync(puppeteerChromiumDir)) {
      const dirs = fs.readdirSync(puppeteerChromiumDir);
      for (const dir of dirs) {
        const chromePath = path.join(puppeteerChromiumDir, dir, 'chrome-linux', 'chrome');
        if (fs.existsSync(chromePath)) {
          return chromePath;
        }
      }
    }
  } catch (e) {
    // Continuar
  }
  
  return null;
}

async function ensureChrome() {
  // Si ya está descargando, esperar a que termine
  if (chromeDownloading && chromeDownloadPromise) {
    return await chromeDownloadPromise;
  }
  
  // Primero buscar si Chrome ya está disponible
  const existingChrome = findChromeExecutable();
  if (existingChrome) {
    return existingChrome;
  }
  
  // Marcar que estamos descargando
  chromeDownloading = true;
  
  // Crear promesa para descargar Chrome
  chromeDownloadPromise = (async () => {
    try {
      console.log('⚠️ Chrome no está disponible. Descargando Chrome...');
      console.log('⏱️  Esto puede tardar 2-3 minutos la primera vez...');
      
      const { execSync } = require('child_process');
      execSync('npx -y @puppeteer/browsers install chrome@stable', {
        stdio: 'inherit',
        timeout: 180000, // 3 minutos
        env: process.env
      });
      
      console.log('✅ Chrome descargado correctamente');
      
      // Buscar el Chrome descargado
      const downloadedChrome = findChromeExecutable();
      chromeDownloading = false;
      return downloadedChrome || true;
    } catch (downloadError) {
      console.log('⚠️ No se pudo descargar Chrome automáticamente.');
      console.log('💡 Se intentará usar Chrome del sistema si está disponible.');
      chromeDownloading = false;
      return null;
    }
  })();
  
  return await chromeDownloadPromise;
}

/**
 * Ruta raíz - Información del servicio
 * GET /
 */
app.get('/', (req, res) => {
  res.json({
    service: 'DHL Tracking Proxy',
    status: 'running',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      track: '/api/track/:trackingNumber',
      warmup: '/warmup',
      keepalive: '/keepalive',
      example: '/api/track/6376423056'
    },
    documentation: 'Este servicio permite consultar el estado de envíos DHL usando web scraping.',
    optimization: {
      warmup: 'Llama a /warmup antes de hacer una consulta para precargar la página y acelerar la primera consulta',
      keepalive: 'Llama a /keepalive periódicamente (cada 10-12 minutos) para mantener el servicio activo en Render'
    }
  });
});

/**
 * Función auxiliar para realizar el scraping de DHL
 * @param {string} trackingNumber - Número de tracking
 * @param {number} attempt - Número de intento (para reintentos)
 * @returns {Promise<Object>} - Datos de tracking
 */
/**
 * Función para precargar el navegador y página de DHL
 */
async function preloadDHLPage() {
  if (isPreloading && preloadPromise) {
    return await preloadPromise;
  }
  
  if (preloadedBrowser && preloadedPage) {
    // Verificar que la página aún esté abierta
    try {
      await preloadedPage.evaluate(() => document.title);
      console.log('✅ Página precargada ya está lista');
      return { browser: preloadedBrowser, page: preloadedPage };
    } catch (e) {
      console.log('⚠️ Página precargada se cerró, recargando...');
      preloadedBrowser = null;
      preloadedPage = null;
    }
  }
  
  isPreloading = true;
  preloadPromise = (async () => {
    try {
      console.log('🔄 Precargando navegador y página de DHL...');
      
      const chromePath = await ensureChrome();
      
      const launchOptions = {
        headless: true,
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--single-process',
          '--disable-blink-features=AutomationControlled',
          '--disable-infobars',
          '--disable-features=IsolateOrigins,site-per-process',
          '--window-size=1280,800',
          '--disable-gpu',
          '--disable-accelerated-2d-canvas',
          '--disable-software-rasterizer',
          '--disable-extensions',
          '--no-first-run',
          '--no-default-browser-check',
          '--disable-default-apps',
          '--disable-popup-blocking',
          '--disable-translate',
          '--disable-background-timer-throttling',
          '--disable-backgrounding-occluded-windows',
          '--disable-renderer-backgrounding',
          '--disable-features=TranslateUI',
          '--disable-ipc-flooding-protection',
        ],
      };
      
      if (chromePath && typeof chromePath === 'string') {
        launchOptions.executablePath = chromePath;
      }
      
      const browser = await puppeteer.launch(launchOptions);
      const page = await browser.newPage();
      
      // Configurar stealth
      await page.evaluateOnNewDocument(() => {
        Object.defineProperty(navigator, 'webdriver', {
          get: () => undefined,
        });
        delete navigator.__proto__.webdriver;
        try { delete navigator.webdriver; } catch (e) {}
        Object.defineProperty(navigator, 'webdriver', {
          value: undefined,
          writable: false,
          configurable: true,
        });
      });
      
      const userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';
      await page.setUserAgent(userAgent);
      await page.setViewport({ width: 1280, height: 800, deviceScaleFactor: 1 });
      
      await page.setExtraHTTPHeaders({
        'accept-language': 'es-MX,es;q=0.9,en;q=0.8',
        'accept-encoding': 'gzip, deflate, br',
        'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'connection': 'keep-alive',
        'upgrade-insecure-requests': '1',
        'sec-fetch-dest': 'document',
        'sec-fetch-mode': 'navigate',
        'sec-fetch-site': 'none',
        'sec-fetch-user': '?1',
        'cache-control': 'max-age=0',
        'sec-ch-ua': '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'dnt': '1',
      });
      
      // Cargar cookies guardadas
      const savedCookies = loadCookies();
      if (savedCookies.length > 0) {
        try {
          await page.setCookie(...savedCookies);
        } catch (e) {}
      }
      
      // Visitar página principal para establecer sesión
      console.log('🏠 Precargando página principal de DHL...');
      await page.goto('https://www.dhl.com/mx-es/home.html', {
        waitUntil: 'domcontentloaded',
        timeout: 45000,
      });
      await page.waitForTimeout(randomDelay(2000, 4000));
      
      // Precargar página de tracking con número de ejemplo
      // Usar 'domcontentloaded' en lugar de 'networkidle2' para ser más rápido
      const preloadUrl = `https://www.dhl.com/mx-es/home/tracking/tracking.html?submit=1&tracking-id=${PRELOAD_TRACKING_NUMBER}`;
      console.log(`📡 Precargando página de tracking: ${PRELOAD_TRACKING_NUMBER}...`);
      await page.goto(preloadUrl, {
        waitUntil: 'domcontentloaded', // Más rápido que networkidle2
        timeout: 120000, // Reducido a 2 minutos
      });
      
      // Esperar menos tiempo para precarga (solo lo esencial)
      await page.waitForTimeout(randomDelay(3000, 5000)); // Reducido de 5-10s a 3-5s
      
      // Guardar cookies
      try {
        const cookies = await page.cookies();
        saveCookies(cookies);
      } catch (e) {}
      
      preloadedBrowser = browser;
      preloadedPage = page;
      isPreloading = false;
      
      console.log('✅ Navegador y página precargados exitosamente');
      return { browser, page };
    } catch (error) {
      console.error('❌ Error al precargar:', error.message);
      isPreloading = false;
      preloadPromise = null;
      throw error;
    }
  })();
  
  return await preloadPromise;
}

async function scrapeDHLTracking(trackingNumber, attempt = 1) {
  let browser = null;
  let page = null;
  let usePreloaded = false;
  
  try {
    console.log(`🔍 Consultando tracking: ${trackingNumber} (Intento ${attempt} de 3)`);
    
    // Rate limiting: esperar si es necesario
    if (!canMakeRequest() && attempt === 1) {
      const waitTime = MIN_REQUEST_INTERVAL;
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }
    
    // Intentar usar página precargada
    try {
      const preloaded = await preloadDHLPage();
      if (preloaded && preloaded.browser && preloaded.page) {
        browser = preloaded.browser;
        page = preloaded.page;
        usePreloaded = true;
        console.log('✅ Usando página precargada (más rápido)');
      }
    } catch (e) {
      console.log('⚠️ No se pudo usar página precargada, creando nueva sesión...');
    }
    
    // Si no hay página precargada, crear nueva
    if (!browser || !page) {
      // Asegurar que Chrome esté disponible y obtener su ruta
      const chromePath = await ensureChrome();
    
    // Configurar opciones de lanzamiento para Render - MODO STEALTH TOTAL
    const launchOptions = {
      headless: true, // Usar headless simple (más estable)
      args: [
        // Flags esenciales para Render
        '--no-sandbox',
        '--disable-setuid-sandbox',
        '--disable-dev-shm-usage',
        '--single-process', // Para entornos con poca memoria como Render
        // Flags CRÍTICOS para evitar detección de bots
        '--disable-blink-features=AutomationControlled', // Oculta que es automatizado
        '--disable-infobars', // Oculta la barra de "Chrome está siendo controlado"
        '--disable-features=IsolateOrigins,site-per-process',
        // Hacer que parezca más un navegador real (tamaño común de ventana)
        '--window-size=1280,800',
        // Flags adicionales para reducir detección
        '--disable-gpu',
        '--disable-accelerated-2d-canvas',
        '--disable-software-rasterizer',
        '--disable-extensions',
        '--no-first-run',
        '--no-default-browser-check',
        '--disable-default-apps',
        '--disable-popup-blocking',
        '--disable-translate',
        '--disable-background-timer-throttling',
        '--disable-backgrounding-occluded-windows',
        '--disable-renderer-backgrounding',
        '--disable-features=TranslateUI',
        '--disable-ipc-flooding-protection',
      ],
    };
    
    // Si encontramos Chrome, especificarlo explícitamente
    if (chromePath && typeof chromePath === 'string') {
      launchOptions.executablePath = chromePath;
      console.log(`📍 Usando Chrome en: ${chromePath}`);
    } else {
      // Intentar encontrar Chrome manualmente
      const foundChrome = findChromeExecutable();
      if (foundChrome) {
        launchOptions.executablePath = foundChrome;
        console.log(`📍 Chrome encontrado en: ${foundChrome}`);
      } else {
        console.log('⚠️ Chrome no encontrado en ubicaciones esperadas, Puppeteer intentará encontrarlo...');
      }
    }
    
    console.log('🚀 Iniciando Puppeteer...');
    browser = await puppeteer.launch(launchOptions);
    console.log('✅ Puppeteer iniciado correctamente');

    const page = await browser.newPage();
    
    // Cargar cookies guardadas para mantener sesión
    const savedCookies = loadCookies();
    if (savedCookies.length > 0) {
      try {
        await page.setCookie(...savedCookies);
        console.log(`🍪 Cargadas ${savedCookies.length} cookies guardadas`);
      } catch (e) {
        console.log('⚠️ No se pudieron cargar cookies guardadas');
      }
    }
    
    // Stealth plugin ya maneja la mayoría de anti-detección, pero agregamos refuerzos EXTRA
    await page.evaluateOnNewDocument(() => {
      // Eliminar webdriver completamente (MÚLTIPLES MÉTODOS para asegurar)
      Object.defineProperty(navigator, 'webdriver', {
        get: () => undefined,
      });
      
      // Eliminar del prototipo también
      delete navigator.__proto__.webdriver;
      
      // Intentar eliminar de todas las formas posibles
      try {
        delete navigator.webdriver;
      } catch (e) {}
      
      // Sobrescribir con undefined
      Object.defineProperty(navigator, 'webdriver', {
        value: undefined,
        writable: false,
        configurable: true,
      });
      
      // Sobrescribir plugins para parecer más real
      Object.defineProperty(navigator, 'plugins', {
        get: () => {
          return [
            { name: 'Chrome PDF Plugin', filename: 'internal-pdf-viewer', description: 'Portable Document Format' },
            { name: 'Chrome PDF Viewer', filename: 'mhjfbmdgcfjbbpaeojofohoefgiehjai', description: '' },
            { name: 'Native Client', filename: 'internal-nacl-plugin', description: '' },
          ];
        },
      });
      
      // Sobrescribir languages
      Object.defineProperty(navigator, 'languages', {
        get: () => ['es-MX', 'es', 'en-US', 'en'],
      });
      
      // Agregar chrome object completo y realista
      window.chrome = {
        runtime: {},
        loadTimes: function() {
          return {
            commitLoadTime: Date.now() - Math.random() * 1000,
            connectionInfo: 'http/1.1',
            finishDocumentLoadTime: Date.now() - Math.random() * 500,
            finishLoadTime: Date.now() - Math.random() * 200,
            firstPaintAfterLoadTime: 0,
            firstPaintTime: Date.now() - Math.random() * 1000,
            navigationType: 'Other',
            npnNegotiatedProtocol: 'unknown',
            requestTime: Date.now() - Math.random() * 2000,
            startLoadTime: Date.now() - Math.random() * 1500,
            wasAlternateProtocolAvailable: false,
            wasFetchedViaSpdy: false,
            wasNpnNegotiated: false,
          };
        },
        csi: function() {
          return {
            startE: Date.now() - Math.random() * 10000,
            onloadT: Date.now() - Math.random() * 5000,
            pageT: Math.random() * 1000,
            tran: 15,
          };
        },
        app: {
          isInstalled: false,
          InstallState: {
            DISABLED: 'disabled',
            INSTALLED: 'installed',
            NOT_INSTALLED: 'not_installed',
          },
          RunningState: {
            CANNOT_RUN: 'cannot_run',
            READY_TO_RUN: 'ready_to_run',
            RUNNING: 'running',
          },
        },
      };
      
      // Sobrescribir permissions
      const originalQuery = window.navigator.permissions.query;
      window.navigator.permissions.query = (parameters) => (
        parameters.name === 'notifications' ?
          Promise.resolve({ state: Notification.permission }) :
          originalQuery(parameters)
      );
    });
    
    // Configurar User-Agent estable (Chrome 122 - menos sospechoso que versiones muy nuevas)
    const userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';
    await page.setUserAgent(userAgent);
    
    // Configurar viewport realista (tamaño común de ventana)
    await page.setViewport({
      width: 1280,
      height: 800,
      deviceScaleFactor: 1,
    });
    
    // Configurar headers REALES y consistentes (DHL los revisa agresivamente)
    await page.setExtraHTTPHeaders({
      'accept-language': 'es-MX,es;q=0.9,en;q=0.8',
      'accept-encoding': 'gzip, deflate, br',
      'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
      'connection': 'keep-alive',
      'upgrade-insecure-requests': '1',
      'sec-fetch-dest': 'document',
      'sec-fetch-mode': 'navigate',
      'sec-fetch-site': 'none',
      'sec-fetch-user': '?1',
      'cache-control': 'max-age=0',
      'sec-ch-ua': '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
      'sec-ch-ua-mobile': '?0',
      'sec-ch-ua-platform': '"Windows"',
      'dnt': '1',
    });
    
      // Si no estamos usando página precargada, visitar página principal
      if (!usePreloaded) {
        // Primero visitar la página principal de DHL para establecer una sesión legítima
        // Esto hace que parezca más humano y reduce las posibilidades de bloqueo
        console.log('🏠 Visitando página principal de DHL para establecer sesión...');
        try {
          await page.goto('https://www.dhl.com/mx-es/home.html', {
            waitUntil: 'domcontentloaded', // Más rápido, menos sospechoso
            timeout: 45000, // Aumentado
          });
          
          // Simular comportamiento humano más realista con delays aleatorios MÁS LARGOS
          await page.waitForTimeout(randomDelay(5000, 10000)); // Aumentado a 5-10s
          
          // Movimientos de mouse más naturales
          const viewport = page.viewport();
          const centerX = viewport.width / 2;
          const centerY = viewport.height / 2;
          
          // Mover mouse de forma más natural (curva)
          await page.mouse.move(centerX - 100, centerY - 50, { steps: 10 });
          await page.waitForTimeout(randomDelay(500, 1000));
          await page.mouse.move(centerX, centerY, { steps: 10 });
          await page.waitForTimeout(randomDelay(500, 1000));
          
          // Scroll más natural (suave)
          await page.evaluate(() => {
            window.scrollTo({
              top: 300,
              behavior: 'smooth'
            });
          });
          await page.waitForTimeout(randomDelay(1000, 2000));
          
          // Scroll hacia arriba
          await page.evaluate(() => {
            window.scrollTo({
              top: 0,
              behavior: 'smooth'
            });
          });
          await page.waitForTimeout(randomDelay(800, 1500));
          
          console.log('✅ Sesión establecida correctamente');
        } catch (e) {
          console.log('⚠️ No se pudo visitar la página principal, continuando...');
        }

        // ESTRATEGIA MEJORADA: Navegar como un usuario real
        // En lugar de ir directo al tracking, simular que el usuario navega desde la página principal
        
        console.log('🔍 Buscando enlace de tracking en la página principal...');
        
        // Intentar encontrar y hacer clic en el enlace de tracking (más humano)
        try {
          // Buscar el campo de tracking o enlace
          const trackingLink = await page.evaluate(() => {
            // Buscar enlaces que contengan "tracking" o "rastrear"
            const links = Array.from(document.querySelectorAll('a'));
            return links.find(link => {
              const text = link.textContent.toLowerCase();
              const href = link.href.toLowerCase();
              return (text.includes('tracking') || text.includes('rastrear') || 
                      text.includes('rastreo') || href.includes('tracking'));
            });
          });
          
          if (trackingLink) {
            console.log('✅ Encontrado enlace de tracking, haciendo clic...');
            await page.click('a[href*="tracking"], a:has-text("Rastrear"), a:has-text("Tracking")');
            await page.waitForTimeout(randomDelay(2000, 4000));
          }
        } catch (e) {
          console.log('⚠️ No se encontró enlace, navegando directamente...');
        }
      }
    }
    
    // Visitar página de tracking de DHL
    const trackingUrl = `https://www.dhl.com/mx-es/home/tracking/tracking.html?submit=1&tracking-id=${trackingNumber}`;
    
    console.log(`📡 Navegando a: ${trackingUrl}`);
    
    // Si estamos usando página precargada, solo navegar a la nueva URL (más rápido)
    if (usePreloaded) {
      console.log('⚡ Usando página precargada - solo actualizando número de tracking...');
      // Usar domcontentloaded primero para ser más rápido, luego esperar contenido dinámico
      await page.goto(trackingUrl, {
        waitUntil: 'domcontentloaded', // Más rápido inicialmente
        timeout: 120000,
      });
      // Esperar un poco menos ya que la página ya está "caliente"
      await page.waitForTimeout(randomDelay(2000, 4000)); // Reducido de 10-15s
    } else {
      // Ir a la página con networkidle2 para asegurar que TODO cargue (más lento pero más seguro)
      console.log('⏳ Cargando página de DHL...');
      await page.goto(trackingUrl, {
        waitUntil: 'networkidle2', // Cambiar a networkidle2 para asegurar carga completa
        timeout: 180000, // Aumentado a 3 minutos para dar más tiempo
      });
    }
    
    // Simular que el usuario está leyendo la página (delay aleatorio MÁS LARGO)
    await page.waitForTimeout(randomDelay(10000, 15000)); // Aumentado a 10-15s
    
    // Simular interacción humana: mover mouse sobre la página (múltiples movimientos)
    for (let i = 0; i < 3; i++) {
      await page.mouse.move(randomDelay(100, 800), randomDelay(100, 600), { steps: 25 });
      await page.waitForTimeout(randomDelay(1500, 3000));
    }

    console.log('⏳ Esperando a que cargue el contenido dinámico...');
    // Esperar tiempo aleatorio MUCHO MÁS LARGO para que carguen los scripts dinámicos de DHL
    // Aumentado a 1 minuto 15 segundos (75 segundos) como solicitado
    await page.waitForTimeout(randomDelay(70000, 80000)); // 70-80 segundos (promedio 75s)
    
    // Verificar si hay CAPTCHA o bloqueo ANTES de hacer scroll
    const hasCaptcha = await page.evaluate(() => {
      const bodyText = document.body.innerText.toLowerCase();
      return bodyText.includes('captcha') || 
             bodyText.includes('verificación') ||
             bodyText.includes('verifica que no eres un robot') ||
             bodyText.includes('access denied') ||
             bodyText.includes('blocked');
    });
    
    if (hasCaptcha) {
      console.log('⚠️ CAPTCHA o bloqueo detectado en la página');
      await browser.close();
      const error = new Error('DHL ha detectado actividad automatizada. Por favor, usa la opción "Abrir en navegador" para verificar manualmente.');
      error.blocked = true;
      error.requiresManualVerification = true;
      throw error;
    }
    
    // Verificar si hay mensaje de error de DHL ANTES de continuar (más específico)
    const hasDHLError = await page.evaluate(() => {
      const bodyText = document.body.innerText.toLowerCase();
      const fullText = document.body.innerText;
      
      // Buscar el mensaje específico de error de DHL
      const errorPatterns = [
        /lo sentimos.*intento de rastreo.*no se realizó correctamente/i,
        /lo sentimos.*su intento de rastreo/i,
        /intento de rastreo.*no se realizó correctamente/i,
        /no se pudo procesar.*rastreo/i,
        /error.*rastreo/i,
      ];
      
      // Verificar patrones específicos
      const hasSpecificError = errorPatterns.some(pattern => pattern.test(fullText));
      
      // También verificar texto general
      const hasGeneralError = bodyText.includes('lo sentimos') && 
             (bodyText.includes('intento de rastreo') || 
              bodyText.includes('no se realizó correctamente') ||
              bodyText.includes('no se pudo procesar') ||
              bodyText.includes('error al consultar'));
      
      return hasSpecificError || hasGeneralError;
    });
    
    if (hasDHLError) {
      console.log('⚠️ DHL detectó el bot y mostró mensaje de error específico');
      await browser.close();
      const error = new Error('DHL ha detectado actividad automatizada y bloqueó la consulta. Por favor, espera unos minutos o usa la opción "Abrir en navegador".');
      error.blocked = true;
      error.requiresManualVerification = true;
      throw error;
    }
    
    // Esperar específicamente por elementos comunes de DHL
    console.log('🔍 Buscando elementos de tracking...');
    try {
      // Intentar esperar por varios selectores que DHL usa
      await Promise.race([
        page.waitForSelector('table', { timeout: 10000 }).catch(() => null),
        page.waitForSelector('[class*="timeline"]', { timeout: 10000 }).catch(() => null),
        page.waitForSelector('[class*="tracking"]', { timeout: 10000 }).catch(() => null),
        page.waitForSelector('[class*="shipment"]', { timeout: 10000 }).catch(() => null),
        page.waitForSelector('[id*="tracking"]', { timeout: 10000 }).catch(() => null),
        page.waitForSelector('[data-testid*="tracking"]', { timeout: 10000 }).catch(() => null),
        page.waitForSelector('div[class*="event"]', { timeout: 10000 }).catch(() => null),
      ]);
      console.log('✅ Encontrados elementos de tracking');
    } catch (e) {
      console.log('⚠️ No se encontraron selectores específicos, continuando de todas formas...');
    }
    
    // Intentar hacer scroll para activar lazy loading y cargar contenido dinámico (más natural y lento)
    console.log('📜 Haciendo scroll para cargar contenido...');
    
    // Simular lectura: scroll muy lento y pausas
    const scrollHeight = await page.evaluate(() => document.body.scrollHeight);
    const viewportHeight = await page.viewport().height;
    const scrollSteps = Math.ceil(scrollHeight / (viewportHeight / 2));
    
    for (let i = 0; i <= scrollSteps; i++) {
      const scrollPosition = Math.min(i * (viewportHeight / 2), scrollHeight);
      await page.evaluate((pos) => {
        window.scrollTo({
          top: pos,
          behavior: 'smooth'
        });
      }, scrollPosition);
      
      // Pausa aleatoria entre scrolls (simula lectura)
      await page.waitForTimeout(randomDelay(800, 1500));
      
      // Ocasionalmente mover el mouse (cada 3-4 scrolls)
      if (i % 3 === 0) {
        await page.mouse.move(
          randomDelay(100, 800), 
          randomDelay(100, 600), 
          { steps: 15 }
        );
      }
    }
    
    // Scroll hacia arriba lentamente
    await page.evaluate(() => {
      window.scrollTo({
        top: 0,
        behavior: 'smooth'
      });
    });
    await page.waitForTimeout(randomDelay(5000, 8000)); // Aumentado a 5-8s
    
    // Scroll hacia abajo de nuevo (simulando que busca algo)
    await page.evaluate(() => {
      window.scrollTo({
        top: document.body.scrollHeight / 2,
        behavior: 'smooth'
      });
    });
    await page.waitForTimeout(randomDelay(5000, 8000)); // Aumentado a 5-8s
    
    // Esperar un poco más para asegurar que todo esté cargado
    await page.waitForTimeout(randomDelay(10000, 15000)); // Aumentado a 10-15s para asegurar carga completa
    
    console.log('✅ Página completamente cargada, extrayendo datos...');

    // Extraer información de la página
    const trackingData = await page.evaluate(() => {
      const data = {
        trackingNumber: '',
        status: 'No encontrado',
        events: [],
        origin: null,
        destination: null,
        currentLocation: null,
        estimatedDelivery: null,
      };

      try {
        // Buscar el contenedor principal de tracking - más específico para DHL
        let trackingContainer = null;
        
        // Intentar selectores más específicos primero
        const specificSelectors = [
          '[class*="tracking-result"]',
          '[class*="tracking-details"]',
          '[class*="shipment-details"]',
          '[id*="trackingResult"]',
          '[id*="tracking-result"]',
          '[data-testid*="tracking"]',
          'main[class*="tracking"]',
          'div[class*="tracking-container"]',
          'div[class*="tracking-result"]',
          'section[class*="tracking"]',
          '[class*="shipment-status"]',
        ];
        
        for (const selector of specificSelectors) {
          trackingContainer = document.querySelector(selector);
          if (trackingContainer) break;
        }
        
        // Si no encontramos uno específico, buscar más genéricos
        if (!trackingContainer) {
          trackingContainer = document.querySelector('[class*="tracking"], [class*="shipment"], [id*="tracking"], [id*="shipment"]') ||
                             document.querySelector('main, [role="main"], article') ||
                                 document.body;
        }
        
        // Buscar en TODO el body si no encontramos nada útil en el contenedor
        // A veces DHL pone la información fuera del contenedor principal
        const searchInBody = document.body;
        
        // Debug: contar elementos encontrados
        const tables = searchInBody.querySelectorAll('table');
        const divs = searchInBody.querySelectorAll('div[class*="event"], div[class*="tracking"], div[class*="shipment"], div[class*="status"]');
        const allText = searchInBody.innerText;
        
        data.debug = {
          tablesFound: tables.length,
          divsFound: divs.length,
          bodyTextLength: allText.length,
        };
        
        // Usar el body completo si no encontramos un contenedor específico útil
        const finalContainer = tables.length > 0 || divs.length > 10 ? searchInBody : trackingContainer;

        // Buscar estado en elementos específicos de tracking - más selectores de DHL
        const statusSelectors = [
          '[class*="status"]',
          '[class*="state"]',
          '[class*="shipment-status"]',
          '[class*="tracking-status"]',
          '[data-status]',
          'h1, h2, h3, h4',
          '.shipment-status',
          '.tracking-status',
          '[class*="alert"]',
          '[class*="badge"]',
          'strong',
          'span[class*="status"]',
        ];

        // Buscar estado también en el body completo
        const statusContainer = searchInBody;

        let statusFound = false;
        for (const selector of statusSelectors) {
          const elements = statusContainer.querySelectorAll(selector);
          for (const elem of elements) {
            const text = elem.textContent.trim();
            const textLower = text.toLowerCase();
            
            // Filtrar elementos que son claramente del menú o no relevantes
            if (textLower.includes('menú') || textLower.includes('menu') || 
                textLower.includes('servicio') || textLower.includes('encontrar') ||
                textLower.includes('cookie') || textLower.includes('privacidad') ||
                text.length < 3 || text.length > 150) {
              continue;
            }
            
            // Buscar estados más específicos
            if (textLower.includes('entregado') || textLower.includes('delivered') || 
                textLower.includes('delivery completed') || textLower.includes('entregada')) {
              data.status = 'Entregado';
              statusFound = true;
              break;
            } else if (textLower.includes('en tránsito') || textLower.includes('in transit') || 
                      textLower.includes('transit') || textLower.includes('transito')) {
              data.status = 'En tránsito';
              statusFound = true;
            } else if (textLower.includes('recolectado') || textLower.includes('picked up') || 
                      textLower.includes('collected') || textLower.includes('pickup')) {
              data.status = 'Recolectado';
              statusFound = true;
            } else if (textLower.includes('en camino') || textLower.includes('on the way') ||
                      textLower.includes('out for delivery')) {
              data.status = 'En tránsito';
              statusFound = true;
            } else if (textLower.includes('procesando') || textLower.includes('processing') ||
                      textLower.includes('preparando')) {
              data.status = 'Procesando';
              statusFound = true;
            } else if (textLower.includes('lo sentimos') || textLower.includes('no se pudo') ||
                      textLower.includes('no encontrado') || textLower.includes('no encontramos')) {
              data.status = 'No encontrado';
              statusFound = true;
            }
          }
          if (statusFound) break;
        }

        // Buscar eventos de tracking en elementos específicos
        // DHL suele usar listas ordenadas o divs con clases específicas
        const eventSelectors = [
          // Tablas de tracking (muy común en DHL)
          'table tr',
          'table tbody tr',
          'table thead tr',
          '[class*="tracking"] table tr',
          '[class*="shipment"] table tr',
          'div[class*="table"] tr',
          // Listas
          '[class*="timeline"] li',
          '[class*="tracking-event"]',
          '[class*="shipment-event"]',
          '[class*="history"] li',
          '[class*="event"]',
          '[class*="status-item"]',
          '[class*="tracking-step"]',
          '[class*="step"]',
          'ol[class*="tracking"] li',
          'ul[class*="tracking"] li',
          'ol li',
          'ul li',
          // Divs con información de tracking
          'div[class*="tracking"] > div',
          'div[class*="shipment"] > div',
          'div[class*="event"]',
          'div[class*="status"]',
          '[class*="tracking"] > div',
          '[class*="shipment"] > div',
          // Elementos con data attributes
          '[data-tracking-event]',
          '[data-status]',
          '[data-event]',
          // Más genéricos - buscar cualquier div que contenga texto relevante
          'div[class*="row"]',
          'div[class*="card"]',
          'div[class*="item"]',
        ];

        const seenEvents = new Set();
        const excludedTexts = ['menú', 'menu', 'servicio al cliente', 'encontrar', 'obtener', 'enviar ahora', 'solicitar', 'explorar', 'seleccione', 'cambiar', 'cookie', 'privacidad', 'términos', 'consentimiento', 'aceptar', 'rechazar'];
        
        // Determinar qué contenedor usar para buscar eventos
        // Usar el body completo si hay tablas o muchos divs, sino usar el contenedor específico
        const useBodyForSearch = tables.length > 0 || divs.length > 10;
        const containerToSearch = useBodyForSearch ? searchInBody : trackingContainer;
        
        for (const selector of eventSelectors) {
          try {
            const elements = containerToSearch.querySelectorAll(selector);
            for (const elem of elements) {
              const text = elem.textContent.trim();
              
              // Filtrar eventos válidos más estrictamente
              const textLower = text.toLowerCase();
              const isExcluded = excludedTexts.some(excluded => textLower.includes(excluded));
              
              // Un evento válido debe tener:
              // - Longitud razonable
              // - Contener palabras clave de tracking O tener fecha/hora
              // - No ser del menú
              const hasTrackingKeywords = textLower.includes('entregado') || 
                                         textLower.includes('delivered') ||
                                         textLower.includes('tránsito') ||
                                         textLower.includes('transit') ||
                                         textLower.includes('recolectado') ||
                                         textLower.includes('picked') ||
                                         textLower.includes('enviado') ||
                                         textLower.includes('shipped') ||
                                         textLower.includes('recibido') ||
                                         textLower.includes('received') ||
                                         textLower.includes('procesado') ||
                                         textLower.includes('processed') ||
                                         textLower.includes('en camino') ||
                                         textLower.includes('on the way') ||
                                         textLower.includes('salida') ||
                                         textLower.includes('departed') ||
                                         textLower.includes('llegada') ||
                                         textLower.includes('arrived') ||
                                         textLower.match(/\d{1,2}[\/\-]\d{1,2}/) || // Tiene fecha
                                         textLower.match(/\d{1,2}:\d{2}/); // Tiene hora
              
              // Para tablas, verificar que tenga al menos 2 celdas con contenido
              const isTableRow = elem.tagName === 'TR';
              let isValidTableRow = false;
              if (isTableRow) {
                const cells = elem.querySelectorAll('td, th');
                const cellTexts = Array.from(cells).map(cell => cell.textContent.trim()).filter(t => t.length > 0);
                isValidTableRow = cellTexts.length >= 2 && cellTexts.some(cellText => {
                  const cellLower = cellText.toLowerCase();
                  return hasTrackingKeywords || cellLower.match(/\d{1,2}[\/\-]\d{1,2}/) || cellLower.match(/\d{1,2}:\d{2}/);
                });
              }
            
            if (text && text.length > 10 && text.length < 400 && 
                !isExcluded &&
                !seenEvents.has(text) &&
                (hasTrackingKeywords || isValidTableRow)) {
              seenEvents.add(text);
              
              // Intentar extraer fecha/hora del texto
              // Formato: DD/MM/YYYY o DD-MM-YYYY
              const dateMatch = text.match(/(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/);
              // Formato: HH:MM
              const timeMatch = text.match(/(\d{1,2}:\d{2}(?:\s*[AP]M)?)/i);
              
              // Intentar extraer ubicación (ciudad, estado, país)
              const locationMatch = text.match(/([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+)*(?:\s+(?:CDMX|México|Mexico|MX))?)/);
              
              let timestamp = new Date().toISOString();
              if (dateMatch) {
                try {
                  let dateStr = dateMatch[1];
                  // Convertir formato DD/MM/YYYY o DD-MM-YYYY a ISO
                  const parts = dateStr.split(/[\/\-]/);
                  if (parts.length === 3) {
                    const day = parseInt(parts[0]);
                    const month = parseInt(parts[1]) - 1; // Mes es 0-indexed
                    const year = parts[2].length === 2 ? 2000 + parseInt(parts[2]) : parseInt(parts[2]);
                    
                    let hour = 0, minute = 0;
                    if (timeMatch) {
                      const timeParts = timeMatch[1].match(/(\d{1,2}):(\d{2})/);
                      if (timeParts) {
                        hour = parseInt(timeParts[1]);
                        minute = parseInt(timeParts[2]);
                        // Manejar AM/PM si existe
                        if (timeMatch[1].toUpperCase().includes('PM') && hour < 12) hour += 12;
                        if (timeMatch[1].toUpperCase().includes('AM') && hour === 12) hour = 0;
                      }
                    }
                    
                    timestamp = new Date(year, month, day, hour, minute).toISOString();
                  }
                } catch (e) {
                  // Usar timestamp actual si falla
                  console.error('Error parsing date:', e);
                }
              }
              
              let location = null;
              if (locationMatch) {
                location = locationMatch[1].trim();
              }
              
              // Limpiar descripción (remover fechas y horas para que quede más limpio)
              let description = text;
              if (dateMatch) {
                description = description.replace(dateMatch[0], '').trim();
              }
              if (timeMatch) {
                description = description.replace(timeMatch[0], '').trim();
              }
              description = description.replace(/^\s*[,\-–]\s*/, '').trim();
              
              // Si la descripción quedó muy corta, usar el texto original
              if (description.length < 5) {
                description = text;
              }
              
              data.events.push({
                description: description || text,
                timestamp: timestamp,
                location: location,
                status: data.status,
              });
            }
            }
          } catch (e) {
            // Si un selector falla, continuar con el siguiente
            console.log(`Error con selector ${selector}:`, e.message);
          }
        }
        
        // Ordenar eventos por fecha (más reciente primero)
        data.events.sort((a, b) => {
          const dateA = new Date(a.timestamp);
          const dateB = new Date(b.timestamp);
          return dateB - dateA; // Orden descendente (más reciente primero)
        });

        // Buscar ubicaciones en elementos específicos
        const locationSelectors = [
          '[class*="location"]',
          '[class*="origin"]',
          '[class*="destination"]',
          '[class*="from"]',
          '[class*="to"]',
        ];

        for (const selector of locationSelectors) {
          const elements = trackingContainer.querySelectorAll(selector);
          for (const elem of elements) {
            const text = elem.textContent.trim();
            if (text && text.length > 3 && text.length < 100) {
              const lowerText = text.toLowerCase();
              if ((lowerText.includes('origen') || lowerText.includes('origin') || lowerText.includes('from')) && !data.origin) {
                data.origin = text.replace(/origen|origin|from/gi, '').trim();
              } else if ((lowerText.includes('destino') || lowerText.includes('destination') || lowerText.includes('to')) && !data.destination) {
                data.destination = text.replace(/destino|destination|to/gi, '').trim();
              }
            }
          }
        }

        // Si no encontramos eventos pero sí encontramos el estado, crear un evento básico
        if (data.events.length === 0 && data.status !== 'No encontrado') {
          data.events.push({
            description: `Estado: ${data.status}`,
            timestamp: new Date().toISOString(),
            location: null,
            status: data.status,
          });
        }

      } catch (error) {
        console.error('Error al extraer datos:', error);
      }

      return data;
    });

    // Verificar si DHL bloqueó la consulta antes de intentar extraer datos
    const isBlocked = await page.evaluate(() => {
      const bodyText = document.body.innerText.toLowerCase();
      const url = window.location.href;
      
      // Detectar varios tipos de bloqueos
      const blockedIndicators = [
        'access denied',
        'blocked',
        'suspicious activity',
        'too many requests',
        'rate limit',
        'forbidden',
        'captcha',
        'verificación',
        'verifica que no eres un robot',
        'lo sentimos, no podemos procesar',
        'error al procesar',
      ];
      
      return blockedIndicators.some(indicator => bodyText.includes(indicator)) ||
             url.includes('error') ||
             url.includes('blocked') ||
             url.includes('captcha');
    });
    
    if (isBlocked) {
      console.log('⚠️ DHL ha bloqueado la consulta');
      await browser.close();
      const error = new Error('DHL ha bloqueado esta consulta. Por favor, espera unos minutos antes de intentar nuevamente o usa la opción "Abrir en navegador".');
      error.blocked = true;
      error.requiresManualVerification = true;
      throw error;
    }
    
    // Capturar un fragmento del HTML para debugging si no encontramos eventos
    if (trackingData.events.length === 0) {
      console.log('⚠️  No se encontraron eventos, capturando HTML para análisis...');
      
      // Capturar el HTML completo del body para analizar
      const pageContent = await page.evaluate(() => {
        return {
          bodyText: document.body.innerText.substring(0, 2000), // Primeros 2000 caracteres
          allText: document.body.textContent.substring(0, 1000),
          title: document.title,
          url: window.location.href,
          hasTables: document.querySelectorAll('table').length,
          hasLists: document.querySelectorAll('ul, ol').length,
          allDivs: Array.from(document.querySelectorAll('div')).slice(0, 20).map(div => ({
            classes: div.className,
            text: div.textContent.trim().substring(0, 100)
          }))
        };
      });
      
      console.log(`📄 Debug HTML: Título="${pageContent.title}", URL="${pageContent.url}", Tablas=${pageContent.hasTables}, Listas=${pageContent.hasLists}`);
      console.log(`📝 Primeros caracteres del body: ${pageContent.bodyText.substring(0, 200)}`);
      
      console.log('⚠️  Intentando scraping más agresivo...');
      
      // Intentar extraer de cualquier tabla o lista visible
      const aggressiveData = await page.evaluate(() => {
        const events = [];
        const errorMessages = [];
        
      // Primero, buscar mensajes de error de DHL (más específicos)
      const allText = document.body.innerText;
      const errorPatterns = [
        /lo sentimos.*intento de rastreo.*no se realizó correctamente/i,
        /lo sentimos.*su intento de rastreo/i,
        /intento de rastreo.*no se realizó correctamente/i,
        /lo sentimos[^.]*\./i,
        /no se pudo[^.]*\./i,
        /error[^.]*\./i,
        /intento[^.]*\./i,
        /no encontrado[^.]*\./i,
        /no encontramos[^.]*\./i,
      ];
        
        for (const pattern of errorPatterns) {
          const match = allText.match(pattern);
          if (match) {
            errorMessages.push(match[0].trim());
          }
        }
        
        // Buscar en todas las listas (ul, ol) - hay 31 listas según los logs
        const allLists = document.querySelectorAll('ul, ol');
        allLists.forEach((list) => {
          const items = list.querySelectorAll('li');
          items.forEach((item) => {
            const text = item.textContent.trim();
            const textLower = text.toLowerCase();
            
            // Verificar si es un mensaje de error
            if (textLower.includes('lo sentimos') || 
                textLower.includes('no se pudo') ||
                textLower.includes('error') ||
                textLower.includes('no encontrado') ||
                textLower.includes('no encontramos')) {
              if (!errorMessages.some(e => e.includes(text))) {
                errorMessages.push(text);
              }
            }
            
            // Verificar si parece un evento de tracking (más flexible)
            if (text.length > 10 && text.length < 500 &&
                (textLower.includes('entregado') || 
                 textLower.includes('delivered') ||
                 textLower.includes('tránsito') ||
                 textLower.includes('transit') ||
                 textLower.includes('recolectado') ||
                 textLower.includes('picked') ||
                 textLower.includes('enviado') ||
                 textLower.includes('shipped') ||
                 textLower.includes('procesado') ||
                 textLower.includes('processed') ||
                 textLower.match(/\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}/) ||
                 textLower.match(/\d{1,2}:\d{2}/))) {
              
              // Extraer fecha y hora
              const dateMatch = text.match(/(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/);
              const timeMatch = text.match(/(\d{1,2}:\d{2}(?:\s*[AP]M)?)/i);
              
              let timestamp = new Date().toISOString();
              if (dateMatch) {
                try {
                  const parts = dateMatch[1].split(/[\/\-]/);
                  if (parts.length === 3) {
                    const day = parseInt(parts[0]);
                    const month = parseInt(parts[1]) - 1;
                    const year = parts[2].length === 2 ? 2000 + parseInt(parts[2]) : parseInt(parts[2]);
                    let hour = 0, minute = 0;
                    if (timeMatch) {
                      const timeParts = timeMatch[1].match(/(\d{1,2}):(\d{2})/);
                      if (timeParts) {
                        hour = parseInt(timeParts[1]);
                        minute = parseInt(timeParts[2]);
                        if (timeMatch[1].toUpperCase().includes('PM') && hour < 12) hour += 12;
                        if (timeMatch[1].toUpperCase().includes('AM') && hour === 12) hour = 0;
                      }
                    }
                    timestamp = new Date(year, month, day, hour, minute).toISOString();
                  }
                } catch (e) {
                  // Usar timestamp actual
                }
              }
              
              events.push({
                description: text,
                timestamp: timestamp,
                location: null,
                status: textLower.includes('entregado') || textLower.includes('delivered') ? 'Entregado' : 
                       textLower.includes('tránsito') || textLower.includes('transit') ? 'En tránsito' : 
                       textLower.includes('recolectado') || textLower.includes('picked') ? 'Recolectado' : 'Desconocido',
              });
            }
          });
        });
        
        // Buscar en todas las tablas
        const tables = document.querySelectorAll('table');
        tables.forEach((table, tableIndex) => {
          const rows = table.querySelectorAll('tr');
          rows.forEach((row, rowIndex) => {
            const cells = Array.from(row.querySelectorAll('td, th'));
            if (cells.length >= 2) {
              const cellTexts = cells.map(cell => cell.textContent.trim()).filter(t => t.length > 0);
              const combinedText = cellTexts.join(' | ');
              
              // Verificar si parece un evento de tracking
              const textLower = combinedText.toLowerCase();
              if ((textLower.includes('entregado') || 
                   textLower.includes('delivered') ||
                   textLower.includes('tránsito') ||
                   textLower.includes('transit') ||
                   textLower.includes('recolectado') ||
                   textLower.includes('picked') ||
                   textLower.match(/\d{1,2}[\/\-]\d{1,2}/) ||
                   textLower.match(/\d{1,2}:\d{2}/)) &&
                  combinedText.length > 15 && combinedText.length < 500) {
                
                // Extraer fecha y hora
                const dateMatch = combinedText.match(/(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/);
                const timeMatch = combinedText.match(/(\d{1,2}:\d{2}(?:\s*[AP]M)?)/i);
                
                let timestamp = new Date().toISOString();
                if (dateMatch) {
                  try {
                    const parts = dateMatch[1].split(/[\/\-]/);
                    if (parts.length === 3) {
                      const day = parseInt(parts[0]);
                      const month = parseInt(parts[1]) - 1;
                      const year = parts[2].length === 2 ? 2000 + parseInt(parts[2]) : parseInt(parts[2]);
                      let hour = 0, minute = 0;
                      if (timeMatch) {
                        const timeParts = timeMatch[1].match(/(\d{1,2}):(\d{2})/);
                        if (timeParts) {
                          hour = parseInt(timeParts[1]);
                          minute = parseInt(timeParts[2]);
                          if (timeMatch[1].toUpperCase().includes('PM') && hour < 12) hour += 12;
                          if (timeMatch[1].toUpperCase().includes('AM') && hour === 12) hour = 0;
                        }
                      }
                      timestamp = new Date(year, month, day, hour, minute).toISOString();
                    }
                  } catch (e) {
                    // Usar timestamp actual
                  }
                }
                
                events.push({
                  description: combinedText,
                  timestamp: timestamp,
                  location: cellTexts.length > 2 ? cellTexts[2] : null,
                  status: textLower.includes('entregado') || textLower.includes('delivered') ? 'Entregado' : 
                         textLower.includes('tránsito') || textLower.includes('transit') ? 'En tránsito' : 'Desconocido',
                });
              }
            }
          });
        });
        
        // Buscar en listas ordenadas y desordenadas (segunda pasada)
        const moreLists = document.querySelectorAll('ol, ul');
        moreLists.forEach((list) => {
          const items = list.querySelectorAll('li');
          items.forEach((item) => {
            const text = item.textContent.trim();
            const textLower = text.toLowerCase();
            if (text.length > 15 && text.length < 400 &&
                (textLower.includes('entregado') || 
                 textLower.includes('delivered') ||
                 textLower.includes('tránsito') ||
                 textLower.includes('transit') ||
                 textLower.includes('recolectado') ||
                 textLower.includes('picked') ||
                 textLower.match(/\d{1,2}[\/\-]\d{1,2}/) ||
                 textLower.match(/\d{1,2}:\d{2}/))) {
              
              const dateMatch = text.match(/(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})/);
              const timeMatch = text.match(/(\d{1,2}:\d{2}(?:\s*[AP]M)?)/i);
              
              let timestamp = new Date().toISOString();
              if (dateMatch) {
                try {
                  const parts = dateMatch[1].split(/[\/\-]/);
                  if (parts.length === 3) {
                    const day = parseInt(parts[0]);
                    const month = parseInt(parts[1]) - 1;
                    const year = parts[2].length === 2 ? 2000 + parseInt(parts[2]) : parseInt(parts[2]);
                    let hour = 0, minute = 0;
                    if (timeMatch) {
                      const timeParts = timeMatch[1].match(/(\d{1,2}):(\d{2})/);
                      if (timeParts) {
                        hour = parseInt(timeParts[1]);
                        minute = parseInt(timeParts[2]);
                        if (timeMatch[1].toUpperCase().includes('PM') && hour < 12) hour += 12;
                        if (timeMatch[1].toUpperCase().includes('AM') && hour === 12) hour = 0;
                      }
                    }
                    timestamp = new Date(year, month, day, hour, minute).toISOString();
                  }
                } catch (e) {
                  // Usar timestamp actual
                }
              }
              
              events.push({
                description: text,
                timestamp: timestamp,
                location: null,
                status: textLower.includes('entregado') || textLower.includes('delivered') ? 'Entregado' : 
                       textLower.includes('tránsito') || textLower.includes('transit') ? 'En tránsito' : 'Desconocido',
              });
            }
          });
        });
        
        return { events, errorMessages };
      });
      
      // Si encontramos mensajes de error, actualizar el estado
      if (aggressiveData && aggressiveData.errorMessages && aggressiveData.errorMessages.length > 0) {
        const errorMsg = aggressiveData.errorMessages[0];
        console.log(`⚠️ Mensaje de error de DHL detectado: ${errorMsg.substring(0, 100)}`);
        trackingData.status = 'No encontrado';
        
        // Agregar el mensaje de error como un evento informativo si no hay otros eventos
        if (!trackingData.events || trackingData.events.length === 0) {
          trackingData.events.push({
            description: errorMsg,
            timestamp: new Date().toISOString(),
            location: null,
            status: 'No encontrado',
          });
        }
      }
      
      // Si encontramos eventos, agregarlos
      if (aggressiveData && aggressiveData.events && aggressiveData.events.length > 0) {
        if (!trackingData.events) trackingData.events = [];
        trackingData.events = trackingData.events.concat(aggressiveData.events);
        console.log(`✅ Encontrados ${aggressiveData.events.length} eventos adicionales con scraping agresivo`);
      }
    }
    
    // Si aún no hay eventos pero sí hay estado, crear eventos básicos basados en el estado
    if (trackingData.events.length === 0 && trackingData.status !== 'No encontrado') {
      console.log('⚠️  Creando eventos básicos basados en el estado...');
      trackingData.events.push({
        description: `Estado actual: ${trackingData.status}`,
        timestamp: new Date().toISOString(),
        location: null,
        status: trackingData.status,
      });
    }
    
    trackingData.trackingNumber = trackingNumber;

    // Log de información de debug si está disponible
    if (trackingData.debug) {
      console.log(`🔍 Debug: ${trackingData.debug.tablesFound} tablas, ${trackingData.debug.divsFound} divs encontrados`);
    }
    
    console.log(`✅ Tracking procesado: Estado = ${trackingData.status}, Eventos = ${trackingData.events.length}`);
    
    // Remover debug antes de enviar respuesta
    if (trackingData.debug) {
      delete trackingData.debug;
    }

    // Guardar cookies antes de cerrar para mantener sesión
    try {
      const cookies = await page.cookies();
      saveCookies(cookies);
      console.log(`🍪 Guardadas ${cookies.length} cookies para la próxima sesión`);
    } catch (e) {
      console.log('⚠️ No se pudieron guardar cookies');
    }
    
    // Solo cerrar el navegador si NO estamos usando la página precargada
    if (!usePreloaded) {
      await browser.close();
    } else {
      console.log('✅ Manteniendo navegador precargado abierto para próximas consultas');
    }

    return {
      success: true,
      data: trackingData,
    };

  } catch (error) {
    // Log del error completo para debugging
    console.error(`❌ Error al consultar tracking (intento ${attempt}):`, error);
    console.error('❌ Error message:', error.message);
    
    // Cerrar browser solo si NO estamos usando la página precargada
    if (browser && !usePreloaded) {
      try {
        await browser.close();
      } catch (closeError) {
        console.error('❌ Error al cerrar browser:', closeError);
      }
    } else if (error.blocked || error.requiresManualVerification) {
      // Si hay bloqueo, reiniciar página precargada
      console.log('🔄 Reiniciando página precargada debido a bloqueo...');
      try {
        if (preloadedBrowser) {
          await preloadedBrowser.close();
        }
      } catch (e) {}
      preloadedBrowser = null;
      preloadedPage = null;
      isPreloading = false;
      preloadPromise = null;
    }
    
    throw error;
  }
}

/**
 * Endpoint para consultar tracking de DHL
 * GET /api/track/:trackingNumber
 */
app.get('/api/track/:trackingNumber', async (req, res) => {
  const { trackingNumber } = req.params;
  
  if (!trackingNumber || trackingNumber.trim().length < 8) {
    return res.status(400).json({
      success: false,
      error: 'Número de tracking inválido',
    });
  }

  const maxRetries = 2; // Máximo 2 reintentos (3 intentos en total)
  let lastError = null;
  
  for (let attempt = 1; attempt <= maxRetries + 1; attempt++) {
    try {
      console.log(`🔄 Intento ${attempt} de ${maxRetries + 1}...`);
      
      // Agregar delay entre reintentos (exponencial backoff)
      if (attempt > 1) {
        const delay = Math.min(1000 * Math.pow(2, attempt - 2), 10000); // Max 10 segundos
        console.log(`⏳ Esperando ${delay}ms antes del reintento...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
      
      const result = await scrapeDHLTracking(trackingNumber, attempt);
      
      // Si llegamos aquí, fue exitoso
      return res.json(result);
      
    } catch (error) {
      lastError = error;
      
      // Si es un error de bloqueo o CAPTCHA, no reintentar
      if (error.blocked || error.requiresManualVerification) {
        return res.status(403).json({
          success: false,
          error: error.error || 'DHL ha bloqueado esta consulta',
          requiresManualVerification: true,
          blocked: true,
        });
      }
      
      // Si es el último intento, devolver el error
      if (attempt === maxRetries + 1) {
        console.error('❌ Todos los intentos fallaron');
        return res.status(500).json({
          success: false,
          error: lastError.message || 'Error desconocido',
          message: 'Error al consultar DHL después de varios intentos. Por favor intenta nuevamente más tarde.',
          details: process.env.NODE_ENV === 'production' ? undefined : lastError.stack,
        });
      }
      
      console.log(`⚠️ Intento ${attempt} falló, reintentando...`);
    }
  }
});

/**
 * Endpoint de salud
 */
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'DHL Tracking Proxy' });
});

/**
 * Endpoint de warmup - Precarga la página de DHL para consultas más rápidas
 * GET /warmup
 * 
 * Este endpoint se puede llamar antes de hacer una consulta real para
 * asegurar que la página ya esté precargada y lista.
 */
app.get('/warmup', async (req, res) => {
  try {
    console.log('🔥 Warmup solicitado - precargando página DHL...');
    const startTime = Date.now();
    
    // Intentar precargar la página
    const preloaded = await preloadDHLPage();
    
    const elapsed = Date.now() - startTime;
    
    if (preloaded && preloaded.browser && preloaded.page) {
      res.json({
        success: true,
        message: 'Página precargada exitosamente',
        elapsed: `${elapsed}ms`,
        ready: true,
      });
      console.log(`✅ Warmup completado en ${elapsed}ms`);
    } else {
      res.json({
        success: false,
        message: 'No se pudo precargar la página',
        elapsed: `${elapsed}ms`,
        ready: false,
      });
    }
  } catch (error) {
    console.error('❌ Error en warmup:', error.message);
    res.status(500).json({
      success: false,
      error: error.message,
      ready: false,
    });
  }
});

/**
 * Endpoint de keep-alive - Mantiene el servicio activo en Render
 * GET /keepalive
 * 
 * Render.com "duerme" los servicios gratuitos después de 15 minutos de inactividad.
 * Este endpoint se puede llamar periódicamente para mantener el servicio activo.
 * También verifica y recarga la página precargada si es necesario.
 */
app.get('/keepalive', async (req, res) => {
  try {
    const isPreloadedReady = preloadedBrowser && preloadedPage;
    let preloadStatus = 'unknown';
    
    // Verificar si la página precargada sigue activa
    if (isPreloadedReady) {
      try {
        await preloadedPage.evaluate(() => document.title);
        preloadStatus = 'ready';
      } catch (e) {
        preloadStatus = 'expired';
        // Limpiar referencias
        preloadedBrowser = null;
        preloadedPage = null;
        isPreloading = false;
        preloadPromise = null;
      }
    } else {
      preloadStatus = 'not_loaded';
    }
    
    // Si la página precargada no está lista, intentar recargarla en background
    if (preloadStatus !== 'ready' && !isPreloading) {
      console.log('🔄 Recargando página precargada en background...');
      preloadDHLPage().catch(err => {
        console.log('⚠️ Error al recargar en background:', err.message);
      });
    }
    
    res.json({
      status: 'alive',
      timestamp: new Date().toISOString(),
      preloadStatus: preloadStatus,
      message: 'Servicio activo',
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      error: error.message,
    });
  }
});

// Iniciar verificación de Chrome en background al iniciar el servidor
// Esto pre-descarga Chrome si no está disponible
ensureChrome().then(chromePath => {
  if (chromePath) {
    console.log('✅ Chrome está listo para usar');
    // Precargar página de DHL después de que Chrome esté listo
    console.log('🔄 Iniciando precarga de página DHL...');
    preloadDHLPage().then(() => {
      console.log('✅ Precarga completada - el servidor está listo para consultas rápidas');
    }).catch(err => {
      console.log('⚠️ Error en precarga (se creará nueva sesión cuando sea necesario):', err.message);
    });
  } else {
    console.log('⚠️ Chrome se descargará cuando sea necesario');
  }
}).catch(err => {
  console.log('⚠️ Error al verificar Chrome:', err.message);
});

// Iniciar servidor en todas las interfaces (0.0.0.0) para que sea accesible desde la red local
app.listen(PORT, '0.0.0.0', () => {
  const os = require('os');
  const networkInterfaces = os.networkInterfaces();
  let localIp = 'localhost';
  
  // Buscar IP local (IPv4) en interfaces de red
  for (const name of Object.keys(networkInterfaces)) {
    for (const iface of networkInterfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        localIp = iface.address;
        break;
      }
    }
    if (localIp !== 'localhost') break;
  }
  
  console.log(`🚀 Servidor DHL Tracking Proxy corriendo en puerto ${PORT}`);
  console.log(`📡 Endpoint local: http://localhost:${PORT}/api/track/:trackingNumber`);
  console.log(`📡 Endpoint red local: http://${localIp}:${PORT}/api/track/:trackingNumber`);
  console.log(`🌐 Accesible desde dispositivos en la misma red: http://${localIp}:${PORT}`);
});

