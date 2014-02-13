(function() {
  var DEBUG, Task, URL, inSideCore, self,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  if (typeof exports !== "undefined" && exports !== null) {
    self = {};
  } else if (typeof window !== "undefined" && window !== null) {
    self = window;
  }

  self.logDebug = function() {
    var arg, args, d, ms, _i, _len;
    d = new Date();
    ms = d.getMilliseconds();
    args = ['[' + d.toLocaleTimeString() + '.' + ms + ']'];
    for (_i = 0, _len = arguments.length; _i < _len; _i++) {
      arg = arguments[_i];
      args.push(arg);
    }
    if ((typeof console !== "undefined" && console !== null ? console.debug : void 0) != null) {
      return console.debug.apply(console, args);
    }
  };

  DEBUG = 0;

  inSideCore = (function() {
    function inSideCore() {}

    inSideCore.prototype._uids = {
      '$': 0
    };

    inSideCore.prototype._mods = {};

    inSideCore.prototype._tpls = {};

    inSideCore.prototype.__nextID = function(seqName) {
      if (seqName == null) {
        seqName = '$';
      }
      if (!inSideCore.prototype._uids[seqName]) {
        inSideCore.prototype._uids[seqName] = 0;
      }
      return inSideCore.prototype._uids[seqName]++;
    };

    inSideCore.prototype.__Register = function(modName, module) {
      if (__indexOf.call(inSideCore.prototype._mods, modName) >= 0) {
        throw 'Module already registered';
      }
      inSideCore.prototype._mods[modName] = new module();
      return inSideCore.prototype[modName] = inSideCore.prototype._mods[modName];
    };

    return inSideCore;

  })();

  Task = (function() {
    function Task() {}

    Task.prototype.create = function(workerFunc, callback) {
      var worker;
      worker = new Worker(window.URL.createObjectURL(new Blob(['(' + workerFunc.toString() + ')()'], {
        "type": "text\/javascript"
      })));
      worker.onmessage = function(event) {
        return callback(event.data);
      };
      return worker;
    };

    return Task;

  })();

// fallback
    var _url = new UrlSerializer();
  URL = {
      encode:_url.stringify,
      decode: _url.parse
  };


  inSideCore.prototype.__Register('Task', Task);

  inSideCore.prototype.__Register('Url', URL);

  if (typeof exports === "undefined" || exports === null) {
    inSideCore.prototype.RenderEngine = {
      _tpl: {},
      loadTemplate: function(name, tpl) {
        var e;
        try {
          return this._tpl[name] = jade.compile(tpl, {
            compileDebug: false
          });
        } catch (_error) {
          e = _error;
          logDebug('Failed to compile template: ' + name);
          throw e;
        }
      },
      render: function(name, args) {
        var e;
        if (args == null) {
          args = {};
        }
        try {
          return this._tpl[name](args);
        } catch (_error) {
          e = _error;
          logDebug('Failed to render template: ' + name);
          throw e;
        }
      }
    };
  }

  self.inSide = new inSideCore();

  if (typeof exports !== "undefined" && exports !== null) {
    exports.inSide = self.inSide;
  }

}).call(this);
