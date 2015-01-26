!function () {
    class ApiDatasource {
        constructor(options) {
            this.options = options;
        }

        fetch() {
            return Fat.API.call_many(this.options);
        }
    }
    Fat.register_backend('Datasource', 'api', ApiDatasource);
}();
