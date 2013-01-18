srv=require("../core/server")
router={
    handle:(req,resultCallback,data={})->
        setTimeout((->resultCallback(req+' received')),1000)
}
srv.run(router)