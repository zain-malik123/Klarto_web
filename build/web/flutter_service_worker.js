'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "e695b4a16016f1b12f68c8600cd47230",
"assets/AssetManifest.bin.json": "9c7fc69cb92d1c7f9b3fa3843fd76872",
"assets/AssetManifest.json": "c4dfa6e4af8c844c5d9f76871ad57554",
"assets/assets/fonts/Inter_24pt-Black.ttf": "2392341284c30f5fffb9fe0ab0cd983e",
"assets/assets/fonts/Inter_24pt-Bold.ttf": "a041f18d0d0c67b376bec0343f7c0cf0",
"assets/assets/fonts/Inter_24pt-BoldItalic.ttf": "79bdd17736cfe1b6ca071a6e298691ed",
"assets/assets/fonts/Inter_24pt-ExtraBold.ttf": "995fb5ac38b90303c0cc1a0b21e2c9fe",
"assets/assets/fonts/Inter_24pt-Italic.ttf": "0b52c6d11ac407c2ef591475f2b4ed11",
"assets/assets/fonts/Inter_24pt-Light.ttf": "65ec965bd90e1a297cdb3be407420abc",
"assets/assets/fonts/Inter_24pt-Medium.ttf": "4591e900425d177e6ba268d165bf12e8",
"assets/assets/fonts/Inter_24pt-Regular.ttf": "e48c1217adab2a0e44f8df400d33c325",
"assets/assets/fonts/Inter_24pt-SemiBold.ttf": "c77560a8441d664af3e65dd57026dff9",
"assets/assets/fonts/Inter_24pt-Thin.ttf": "1e9e30c74648950a240427636b6c1992",
"assets/assets/icons/activity.svg": "15a80eb621ca35685d3d533ea5862882",
"assets/assets/icons/add-square.svg": "bb5f72506669a08ca1c4b3093f9cd74e",
"assets/assets/icons/add.svg": "193e7de7246f0ac47d4bd107ad8801f8",
"assets/assets/icons/align.svg": "bc6ceb11aa461c5f9712a79de84bfe17",
"assets/assets/icons/apple.png": "d20c46820dffe0f5b3cdfada2419c78f",
"assets/assets/icons/apple.svg": "4efbbd4b7a0e535fdbf8ee0b40937381",
"assets/assets/icons/arrow-left.svg": "dc81abab300820d4d6509a59671b2d45",
"assets/assets/icons/arrow-right.svg": "43316d513ffeefaaa4af53d01745288b",
"assets/assets/icons/avatar.png": "614ad3c965e05194526929f35b03c9f5",
"assets/assets/icons/avatar.svg": "a8bf760bef0ed489c2e32b4912dcbcd6",
"assets/assets/icons/bell.svg": "e7d99f5a0bbbcd95c68ab136307aba6c",
"assets/assets/icons/calendar-2.svg": "33aebd47e870c7cc5facb3a59415de2e",
"assets/assets/icons/calendar.svg": "08f3c2b0da99540c19023e787c3bd2fd",
"assets/assets/icons/check.svg": "ccfe5ed01a25f574994493077695eded",
"assets/assets/icons/chevron-down.svg": "faf2ff9406b94e5ffeec1c8fba8d0505",
"assets/assets/icons/clock.svg": "3a5eda578ef50c0862c1482cd16aeac9",
"assets/assets/icons/close.svg": "6a1854153195e60da309ec5955db7364",
"assets/assets/icons/dock.svg": "603366a8e150c8197c9927b8a7e7154d",
"assets/assets/icons/edit.svg": "32ff6ddc910357d3a6cdb58d294c4c08",
"assets/assets/icons/facebook.png": "e4da23704f27c9df07e6c21a13e28bfd",
"assets/assets/icons/filter.svg": "f8d36df8c8c8cf25764da246f6fbba47",
"assets/assets/icons/filters.svg": "504e4fb2ef343b458c0f09cf338c6e1a",
"assets/assets/icons/folder.svg": "17aa7ec109fd0109040631db9d7f2963",
"assets/assets/icons/google.png": "41cb353875b6d18e6e18472da89d0354",
"assets/assets/icons/grid.svg": "120efa34003bddee435e44b173ae6067",
"assets/assets/icons/heart.svg": "5d2beda648034ac7bcc5ca0ab2b0bdc6",
"assets/assets/icons/help.svg": "a2c1797ead9842a515fb94f41733e235",
"assets/assets/icons/link.svg": "7d8bdb72739cb3e55a5f5d3f8485afdb",
"assets/assets/icons/notes.svg": "03c527178563ecee78d6728fedbe7b87",
"assets/assets/icons/overdue.svg": "a992613bf911553f07640b6ce6ccb77f",
"assets/assets/icons/priority.svg": "9efe5665ac171921e5bcfc81dd52fe2d",
"assets/assets/icons/project.svg": "db74c32def550a787f860c7a0afd2fb0",
"assets/assets/icons/refresh.svg": "c1a3f9b198f660c12a8b5d15b2635acf",
"assets/assets/icons/search.svg": "718190346ab4835f942723e3ee928b28",
"assets/assets/icons/send.svg": "69d0c57bfcdff622505bc3de5d5ecee3",
"assets/assets/icons/subtasks.svg": "7711506b4b98108b6f79125d0a470540",
"assets/assets/icons/svg": "d20c46820dffe0f5b3cdfada2419c78f",
"assets/assets/icons/tag.svg": "111cdaae5fc2efba5d4183caf0d29ff8",
"assets/assets/icons/three-dots.svg": "e87ee35eff395c2840ccb8388799bb09",
"assets/assets/icons/today.svg": "b1ebc751a90c175922111cbde71e0dee",
"assets/assets/icons/trash.svg": "e098988d4abc6ca9c71a808a9dffa8d0",
"assets/assets/icons/view.svg": "eb9a6d0d64d0ffa193c7183954bcd2c6",
"assets/assets/images/avatar.png": "614ad3c965e05194526929f35b03c9f5",
"assets/assets/images/logo.png": "e784aa21192bcbe6aa27212550ea786d",
"assets/assets/images/logo_a.png": "614ad3c965e05194526929f35b03c9f5",
"assets/assets/images/logo_blue.png": "614ad3c965e05194526929f35b03c9f5",
"assets/assets/images/logo_full.png": "bccdc3fc59d1dfa6a4243f67642bcc8e",
"assets/FontManifest.json": "98e1b10d8b55e1bbc8fee73ffdf9fe50",
"assets/fonts/MaterialIcons-Regular.otf": "fb8d9b71699110f52dfe95984a926007",
"assets/NOTICES": "665b744c06989570164509f22faf9b48",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/packages/record_web/assets/js/record.fixwebmduration.js": "1f0108ea80c8951ba702ced40cf8cdce",
"assets/packages/record_web/assets/js/record.worklet.js": "6d247986689d283b7e45ccdf7214c2ff",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "41b86a474fe81da6a636d91daae40730",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "4803db2953c2e73935bc863fc622883b",
"/": "4803db2953c2e73935bc863fc622883b",
"main.dart.js": "387abc5c00dc6429d7b168e49c499ece",
"manifest.json": "b1ff4d21929d73ee670d408aa0a52bbf",
"version.json": "e4924621a53741f1b6da3b0b5c901fad"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
