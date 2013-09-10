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
        inSide.LoadIndicator.loadMessage='<div style="margin: auto;margin-top:200px;width:230px;padding:20px;background: #fff;border-radius: 6px"><progress id="UploadIndicator" max="100"></progress><div id="UploadPercent" style="display: inline-block; margin-left: 10px;"></div></div>'
        xhr = new XMLHttpRequest();
        xhr.upload.addEventListener('progress', (e)->
            if e.lengthComputable
               percent=Math.ceil((e.loaded/e.total) * 100);
               $s('#UploadIndicator').value=percent;
               $s('#UploadPercent').innerHTML=percent + '%';
        )
        xhr.open('POST', url, true);
        xhr.onload = (e)->
            EMIT('=UPLOAD_FILES',this.responseText,emitter)
            inSide.LoadIndicator.hide()
        inSide.LoadIndicator.show()
        xhr.send(formData)
        return null
inSide.__Register('Uploader',Upload)
