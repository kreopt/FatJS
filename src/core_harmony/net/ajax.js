class Ajax {
    constructor() {
        this.__require__=['serializers.url'];
    }

    request(method, url, params, success, error) {
        new inSide.SerializerFactory('url').encode(params);

        let requestObject = new XMLHttpRequest();
        requestObject.onreadystatechange = function(){
            if (requestObject.readyState === 4) {
                if (requestObject.status === 200){
                    success(requestObject);
                } else {
                    error(requestObject);
                }
            }
        };

        let requestData=this.url_encode(params);

        if (method === "GET") {
            if (requestData) {
                url += "?"+requestData;
            }
            requestData = null;
        }

        requestObject.open(method, url, true);

        if (method === "POST") {
            requestObject.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
        }
        requestObject.send(requestData);
    }

    requestJSON(method, url, params, success, error) {
        this.request(method, url, params, function(request){
            success(JSON.parse(request.responseText));
        },function(request){
            error(request);
        });
    }

    get_(url, params, success, error) {
        this.request("GET", url, params, success, error);
    }

    get get(){
        return this.get_;
    }

    post() {
        this.request("POST", url, params, success, error);
    }

    getJSON(url, params, success, error){
        this.requestJSON("GET", url, params, success, error);
    }
    postJSON(url, params, success, error){
        this.requestJSON("POST", url, params, success, error);
    }
}