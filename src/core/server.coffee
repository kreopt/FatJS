sys=require('sys')
path = require('path');
cluster = require('cluster');
http = require('http');
url=require('url')
numCPUs = require('os').cpus().length;
core=require('./core')

PORT=8000

runserver=(router,options)->
    PORT=options.port if options.port?
    if (cluster.isMaster)
        for i in [0...numCPUs]
            cluster.fork()
        cluster.on 'exit', (worker, code, signal)->
            console.warn('worker ' + worker.process.pid + ' died')
    else
        makeResponse=(response,result)->
            response.writeHead(200, {"Content-Type": "text/plain"});
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
            responseCallback=(result)->makeResponse(response,result)
            request.addListener "end", ->
                try
                    router.handle(request,responseCallback,core.jawf.Url.decode(postData))
                catch exception
                    console.error(exception.stack)
                    response.writeHead(500, {"Content-Type": "text/plain"});
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
                    router.handleSocket(event,(data)->client.send(data))
                catch exception
                    console.error(exception.stack)
                    client.send({error:exception.stack})
            client.on 'disconnect',->
                console.warn('Socket '+process.pid+' has disconnected');
        sys.puts("Worker "+process.pid+" listerning port "+PORT);

exports.run=runserver
