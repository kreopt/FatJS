CMP 'jafw.gui.ToggleButton',
    __forms:['@button']
    __css:['lib/toggleButton']
    _init:->
    put:(DOMContainer)->
        @container=DOMContainer
        @state=0
        @RENDER '@button',@container
        @setActive(@state)
        $s('div.ToggleButton',@container).onclick= =>
            @state^=1
            @setActive(@state)
    setActive:(bState)->
        @state=Number(bState)
        if bState
            addClass($s('div.ToggleButton',@container),'Active')
            addClass($s('div.Switch',@container),'Active')
            addClass($s('div.SwitchSym',@container),'Active')
            $s('div.SwitchSym',@container).innerHTML="Вкл"
        else
            removeClass($s('div.ToggleButton',@container),'Active')
            removeClass($s('div.Switch',@container),'Active')
            removeClass($s('div.SwitchSym',@container),'Active')
            $s('div.SwitchSym',@container).innerHTML="Выкл"
        @onStateChange?(bState)
