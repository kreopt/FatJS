!function(){
    let seq=0;
    let state=null;
    let ws=null;
    let handlers={};
    let queue=[];
    let timeout = 100;

    var init=function(url){
        ws = new WebSocket(url);
        ws.onopen = function() {
            state=1;
            console.debug('connected');
            timeout=100;
            while(queue.length){
                send.apply(this, queue.splice(0,1)[0]);
            }
        };
        ws.onclose = function() {
            state = null;
            console.log('Соединение потеряно, восстанавливаем...');
            setTimeout(function() {
                timeout*=2;
                init(url)
            }, timeout);
        };
        ws.onmessage = function(evt) {
            let msg = JSON.parse(evt.data);
            console.debug('RECV>', msg);
            if (!msg.status && typeof(handlers[msg.seq])==='function'){
                handlers[msg.seq](msg.data);
            }
            delete handlers[msg.seq];
        };
    };
    var send=function(data, ready, options){
        handlers[seq]=ready;
        data.seq=seq;
        if (options.gen_head){
            data.head=options.gen_head();
        }
        console.debug('SEND>', data);
        ws.send(JSON.stringify(data));
        seq++;
    };
    Fat.register_backend('API','ws',{
        call:function(options, signature, data, ready){
            if (!state){
                queue.push([{signature:signature, data:data}, ready, options]);
                init(options.url);
            } else {
                send({signature:signature, data:data}, ready, options);
            }
        },
        call_many:function(options, requests, ready){
            if (!state){
                queue.push([{requests:requests}, ready, options]);
                init(options.url);
            } else {
                send({requests:requests}, ready, options);
            }
        }
    })
}();
