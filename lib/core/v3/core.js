!function () {
    const Fat = {
        plugins:{},
        config:{},
        configure:function(options){
            $.extend(this.config, options);

            if (jinja && this.config.template_url){
                jinja.template_url = this.config.template_url;
            }
        }
    };
    Fat.fetch = function(name){
        return new Promise(function(resolve, reject){
            var url = Fat.config.static_url;
            if (!url.endsWith('/')) {url+='/';}
            url+='data/'+name+'.json';
            $.ajax({
                type: "GET",
                url: url,
                dataType: 'json',
                success: function(r){
                    resolve(r)
                },
                error: function(jqXHR, textStatus, errorThrown){
                    reject("API: "+textStatus+" "+errorThrown)
                }
            });
        });
    };
    window.Fat = Fat;
}();
