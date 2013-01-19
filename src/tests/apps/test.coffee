testFunc=(responseCallback,data)->
    data.pid=process.pid
    responseCallback(data)
exports.testFunc=testFunc