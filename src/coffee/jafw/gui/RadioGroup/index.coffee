CMP 'jafw.gui.RadioGroup',
    _init:(oConfig)->
        if not oConfig? or not oConfig.className? or not oConfig.default?
            throw 'No span class or default value passed. RequiredParams are {className,default}'
        @onSelect=oConfig.onSelect
        @span(oConfig.className,oConfig.default,oConfig.scope)
    #span Toggle buttons in the group
    span:(sClassName,vInitialVal,DOMScope)->
        @className=sClassName
        DOMScope=$d if not DOMScope
        @scope=DOMScope
        app=@
        addClass(el,'Toggle') for el in $a('.'+sClassName,DOMScope)
        addEventBySelector '.'+sClassName,DOMScope,'click',->
            oldNodes=$a('.'+sClassName)
            removeClass(node,'Toggled') for node in oldNodes
            addClass(@,'Toggled')
            app.onSelect?(@,$a('.'+sClassName+':not(.Toggled)'))
        @toggled=$s('.'+sClassName+'[data-value="'+vInitialVal+'"]',DOMScope)
        addClass(@toggled,'Toggled')
        @onSelect?(@toggled,$a('.'+sClassName+':not(.Toggled)',DOMScope))

#returns radio group selected value
CPROPERTY 'jafw.gui.RadioGroup.value',
    get:->
        toggleElement = $s('.'+@className+'.Toggled',@scope)
        if hasClass(toggleElement, @className)
            toggleElement.dataset['value']
            return toggleElement.dataset['value']
        else
            return null
    set:(vVal)->
        toggled=$s('.'+@className+'[data-value="'+vVal+'"]')
        addUniqueClass(toggled,'Toggled',@scope)
        @onSelect?(toggled,$a('.'+@className+':not(.Toggled)',@scope))
