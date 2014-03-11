Fat.register_backend('API','http', {
    call: function (url, signature, data, resolve, reject) {
        $.ajax({
          type:"POST",
          url: url,
          data: {signature: signature, data: data},
          success: resolve,
          error: reject
        });
    },
    call_many: function (url, requests, resolve, reject) {
        $.ajax({
          type:"POST",
          url: url,
          data: {requests: requests},
          success: resolve,
          error: reject
        });
    }
});
