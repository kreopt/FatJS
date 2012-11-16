window.JAFW={
    ## КОНФИГУРАЦИЯ

    ScriptPath:'js',    # Путь к скриптам проекта
    AppPath:'js/apps',  # Путь к скриптам приложений
    AppCssPath:'css',   # Путь к стилям приложений
    IncludeLibs:[],     # Подключаемые сторонние библиотеки
    JafwModules:[
        {core:['app','dom','signals']}
        {core:['api','launcher']}
    ]
    mainFunc:null       # Главная функция, запускаемая после инициализации
    # Функция загрузки шаблонов.
    # oRequest - массив имен шаблонов ['Test/template',...]
    # fGoOn - функция инициализатора приложения.
    # Должна вызываться после успешной загрузки шаблонов и принимать в качестве
    # параметра массив вида [{status,data:{path,content}},]. status=0, если шаблон загружен без ошибки.
    # path - имя шаблона, content - его содержание
    AppTemplateLoadEngine:(oRequest,fGoOn)->throw 'AppTemplateLoadEngine Not Implemented'
    RenderEngine:{}
    #ФУНКЦИЯ ЗАПУСКА. НЕ ИЗМЕНЯТЬ!

    start:(fMain)->
        JAFW.mainFunc=fMain if fMain?
        coreScript=document.createElement('script')
        coreScript.src="#{JAFW.ScriptPath}/jafw/core/core.js"
        head=document.querySelector('head')
        head.appendChild(coreScript)

}
window.APP_DELIMITER='.'
__MAIN__=->JAFW.RenderEngine=new jSmart()
# Запуск JAFW.
JAFW.start __MAIN__
