exports.testFunc=(responseCallback,data)->
    data.pid=process.pid
    responseCallback(data)