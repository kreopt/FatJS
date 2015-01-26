!function () {
    var seq = 0;
    var state = null;
    var ws = null;
    var promises = {};
    var queue = [];
    var timeout = 100;

    var init = function (url) {
        ws = new WebSocket(url);
        ws.onopen = function () {
            state = 1;
            console.debug('connected');
            timeout = 100;
            while (queue.length) {
                send.apply(this, queue.splice(0, 1)[0]);
            }
        };
        ws.onclose = function () {
            state = null;
            console.log('Соединение потеряно, восстанавливаем...');
            setTimeout(function () {
                timeout *= 2;
                init(url);
            }, timeout);
        };
        ws.onmessage = function (evt) {
            var msg = JSON.parse(evt.data);
            console.debug('RECV>', msg);
            if (promises[msg.seq]) {
                if (!msg.status) {
                    promises[msg.seq].resolve(msg.data);
                } else {
                    promises[msg.seq].reject(msg.data);
                }
                delete promises[msg.seq];
            }
        };
    };
    var send = function (data, ready, options) {
        promises[seq] = ready;
        data.seq = seq;
        if (options.gen_head) {
            data.head = options.gen_head();
        }
        console.debug('SEND>', data);
        ws.send(JSON.stringify(data));
        seq++;
    };
    Fat.API.prototype.add_backend('ws', {
        call: function (options, signature, data) {
            var ready = new Promise();
            if (!state) {
                queue.push([
                    {signature: signature, data: data},
                    ready,
                    options
                ]);
                init(options.url);
            } else {
                send({signature: signature, data: data}, ready, options);
            }
        },
        call_many: function (options, requests) {
            var ready = new Promise();
            if (!state) {
                queue.push([
                    {requests: requests},
                    ready,
                    options
                ]);
                init(options.url);
            } else {
                send({requests: requests}, ready, options);
            }
        }
    });
}();
