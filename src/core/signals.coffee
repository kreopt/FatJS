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
    if __connectionTable[sSignal]?[objectName]?.slots[sSlot]
        delete __connectionTable[sSignal][objectName].slots[sSlot]
    else
        return
    if Object.keys(__connectionTable[sSignal][objectName].slots).length==0
        delete __connectionTable[sSignal][objectName]
        if Object.keys(__connectionTable[sSignal]).length
            delete __connectionTable[sSignal]
invoke=(sSignal,oData)->
    # Глобальная рассылка (не только на клиент, но и на сервер и дочерние окна)
    if sSignal[0]=='@'
        sSignal=sSignal[1..]
        api.call sSignal, oData,(oResponseSignal)->
            if oResponseSignal
                EMIT(oResponseSignal.name,oResponseSignal.data)
        # TODO: отправлять на дочерние окна
    # Локальная рассылка
    if __connectionTable[sSignal]
        for appName,connectionInfo of __connectionTable[sSignal]
            for slotName,slot of connectionInfo.slots
                slot.call(connectionInfo.instance,oData)

# Удалить подписку на сигнал
# sSignal - название сигнала
# sSlot - название обработчика сигнала
# oReceiver - объект, для которого выполнить отключение
window.DISCONNECT=(sSignal,sSlot,oReceiver)->
    removeConnection(sSignal,sSlot,oReceiver)
# Подписать объект на сигнал. Возвращает название обработчика, которое можно использовать для отключение
# sSignal - название сигнала
# sSlot - название обработчика сигнала, содержащегося в oReceiver. Если sSlot - функция, генерируется уникальный ID
# oReceiver - объект, для которого выполнить подключение. oReceiver должен иметь свойство toString, возвращающее уникальное имя объекта
window.CONNECT=(sSignal,sSlot,oReceiver)->
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
window.EMIT=(sSignal,oArgs,oSender)->
    invoke(sSignal,oArgs,oSender)