## code is adapted from http://blog.evantahler.com/blog/production-deployment-with-node-js-clusters.html
# TODO: update from https://github.com/evantahler/actionHero/blob/master/bin/include/startCluster.js
fs=require('fs')
colors = require('colors');
cluster = require('cluster');
numCPUs = require('os').cpus().length;
workerCount = numCPUs - 2
workerCount = 2 if workerCount < 2

## default config
config = {
   exec: __dirname + "/slave",
   workers: workerCount,
   pidfile: "./cluster_pidfile",
   log: process.cwd() + "/cluster.log",
   title: "inSide-master",
   workerTitlePrefix: " inSide-worker",
   silent: true,
   services:[]
}

# try to load user config and override defaults
try
   userConf=JSON.parse(fs.readFileSync(process.cwd()+'/clusterConfig.json'))
   for key,value of userConf.master
      config[key]=value
catch e
   console.log("Failed to override config");
   # do nothing

## logging

logHandle = fs.createWriteStream(config.log, {flags:"a"});
log = (msg, col)->
   sqlDateTime = (time)->
      time = new Date() if time == null
      dateStr = padDateDoubleStr(time.getFullYear()) +
                "-" + padDateDoubleStr(1 + time.getMonth()) +
                "-" + padDateDoubleStr(time.getDate()) +
                " " + padDateDoubleStr(time.getHours()) +
                ":" + padDateDoubleStr(time.getMinutes()) +
                ":" + padDateDoubleStr(time.getSeconds());
      return dateStr;

   padDateDoubleStr = (i)->
      return if (i < 10) then "0" + i else "" + i
      msg = sqlDateTime() + " | " + msg;
      logHandle.write(msg + "\r\n");
      col = [col] if typeof(col) == "string"
      for i of col
         msg = colors[col[i]](msg);
   console.log(msg);
runningWorkers={}
env={
   runningWorkers:runningWorkers,
   config:config
}
exports.start=()->
   ## Main
   log(" - STARTING CLUSTER -", ["bold", "green"])
   # set pidFile
   if config.pidfile != null
      fs.writeFileSync(config.pidfile, process.pid.toString())

   process.stdin.resume()
   process.title = config.title
   workerRestartArray = []

   # used to trask rolling restarts of workers
   workersExpected = 0

   # signals
   process.on 'SIGINT', ->
      log("Signal: SIGINT")
      workersExpected = 0;
      setupShutdown()

   process.on 'SIGTERM', ->
      log("Signal: SIGTERM");
      workersExpected = 0;
      setupShutdown()

   #process.on 'SIGKILL', ->
   #   log("Signal: SIGKILL")
   #   workersExpected = 0;
   #   setupShutdown()

   process.on 'SIGUSR2', ->
      log("Signal: SIGUSR2");
      log("swap out new workers one-by-one");
      workerRestartArray = [];
      for i of cluster.workers
         workerRestartArray.push(cluster.workers[i])
      reloadAWorker()

   process.on 'SIGHUP', ->
      log("Signal: SIGHUP");
      log("reload all workers now");
      for i of cluster.workers
         worker = cluster.workers[i];
         worker.send({cmd:"restart"});

   process.on 'SIGWINCH', ->
      log("Signal: SIGWINCH");
      log("stop all workers");
      workersExpected = 0;
      for i in cluster.workers
         stopAWorker(cluster.workers[i])

   process.on 'SIGTTIN', ->
      log("Signal: SIGTTIN");
      log("add a worker");
      workersExpected++;
      startAWorker()

   process.on 'SIGTTOU', ->
      log("Signal: SIGTTOU");
      log("remove a worker");
      workersExpected--;
      for i of cluster.workers
         stopAWorker(cluster.workers[i])
         break

   process.on "exit", ->
      workersExpected = 0;
      log("Bye!")

   # signal helpers
   startAWorker = ->
      worker = cluster.fork();
      runningWorkers[worker.id]=worker
      worker.on 'message', (message)->
         if(worker.state != "none")
            log("#"+worker.process.pid+"/" + message);
   stopAWorker = (worker)->
      worker.send({cmd:"stop"});
      delete runningWorkers[worker.id]
   setupShutdown = ->
      log("Cluster manager quitting", "red");
      log("Stopping each worker...");
      for i of cluster.workers
         stopAWorker(cluster.workers[i])
      setTimeout(loopUntilNoWorkers, 1000);

   loopUntilNoWorkers = ->
      if cluster.workers.length > 0
         log("there are still " + cluster.workers.length + " workers...");
         setTimeout(loopUntilNoWorkers, 1000);
      else
         log("all workers gone");
         if config.pidfile != null
            fs.unlinkSync(config.pidfile)
         process.exit();

   reloadAWorker = (next)->
      count = 0
      for i of cluster.workers
         count++
      if workersExpected > count
         startAWorker()
      if workerRestartArray.length > 0
         stopAWorker(workerRestartArray.pop())

   # Fork it.
   cluster.setupMaster({
      exec : config.exec,
      args : process.argv.slice(2),
      silent : config.silent
   })

   for i in [0...config.workers]
      workersExpected++;
      startAWorker()

   cluster.on 'fork', (worker)->
   cluster.on 'listening', (worker, address)->
   cluster.on 'exit', (worker, code, signal)->
      log("#" + worker.process.pid + "/exited");
      setTimeout(reloadAWorker, 1000)
   for service in config.services
      try
         runable=require(process.cwd()+'/'+service)
         runable.run(cluster,env)
      catch e
         log(e.stack)