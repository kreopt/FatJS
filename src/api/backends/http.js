Fat.register_backend('api','http', {
    call: function (url, signature, data) {
        return Fat.fetch(url,{
            method:"POST",
            body: Fat.url.stringify({signature: signature, data: data}),
            type:'json'
        });
    },
    call_many: function (url, requests) {
        return Fat.fetch(url,{
            method:"POST",
            body: Fat.url.stringify({requests: requests}),
            type:'json'
        });
    }
});
