// Generated by CoffeeScript 1.7.1
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

  URL = (function() {
    function URL() {}

    URL.prototype.encode = function(oSubObject, sPrefix) {
      var encoded, keyIndex, keyName, subObject;
      if (typeof oSubObject === typeof '') {
        return oSubObject;
      }
      encoded = [];
      for (keyIndex in oSubObject) {
        subObject = oSubObject[keyIndex];
        keyName = sPrefix ? "" + sPrefix + "[" + (encodeURIComponent(keyIndex)) + "]" : encodeURIComponent(keyIndex);
        encoded.push(typeof subObject !== typeof {} ? "" + keyName + "=" + (encodeURIComponent(subObject)) : URL.prototype.encode(subObject, keyName));
      }
      return encoded.join('&');
    };

    URL.prototype.decode = function(sUrlStr) {
      var hash, hashes, key, parseKey, val, vars, _i, _len, _ref;
      if (!sUrlStr) {
        return {};
      }
      if (sUrlStr === void 0) {
        sUrlStr = self.location.href.slice(self.location.href.indexOf('?') + 1);
      }
      hashes = sUrlStr.split('&');
      vars = {};
      parseKey = function(sKey, oObject, vValue) {
        var key, unparsed;
        key = sKey.substr(0, sKey.indexOf('['));
        if (!key) {
          oObject[sKey] = vValue;
          return;
        }
        if (oObject[key] == null) {
          oObject[key] = {};
        }
        unparsed = sKey.substr(sKey.indexOf('[') + 1);
        return parseKey(unparsed.substr(0, unparsed.indexOf(']')) + unparsed.substr(unparsed.indexOf(']') + 1), oObject[key], vValue);
      };
      for (_i = 0, _len = hashes.length; _i < _len; _i++) {
        hash = hashes[_i];
        _ref = decodeURIComponent(hash).split('='), key = _ref[0], val = _ref[1];
        parseKey(key, vars, val);
      }
      return vars;
    };

    return URL;

  })();


  /*
      СИГНАЛЫ
  
      Именование:
          sigName ::= [typeDescriptor] [a-zA-Z._]+
          typeDescriptor ::= [=]{,1}
      Типы:
      sigName - простой сигнал, отправляется на локальные объекты, подписка является постоянной
      =sigName - временный сигнал. отправляется на локальные объекты, подписка уничтожается после вызова
      * - любой сигнал
   */


  /*
   *TODO: сигналы с ограниченным числом перехватов
  signalModifiers=['=','*']
  parseSignal=(sSignal)->
      [signal,emitter]=sSignal.split(':')
      name=signal.replace(new RegExp('['+signalModifiers.join('')+']'),'')
      modifier=if signal[0] in signalModifiers then signal[0] else ''
      return {name,emitter,modifier}
  validateSignal=(sSignal)->
      if sSignal!='*'
          throw 'Bad signal name: '+sSignal if not (sSignal.match('^['+signalModifiers.join('')+']?[a-zA-Z][a-zA-Z_.]*$'))
   * Таблица соединений сигналов и объектов
  __connectionTable={}
  addConnection=(sSignal,sSlot,oReceiver,fSlot)->
      objectName=oReceiver.toString()
      __connectionTable[sSignal]={} if not __connectionTable[sSignal]?
      __connectionTable[sSignal][objectName]={instance:oReceiver,slots:{}} if not __connectionTable[sSignal][objectName]?
      if (fSlot)
          __connectionTable[sSignal][objectName].slots[sSlot]=fSlot
      else
          __connectionTable[sSignal][objectName].slots[sSlot]=oReceiver[sSlot]
      sSlot
  removeConnection=(sSignal,sSlot,oReceiver)->
      objectName=oReceiver.toString()
      if sSignal=='*'
          for sig of __connectionTable
              delete __connectionTable[sig][objectName] if __connectionTable[sig]?[objectName]?
          return
  
      if __connectionTable[sSignal]?[objectName]?.slots[sSlot]
          delete __connectionTable[sSignal][objectName].slots[sSlot]
      else
          return
      if Object.keys(__connectionTable[sSignal][objectName].slots).length==0
          delete __connectionTable[sSignal][objectName]
          if Object.keys(__connectionTable[sSignal]).length==0
              delete __connectionTable[sSignal]
  invoke=(sSignal,oData={},emitResult=false)->
       * TODO: отправлять на дочерние окна
       *[signal,uid]=sSignal.split(':')
      sigData=parseSignal(sSignal)
      temporary=(sigData.modifier=='=')
      invokeSlots=(connectionList)->
          for appName,connectionInfo of connectionList
              for slotName,slot of connectionInfo.slots
                  if DEBUG
                      console.log('['+new Date().toLocaleTimeString()+'] =INVOKE=  '+connectionInfo.instance.__app__+'.'+connectionInfo.instance.__name__+'.'+slotName+'('+JSON.stringify(oData)+'):'+sigData.emitter)
                   *fi DEBUG
                  oData.__signal__=sigData.name
                  res=slot.call(connectionInfo.instance,oData,sigData.emitter)
                  if sigData.emitter and emitResult and res isnt null
                      EMIT '='+sigData.name,res,sigData.emitter
                   *Удаляем временные сигналы
                  if temporary
                      removeConnection('='+sigData.name+(if sigData.emitter then ':'+sigData.emitter else ''),slotName,connectionInfo.instance)
          return
       * Локальная рассылка
      if __connectionTable[sSignal]
          invokeSlots(__connectionTable[sSignal])
      else if __connectionTable[sigData.modifier+sigData.name]
          invokeSlots(__connectionTable[sigData.modifier+sigData.name])
  
   * Удалить подписку на сигнал
   * sSignal - название сигнала
   * sSlot - название обработчика сигнала
   * oReceiver - объект, для которого выполнить отключение
  self.DISCONNECT=(sSignal,sSlot,oReceiver,UID=null)->
      validateSignal(sSignal)
      sSignal+=(':'+UID) if UID
      removeConnection(sSignal,sSlot,oReceiver)
   * Подписать объект на сигнал. Возвращает название обработчика, которое можно использовать для отключение
   * sSignal - название сигнала
   * sSlot - название обработчика сигнала, содержащегося в oReceiver. Если sSlot - функция, генерируется уникальный ID
   * oReceiver - объект, для которого выполнить подключение. oReceiver должен иметь свойство toString, возвращающее уникальное имя объекта
  self.CONNECT=(sSignal,sSlot,oReceiver,UID=null)->
      validateSignal(sSignal)
      sSignal+=(':'+UID) if UID
       * Если sSlot - функция, генерируем UID и подписываем объект на анонимную функцию
      if (typeof sSlot == typeof(->))
          fSlot=sSlot
          sSlot=inSide.__nextID()
      else
          throw "No such slot: #{sSlot}" if not oReceiver[sSlot]?
      addConnection(sSignal,sSlot,oReceiver,fSlot)
   * Порождение сигнала
   * sSignal - название сигнала
   * oArgs - параметры сигнала
   * oSender - отправитель
  self.EMIT=(sSignal,oArgs,oSender=null,emitResult=false)->
      if DEBUG
          console.log('['+new Date().toLocaleTimeString()+'] =EMIT=    '+sSignal+'('+JSON.stringify(oArgs)+'):'+if oSender then oSender.__id__ else '*')
       *fi DEBUG
      validateSignal(sSignal)
      sSignal=(sSignal+':'+(if oSender.__id__? then oSender.__id__ else oSender.toString())) if oSender
      invoke(sSignal,oArgs,emitResult)
  self.EMIT_AND_WAIT=(oSender,sSignal,oArgs,sSlot)->
      sSignal.replace('=','')
      validateSignal(sSignal)
      CONNECT('='+sSignal,sSlot,oSender,oSender.__id__)
      EMIT(sSignal,oArgs,oSender,true)
  
  class Signal
      constructor:(@context,@name,@maxHandlers=-1)->@
      setMaxHandlers:(@maxHandlers=-1)->@
      tunnel:(@tunnelName)->@
      emit:(args)->EMIT(@name,args);return @
      emitAndWait:(args)->EMIT_AND_WAIT(@context,@name,args,@name+'=');return @
      _serialize:()->
  class SigHandler
      constructor:(@context,@sigName,@handler)->
      _deserialize:()->
   */

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