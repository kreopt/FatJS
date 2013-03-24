domain=require("domain");
http = require('http');
url=require('url')
io = require('socket.io')

config={
   socketTransport:['websocket'],
   port:8000,
   httpHandler:->
   socketHandler:->
}
asyncCatch=(func)->
   F = ->
   dom = domain.create();
   dom.on "error",(err)->
      process.send(err.stack)
   dom.run ->func();

socketConnections={}

handleSignal=(signal)->

exports.start=(userConfig,ready)->
   for key,val of userConfig
      config[key]=val

   if typeof(config.httpHandler) =='string'
      try
         config.httpHandler=(req,res)->
            handler=require(process.cwd()+'/'+config.httpHandler).handler
            asyncCatch(->handler(req,res))
      catch e
         config.httpHandler=->
   if typeof(config.socketHandler) =='string'
      try
         config.socketHandler=require(process.cwd()+'/'+config.socketHandler).handler
      catch e
         config.socketHandler=->

   RedisStore = io.RedisStore
   srv=http.createServer(config.httpHandler)
   socket=io.listen(srv)
   socket.set('store', new RedisStore);
   socket.set('transports', config.socketTransport);
   socket.sockets.on 'connection', (client)->
      socketConnections[client.id]=client
      process.send('SOCK['+client.id+']: Connection')
      client.on 'message',(msg)->
         process.send('SOCK['+client.id+']: '+msg)
         asyncCatch(config.socketHandler)
      client.on 'disconnect',->
         delete socketConnections[client.id]
         process.send('disconnected');

   srv.listen(config.port)
   process.send("listerning port "+config.port);
   ready()
