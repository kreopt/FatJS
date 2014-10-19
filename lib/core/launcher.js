!function () {
    class Launcher {
        // url: /state/substate/subsubstate/...

        init(url) {
            // run states consequently
            let states = url.split('/');
        }

        push(state, args) {
            window.history.pushState(args, state.title, state.url);
            // state.container
            // destroy old app in state.container
            // run newapp
        }

        replace(state, args) {
            window.history.replaceState(args, state, state.url);
        }

        back() {
            window.history.back();
        }

        forward() {
            window.history.forward();
        }
    }
    window.addEventListener('popstate', (e)=> {
        // destroy old app
        // run new app
    });
    Fat.Launcher = new Launcher();
}();