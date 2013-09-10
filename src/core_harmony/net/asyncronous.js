class AsyncRequest {
    constructor(){
        this.allowed_messages=[];
    }

    on(event, callback){
        if (!this.event_listener){
            return this;
        }
        if (this.allowed_messages.indexOf(event)>-1){
            this.event_listener["on"+event] = callback;
        }
        return this;
    }

    post_message(data){

    }
}