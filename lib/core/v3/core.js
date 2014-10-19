!function () {
    const Fat = {
        plugins:{},
        config:{},
        configure:function(options){
            $.extend(this.config, options);
        }
    };
    window.Fat = Fat;
}();
