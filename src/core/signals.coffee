registeredBuses = {}
class self.IBus
   constructor: ->
      errors=''
      if not @hasOwnProperty('sighandler')
         errors += 'sighandler property unimplemented!\n'
      if not @hasOwnProperty('setupConnection')
         errors += 'setupConnection property unimplemented!\n'
    #@setupConnection()
   setupConnection: ->
   sighandler: (signal)->
self.registerBus = (name, oBus)->
   registeredBuses[name] = oBus
self.getBus=(name)->
   registeredBuses[name]
###
    СИГНАЛЫ

    Именование:
        sigName ::= [typeDescriptor] [a-zA-Z._]+
        typeDescriptor ::= [=]{,1}
    Типы:
    sigName - простой сигнал, отправляется на локальные объекты, подписка является постоянной
    =sigName - временный сигнал. отправляется на локальные объекты, подписка уничтожается после вызова
    * - любой сигнал
###
#TODO: сигналы с ограниченным числом перехватов
signalModifiers = ['=', '*']
parseSignal = (sSignal)->
   [signal, emitter]=sSignal.split(':')
   name=signal.replace(new RegExp('[' + signalModifiers.join('') + ']'), '')
   modifier=if signal[0] in signalModifiers then signal[0] else ''
   return {name, emitter, modifier}
validateSignal = (sSignal)->
   if sSignal != '*'
      throw 'Bad signal name: ' + sSignal if not (sSignal.match('^[' + signalModifiers.join('') + ']?[a-zA-Z][a-zA-Z_.0-9]*$'))
# Таблица соединений сигналов и объектов
__connectionTable = {}
addConnection = (sSignal, sSlot, oReceiver, fSlot)->
   objectName=oReceiver.__id__
   __connectionTable[sSignal] = {} if not __connectionTable[sSignal]?
   __connectionTable[sSignal][objectName] = {instance: oReceiver, slots:
      {}} if not __connectionTable[sSignal][objectName]?
   if (fSlot)
      __connectionTable[sSignal][objectName].slots[sSlot] = fSlot
   else
      __connectionTable[sSignal][objectName].slots[sSlot] = oReceiver[sSlot]
   sSlot
removeConnection = (sSignal, sSlot, oReceiver)->
   objectName=oReceiver.__id__
   if sSignal == '*'
      for sig of __connectionTable
         delete __connectionTable[sig][objectName] if __connectionTable[sig] ? [objectName]?
      return

   if __connectionTable[sSignal] ? [objectName]?.slots[sSlot]
      delete __connectionTable[sSignal][objectName].slots[sSlot]
   else
      return
   if Object.keys(__connectionTable[sSignal][objectName].slots).length == 0
      delete __connectionTable[sSignal][objectName]
      if Object.keys(__connectionTable[sSignal]).length == 0
         delete __connectionTable[sSignal]
invoke = (sSignal, oData = {}, emitResult = false)->
   # TODO: отправлять на дочерние окна
   #[signal,uid]=sSignal.split(':')
   sigData=parseSignal(sSignal)
   temporary=(sigData.modifier == '=')
   invokeSlots=(connectionList)->
      for appName,connectionInfo of connectionList
         for slotName,slot of connectionInfo.slots
            name=if connectionInfo.instance.__app__ then connectionInfo.instance.__app__ + '.' + connectionInfo.instance.__name__ else connectionInfo.instance.toString()
            #console.debug('[' + new Date().toLocaleTimeString() + '] =INVOKE=  ' + name + '.' + slotName + '(' , oData , '):' + sigData.emitter)
            #fi DEBUG
            oData.__signal__ = sigData.name
            res=slot.call(connectionInfo.instance, oData, sigData.emitter)
            if sigData.emitter and emitResult and res isnt null
               EMIT '=' + sigData.name, res, sigData.emitter
            #Удаляем временные сигналы
            if temporary
               removeConnection('=' + sigData.name + (if sigData.emitter then ':' + sigData.emitter else ''), slotName, connectionInfo.instance)
      return
   # Локальная рассылка
   if __connectionTable[sSignal]
      invokeSlots(__connectionTable[sSignal])
   else if __connectionTable[sigData.modifier + sigData.name]
      invokeSlots(__connectionTable[sigData.modifier + sigData.name])

# Удалить подписку на сигнал
# sSignal - название сигнала
# sSlot - название обработчика сигнала
# oReceiver - объект, для которого выполнить отключение
self.DISCONNECT = (sSignal, sSlot, oReceiver, UID = null)->
   validateSignal(sSignal)
   sSignal += (':' + UID) if UID
   removeConnection(sSignal, sSlot, oReceiver)
# Подписать объект на сигнал. Возвращает название обработчика, которое можно использовать для отключение
# sSignal - название сигнала
# sSlot - название обработчика сигнала, содержащегося в oReceiver. Если sSlot - функция, генерируется уникальный ID
# oReceiver - объект, для которого выполнить подключение. oReceiver должен иметь свойство toString, возвращающее уникальное имя объекта
self.CONNECT = (sSignal, sSlot, oReceiver, UID = null)->
   validateSignal(sSignal)
   sSignal += (':' + UID) if UID
   # Если sSlot - функция, генерируем UID и подписываем объект на анонимную функцию
   if (typeof sSlot == typeof(->))
      fSlot=sSlot
      sSlot = inSide.__nextID()
   else
      if not oReceiver[sSlot]?
         console.log('failed to connect: '+sSignal+' -> '+sSlot)
         throw "No such slot: #{sSlot}"
   addConnection(sSignal, sSlot, oReceiver, fSlot)
# Порождение сигнала
# sSignal - название сигнала
# oArgs - параметры сигнала
# oSender - отправитель
self.EMIT = (sSignal, oArgs, oSender = null, emitResult = false)->
   #console.debug('[' + new Date().toLocaleTimeString() + '] =EMIT=    ' + sSignal + '(' , oArgs , '):' + if oSender then oSender.__id__ else '*')
   #fi DEBUG
   validateSignal(sSignal)
   sSignal = (sSignal + ':' + (if oSender.__id__? then oSender.__id__ else oSender.toString())) if oSender
   # Local bus
   invoke(sSignal, oArgs, emitResult)
   # External buses
   for busName,bus of registeredBuses
      bus.sighandler({type: 'signal', signal: sSignal, data: oArgs, sender: oSender})
self.EMIT_AND_WAIT = (oSender, sSignal, oArgs, sSlot)->
   sSignal.replace('=', '')
   validateSignal(sSignal)
   CONNECT('=' + sSignal, sSlot, oSender, oSender.__id__)
   EMIT(sSignal, oArgs, oSender, true)


self.INIT_CONNECTIONS = (scope, oConnections)->
   for signal, handler of oConnections
      CONNECT(signal, handler, scope)