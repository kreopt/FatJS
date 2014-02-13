Fat.UI.addLoader('http',{
    loadTemplate:function(uiName, url, ready){
        if (!Fat.UI.templates[uiName]){
            $.get(url, '', function(template){
                Fat.UI.templates[uiName]=template;
                ready(template);
            })
        } else {
            ready(Fat.UI.templates[uiName]);
        }

    },
    load_style:function(url, ready){}
});
