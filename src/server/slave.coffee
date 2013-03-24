#!/usr/bin/env node
fs=require('fs')
cluster = require('cluster')
http = require('./http')

startServer = (next)->
   if(cluster.isWorker)
      process.send("starting")
   try
      userConf=JSON.parse(fs.readFileSync(process.cwd()+'/clusterConfig.json')).slave
   catch e
      userConf={}
   # start server
   http.start userConf, ->
      if(cluster.isWorker)
         process.send("started")
      next?()

# handle signals from master if running in cluster
if cluster.isWorker
   process.on 'message', (msg)->
      switch msg.cmd
         when "start"
            process.send("starting")
            startServer ->process.send("started")
         when "stop"
            process.send("stopping");
            # kill it!
            process.send("stopped");
            process.exit();
         when "restart"
            process.send("restarting")
            # restart
         when "signal"
            http.handleSignal(msg.data)
         else
            process.send("unhandled message: "+msg.cmd)

# start the server!
startServer ->
   console.log("Successfully Booted!");
