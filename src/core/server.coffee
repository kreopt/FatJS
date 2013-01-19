sys=require('sys')
path = require('path');
cluster = require('cluster');
http = require('http');
url=require('url')
numCPUs = require('os').cpus().length;
core=require('./core')
PORT=8000

runserver=(router)->
    if (cluster.isMaster)
        for i in [0...numCPUs]
            cluster.fork()
        cluster.on 'exit', (worker, code, signal)->
            console.log('worker ' + worker.process.pid + ' died')
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
                console.log("Received POST data chunk '"+postDataChunk + "'.");
            responseCallback=(result)->makeResponse(response,result)
            request.addListener "end", ->
                try
                    router.handle(request,responseCallback,core.jawf.Url.decode(postData))
                catch exception
                    console.log(exception.stack)
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
            console.log('Connection..')
            client.on 'message',(event)->
                console.log('Socket '+process.pid+' received data: ',event);
                router.handleSocket(event,(data)->client.send(data))
            client.on 'disconnect',->
                console.log('Socket '+process.pid+' has disconnected');
        sys.puts("Worker "+process.pid+" listerning port "+PORT);

exports.run=runserver
