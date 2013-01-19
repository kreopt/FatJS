JAFW_PATH='../'
APPS_PATH='./apps/'
srv=require(JAFW_PATH+"/core/server")
loaded={}
modLoad=(app)->
    if not loaded[app]
        loaded[app]=require(APPS_PATH+app)
    loaded[app]
router={
    handle:(req,resultCallback,data={})->
        resultCallback(req.data+' received')
    handleSocket:(data,resultCallback)->
        data=JSON.parse(data)
        if data.type=='api'
            modLoad(data.app)[data.method](((response)->resultCallback(JSON.stringify(response))),data.data)
        #setTimeout((->resultCallback(data)),100)
}
options={
    port:8001
}
srv.run(router,options)