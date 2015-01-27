Fat.register_backend('api','httpjson', {
    call: function (url, signature, data) {
        return Fat.fetch(url,{
            method:"POST",
            body: JSON.stringify({signature: signature, data: data}),
            type:'json'
        });
    },
    call_many: function (url, requests) {
        return Fat.fetch(url,{
            method:"POST",
            body: JSON.stringify({requests: requests}),
            type:'json'
        });
    }
});
