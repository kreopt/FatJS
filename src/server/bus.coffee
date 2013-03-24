###
dbus=require('dbus-native')
bus=dbus.sessionBus()
dbusConn = bus.connection
name = 'org.inSide.bus';
bus.requestName(name, 0);
###
handlers={}

net = require('net');
# Временное решение, пока не ясно , почему не работает dbus

HOST="192.168.1.36"

###
dbusConn.on 'message', (msg) ->
   console.log(msg)
   if msg['interface']==name
      msg=JSON.parse(msg.body[0])
      sigName=msg.head.name
      if sigName of handlers
         handlers[sigName](msg.body,msg.head,msg.path.split('/').slice(1))
      else
         for handlerRE,handler of handlers
            if sigName.match(handlerRE)
               handler(msg.body,msg.head)
###

exports.send=(destination,msg,path=[])->
   try
      client = new net.Socket({type:'unix'});
      client.connect '/tmp/wtpProxy.sock', ->
         client.write(JSON.stringify(msg))
         client.end()

      ###
      dbusConn.message({
         "type":dbus.messageType.signal,
         "path": '/'+path.join('/'),
         "destination": destination,
         "interface": name,
         "member":'inSide'
         "signature": "s",
         "body": [
            JSON.stringify(msg)
         ]
      })
      ###
   catch ee
      console.log(ee);
exports.setHandler=(sigNameWildcard,handler)->
   pattern = '^';
   for i in sigNameWildcard
      c = sigNameWildcard.charAt(i);
      switch c
         when '?' then pattern += '.'
         when '*' then pattern += '.*'
         else
            pattern += c
   pattern += '$'
   handlers[pattern]=handler