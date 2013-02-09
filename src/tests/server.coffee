JAFW_PATH = '../'
APPS_PATH = './apps/'

srv = require(JAFW_PATH + "/core/server")
JAFW= require(JAFW_PATH+"/core/core").jafw
handlers=require('./handlers')

loaded = {}
modLoad = (app)->
   if not loaded[app]
      loaded[app] = require(APPS_PATH + app)
   loaded[app]

routes = {
   "^/([a-z0-9]{1,20})$":handlers.index
   "^/jafwload/(.*)":handlers.loader
   "^/@([^@]*)@(.*)":handlers.script
   "/client/.*": handlers.staticfiles
   ".*":handlers.django
}
router = {
   handle: (req, resultCallback, data = '')->
      for route of routes
         match=req.url.match(new RegExp(route))
         if match
            routes[route](resultCallback,req,data,match)
            break
      #resultCallback(req.data + ' received')
   handleSocket: (data, resultCallback)->
      data = JSON.parse(data)
      switch data.type
         when 'signal'
            resultCallback(JSON.stringify({type:'signal',signal:'testresult',data:data.data}))
         when 'api'
            try
               mod=modLoad(data.mod)
               mod.init resultCallback, (app)->
                  makeResponse=(response)->
                     mod.destroy()
                     resultCallback(JSON.stringify({type:'api',seq:data.seq,data:response}))
                  if app[data.method]
                     console.log('Using nodejs for '+data.mod+'.'+data.method)
                     app[data.method](makeResponse, data.data,data.meta)
                  else
                     handlers.apiFallback(resultCallback,JAFW.Url.encode(data),data.seq)
            catch e
               console.log(e)
               handlers.apiFallback(resultCallback,JAFW.Url.encode(data),data.seq)
         when 'businit'
            handles=['testsig1','testsig2']
            #TODO: get handles from apps metadata(store in redis?)
            resultCallback(JSON.stringify({type:'businit',handles:handles}))
         else
            resultCallback(JSON.stringify({type:'error',data:'unknown request type: '+data.type}))
}
options = {
port: 9000
}
srv.run(router, options)