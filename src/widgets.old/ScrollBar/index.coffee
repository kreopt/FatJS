handle=(delta)->
    #TODO: smooth scroll
    container.scrollTop+=delta*15
wheel=(event)->
    delta = 0;
    if (!event)
        event = window.event
    if (event.wheelDelta)
        delta = event.wheelDelta/120
    else if (event.detail)
        delta = -event.detail/3

    if (delta && typeof handle == 'function')
        handle(delta)
        if (event.preventDefault)
            event.preventDefault();
        event.returnValue = false;

if (window.addEventListener)
    window.addEventListener('DOMMouseScroll', wheel, false)
window.onmousewheel = document.onmousewheel = wheel;