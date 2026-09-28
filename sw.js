// Service worker mínimo: permite instalar o app no celular.
// Não guarda nada em cache, para a equipe sempre usar a versão mais recente.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));
self.addEventListener('fetch', () => {});
