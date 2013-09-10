class GenericApi {
    constructor(){
        let url = inSide.get_option('api.url');
        if (url){
            this.url = url;
        } else {
            throw("No url property found in the inSideConf.api!");
        }
    }

    call(method, args={}){
        throw("Abstract method!");
    }

    callMany(callChain){
        throw("Abstract method!");
    }
}