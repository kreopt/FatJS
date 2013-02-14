JAFW_PATH = './jafw/'
APPS_PATH = './srvapps/'

srv = require(JAFW_PATH + "/core/server")
JAFW= require(JAFW_PATH+"/core/core").jafw
handlers=require('./handlers')

loaded = {}
modLoad = (app)->
   if not loaded[app]
      loaded[app] = require(APPS_PATH + app)
   loaded[app]

routes = {
   "^/([A-Z0-9]{1,20})$":handlers.index
   "^/jafwload/(.*)":handlers.loader
   "^/@([^@]*)@(.*)":handlers.script
   "^/api/":handlers.api
   "^/apps/.*": handlers.staticfiles
   "^/jafw/.*": handlers.staticfiles
   "^/lib/.*": handlers.staticfiles
   "[^/]+\.js|[^/]+\.css": handlers.staticfiles
   "/img/.*": (c,r,d)->handlers.staticfiles(c,r,d, [] ,'/..')
   ".*":handlers.fallback
}
router = {
   handle: (req, fReply, data = '')->
      for route of routes
         match=req.url.match(new RegExp(route))
         if match
            routes[route](fReply,req,data,match)
            break
      #fReply(req.data + ' received')
   handleSocket: (data, fReply)->
      data = JSON.parse(data)
      switch data.type
         when 'signal'
            fReply(JSON.stringify({type:'signal',signal:'testresult',data:data.data}))
         when 'api'
            try
               makeResponse=(response)->
                  mod.destroy?()
                  if response!=null && typeof(response)==typeof({}) and response.type=='error'
                     fReply(JSON.stringify(response))
                  else
                     fReply(JSON.stringify({type:'api',seq:data.seq,data:response}))
                  #throw 'NOERROR'
               ready=(app)->
                  if app[data.method]
                     console.log('Using nodejs for '+data.mod+'.'+data.method)
                     app[data.method]()
                  else
                     handlers.apiFallback(fReply,JAFW.Url.encode(data),data.seq)
               mod=new modLoad(data.mod).App
               mod.init(makeResponse,data, ready)
            catch e
               console.log(e.stack)
               handlers.apiFallback(fReply,JAFW.Url.encode(data),data.seq)
         when 'businit'
            handles=['testsig1','testsig2']
            #TODO: get handles from apps metadata(store in redis?)
            fReply(JSON.stringify({type:'businit',handles:handles}))
         else
            fReply(JSON.stringify({type:'error',data:'unknown request type: '+data.type}))
}
options = {
port: 9000
}
srv.run(router, options)