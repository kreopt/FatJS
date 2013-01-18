PORT=8000
sys = require("sys")
my_http = require("http")
url=require('url')
core=require('./core')
makeResponse=(response,result)->
    response.writeHead(200, {"Content-Type": "text/plain"});
    response.write(result);
    response.end()
runserver=(router)->
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

    my_http.createServer(requestHandler).listen(PORT);
sys.puts("Server running on "+PORT);

exports.run=runserver
