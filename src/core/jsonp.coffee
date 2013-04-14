##
# ВЗАИМОДЕЙСТВИЕ С СЕРВЕРНЫМ API
##
class JSONP
   request:(url, data)->
      removeNodesBySelector('#JSONPRequester')
      script=$c('script')
      requestData=url+'?'+inSide.Url.encode(data)
      script.src=requestData
      script.type='text/javascript'
      script.id="JSONPRequester"
      document.body.appendChild(script)

inSide.__Register('JSONP',JSONP)
