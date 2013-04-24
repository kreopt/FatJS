##
# SESSION
##
class inSide.Session
   constructor : (type = 'local', ns = 'global')->
      @storage = if type == 'local' then localStorage else sessionStorage
      @ns = ns
   _storageName : (sParamName, sNamespace)->
      (if sNamespace then sNamespace else @ns) + ':' + sParamName
   get : (sParameter, sNamespace)->
      storageName=@_storageName(sParameter, sNamespace)
      res=@storage[storageName]
      if res isnt null
         res = if (res is "undefined" or res is undefined) then undefined else JSON.parse(res)
      res
   set : (sParameter, oValue, sNamespace)->
      storageName=@_storageName(sParameter, sNamespace)
      @storage[storageName] = JSON.stringify(oValue)
   remove : (sParameter, sNamespace)->
      @storage.removeItem(@_storageName(sParameter, sNamespace))
   clear : ->@storage.clear()
