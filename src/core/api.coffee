##
# ВЗАИМОДЕЙСТВИЕ С СЕРВЕРНЫМ API
##
class API
    constructor:()->
    setUrl:(@gatewayURL)->
    # Стандартный обработчик ошибок
    stdError:(oResponse)->
        DEBUG(oResponse)
    # Отправка запроса, подготовленного в call или chain
    _sendRequest:(sRequestData,fSuccess,fError)->
        if not fError?
            fError=@stdError
        successHandler=(oRequest)->
            result=JSON.parse(oRequest.responseText)
            # Проверка на наличие ошибок на прикладном уровне
            handler=if result.status==0 then fSuccess else fError
            handler?(result.data)
        errorHandler=(oRequest)->fError?(oRequest.statusText)
        JAFW.Ajax.post(@gatewayURL,sRequestData,successHandler,errorHandler)
    # API-вызов
    # sSignature - сигнатура нужного метода в формате Module.method
    # oArgs - параметры метода. Имена параметров должны начинаться с обозначения типа: [n=i=integer,f=float,s=string,o=complex object]
    call:(sSignature,oArgs,fSuccess,fError)->
        [module...,method]=sSignature.split('.')
        requestData={mod:module.join('.'),method:method,args:oArgs}
        requestData=@onBeforeSend(requestData) if @onBeforeSend?
        requestData=JAFW.Url.encode requestData
        @_sendRequest(requestData,fSuccess,fError)
    # Цепочечный вызов API-функций. Вызовы происходят в порядке следования в oRequests
    # oRequests - массив вида [[sName,sSignature,[oArgs1,oArgs2,..]],..]. Каждый массив в массиве oRequests задает
    # вызов одной функции с разными наборами аргументов. Например, ['tplTest','Template.get',['index','list']] выполнит
    # два вызова: Template.get('index') и Template.get('list'). Результаты вызова доступны в oResponse.tplTest[0] и
    # oResponse.tplTest[1]
    # fSuccess/fError - обработчики успешного/ошибочного запросов
    chain:(oRequests,fSuccess,fError)->
        requests=[]
        oRequests.forEach (request)->
            [module...,method]=request[1].split('.')
            requests=requests.concat request[2].map (args)->{name:request[0],mod:module.join('.'),method:method,args:args}
        requestData={chain:1,requests:requests}
        requestData=@onBeforeSend(requestData) if @onBeforeSend?
        requestData=JAFW.Url.encode requestData
        @_sendRequest(requestData,fSuccess,fError)
JAFWCore::__Register('API',API)