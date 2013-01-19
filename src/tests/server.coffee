srv=require("../core/server")
router={
    handle:(req,resultCallback,data={})->
        setTimeout((->resultCallback(req.data+' received')),100)
    handleSocket:(data,resultCallback)->
        setTimeout((->resultCallback(data)),100)
}
srv.run(router)