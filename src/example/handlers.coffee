http=require('http')
fs=require('fs')
path=require('path')
mime = require('mime');
PROJECT_PATH='.'
JAFW_PATH = './jafw/'
APPS_PATH = './srvapps/'

srv = require(JAFW_PATH + "/core/server")
JAFW= require(JAFW_PATH+"/core/core").jafw
loaded = {}
modLoad = (app)->
   if not loaded[app]
      loaded[app] = require(APPS_PATH + app)
   loaded[app]
exports.api=(fReply,req,data,seq)->
   try
      data=JAFW.Url.decode(data.toString())
      makeResponse=(response)->
         mod.destroy?()
         if response!=null && typeof(response)==typeof({}) and response.type=='error'
            fReply(JSON.stringify(response))
         else
            fReply(JSON.stringify({type:'api',status:0,seq:data.seq,data:response}))
      #throw 'NOERROR'
      ready=(app)->
         if app[data.method]
            console.log('Using nodejs for '+data.mod+'.'+data.method)
            app[data.method]()
         else
            exports.apiFallback(fReply,JAFW.Url.encode(data),data.seq)
      mod=new modLoad(data.mod).App
      mod.init(makeResponse,data, ready)
   catch e
      console.log(e.stack)
      exports.apiFallback(fReply,JAFW.Url.encode(data),data.seq)
exports.apiFallback=(fReply,data,seq)->
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
   }
   respdata=''
   req=http.request options, (response)->
      response.setEncoding('utf8');
      response.on 'data', (chunk)->respdata+=chunk
      response.on 'end',()->fReply(JSON.stringify({type:'api',seq:seq,data:JSON.parse(respdata)}))
   req.on 'error', (e)->
      console.log('problem with request: ' + e.message);
   req.end(data,'utf8')
exports.django=(fReply,req,data)->
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
         fReply(respdata,response.statusCode,response.headers)
   req.on 'error', (e)->
      console.log('problem with request: ' + e.message);
   req.end(data,'utf8')
exports.staticfiles=(fReply,req,data,match,prefix='')->
   fs.readFile PROJECT_PATH+prefix+req.url,(err,data)->
      mimeType=mime.lookup(req.url)
      console.log(PROJECT_PATH+prefix+req.url+':'+mimeType)
      fReply((if err then '' else data),200,{'Content-Type': mimeType })
exports.index=(fReply,req,data,match)->
   fReply(fs.readFileSync(PROJECT_PATH+'/index.html','utf-8').replace('id="jafw_container"','id="jafw_container" data-token="'+match[1]+'"'),200,{'Content-Type': 'text/html' })
exports.fallback=(fReply,req,data,match)->
   fReply('Unknown URL',200,{'Content-Type': 'text/html' })
exports.loader=(fReply,req,data,match)->
   res={css:{},html:{},js:[]}
   prefix=match[1].split(':')
   if prefix.length>1
      config=JSON.parse(fs.readFileSync(PROJECT_PATH+'/application.json','utf-8'))
      try
         appName=prefix[1].split('?')[0]
         prefix=config.prefix[prefix[0]]
      catch e
         prefix='apps'
   else
      appName=prefix[0].split('?')[0]
      prefix='apps'
   appPath=PROJECT_PATH+'/'+prefix+'/'+appName
   console.log(appPath)
   dirList=fs.readdirSync(appPath)
   for fname in dirList
      filepath=appPath+'/'+fname
      ext=path.extname(fname)
      view=path.basename(fname, ext)
      if ext=='.js'
         res['js'].push(filepath.replace(PROJECT_PATH+'/','@')+'@:')#'@%s@%s:%s'%(path,request.uid,request.token))
      else if ext=='.css'
         res['css'][view]=fs.readFileSync(filepath,'utf-8')
      else if ext=='.jade'
         res['html'][view]=fs.readFileSync(filepath,'utf-8')
   fReply(JSON.stringify(res))
exports.script=(fReply,req,data,match)->
   fReply(fs.readFileSync(PROJECT_PATH+'/'+match[1],'utf-8'),200,{'Content-Type': 'application/javascript' })