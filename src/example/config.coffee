window.JAFWConf={
    img_dir:'/img/',
    app_dir:'/lib/apps/',
    jafw_dir:'/lib/jafw/',
    lib_dir:'/lib/lib/',
    useWSAPI:1
}

ready=->
   JAFW.run('#jafw_container','Your:app',{})
   window.api=JAFW.API
   api.setUrl('api/')
   api.stdError=(error)->
      EMIT 'ERROR',{body:error.text}
      console.log(error.trace)
   # Добавляем аутентификационные данные к запросу API
   api.onBeforeSend=(oData)=>
      oData.meta={}
      oData.meta.uid=uid
      oData.meta.pid=pid
      return oData
   window.Session=JAFW.Session
CONNECT 'BUS_READY',ready,{toString:->'config'}

if JAFWConf.useWSAPI
   self.registerBus('wsbus',new WebSocketBus("ws://#{window.location.hostname}",(->EMIT 'BUS_READY',{name:'wsbus'})))
else
   ready()

window.Session=JAFW.Session

CONNECT('NOTIFY','notify',JAFW.Notifier)
CONNECT('NOTIFY_SUCCESS','success',JAFW.Notifier)
CONNECT('ALERT', 'alert', JAFW.Notifier)
CONNECT('ERROR', 'error', JAFW.Notifier)
CONNECT('BANNER','banner',JAFW.Notifier)


