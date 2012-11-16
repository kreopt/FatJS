##
# SESSION
##
class JAFW.Session
    constructor:->
        for data,storageIndex of sessionStorage
            sessionStorage.removeItem(storageIndex) if storageIndex.indexOf('__TPL__')!=-1
    _storageName:(sParamName,sNamespace)->
        'ns:'+(if sNamespace then sNamespace else 'global')+':'+sParamName
    get:(sParameter,sNamespace)->
        storageName=@_storageName(sParameter,sNamespace)
        res=sessionStorage[storageName]
        if res isnt null
            res=if (res is "undefined" or res is undefined) then undefined else JSON.parse(res)
        res
    set:(sParameter,oValue,sNamespace)->
        storageName=@_storageName(sParameter,sNamespace)
        sessionStorage[storageName]=JSON.stringify(oValue)
    remove:(sParameter)->
        sessionStorage.removeItem(sParameter)
    clear:->sessionStorage.clear()
