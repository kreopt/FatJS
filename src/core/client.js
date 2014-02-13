// Generated by CoffeeScript 1.7.1
(function() {
  var Ajax, AppEnvironment, Launcher, containerApps, debugRnd,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  debugRnd = function() {
    var _ref;
    if ((_ref = window.inSideConf) != null ? _ref.debug : void 0) {
      return Math.round(Math.random() * 100);
    } else {
      return '';
    }
  };

  AppEnvironment = (function() {
    function AppEnvironment() {}

    AppEnvironment.prototype._styles = {};

    AppEnvironment.prototype._registered = {};

    AppEnvironment.prototype._selectorHandlers = {};

    AppEnvironment.prototype._initializers = {};

    AppEnvironment.prototype._runQueue = [];

    AppEnvironment.prototype._busy = false;

    AppEnvironment.prototype._running = {};

    AppEnvironment.prototype._dirty = false;

    AppEnvironment.prototype._kill = function(selector) {
      var appId, _ref;
      appId = AppEnvironment.prototype._selectorHandlers[selector];
      return (_ref = AppEnvironment.prototype._running[appId]) != null ? _ref.__destroy__() : void 0;
    };

    AppEnvironment.prototype._garbageCollect = function() {
      var app, appId, _ref;
      if (AppEnvironment.prototype._dirty) {
        _ref = AppEnvironment.prototype._running;
        for (appId in _ref) {
          app = _ref[appId];
          if (app.__container__ == null) {
            continue;
          }
          if (!app.__container__.parentNode && app.__disposable__) {
            console.log('Garbage collector destroying app: ' + app.__name__ + ' at container ' + appId);
            app.__destroy__();
            delete AppEnvironment.prototype._running[appId];
          }
        }
        return AppEnvironment.prototype._dirty = false;
      }
    };

    AppEnvironment.prototype._load = function(appName, selector, args, onLoad) {
      var script;
      if (AppEnvironment.prototype._registered[appName] != null) {
        return onLoad(appName, selector, args);
      } else {
        AppEnvironment.prototype._initializers[appName] = function(appName) {
          return onLoad(appName, selector, args);
        };
        script = document.createElement("script");
        script.type = "text/javascript";
        script.src = "" + inSideConf.app_dir + "/" + (appName.split(':').join('/')) + ".jsb.js?" + (debugRnd());
        script.onerror = function() {
          return AppEnvironment.prototype._busy = false;
        };
        script.async = true;
        return document.getElementsByTagName('head')[0].appendChild(script);
      }
    };

    AppEnvironment.prototype._setupClass = function(body) {
      body.kill = function(selector) {
        return AppEnvironment.prototype._kill(selector);
      };
      body.run = function(selector, appName, args, onload) {
        return inSide.run(appName, selector, args, onload, this.__id__);
      };
      if (body.__oncreate__ == null) {
        body.__oncreate__ = (function(r, args) {
          return r(args);
        });
      }
      if (body.__onrender__ == null) {
        body.__onrender__ = (function(r, args) {
          return r(args);
        });
      }
      body.__init__ = body.init;
      return body.__destroy__ = function(calledByParent) {
        var c, child, childIndex, children, _i, _j, _len, _len1, _ref, _ref1, _ref2;
        if (calledByParent == null) {
          calledByParent = false;
        }
        if (this.__parent__ && (!calledByParent)) {
          children = this.__parent__.__children__;
          for (childIndex = _i = 0, _len = children.length; _i < _len; childIndex = ++_i) {
            child = children[childIndex];
            if (child.__id__ === this.__id__) {
              this.__parent__.__children__.splice(childIndex, 1);
              break;
            }
          }
        }
        DISCONNECT('*', '*', this);
        if (this.destroy != null) {
          this.destroy();
        }
        if ((_ref = this.__super__) != null) {
          if (typeof _ref.destroy === "function") {
            _ref.destroy();
          }
        }
        if (AppEnvironment.prototype._running[this.__id__] == null) {
          return;
        }
        _ref1 = AppEnvironment.prototype._running[this.__id__].__children__;
        for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
          c = _ref1[_j];
          c.__destroy__(true);
        }
        if (((_ref2 = this.__container__) != null ? _ref2.innerHTML : void 0) != null) {
          this.__container__.innerHTML = '';
        }
        return delete AppEnvironment.prototype._running[this.__id__];
      };
    };

    AppEnvironment.prototype._setupInstance = function(instance, selector, args, parentId, onload) {
      var container, disposable, init, instanceId;
      if (typeof selector === typeof {}) {
        container = selector;
        disposable = false;
      } else {
        container = selector ? $s(selector) : null;
        disposable = true;
        AppEnvironment.prototype._kill(selector);
      }
      instanceId = inSide.__nextID('inSideHandler');
      AppEnvironment.prototype._running[instanceId] = instance;
      AppEnvironment.prototype._selectorHandlers[selector] = instanceId;
      args.config = inSideConf;
      instance.__id__ = instanceId;
      instance.__winId__ = 0;
      instance.__parent__ = AppEnvironment.prototype._running[parentId];
      instance.__children__ = [];
      instance.__container__ = container;
      instance.__disposable__ = disposable;
      instance.__args__ = args;
      instance.toString = function() {
        return this.__name__;
      };
      if (parentId in AppEnvironment.prototype._running) {
        AppEnvironment.prototype._running[parentId].__children__.push(instance);
      }
      init = function(args, noreload) {
        var style;
        if (noreload == null) {
          noreload = true;
        }
        if (instance.__container__) {
          installDOMWrappers(instance, container);
          if (instance.__template__) {
            style = instance.__style__ != null ? instance.__style__ : '';
            instance.__container__.innerHTML = style + instance.__template__(args, jade);
          }
          AppEnvironment.prototype._dirty = true;
          if (instance.__events__) {
            instance.setupEvents(instance.__events__);
          }
        }
        if (instance.__connections__) {
          INIT_CONNECTIONS(instance, instance.__connections__);
        }
        if (instance.__init__) {
          instance.__init__();
        }
        if (noreload) {
          return typeof onload === "function" ? onload(instance) : void 0;
        }
      };
      instance.__reload__ = (function(init, args) {
        return function() {
          return instance.__onrender__((function(args) {
            return init(args, false);
          }), args);
        };
      })(init, args);
      return instance.__oncreate__((function(args) {
        return instance.__onrender__(init, args);
      }), args);
    };

    AppEnvironment.prototype.register = function(appName, body) {
      var _base;
      logDebug(appName);
      if (__indexOf.call(AppEnvironment.prototype._registered, appName) >= 0) {
        throw 'Application already registered';
      }
      AppEnvironment.prototype._setupClass(body);
      AppEnvironment.prototype._registered[appName] = {
        body: body,
        constructor: function(bindObject) {
          var property, value;
          if (!bindObject) {
            bindObject = this;
          }
          body = AppEnvironment.prototype._registered[appName].body;
          for (property in body) {
            value = body[property];
            this[property] = typeof value === typeof (function() {}) ? value.bind(bindObject) : value;
          }
          if (body.__extends__) {
            this.__super__ = new AppEnvironment.prototype._registered[body.__extends__].constructor(this);
          }
          return void 0;
        },
        run: function(selector, args, parentId, onload) {
          var nextargs, _ref;
          if (selector == null) {
            selector = null;
          }
          if (args == null) {
            args = {};
          }
          if (parentId == null) {
            parentId = null;
          }
          if (onload == null) {
            onload = null;
          }
          AppEnvironment.prototype._garbageCollect(this);
          AppEnvironment.prototype._setupInstance(new AppEnvironment.prototype._registered[appName].constructor(), selector, args, parentId, onload);
          AppEnvironment.prototype._busy = false;
          if (AppEnvironment.prototype._runQueue.length) {
            nextargs = AppEnvironment.prototype._runQueue.shift();
            _ref = [nextargs[4], nextargs[3]], nextargs[3] = _ref[0], nextargs[4] = _ref[1];
            return inSide.run.apply(AppEnvironment.prototype._registered[nextargs[0]], nextargs);
          }
        }
      };
      if (body.__extends__ != null) {
        return AppEnvironment.prototype._load(body.__extends__, null, {}, (function(_this) {
          return function() {
            var extendable, property, value, _base, _ref;
            extendable = AppEnvironment.prototype._registered[appName].body;
            _ref = AppEnvironment.prototype._registered[body.__extends__].body;
            for (property in _ref) {
              value = _ref[property];
              if (extendable[property] == null) {
                extendable[property] = value;
              }
            }
            return typeof (_base = AppEnvironment.prototype._initializers)[appName] === "function" ? _base[appName](appName) : void 0;
          };
        })(this));
      } else {
        return typeof (_base = AppEnvironment.prototype._initializers)[appName] === "function" ? _base[appName](appName) : void 0;
      }
    };

    return AppEnvironment;

  })();

  Ajax = (function() {
    Ajax.prototype.__id__ = 'ajax';

    function Ajax() {
      CONNECT('inSide.Ajax.post', ((function(_this) {
        return function(_arg) {
          var data, url;
          url = _arg.url, data = _arg.data;
          return _this.get(url, data);
        };
      })(this)), this);
      CONNECT('inSide.Ajax.get', ((function(_this) {
        return function(_arg) {
          var data, url;
          url = _arg.url, data = _arg.data;
          return _this.get(url, data);
        };
      })(this)), this);
      CONNECT('inSide.Ajax.request', ((function(_this) {
        return function(_arg) {
          var data, method, url;
          method = _arg.method, url = _arg.url, data = _arg.data;
          return _this.get(method, url, data);
        };
      })(this)), this);
    }

    Ajax.prototype.get = function(sUrl, oData, fSuccess, fError) {
      return Ajax.prototype.request('GET', sUrl, oData, fSuccess, fError);
    };

    Ajax.prototype.getJSON = function(sUrl, oData, fSuccess, fError) {
      return Ajax.prototype.get(sUrl, oData, (function(r) {
        return fSuccess(JSON.parse(r.responseText));
      }), fError);
    };

    Ajax.prototype.post = function(sUrl, oData, fSuccess, fError) {
      return Ajax.prototype.request('POST', sUrl, oData, fSuccess, fError);
    };

    Ajax.prototype.postJSON = function(sUrl, oData, fSuccess, fError) {
      return Ajax.prototype.post(sUrl, oData, (function(r) {
        return fSuccess(JSON.parse(r.responseText));
      }), fError);
    };

    Ajax.prototype.request = function(sMethod, sUrl, oData, fSuccess, fError) {
      var request, requestData;
      request = new XMLHttpRequest();
      request.onreadystatechange = function() {
        var handler;
        if (request.readyState === 4) {
          handler = request.status === 200 ? fSuccess : fError;
          return typeof handler === "function" ? handler(request) : void 0;
        }
      };
      requestData = inSide.Url.encode(oData);
      if (sMethod === 'GET') {
        if (requestData) {
          sUrl += "?" + requestData;
        }
        requestData = null;
      }
      request.open(sMethod, sUrl, true);
      if (sMethod === 'POST') {
        request.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
      }
      return request.send(requestData);
    };

    return Ajax;

  })();

  Launcher = (function() {
    Launcher.prototype.toString = function() {
      return 'appLauncher';
    };

    function Launcher() {
      CONNECT('LAUNCHER_PUSH', 'push', this);
      CONNECT('LAUNCHER_REPLACE', 'push', this);
      CONNECT('LAUNCHER_BACK', 'back', this);
      CONNECT('LAUNCHER_START', 'start', this);
      CONNECT('LAUNCHER_CLEAR', 'clear', this);
      CONNECT('LAUNCHER_SET_ARG', 'setArg', this);
      this.defaultContainer = '#inSideContainer';
      this.defaultApp = 'Main:index';
      this.layout = 'Main:layout';
      this.currentView = null;
      this.storedStates = {};
      self.onhashchange = (function(_this) {
        return function(e) {
          var app, args, hash, _ref;
          if (e.newURL) {
            hash = e.newURL.split('#!');
          } else {
            hash = window.location.hash.split('#!');
          }
          if (hash[1] === _this.hash) {
            return;
          }
          _this.hash = hash[1];
          if (hash[1]) {
            _ref = hash[1].substr(1).split('/'), app = _ref[0], args = _ref[1];
          } else {
            app = _this.defaultApp;
            args = "";
          }
          AppEnvironment.prototype._kill(_this.defaultContainer);
          if (app) {
            EMIT('inSide.launcher.hashChange', {
              app: app
            });
            return inSide.run(app, _this.defaultContainer, inSide.Url.decode(args));
          }
        };
      })(this);
    }

    Launcher.prototype.start = function(_arg) {
      var app, args, layout, selector;
      layout = _arg.layout, app = _arg.app, selector = _arg.selector, args = _arg.args;
      if (!args) {
        args = {};
      }
      this.layout = layout;
      this.defaultApp = app;
      this.defaultContainer = selector;
      return inSide.run(layout, '#inSideContainer', args, (function(_this) {
        return function() {
          var hash, _ref;
          hash = window.location.hash.split('#!');
          if (!hash[1]) {
            app = _this.defaultApp;
            args = '';
          } else {
            _ref = hash[1].substr(1).split('/'), app = _ref[0], args = _ref[1];
            if (!app) {
              app = _this.defaultApp;
              args = '';
            }
          }
          if (app === null) {
            return;
          }
          return self.onhashchange({
            newURL: window.location.pathname + ("#!/" + app + "/" + args)
          });
        };
      })(this));
    };

    Launcher.prototype.clear = function() {
      var _base;
      this.hash = '';
      return typeof (_base = self.history).pushState === "function" ? _base.pushState(null, '', '#') : void 0;
    };

    Launcher.prototype.setArg = function(_arg) {
      var app, arg, args, hash, oldArgs, reload, _base, _ref, _ref1;
      args = _arg.args, reload = _arg.reload;
      hash = window.location.hash.split('#!');
      if (!hash[1]) {
        app = this.defaultApp;
        oldArgs = '';
      } else {
        _ref = hash[1].substr(1).split('/'), app = _ref[0], oldArgs = _ref[1];
        if (!app) {
          app = this.defaultApp;
          oldArgs = '';
        }
      }
      oldArgs = inSide.Url.decode(oldArgs);
      for (arg in args) {
        oldArgs[arg] = args[arg];
      }
      return typeof (_base = self.history).pushState === "function" ? _base.pushState(this.defaultContainer, (((_ref1 = this.currentView) != null ? _ref1.__printable__ : void 0) != null ? this.currentView.__printable__ : null), window.location.pathname + ("#!/" + app + "/" + (inSide.Url.encode(oldArgs)))) : void 0;
    };

    Launcher.prototype.back = function(_arg) {
      var defaultApp, defaultArgs;
      defaultApp = _arg.defaultApp, defaultArgs = _arg.defaultArgs;
      if (self.history.state) {
        return self.history.back();
      } else {
        return this.push({
          app: defaultApp,
          cont: this.defaultContainer,
          args: defaultArgs
        });
      }
    };

    Launcher.prototype.push = function(_arg) {
      var app, args, cont, _base, _ref;
      cont = _arg.cont, app = _arg.app, args = _arg.args;
      if (typeof (_base = self.history).pushState === "function") {
        _base.pushState(cont, (((_ref = this.currentView) != null ? _ref.__printable__ : void 0) != null ? this.currentView.__printable__ : null), window.location.pathname + ("#!/" + app + "/" + (inSide.Url.encode(args))));
      }
      return self.onhashchange({
        newURL: window.location.pathname + ("#!/" + app + "/" + (inSide.Url.encode(args)))
      });
    };

    return Launcher;

  })();

  containerApps = null;

  inSide.run = function(appName, selector, args, onload, parentId) {
    var doRun;
    if (parentId == null) {
      parentId = null;
    }
    doRun = function(appName, selector, args) {
      return AppEnvironment.prototype._registered[appName].run(selector, args, parentId, onload);
    };
    if (AppEnvironment.prototype._busy === true) {
      AppEnvironment.prototype._runQueue.push([appName, selector, args, this.__id__, onload]);
      return;
    }
    if (!(appName in AppEnvironment.prototype._registered)) {
      AppEnvironment.prototype._busy = true;
      return AppEnvironment.prototype._load(appName, selector, args, doRun);
    } else {
      return doRun(appName, selector, args);
    }
  };

  inSide.__Register('Ajax', Ajax);

  inSide.__Register('Apps', AppEnvironment);

  inSide.__Register('Launcher', Launcher);

}).call(this);
