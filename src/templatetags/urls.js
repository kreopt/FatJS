!function(){
    const reverse={};
    const urls = {};

    Fat.urls=function(urls){

    };

    function make_reverse(){}
    make_reverse();

    jinja.make_tag('url',function(stmt){
        var tokens=stmt.split(' ');
        var url = tokens[0].substr(1,tokens[0].length-2);

        var open = url.indexOf('(');
        var close = -1;
        var url_part;
        if (open) {
            url_part = url.substr(close+1, open-close-1);
            this.push(url_part);
            close = url.indexOf(')');
            for (var i = 1; i < tokens.length; i++) {
                this.push('get(' + tokens[i] + ')');
                open = url.indexOf('(', close+1);
                if (open > 0) {
                    url_part = url.substr(close+1, open-close-1);
                    this.push(url_part);
                    close = url.indexOf(')');
                }
            }
            url_part = url.substr(close+1, url.length-close-1);
        } else {
            url_part = url;
        }
        this.push(url_part);
    });

    jinja.make_tag('static',function(stmt){
        stmt = stmt.trim();
        this.push("write(\""+Fat.config.static_url + stmt.substr(1,stmt.length-2)+"\")");
    });
}();
