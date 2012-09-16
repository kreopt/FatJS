window=self if not window?
##
# Генератор уникальных в пределах сессии ID
##
UID=0
JAFW.nextID=->UID++
JAFW.DEBUG=true
window.DEBUG=if JAFW.DEBUG then (args...)->console?.log?.apply?(console,args) else ->
window.assert=if JAFW.DEBUG then (args...)->console?.assert?.apply?(console,args) else ->
##
# АСИНХРОННОЕ ДИНАМИЧЕСКОЕ ПОДКЛЮЧЕНИЕ СКРИПТОВ
##

# Функция импорта скриптов
# oScriptArray - массив массивов независимо загружаемых скриптов [['script1','script2'],['script2'],...]
# sPath - относительный путь, откуда будут загружаться скрипты. (относительло JAFW.ScriptPath)
# fAfterLoad - функция, которая будет вызвана после загрузки скриптов
window.IMPORT=(oScriptArray,sPath,fAfterLoad)->
    # Если загружать больше нечего, вызываем fAfterLoad
    if oScriptArray.length==0
        fAfterLoad?()
    else
        # Берем первый массив независимых скриптов и загружаем его
        loadScripts oScriptArray[0],sPath,->
            DEBUG('Loaded from path %s: %o',sPath,oScriptArray[0])
            # Удаляем массив из массива необходимой загрузки
            oScriptArray.shift()
            # Загружаем остальные скрипты
            IMPORT(oScriptArray,sPath,fAfterLoad)
# Функция загрузки CSS
# oЫендуArray - массив загружаемых стилей
# sPath - относительный путь, откуда будут загружаться стили. (относительло JAFW.StylePath)
# sId - id, который будет присвоен стилю(в свойстве class). Отражает принадлежность приложению
window.IMPORTCSS=(oStyleArray,sPath,sId)->
    loadStyes oStyleArray,sId,sPath
# Сюда складывается количество необходимых для загрузки сущностей
needToLoad={}
# Обработчик загрузки сущности
# sId - идентификотор загрузки
# fCallback - функция, вызываемая после окончания загрузки
# args.. - аргумены функции
loaderCallNext=(iId,fCallback,args...)->
    # Если серия загрузок под этим id закончена, вызываем нудную функцию,
    # иначе уменьшаем на единицу количество необходимых загрузок
    if --needToLoad[iId] is 0
        delete needToLoad[iId]
        fCallback?.apply?(null,args)
# Запрос на загрузку сущностей
# fLoadMethod - функция-загрузчик сущности
# sPath - относительный путь загрузки
# oData - список сущностей для загрузки
# fCallback - функция, вызываемая после окончания загрузки
loaderRequest=(fLoadMethod,sPath,oData,fCallback)->
    # id сессии загрузки
    id=JAFW.nextID()
    needToLoad[id]=oData.length
    oData.forEach (request)->fLoadMethod("#{sPath}/#{request}",id)
    # Если загружать нечего, сразу выполняем функцию
    fCallback?() if not oData.length
scripts={}
styles={}
# Загрузчик скриптов
# oRequest - список загружаемых скриптов
# fCallback - функция, вызываемая после окончания загрузки
loadScripts=(oRequest,sPath,fCallback)->
    loadMethod=(sPath,iId)->
        # Если скрипт уже загружен, переходим к следующему
        if scripts[sPath]?
            loaderCallNext(iId,fCallback)
        else
            script=document.createElement('script')
            script.src="#{sPath}.js"
            script.id='SCR_'+sPath.replace(/\//g,'_')
            script.async=true
            document.getElementsByTagName('head')[0].appendChild(script)
            window.ImportName=sPath
            #cохряняем созданный скрипт
            scripts[sPath]=script
            # переходим к следующему после успешной загрузки
            script.onload=->loaderCallNext(iId,fCallback)
    loaderRequest(loadMethod,sPath,oRequest,fCallback)
# Загрузчик стилей
# ORequest - массив стилей
# appName - имя приложения, к кторому относятся скрипты
# sPath - относительный путь загрузки стилей (относительно JAFW.StylePath)
# bNoAppend - флаг, позволяющий запретить применения стиля после загрузки
loadStyes=(oRequest,appName,sPath,fCallback,bNoAppend)->
    loadMethod=(sPath,iId)->
        if not styles[sPath]?
            style=document.createElement('link')
            style.rel='stylesheet'
            style.href="#{sPath}.css"
            style.className='CSS_'+appName
            style.id='CSS_'+appName+'_'+sPath.replace(/\//,'_')
            styles[sPath]=style
            if not bNoAppend
                document.getElementsByTagName('head')[0].appendChild(style);
        else
            if not document.querySelector('#CSS_'+appName+'_'+sPath.replace(/\//,'_'))
                document.getElementsByTagName('head')[0].appendChild(styles[sPath]);
    loaderRequest(loadMethod,sPath,oRequest,fCallback)

if not JAFW.ScriptPath?
    throw 'JAFW.ScriptPath is not defined!'
if not JAFW.mainFunc
    throw 'JAWF.mainFunc is not defined!'
# Импорт библиотек
libImport=[]
JAFW.IncludeLibs.forEach (importArray)->libImport.push importArray
#IMPORT [['initial']],"#{JAFW.ScriptPath}",->
#    JAFW.mainFunc()
IMPORT libImport,"#{JAFW.ScriptPath}/lib",->
    importKeys=JAFW.JafwModules
    importPaths=(aPaths,oScripts,fReady)->
        if aPaths.length
            path=aPaths[0]
            aPaths.shift()
            IMPORT [oScripts[path]],"#{JAFW.ScriptPath}/jafw/#{path}",->importPaths(aPaths,oScripts,fReady)
        else
            fReady?()
    importScripts=(aPaths)->
        if aPaths.length
            path=aPaths[0]
            aPaths.shift()
            importPaths(Object.keys(path),path,->importScripts(aPaths))
        else
            JAFW.mainFunc()
    importScripts(importKeys)
