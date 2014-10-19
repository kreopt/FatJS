!()
->
{
    class Upload {
        constructor() {
            CONNECT('Ajax.upload', 'upload', this);
        }

        upload({url,files,params}, emitter) {
            params = params || {};

            let formData = new FormData();

            for (let param in params) {
                formData.append(param, params[param]);
            }
            for (let file of files) {
                formData.append(file.name, file);
            }

            EMIT('UI.loadIndicator.show', {type: 'progress'})

            let xhr = new XMLHttpRequest();
            xhr.upload.addEventListener('progress', function (e) {
                if (e.lengthComputable) {
                    EMIT('UI.loadIndicator.progress', {value: Math.ceil((e.loaded / e.total) * 100)});
                }
            });
            xhr.onload = function (e) {
                EMIT('Ajax.upload.complete', this.responseText);
                EMIT('UI.loadIndicator.hide')
            };
            xhr.open('POST', url, true);
            xhr.send(formData);
        }

    ;

    }
)
    ();

    inSide.__Register('Uploader', Upload);

}
();
