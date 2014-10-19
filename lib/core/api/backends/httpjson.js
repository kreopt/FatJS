Fat.register_backend('API', 'httpjson', {
    call: function (url, signature, data) {
        return $.ajax({
            type: "POST",
            url: url,
            data: JSON.stringify({signature: signature, data: data})
        });

    },
    call_many: function (url, requests) {
        return $.ajax({
            type: "POST",
            url: url,
            data: JSON.stringify({requests: requests})
        });
    }
});
