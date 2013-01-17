signalModifiers=['@','=','*']
parseSignal=(sSignal)->
    [signal,emitter]=sSignal.split(':')
    name=signal.replace(new RegExp('['+signalModifiers.join('')+']'),'')
    modifier=if signal[0] in signalModifiers then signal[0] else ''
    return {name,emitter,modifier}
validateSignal=(sSignal)->
    if sSignal!='*'
        assert(sSignal.match('^['+signalModifiers.join('')+']?[a-zA-Z][a-zA-Z_.]*$'),'Bad signal name: '+sSignal)
# Таблица соединений сигналов и объектов
__connectionTable={}
addConnection=(sSignal,sSlot,oReceiver,fSlot)->
    objectName=oReceiver.toString()
    __connectionTable[sSignal]={} if not __connectionTable[sSignal]?
    __connectionTable[sSignal][objectName]={instance:oReceiver,slots:{}} if not __connectionTable[sSignal][objectName]?
    if (fSlot)
        __connectionTable[sSignal][objectName].slots[sSlot]=fSlot
    else
        __connectionTable[sSignal][objectName].slots[sSlot]=oReceiver[sSlot]
    sSlot
removeConnection=(sSignal,sSlot,oReceiver)->
    objectName=oReceiver.toString()
    if sSignal=='*'
        for sig of __connectionTable
            delete __connectionTable[sig][objectName] if __connectionTable[sig]?[objectName]?
        return

    if __connectionTable[sSignal]?[objectName]?.slots[sSlot]
        delete __connectionTable[sSignal][objectName].slots[sSlot]
    else
        return
    if Object.keys(__connectionTable[sSignal][objectName].slots).length==0
        delete __connectionTable[sSignal][objectName]
        if Object.keys(__connectionTable[sSignal]).length==0
            delete __connectionTable[sSignal]
invoke=(sSignal,oData,emitResult=false)->
    # Глобальная рассылка (не только на клиент, но и на сервер и дочерние окна)
    if sSignal[0]=='@'
        sSignal=sSignal[1..]
        api.call sSignal, oData,(oResponseSignal)->
            if oResponseSignal
                EMIT(oResponseSignal.name,oResponseSignal.data)
    # TODO: отправлять на дочерние окна
    #[signal,uid]=sSignal.split(':')
    sigData=parseSignal(sSignal)
    temporary=(sigData.modifier=='=')
    invokeSlots=(connectionList)->
        for appName,connectionInfo of connectionList
            for slotName,slot of connectionInfo.slots
                if DEBUG
                    console.log('['+new Date().toLocaleTimeString()+'] =INVOKE=  '+connectionInfo.instance.__app__+'.'+connectionInfo.instance.__name__+'.'+slotName+'('+JSON.stringify(oData)+'):'+sigData.emitter)
                #fi DEBUG
                res=slot.call(connectionInfo.instance,oData,sigData.emitter)
                if sigData.emitter and emitResult and res isnt null
                    EMIT '='+sigData.name,res,sigData.emitter
                #Удаляем временные сигналы
                if temporary
                    removeConnection('='+sigData.name+(if sigData.emitter then ':'+sigData.emitter else ''),slotName,connectionInfo.instance)
        return
    # Локальная рассылка
    if __connectionTable[sSignal]
        invokeSlots(__connectionTable[sSignal])
    else if __connectionTable[sigData.modifier+sigData.name]
        invokeSlots(__connectionTable[sigData.modifier+sigData.name])

# Удалить подписку на сигнал
# sSignal - название сигнала
# sSlot - название обработчика сигнала
# oReceiver - объект, для которого выполнить отключение
self.DISCONNECT=(sSignal,sSlot,oReceiver,UID=null)->
    validateSignal(sSignal)
    sSignal+=(':'+UID) if UID
    removeConnection(sSignal,sSlot,oReceiver)
# Подписать объект на сигнал. Возвращает название обработчика, которое можно использовать для отключение
# sSignal - название сигнала
# sSlot - название обработчика сигнала, содержащегося в oReceiver. Если sSlot - функция, генерируется уникальный ID
# oReceiver - объект, для которого выполнить подключение. oReceiver должен иметь свойство toString, возвращающее уникальное имя объекта
self.CONNECT=(sSignal,sSlot,oReceiver,UID=null)->
    validateSignal(sSignal)
    sSignal+=(':'+UID) if UID
    # Если sSlot - функция, генерируем UID и подписываем объект на анонимную функцию
    if (typeof sSlot == typeof(->))
        fSlot=sSlot
        sSlot=JAFW.__nextID()
    else
        throw "No such slot: #{sSlot}" if not oReceiver[sSlot]?
    addConnection(sSignal,sSlot,oReceiver,fSlot)
# Порождение сигнала
# sSignal - название сигнала
# oArgs - параметры сигнала
# oSender - отправитель
self.EMIT=(sSignal,oArgs,oSender=null,emitResult=false)->
    if DEBUG
        console.log('['+new Date().toLocaleTimeString()+'] =EMIT=    '+sSignal+'('+JSON.stringify(oArgs)+'):'+if oSender then oSender.__id__ else '*')
    #fi DEBUG
    validateSignal(sSignal)
    sSignal=(sSignal+':'+(if oSender.__id__? then oSender.__id__ else oSender.toString())) if oSender
    invoke(sSignal,oArgs,emitResult)
self.EMIT_AND_WAIT=(oSender,sSignal,oArgs,sSlot)->
    sSignal.replace('=','')
    validateSignal(sSignal)
    CONNECT('='+sSignal,sSlot,oSender,oSender.__id__)
    EMIT(sSignal,oArgs,oSender,true)
