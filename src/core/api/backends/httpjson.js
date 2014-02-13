Fat.register_backend('API','httpjson', {
    call: function (url, signature, data, ready) {
        $.post(url, JSON.stringify({signature: signature, data: data}), ready)
    },
    call_many: function (url, requests, ready) {
        $.post(url, JSON.stringify({requests: requests}), ready)
    }
});
