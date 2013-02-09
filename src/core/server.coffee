sys=require('sys')
path = require('path');
cluster = require('cluster');
http = require('http');
url=require('url')
numCPUs = require('os').cpus().length;
core=require('./core')
domain=require("domain");

asyncCatch=(func)->
   F = ->
   dom = domain.create();
   F::catch = (errHandle)->
      args = arguments;
      dom.on "error",(err)->return errHandle(err)
      dom.run ->func.call(null,args);
      return this;
   return new F();
runserver=(router,options)->
    PORT=options.port if options.port?
    if (cluster.isMaster)
        for i in [0...numCPUs]
            cluster.fork()
        cluster.on 'exit', (worker, code, signal)->
            console.warn('worker ' + worker.process.pid + ' died')
    else
        makeResponse=(response,result,status,head)->
            response.writeHead(status, head);
            response.write(result);
            response.end()
        requestHandler=(request,response)->
            d=new Date()
            console.log('['+d.toLocaleDateString()+' '+d.toLocaleString()+']'+url.parse(request.url).pathname);

            postData=''
            request.setEncoding("utf8");
            request.addListener "data", (postDataChunk)->
                postData += postDataChunk;
                console.info("Received POST data chunk '"+postDataChunk + "'.");
            responseCallback=(result,status=200,head={"Content-Type": "text/plain"})->
               asyncCatch(->makeResponse(response,result,status,head)).catch((e)->makeResponse(response,JSON.stringify({type:'error',data:e.stack}),status,head))
            request.addListener "end", ->
                try
                    router.handle(request,responseCallback,postData)
                catch exception
                    console.error(exception.stack)
                    response.writeHead(500, {"Content-Type": "text/html"});
                    response.write('INTERNAL SERVER ERROR');
                    response.end()

        io = require('socket.io')
        RedisStore = io.RedisStore
        srv=http.createServer(requestHandler)
        socket=io.listen(srv)
        socket.set('store', new RedisStore);
        socket.set('transports', ['websocket']);
        srv.listen(PORT)
        socket.sockets.on 'connection', (client)->
            console.info('Connection..')
            client.on 'message',(event)->
                console.info('Socket '+process.pid+' received data: ',event);
                try
                   handleRequest=->router.handleSocket(event,(data)->
                      client.send(data)
                      throw 'NOERROR'
                   )
                   asyncCatch(handleRequest).catch((e)->
                      return if e=='NOERROR'
                      console.log(e.stack)
                      #client.send(JSON.stringify({type:'error',data:e.stack}))
                   )
                catch exception
                    return if exception=='NOERROR'
                    console.log(exception.stack)
                    #client.send({type:'error',data:exception.stack})
            client.on 'disconnect',->
                console.warn('Socket '+process.pid+' has disconnected');
        sys.puts("Worker "+process.pid+" listerning port "+PORT);

exports.run=runserver
