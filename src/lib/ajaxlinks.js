//require datasource
//require serializers.url
//require template
Fat.register_plugin("ajaxlinks",{
    init: function(options){
        var element = document.getElementById(options.root_id || 'fat_ajaxpage');
        $(document.body).on('click', 'a[data-type="'+(options.link_type||"ajax")+'"]', function () {
            // TODO: parse get parameters
            var link = this.getAttribute('href');
            var route = Fat.router.resolve(link);
            window.history.pushState(Fat.url.parse(link),'',link);
            Fat.datasource.fetch(route).then(function(data){
                Fat.render(element, route.view, /*data*/ {});
            });
            return false;
        });
    }
});

Fat.register_plugin("ajaxlinks_server",{
    init: function(options){
        var element = document.getElementById(options.root_id || 'fat_ajaxpage');
        $(document.body).on('click', 'a[data-type="'+(options.link_type||"ajax")+'"]', function () {
            var link = this.getAttribute('href');
            link+=((link.indexOf('?') < 0)?'?':'&')+'fat_ajax=1';
            Fat.ajax_get(link).then(function(html){
                element.innerHTML = html;
            });
            return false;
        });
    }
});
