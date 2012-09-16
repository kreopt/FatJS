window=self if not window?
##
# РАБОТА С URL: кодирование/декодирование объектов в/из строки URL
##
class URL
    # Разбор объекта и сериализация его в параметры URL
    # oSubObject - Объект для сериализации
    # sPrefix - Префикс сериализации. Помещается перед разобранной строкой.
    # Если префикс не пустой, сериализованный объект заключается в [квадратные скобки]
    encode:(oSubObject,sPrefix)->
        # Если объект - строка, сериализация не нужна
        return oSubObject if typeof oSubObject == typeof ''
        encoded=[]
        for keyIndex,subObject of oSubObject
            # Вычисление имени ключа с учетом префикса.
            keyName=if sPrefix then "#{sPrefix}[#{encodeURIComponent(keyIndex)}]" else encodeURIComponent(keyIndex)
            # Разбор узла дерева. Если значение примитивное, запоминаем строку key=val, иначе рекурсивно спускаемся по дереву
            encoded.push if typeof subObject != typeof {} then "#{keyName}=#{encodeURIComponent(subObject)}" else URL::encode(subObject,keyName)
        encoded.join('&')
    # Получение объекта из строки URL
    # sUrlStr - строка URL. Если sUrlStr не определена, берется текущая URL строка браузера.
    decode:(sUrlStr)->
        sUrlStr = window.location.href.slice(window.location.href.indexOf('?') + 1) if sUrlStr==undefined
        hashes=sUrlStr.split('&')
        vars={}
        # Разбор ключа, создание дерева объекта
        # sKey - ключ URL
        # oObject - объект, в который записывается разобранные значения
        # vValue - значение ключа, которое будет помещено в узел oObject, соответствующий ключу sKey
        parseKey=(sKey,oObject,vValue)->
            # Выбор следующего ключа для создания
            key=sKey.substr(0,sKey.indexOf('['))
            # Если sKey - не массив, записываем значение в oObject
            if !key
                oObject[sKey]=vValue
                return
            # Создаем узел key в объекте oObject
            oObject[key]={} if !oObject[key]?
            # Избавляемся от ] в отсавшейся неразобранной строке и продолжаем рекурсивную обработку
            unparsed=sKey.substr(sKey.indexOf('[')+1)
            parseKey(unparsed.substr(0,unparsed.indexOf(']'))+unparsed.substr(unparsed.indexOf(']')+1),oObject[key],vValue)
        # Разбор каждого хэша key=val
        for hash in hashes
            [key,val] = decodeURIComponent(hash).split('=');
            parseKey(key,vars,val)
        vars
##
# АСИНХРОННАЯ ПЕРЕДАЧА ДАННЫХ
##
class Ajax
    # Отправка GET-запроса на сервер
    # sUrl - URL, на который отправится запрос
    # oData - объект данных
    # fSuccess/fError - обработчики успешного/ошибочного запроса
    get:(sUrl,oData,fSuccess,fError)->Ajax::request('GET',sUrl,oData,fSuccess,fError)
    # Отправка POST-запроса на сервер
    # sUrl - URL, на который отправится запрос
    # oData - объект данных
    # fSuccess/fError - обработчики успешного/ошибочного запроса
    post:(sUrl,oData,fSuccess,fError)->Ajax::request('POST',sUrl,oData,fSuccess,fError)
    # Отправка запроса на сервер
    # sMethod - тип запроса (GET/POST)
    # sUrl - URL, на который отправится запрос
    # oData - объект данных
    # fSuccess/fError - обработчики успешного/ошибочного запроса
    request:(sMethod,sUrl,oData,fSuccess,fError)->
        request=new XMLHttpRequest()
        request.onreadystatechange=->
            if request.readyState == 4
                # Если не произошло ошибок на протокольном уровне, выполняем fSuccess, иначе fError
                handler=if request.status==200 then fSuccess else fError
                handler?(request)
        requestData=URL::encode oData
        # Если метод - GET, кладем данные с строку запроса
        if sMethod=='GET'
            sUrl+="?#{requestData}"
            requestData=null
        # Выполнение асинхронного запроса
        request.open(sMethod,sUrl,true);
        # Заголовок для POST
        request.setRequestHeader("Content-type", "application/x-www-form-urlencoded") if sMethod=='POST'
        request.send(requestData)
##
# ВЗАИМОДЕЙСТВИЕ С СЕРВЕРНЫМ API
##
class JAFW.API
    constructor:(@gatewayURL)->
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
        # TODO: сделать кроссдоменный запрос
        Ajax::post(@gatewayURL,sRequestData,successHandler,errorHandler)
    # API-вызов
    # sSignature - сигнатура нужного метода в формате Module.method
    # oArgs - параметры метода. Имена параметров должны начинаться с обозначения типа: [n=i=integer,f=float,s=string,o=complex object]
    call:(sSignature,oArgs,fSuccess,fError)->
        [module...,method]=sSignature.split(APP_DELIMITER)
        requestData=URL::encode {mod:module.join('.'),method:method,args:oArgs}
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
            [module...,method]=request[1].split(APP_DELIMITER)
            requests=requests.concat request[2].map (args)->{name:request[0],mod:module.join('.'),method:method,args:args}
        requestData=URL::encode {chain:1,requests:requests}
        @_sendRequest(requestData,fSuccess,fError)
JAFW.URL=URL
JAFW.Ajax=Ajax