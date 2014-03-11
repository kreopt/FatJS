(function() {
    class JSONP {
        request(url, data) {
            removeNodesBySelector('#JSONPRequester');
            let script = $('<script></script>');
            let requestData = url + '?' + UrlSerializer.stringify(data);
            script.src = requestData;
            script.type = 'text/javascript';
            script.id = "JSONPRequester";
            return document.body.appendChild(script);
        }
    }
    inSide.__Register('JSONP', JSONP);
})();
