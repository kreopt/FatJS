Fat.API.prototype.add_backend('http', {
    call: function (url, signature, data) {
        return new Promise(function(resolve, reject){
            $.ajax({
                type: "POST",
                url: url,
                data: {signature: signature, data: data},
                dataType: 'json',
                success: function(r){
                    resolve(r)
                },
                error: function(jqXHR, textStatus, errorThrown){
                    reject("API: "+textStatus+" "+errorThrown)
                }
            });
        });

    },
    call_many: function (url, requests) {
        return new Promise(function(resolve, reject) {
            $.ajax({
                type:    "POST",
                url:     url,
                data:    {requests: requests},
                dataType: 'json',
                success: function (r) {
                    resolve(r)
                },
                error: function(jqXHR, textStatus, errorThrown){
                    reject("API: "+textStatus+" "+errorThrown)
                }
            });
        });
    }
});
