Fat.register_backend('API','http', {
    call: function (url, signature, data, ready) {
        $.post(url, {signature: signature, data: data}, ready)
    },
    call_many: function (url, requests, ready) {
        $.post(url, {requests: requests}, ready)
    }
});