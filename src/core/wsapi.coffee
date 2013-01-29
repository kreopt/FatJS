##
# ВЗАИМОДЕЙСТВИЕ С СЕРВЕРНЫМ API
##
class WSAPI
    constructor:()->
        CONNECT 'SERVER_REQUEST','sendRequest',@
    open:(sUrl,secure=false,fOnOpen)->
        @ws=io.connect((if secure then 'wss://' else 'ws://') + window.location.host+'/'+sUrl)
        @ws.on 'connect',fOnOpen
        @ws.on 'error',@stdError
        @ws.on 'message',(sMessage)->
            msg=JSON.parse(sMessage)
            EMIT 'DEBUG',{body:msg}
            if msg.type=='signal'
                EMIT msg.signal,if msg.data then msg.data else {}
            else if msg.type=='error'
                EMIT 'ERROR',{body:msg.data}
        # Стандартный обработчик ошибок
    stdError:(oResponse)->EMIT 'DEBUG',{body:oResponse}
    onBeforeSend:(oRequest)->oRequest
    sendRequest:(oRequest)->
        if 'signal' of oRequest
            realRequest={signal:oRequest.signal,body:if oRequest.body then oRequest.body else {}}
            realRequest=@onBeforeSend(realRequest)
            @ws.send(JSON.stringify(realRequest))
        else
            throw 'Bad server request'
JAFW::__Register('WSAPI',WSAPI)