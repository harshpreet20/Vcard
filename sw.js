var CACHE='hotbot-vcard-v8';
var ASSETS=['/','/manifest.json','/icons/icon-192.png','/icons/icon-512.png','/assets/portrait.webp','/assets/avatar.jpg'];

self.addEventListener('install',function(e){
  e.waitUntil(caches.open(CACHE).then(function(c){return c.addAll(ASSETS.map(function(u){return new Request(u,{cache:'reload'})}))}));
  self.skipWaiting();
});

self.addEventListener('activate',function(e){
  e.waitUntil(caches.keys().then(function(keys){
    var old=keys.filter(function(k){return k!==CACHE});
    return Promise.all(old.map(function(k){return caches.delete(k)})).then(function(){return old.length});
  }).then(function(upgraded){
    return self.clients.claim().then(function(){
      /* replacing an older version: reload open windows so nobody is stuck on stale content */
      if(!upgraded)return;
      return self.clients.matchAll({type:'window'}).then(function(list){
        list.forEach(function(c){if(c.navigate)c.navigate(c.url).catch(function(){})});
      });
    });
  }));
});

function save(req,resp){
  if(resp&&resp.status===200&&resp.type==='basic'){var copy=resp.clone();caches.open(CACHE).then(function(c){c.put(req,copy)})}
  return resp;
}

self.addEventListener('fetch',function(e){
  var req=e.request;
  if(req.method!=='GET'||new URL(req.url).origin!==location.origin)return;

  /* Pages: always try the network first so the latest version shows; cache is the offline fallback */
  if(req.mode==='navigate'||(req.headers.get('accept')||'').indexOf('text/html')>-1){
    e.respondWith(fetch(req,{cache:'no-store'}).then(function(r){return save(req,r)}).catch(function(){
      return caches.match(req).then(function(c){return c||caches.match('/')});
    }));
    return;
  }

  /* Images and files: serve from cache instantly, refresh in the background */
  e.respondWith(caches.match(req).then(function(cached){
    var fresh=fetch(req).then(function(r){return save(req,r)}).catch(function(){return cached});
    return cached||fresh;
  }));
});
