class WebSocketJSON extends AsyncRequest {
    constructor() {
        this.allowed_events=["message","connect","disconnect","error"];
    }

    post_message(data) {

    }
}