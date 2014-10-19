(function () {
    var ui = {},
        compiled = {},
        engines = {},
        templates = {},
        instances = {},
        options = {
            engine: 'jade',
            loader: 'http'
        },
        renderEngine = null;

    function attachEvents(scope, fragment, events) {
        //TODO: use jQuery event delegation
        if (!events) {
            return;
        }
        for (var j = 0, keys = Object.keys(events), klen = keys.length; j < klen; j++) {
            var selector = keys[j],
                nodes = fragment.querySelectorAll(selector),
                selectorEvents = events[selector];

            for (var i = 0, len = nodes.length; i < len; i++) {
                for (var k = 0, ekeys = Object.keys(selectorEvents), elen = ekeys.length; k < elen; k++) {
                    var event = ekeys[k],
                        listener = selectorEvents[event];
                    if (typeof listener === 'function') {
                        $(selector, fragment).on(event, listener.bind(scope));
                    }
                }
            }
        }
    }

    function getData(datasources) {
        if (datasources instanceof Fat.Datasource) {
            return datasources.fetch();
        } else {
            if (datasources.length === 1) {
                return getData(datasources[0]);
            }
            let datasource = datasources[0];
            datasources = datasources.splice(1);
            return new Promise(function (resolve, reject) {
                Promise.all([getData(datasource), getData(datasources)]).then((arg_list)=> {
                    resolve(Object.assign(arg_list[0], arg_list[1]));
                }).catch(()=> {
                    reject();
                });
            });
        }
    }

    var UI = {
        configure: function (new_options) {
            Object.assign(options, new_options);
        },
        postMessage: function (uiName, msgName, data) {
            $(ui[uiName]).triggerHandler(msgName, data);
        },
        addRenderEngine: function (engineName, engine) {
            if (!(engine.compile && engine.render)) {
                throw 'Failed to register "' + engineName + '" engine! "compile" and "render" functions must be present';
            }
            engines[engineName] = engine;
        },
        setRenderEngine: function (engineName) {
            renderEngine = engines[engineName];
        },
        addLoader: function (name, loader) {
            UI.Loader[name] = loader;
        },
        createElement: function (name) {
            if (!ui.hasOwnProperty(name)) {
                ui[name] = new UI.Element(name);
            } else {
                console.error("Failed to register ui: already exists");
            }
            return ui[name];
        },
        render: function (uiName, instanceName, datasources, ready) {
            if (!renderEngine) {
                throw 'Render engine is not set! Use FatJS.UI.setRenderEngine in your config file';
            }
            Fat.UI.destroyInstance(instanceName);
            /*if (instances[instanceName]){
             console.error('Failed to run instance '+instanceName+': already exists');
             return;
             }*/
            ui[uiName].loadTemplate(function (template) {
                if (!compiled[uiName]) {
                    compiled[uiName] = renderEngine.compile(template);
                }
                var fragment = document.createDocumentFragment();
                var d = document.createElement('div');
                getData(datasources, function (args) {
                    d.innerHTML = renderEngine.render(compiled[uiName], args);
                    instances[instanceName] = new UI.ElementInstance(ui[uiName], instanceName);
                    attachEvents(instances[instanceName], d, ui[uiName].events);
                    for (var i = 0, len = d.children.length; i < len; i++) {
                        // TODO: test in all browsers
                        fragment.appendChild(d.children[0]);
                    }
                    Object.defineProperty(instances[instanceName], 'fragment', {
                        get: function () {
                            return fragment;
                        }
                    });
                    Object.defineProperty(instances[instanceName], 'elements_container', {
                        get: function () {
                            return d;
                        }
                    });
                    Object.defineProperty(instances[instanceName], 'args', {
                        value: args
                    });
                    ready(instances[instanceName]);
                });
            });
        },
        renderInto: function (uiName, instanceName, datasources, adjacentNode, position, ready) {
            Fat.UI.render(uiName, instanceName, datasources, function (instance) {
                Fat.UI.putFragmentNode(adjacentNode, position, instance.fragment);
                if (typeof ready === 'function') {
                    ready(instance);
                }
            });
        },
        renderIntoSelector: function (uiName, instanceName, datasources, scope, selector, position, ready) {
            Fat.UI.render(uiName, instanceName, datasources, function (instance) {
                Fat.UI.putFragmentSelector(scope, selector, position, instance.fragment);
                if (typeof ready === 'function') {
                    ready(instance);
                }
            });
        },
        putFragmentNode: function (adjacentNode, position, fragment) {
            // FF does not support insertAdjacentElement:(
            switch (position.toLowerCase()) {
                case 'beforebegin':
                    adjacentNode.parentNode.insertBefore(fragment, adjacentNode);
                    break;
                case 'beforeend':
                    adjacentNode.appendChild(fragment);
                    break;
                case 'afterbegin':
                    adjacentNode.insertBefore(fragment, adjacentNode.firstChild);
                    break;
                case 'afterend':
                    adjacentNode.parentNode.insertBefore(fragment, adjacentNode.nextSibling);
                    break;
                case 'instead':
                    adjacentNode.innerHTML = '';
                    adjacentNode.appendChild(fragment);
                    break;
            }
        },
        putFragmentSelector: function (scope, selector, position, fragment) {
            var node = scope.querySelector(selector);
            if (node) {
                this.putFragmentNode(node, position, fragment);
            }
        },
        putNode: function (adjacentNode, position, uiName, args) {
            var ui = ui[uiName];
            if (!ui) {
                console.error('Failed to render "' + uiName + '": no such element');
                return null;
            }
            var fragment = this.render(uiName, args);

            if (ui.css && !adjacentNode.parentNode.querySelector('style[data-ui="' + uiName + '"]')) {
                var style = document.createElement('style');
                style.setAttribute('scoped', 'scoped');
                style.setAttribute('data-ui', uiName);
                style.innerHTML = ui.css;
                adjacentNode.parentNode.insertBefore(style, adjacentNode.parentNode.firstChild);
            }
            this.putFragmentNode(adjacentNode, position, fragment);
            return fragment;
        },
        putSelector: function (scope, selector, position, uiName, args) {
            var node = scope.querySelector(selector);
            if (node) {
                this.putNode(node, position, uiName, args);
            }
        },
        destroyInstance: function (instanceName) {
            if (instances[instanceName]) {
                delete instances[instanceName];
            }
        }
    };

    Object.defineProperty(UI, 'templates', {
        get: function () {
            return templates;
        }
    });

    UI.Loader = {};

    UI.Element = function (name) {
        var _name = name;
        var _template = null;
        var _css = null;
        var _events = null;
        var _loader = null;

        Object.defineProperties(this, {
            template: {
                get: function () {
                    return _template;
                },
                set: function (val) {
                    if (typeof val === 'string') {
                        _template = val;
                    } else {
                        console.log('Bad template!');
                    }
                }
            },
            css: {
                get: function () {
                    return _css;
                },
                set: function (val) {
                    if (typeof val === 'string') {
                        //TODO: media queries
                        _css = '<style scoped="scoped" data-ui="' + _name + '">@import url(' + val + ');</style>';
                    } else {
                        console.log('Bad CSS!');
                    }
                }
            },
            events: {
                set: function (val) {
                    if (typeof val === 'object') {
                        _events = val;
                    }
                },
                get: function () {
                    return _events;
                }
            },
            setLoader: {
                value: function (loaderName) {
                    if (!UI.Loader(loaderName)) {
                        throw 'No such loader: ' + loaderName;
                    }
                    _loader = UI.Loader(loaderName);
                }
            },
            loadTemplate: {
                value: function (ready) {
                    if (!_loader) {
                        _loader = UI.Loader[options.loader];
                    }
                    _loader.loadTemplate(_name, _template, ready);
                }
            }
        });

        function connect(scope, connections, handler_scope) {
            for (var message in connections) {
                if (connections.hasOwnProperty(message) && typeof connections[message] === 'function') {
                    $(scope).on(message, connections[message].bind(handler_scope))
                }
            }
        }

        UI.Element.prototype.destroy = function (instanceName) {
            delete instances[instanceName];
        };

        UI.Element.prototype.connect = function (connections, scope) {
            connect(this, connections, scope);
        };
        UI.Element.prototype.postMessage = function (message, data) {
            $(this).triggerHandler(message, data);
        };
        UI.ElementInstance = function (element, name) {
            this.element = element;
            this.name = name;
        };
        UI.ElementInstance.prototype.connect = function (connections, scope) {
            connect(this, connections, scope);
        };
        UI.ElementInstance.prototype.postMessage = function (message, data) {
            $(this).triggerHandler(message, data);
        };
    };

    Fat.UI = UI;
})();
