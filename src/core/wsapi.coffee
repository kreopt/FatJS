##
# ВЗАИМОДЕЙСТВИЕ С СЕРВЕРНЫМ API
##
class WSAPI
    constructor:()->
        @CONNECT 'SERVER_REQUEST','_sendRequest',@
    open:(sUrl,secure=false,fOnOpen)->
        @ws=new WebSocket((if secure then 'wss://' else 'ws://') + window.location.host+':'+window.location.port+'/'+sUrl)
        @ws.onopen=fOnOpen
        @ws.onerror=@stdError
        @ws.onmessage=(sMessage)->
            msg=JSON.parse(sMessage)
            EMIT msg.signal,if msg.body then msg.body else {}
        # Стандартный обработчик ошибок
    stdError:(oResponse)->
        DEBUG(oResponse)
    onBeforeSend:(oRequest)->oRequest
    _sendRequest:(oRequest)->
        if 'signal' of oRequest
            realRequest={signal:oRequest.signal,body:if oRequest.body then oRequest.body else {}}
            realRequest=@onBeforeSend(realRequest)
            @ws.send(JSON.stringify(realRequest))
        else
            throw 'Bad server request'
JAFWCore::__Register('WSAPI',WSAPI)