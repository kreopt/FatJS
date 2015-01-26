Fat.register_plugin("actions",{
    init: function(options){
        $(document.body).on('click', '.action', function(){
            Fat.emit('action.'+this.dataset['signal'])
        });
    }
});
