Fat.register_backend('API', 'http', {
    call: function (url, signature, data) {
        return $.ajax({
            type: "POST",
            url: url,
            data: {signature: signature, data: data},
        });

    },
    call_many: function (url, requests) {
        return $.ajax({
            type: "POST",
            url: url,
            data: {requests: requests},
        });
    }
});
