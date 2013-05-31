##
# ВЗАИМОДЕЙСТВИЕ С СЕРВЕРНЫМ API
##
class self.WebSocketBus extends IBus
   toString:->'WebSocketBus'
   constructor:(sUrl,fOnOpen)->
      @rhandlers={}
      @handlers={}
      @setupConnection(sUrl,fOnOpen)
      @busInitialized=false
      CONNECT 'WSAPI_REQUEST','apiRequest',@
   setupConnection: (sUrl,fOnOpen)->
      ###
         тело сигнала: {type:'signal',signal:'sigName',data:{},sender:senderId}
         Входящий сигнал: sig:bus.sockId.objId
      ###
      @remoteHandles={}
      @busy=false
      @queue=[]
      @head={}
      @UID=inSide.__nextID()
      @reconnect(sUrl, fOnOpen)
   reconnect:(sUrl, fOnOpen)->
      @ws = new WebSocket(sUrl)

      @ws.onopen = =>
         console.debug('connected')
         if not @busInitialized
            @ws.send(JSON.stringify({type:'businit',uid:@UID}))
            @busInitialized=true

      @ws.onclose = =>
         console.log('Соединение потеряно, восстанавливаем...')
         setTimeout((=>@reconnect(sUrl, fOnOpen)),1000)

      @ws.onmessage = (evt)=>
         msg=JSON.parse(evt.data)
         logDebug('RECV> ',msg)
         EMIT 'DEBUG', {body: msg}
         if msg.type == 'signal'
            #TODO: parseSender
            EMIT msg.name,(if msg.body then msg.body else {}),msg.sender
         else if msg.type=='api'
            @busy=false
            #EMIT '=WSAPI_REQUEST',{status:0,data:msg.data},msg.seq
            @rhandlers[Number(msg.seq)].success({status:0,data:msg.data})
            delete @rhandlers[Number(msg.seq)]
            if @queue.length
               req=@queue.shift()
               if req
                  @apiRequest2(req,@rhandlers[Number(req.seq)].success,@rhandlers[Number(req.seq)].error)
         else if msg.type == 'error'
            EMIT 'ERROR', {body: msg.data}
            if msg.errtype=='api'
               @busy=false
               #EMIT '=WSAPI_REQUEST',{status:1,data:msg.data},msg.seq
               @rhandlers[Number(msg.seq)].error?({status:1,data:msg.data})
               delete @rhandlers[Number(msg.seq)]
               if @queue.length
                  req=@queue.shift()
                  if req
                     @apiRequest2(req,@rhandlers[Number(req.seq)].success,@rhandlers[Number(req.seq)].error)
         else if msg.type=='businit'
            @remoteHandles=msg.handles
            fOnOpen()
         else if msg.type of @handlers
               @handlers[msg.type](msg)
   addHandler:(type,handler)->
      @handlers[type]=handler
   sighandler:(signal)->
      if ('signal' of signal)
         if (signal.signal in @remoteHandles)
            logDebug('SEND> ',signal)
            @ws.send(JSON.stringify(signal))
      else
         console.error(signal)
         throw 'Bad signal'
   apiRequest:(oRequest)->
      oRequest.type='signal'
      oRequest.head=@head
      logDebug('SEND> ',oRequest)
      @ws.send(JSON.stringify(oRequest))
      return null
   apiRequest2:(oRequest, success, error)->
      @rhandlers[Number(oRequest.seq)]={success,error}
      if not @busy
         oRequest.head=@head
         @busy=true
         logDebug('SEND> ',oRequest)
         @ws.send(JSON.stringify(oRequest))
      else
         @queue.push(oRequest)
