exports.App={
init:(@reply,{@meta,@data},@ready)->
   @ready(@)
destroy:->
testResponse:->
   @reply({meta:@meta,data:@data})
}