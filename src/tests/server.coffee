http=require('http')
fs=require('fs')
mime = require('mime');
JAFW_PATH = '../'
APPS_PATH = './apps/'
PROJECT_PATH='../../../../'
srv = require(JAFW_PATH + "/core/server")
JAFW= require(JAFW_PATH+"/core/core").jafw
loaded = {}
modLoad = (app)->
   if not loaded[app]
      loaded[app] = require(APPS_PATH + app)
   loaded[app]
apiFallback=(resultCallback,data,seq)->
   options = {
      host: 'localhost',
      port: 8000,
      path: '/api/',
      method: 'POST',
      headers: {
         'Content-Type': 'application/x-www-form-urlencoded',
         'Content-Length': data.length,
         'charset':'utf-8',
         'Accept-Encoding': 'gzip, deflate',
         'Accept-Language': 'ru-RU,ru;q=0.8,en-US;q=0.5,en;q=0.3'
      }
   };
   respdata=''
   req=http.request options, (response)->
      response.setEncoding('utf8');
      response.on 'data', (chunk)->respdata+=chunk
      response.on 'end',()->resultCallback(JSON.stringify({type:'api',seq:seq,data:JSON.parse(respdata)}))
   req.on 'error', (e)->
      console.log('problem with request: ' + e.message);
   req.end(data,'utf8')
djangoFallback=(resultCallback,req,data)->
   options = {
      host: 'localhost',
      port: 8000,
      path: req.url,
      method: req.method,
      headers: req.headers
   };
   respdata=''
   req=http.request options, (response)->
      response.setEncoding('utf8');
      response.on 'data', (chunk)->respdata+=chunk
      response.on 'end',()->
         resultCallback(respdata,response.statusCode,response.headers)
   req.on 'error', (e)->
      console.log('problem with request: ' + e.message);
   req.end(data,'utf8')
staticHandler=(resultCallback,req,data)->
   fs.readFile PROJECT_PATH+req.url,(err,data)->
      mimeType=mime.lookup(req.url)
      console.log(mimeType)
      resultCallback((if err then '' else data),200,{'Content-Type': mimeType })
routes = {
   "/client/.*": staticHandler
   ".*":djangoFallback
}
router = {
   handle: (req, resultCallback, data = '')->
      for route of routes
         if req.url.match(new RegExp(route))
            routes[route](resultCallback,req,data)
            break
      #resultCallback(req.data + ' received')
   handleSocket: (data, resultCallback)->
      data = JSON.parse(data)
      switch data.type
         when 'signal'
            resultCallback(JSON.stringify({type:'signal',signal:'testresult',data:data.data}))
         when 'api'
            try
               modLoad(data.app)[data.method](((response)->resultCallback(JSON.stringify(response))), data.data)
            catch e
               apiFallback(resultCallback,JAFW.Url.encode(data),data.seq)
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