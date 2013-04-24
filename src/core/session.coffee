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
   clearNS: (sNamespace)->
      toDel=[]
      for rec of @storage
         if rec.indexOf(sNamespace+':')==0
            toDel.push(rec)
      for rec in toDel
         @storage.removeItem(rec)
   clear : ->@storage.clear()
