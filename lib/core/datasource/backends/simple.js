!function () {
    class SimpleDatasource {
        constructor(options) {
            this.options = options;
        }

        fetch() {
            return Promise.cast(this.options);
        }
    }
    Fat.register_backend('Datasource', 'simple', SimpleDatasource);
}();
