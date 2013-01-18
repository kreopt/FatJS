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
        for i in [0..numCPUs]
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

        http.createServer(requestHandler).listen(PORT)
        sys.puts("Worker "+process.pid+" listerning port "+PORT);

exports.run=runserver
