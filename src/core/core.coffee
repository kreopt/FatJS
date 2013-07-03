if exports?
    self={}
else if window?
    self=window
self.logDebug=()->
   d=new Date()
   ms=d.getMilliseconds()
   args=['['+d.toLocaleTimeString()+'.'+ms+']']
   for arg in arguments
     args.push(arg)
   console.debug.apply(console,args)
DEBUG=0
# COMMON
class inSideCore
    _uids:{
      '$':0
    }
    _mods:{}
    _tpls:{}
    ##
    # Генератор уникальных в пределах сессии ID
    ##
    __nextID:(seqName='$')->
       inSideCore::_uids[seqName]=0 if not inSideCore::_uids[seqName]
       inSideCore::_uids[seqName]++
    ##
    # Регистрация модулей
    ##
    __Register:(modName,module)->
        if modName in inSideCore::_mods
            throw('Module already registered')

        inSideCore::_mods[modName]=new module()
        Object.defineProperty(inSideCore::,modName,{
            get:->inSideCore::_mods[modName]
        })

class Task
   create:(workerFunc, callback)->
      worker = new Worker(window.URL.createObjectURL(new Blob(['('+workerFunc.toString()+')()'], { "type" : "text\/javascript" })))
      worker.onmessage = (event)->
         callback(event.data)
      return worker

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
        return {} if not sUrlStr
        sUrlStr = self.location.href.slice(self.location.href.indexOf('?') + 1) if sUrlStr==undefined
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

###
#TODO: сигналы с ограниченным числом перехватов
signalModifiers=['=','*']
parseSignal=(sSignal)->
    [signal,emitter]=sSignal.split(':')
    name=signal.replace(new RegExp('['+signalModifiers.join('')+']'),'')
    modifier=if signal[0] in signalModifiers then signal[0] else ''
    return {name,emitter,modifier}
validateSignal=(sSignal)->
    if sSignal!='*'
        throw 'Bad signal name: '+sSignal if not (sSignal.match('^['+signalModifiers.join('')+']?[a-zA-Z][a-zA-Z_.]*$'))
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
invoke=(sSignal,oData={},emitResult=false)->
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
                oData.__signal__=sigData.name
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
        sSlot=inSide.__nextID()
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

class Signal
    constructor:(@context,@name,@maxHandlers=-1)->@
    setMaxHandlers:(@maxHandlers=-1)->@
    tunnel:(@tunnelName)->@
    emit:(args)->EMIT(@name,args);return @
    emitAndWait:(args)->EMIT_AND_WAIT(@context,@name,args,@name+'=');return @
    _serialize:()->
class SigHandler
    constructor:(@context,@sigName,@handler)->
    _deserialize:()->
###
inSideCore::__Register('Task',Task)
inSideCore::__Register('Url',URL)
#inSideCore::__Register('Signal',Signal)

if not exports?
    #inSideCore::RenderEngine=new jSmart()
    inSideCore::RenderEngine={
        _tpl:{}
        loadTemplate:(name,tpl)->
            try
                @_tpl[name]=jade.compile(tpl,{compileDebug:false})
            catch e
                console.error('Failed to compile template: '+name)
                throw e
        render:(name,args={})->
            try
                @_tpl[name](args)
            catch e
                console.error('Failed to render template: '+name)
                throw e
    }

self.inSide=new inSideCore()
# nodejs
if exports?
    exports.inSide=self.inSide
