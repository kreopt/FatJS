window=self if not window?
##
# APPLICATION FRAMEWORK
##
Object.defineProperty(window,'CHILD_WINDOWS',{value:{},writable:true,configurable:false})
window.DOCUMENT=document;
JAFW['apps']={}
JAFW['cmp']={}
JAFW['forms']={}
JAFW['ifc']={}
JAFW['nsp']={}
$N=JAFW['nsp']
$A=JAFW['apps']
$F=JAFW['forms']
$I=JAFW['ifc']
$N=JAFW['nsp']
$C=JAFW['cmp']

class appLoader
    queue:{}
    included:{}
    request:{}
    load:(oApp,isApp)->
        queue=appLoader::queue
        appName=oApp::__name
        # Создаем в очереди загрузок приложение, если еще не было создано
        if not queue[appName]?
            queue[appName]={status:0,required:[],requiredBy:{},apps:[],forms:{},isApp:isApp}
            # Запоминаем имя приложения, чтобы больше не пытаться его загрузить
            appLoader::included[appName]=1
            if isApp
                queue[appName].apps.push oApp
        # Ищем еще не подключенные модули
        oApp::__using.forEach (reqName)->
            if !appLoader::included[reqName]?
                # Подключаем их, если надо
                appLoader::included[reqName]=1
                queue[appName].required.push reqName
        queue[appName].forms=oApp::__forms
        if oApp::__css
            if JAFW.AppCssPath
                IMPORTCSS oApp::__css,JAFW.AppCssPath,appName
            else
                DEBUG 'JAFW.AppCssPath is not defined!'
        appLoader::request[appName]={}
        oApp::__using.forEach (using)->
            if not queue[using]?
                queue[using]={status:0,required:[],requiredBy:{},forms:{}}
            queue[using].requiredBy[appName]=1
        appLoader::scripts(appName)
    check:(sName)->
        # Если все зависимости загружены
        if appLoader::queue[sName].required.every((el)->appLoader::queue[el].status==1)
            # Помечаем скрипт загруженным
            appLoader::queue[sName].status=1
            # Проверяем обратные зависимости
            appLoader::check(req) for req of appLoader::queue[sName].requiredBy
            # Если это приложение - запускаем его
            appLoader::forms(sName) if appLoader::queue[sName].isApp
    scripts:(sName)->
        request=appLoader::queue[sName].required
                    .filter((req)-> appLoader::queue[sName].status==0 and appLoader::included[sName]?)
                    .map((req)->["#{req.replace(/\./g,'/')}/index"])
        throw 'JAFW.AppPath is not defined!' if !JAFW.AppPath
        if Object.keys(request).length==0
            appLoader::check(sName)
        else
            IMPORT request,"#{JAFW.ScriptPath}"

    _getFormList:(sName,oList)->
        appLoader::queue[sName].required.forEach (req)->appLoader::_getFormList(req,oList)
        oList[sName]=appLoader::queue[sName].forms if Object.keys(appLoader::queue[sName].forms).length
    forms:(sName)->
        request=appLoader::request[sName]
        toLoad=[]
        appLoader::_getFormList(sName,request)
        for appName,formList of request
            formList.filter((form)->not $F[form])
                    .forEach (form)->toLoad.push(form.replace('@',appName.replace(/\./g,'/')+'/'))
        templatesLoaded=(oResponse)=>
            oResponse.filter((tpl)->not tpl.status)
                     .forEach (tpl)->
                         tpl=tpl.data
                         $F[tpl.path]=tpl.content
                         JAFW.RenderEngine.loadTemplate(tpl.path,tpl.content)
            appLoader::start(sName) if appLoader::queue[sName].apps
        if Object.keys(toLoad).length
            if JAFW.AppTemplateLoadEngine?
                JAFW.AppTemplateLoadEngine(toLoad,templatesLoaded)
            else
                throw 'JAFW.AppTemplateLoadEngine(oRequest,fCallback(tplList)) is not defined!'
        else
            templatesLoaded([])
    start:(sName)->
#        appName=sName.split('.')
#        appName=appName[appName.length-1]
        sName=sName.replace('/','.')
        appLoader::queue[sName].apps.forEach (app)->
            if JAFW.init[sName]
                container=$s('#'+JAFW.init[sName].container)
                setup=JAFW.init[sName].setup
            new app(container,setup)
        delete JAFW.init[sName] if JAFW.init[sName]
JAFW.running={}
window.APPLICATION=(sName,oBody)->
    JAFW.Apps.__Register(sName,oBody)

window.CPROPERTY=(sSignature,vValue)->
    #TODO: private
    delimiterIndex=sSignature.lastIndexOf(APP_DELIMITER)
    appName=sSignature.substr(0,delimiterIndex)
    propName=sSignature.substr(delimiterIndex+1)
    assert(propName?,'Invalid application signature '+sSignature+'!');
    if not $C[appName]?
        DEBUG('There is no application with name '+appName+'! Property assignment skipped.')
    else
        if typeof(vValue)==typeof(->)
            $C[appName]::[propName]=vValue
        else
            Object.defineProperty($C[appName]::,propName,vValue)
window.CMP=(sName,oBody)->
    JAFW.running[sName]={}
    class $C[sName] extends JafComponent
        constructor:(oConfig)->
            @connectionList=[]
            @UID=JAFW.nextID()
            JAFW.running[sName][@UID]=@
            @__setup?()
            if typeof(oConfig)!=typeof({})
                oConfig={}
            @config=oConfig
            @__=(sName,oVal)->Object.defineProperty(@,sName,oVal)
            @_init?(oConfig)
        __getForm:(sFormName)->
            $F[sFormName.replace('@',@__name.replace(/\./g,'/')+'/')]
    mix($C[sName]::,oBody)
    $C[sName]::__forms=[] if !$C[sName]::__forms
    $C[sName]::__using=[] if !$C[sName]::__using
    $C[sName]::__name=sName
    appLoader::load($C[sName])
JAFW.init={}
window.RUN=(appName,DOMContainer)->
    JAFW.Meta.get(appName.replace('.','/'),->JAFW.Apps.start(appName,DOMContainer))
window.INSTANCE=(sName,oConfig)->
    new $C[sName](oConfig)
mix=(oObject,oMixin)->
    for key,val of oMixin
        oObject[key]=val
window.RENDER=(sFormName,DOMContainer,oData)->
    oData={} if not oData?
    oData.config=JAFWConf
    try
        rendered=JAFW.RenderEngine.render(sFormName.replace(/\./g,'/'),oData)
    catch expection
        rendered = ''
        DEBUG 'Render error: '+sFormName+' ('+expection+')'
    if DOMContainer isnt null
        DOMContainer.innerHTML=rendered
    else
        rendered
window.RENDERSEL=(sFormName,sSelector,oData)->
    containers=$a(sSelector)
    RENDER(sFormName,container,oData) for container in containers
class JafComponent
    ## PUBLIC
    EMIT:(sSignal,oData)->EMIT(sSignal,oData,@)
    CONNECT:(sSignal,sSlot)->CONNECT(sSignal,sSlot,@)
    DISCONNECT:(sSignal,sSlot)->DISCONNECT(sSignal,sSlot,@)
    RENDER:(sFormName,DOMContainer,oData)->
        RENDER(sFormName.replace('@',@__name.replace(/\./g,'/')+'/'),DOMContainer,oData)
    toString:->@__name
    ## PRIVATE
    __requiredConfig:(oConfig,aRequiredParams)->
        if typeof(oConfig)!=typeof({})
            oConfig={}
        for param in aRequiredParams
            if not (param of oConfig)
                throw 'Not all required parameters present in '+@__name+' component constructor!\nRequired are: {'+aRequiredParams+'}'
    __destroy:->
        for conn in @connectionList
            @DISCONNECT(conn[0],conn[1])
        @_destroy?()
        delete JAFW.running[@__name][@UID]

class JafApplication extends JafComponent
    __destroy:->
        #TODO: recursive destroy
        for conn in @connectionList
            @DISCONNECT(conn[0],conn[1])
        @_destroy?()
        delete JAFW.running[@__name][@UID]
