Fat.register_backend('API','httpjson', {
    call: function (url, signature, data, resolve, reject) {
        $.ajax({
          type:"POST",
          url: url,
          data: JSON.stringify({signature: signature, data: data}),
          success: resolve,
          error: reject
        });
    },
    call_many: function (url, requests, resolve, reject) {
        $.ajax({
          type:"POST",
          url: url,
          data: JSON.stringify({requests: requests}),
          success: resolve,
          error: reject
        });
    }
});
