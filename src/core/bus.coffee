class RemoteBus
    constructor:(sConnectionString)->
    postData:(oMessage)->
inSide.signal={
    meta:{OID:'ObjectID',BID:'BusID'},
    name:'SignalName',
    data:{},
    ext:{}
}
class inSide.Bus
    constructor:->
        @__services=[]
        @__buses=[]
        @__connectionTable={}
    # Расширяет функционал шины сервисом, реализующем инферфейс IBusService
    extend:(oService)->@__services.push(oService)
    # Вызов цепочки сервисов для обработки данных
    __callServices:(sMethodName,oData)->
        result=oData
        if @__services.length
            for serviceIndex in [@__services.length-1..0]
                if @__services[serviceIndex][sMethodName]
                    result=@__services[serviceIndex][sMethodName](result)
        return result
    # Добавляет связь с другой шиной по ее имени
    connect:(sConnectionString)->
        bus=new RemoteBus(sConnectionString)
        @__buses.push(bus) if bus
    # Пересылает сообщение связанным шинам
    __resend:(oMessage)->
        # Предварительная подготовка сообщения к отправке
        oMessage=@__callServices 'resend_PreDispatch', oMessage
        @__buses.forEach (bus)->
            # Выбор шины для отправки. Отправка не производится, если результат - false
            @::__sendToBus(bus,oMessage) if @__callServices 'resend_SelectBus', bus
    # Отправка данных на шину oBus
    __sendToBus:(oRemoteBus,oMessage)->
        # Подготовка к отправке на шину
        oMessage=@__callServices 'resend_PostDispatch', {bus:oRemoteBus,message:oMessage}
        # Отправка данных
        oRemoteBus.postData(oMessage)
    # Обработка полученного сигнала
    handleSignal:(oMessage,isRemote=false)->
        # TODO: send to objects
        @__callServices 'handleSignal_SelectObject', oMessage
        @__resend(oMessage) if not isRemote


