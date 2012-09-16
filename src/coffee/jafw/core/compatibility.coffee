if !window.JSON?
    window.JSON={}
if !window.JSON.parse?
    window.JSON::parse=(sJSONString)->
if !window.JSON.strigify?
    window.JSON::strigify=(oObject)->
if !window.Object.defineProperty?
    window.Object::defineProperty=(oObject,sPropName,oDescriptors)->
if !document.querySelector?
    document.querySelector=(sSelector)->
if !document.querySelectorAll?
    document.querySelectorAll=(sSelector)->

#TODO: array extras