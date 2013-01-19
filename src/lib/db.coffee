pg = require('pg').native
connect=(config)->
    client = new pg.Client(config);
    client.connect (err) ->
    client
