!function(){
    Fat.render = function($elements, template, data){
        return new Promise(function(resolve, reject){
            jinja.render('{% include "'+template+'" %}', data).then(function(html){
                // TODO: mb make sure elements are empty
                for (var i=0; i<$elements.length; i++){
                    $elements[i].innerHTML = html;
                }
                resolve();
            });
        });
    }
}();
