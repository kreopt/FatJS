net=require('net')
fs=require('fs')

class exports.Bus
   constructor:(@__name__)->
      throw('Bus name does not match [A-Za-z0-9][A-Za-z0-9.]+') if not @__name__ or (not @__name__.match(/[A-Za-z0-9][A-Za-z0-9.]+/))
      @sighandlers={}
      @connTableCache={}

   dumpConnectionTable:(busName)->
      #TODO: lock connection table
      connTable=@loadConnectionTable()
      for signal of @sighandlers
         connTable[signal]={} if not connTable[signal]?
         connTable[signal][busName]={}
      for signal of connTable
         for bus of connTable[signal]
            if bus == busName and signal not of @sighandlers
               delete connTable[signal][bus]
            if not Object.keys(connTable[signal]).length
               delete connTable[signal]
      fs.writeFileSync('/tmp/inSide_connectionTable.json',JSON.stringify(connTable),'utf8')
   loadConnectionTable:->
      try
         @connTableCache=JSON.parse(fs.readFileSync('/tmp/inSide_connectionTable.json','utf-8'))
      catch e
         @connTableCache={}
      return @connTableCache
   close:->
      @__bus__.close()
   listen:(success,error)->
      @__bus__ = new net.createServer (client)=>
         sigData=[]
         client.on 'data', (data)->
            sigData.push(new Buffer(data, 'binary'))
         client.on 'end', =>
            @parseSignal(Buffer.concat(sigData))

      reconnect= =>
         @__bus__.close();
         @__bus__.listen("/tmp/inSide_#{@__name__}.sock");
      @__bus__.on 'close',=>
         @sighandlers={}
         @dumpConnectionTable(@__name__)
      @__bus__.on 'listening', =>
         @dumpConnectionTable(@__name__)
         success?()
      @__bus__.on 'error', (e)->
         if e.code == 'EADDRINUSE'
            console.log('Address in use, retrying...');
            setTimeout(reconnect, 1000);
      @__bus__.listen("/tmp/inSide_#{@__name__}.sock")
   parseSignal:(sigBuffer)->
      signal=JSON.parse(sigBuffer.toString('utf8'))
      if signal.name of @sighandlers
         for handler of @sighandlers[signal.name]
            @sighandlers[signal.name][handler](signal)
   send:(busName,signal)->
      client = new net.Socket({type:'unix'});
      client.connect "/tmp/inSide_#{busName}.sock", ->
         client.write(JSON.stringify(signal))
         client.end()
   emit:(signal)->
      connTable=@loadConnectionTable()
      if signal.name of connTable
         for busName of connTable[signal.name]
            @send(busName,signal)
   connect:(signal,handlerName,handler)->
      @sighandlers[signal]={} if not @sighandlers[signal]?
      @sighandlers[signal][handlerName]=handler
      @dumpConnectionTable(@__name__)
   disconnect:(signal,handlerName)->
      delete @sighandlers[signal][handlerName]
###
bus=new exports.Bus('testBus')
bus1=new exports.Bus('testBus1')
bus.listen ->
   console.log('ok')
   bus.connect('test.bus.signal','handler',(signal)->console.log(signal))
bus1.listen ->
   console.log('ok1')
   setTimeout (->bus1.emit({name:'test.bus.signal',head:{},body:{}})),500
process.on 'SIGINT', ->
   console.log("Signal: SIGINT")
   bus.close()
   bus1.close()

process.on 'SIGTERM', ->
   console.log("Signal: SIGTERM");
   bus.close()
   bus1.close()
###