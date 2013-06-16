class Upload
    constructor:->
        CONNECT('UPLOAD_FILES','upload',@)
    upload:({url,params,files},emitter)->
        params={} if not params
        formData = new FormData();
        for param,value of params
            formData.append(param,value)
        for file in files
            formData.append(file.name, file);
        xhr = new XMLHttpRequest();
        xhr.open('POST', url, true);
        xhr.onload = (e)->EMIT('=UPLOAD_FILES',this.responseText,emitter)
        xhr.send(formData)
        return null
inSide.__Register('Uploader',Upload)
