##
# ВЗАИМОДЕЙСТВИЕ С СЕРВЕРНЫМ API
##

###
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
JAFW::__Register('WSAPI',WSAPI
###
class self.WebSocketBus extends IBus
   toString:->'WebSocketBus'
   constructor:(sUrl,fOnOpen)->
      @setupConnection(sUrl,fOnOpen)
      CONNECT 'WSAPI_REQUEST','apiRequest',@
   setupConnection: (sUrl,fOnOpen)->
      ###
         тело сигнала: {type:'signal',signal:'sigName',data:{},sender:senderId}
         Входящий сигнал: sig:bus.sockId.objId
      ###
      @remoteHandles={}
      @UID=JAFW.__nextID()
      @ws = io.connect(sUrl)
      @ws.on 'connect', =>
         console.debug('connected')
         @ws.send(JSON.stringify({type:'businit',uid:@UID}))
      @ws.on 'error', @stdError
      @ws.on 'message', (sMessage)=>
         msg=JSON.parse(sMessage)
         logDebug('RECV> ',msg)
         EMIT 'DEBUG', {body: msg}
         if msg.type == 'signal'
            #TODO: parseSender
            EMIT msg.signal,(if msg.data then msg.data else {}),msg.sender
         else if msg.type=='api'
            EMIT '=WSAPI_REQUEST',msg.data.data,msg.seq
         else if msg.type == 'error'
            EMIT 'ERROR', {body: msg.data}
         else if msg.type=='businit'
            @remoteHandles=msg.handles
            fOnOpen()
   sighandler:(signal)->
      if ('signal' of signal)
         if (signal.signal in @remoteHandles)
            logDebug('SEND> ',signal)
            @ws.send(JSON.stringify(signal))
      else
         console.error(signal)
         throw 'Bad signal'
   apiRequest:(oRequest)->
      if oRequest.type=='api'
         logDebug('SEND> ',oRequest)
         @ws.send(JSON.stringify(oRequest))
         return null
      else
         throw 'Bad API request'