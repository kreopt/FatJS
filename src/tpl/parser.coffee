###
    NON-STANDARD OPERATORS:
    $a**$b - b degree of a
    $a#$b - concatenate
    $a? - existance
###
# tokens[TOKEN][0] - регулярное выражение
# tokens[TOKEN][1] - обработчик токена
tokens={
    FOREACH:[/^foreach/]
    FOR:[/^for/]
    WHILE:[/^while/]
    SECTION:[/^section/]
    CDATA:[/^literal/]
    BLOCK:[/^block/]
    IF:[/^if/]

    ENDFOREACH:[/^\/foreach/]
    ENDFOR:[/^\/for/]
    ENDWHILE:[/^\/while/]
    ENDSECTION:[/^\/section/]
    ENDCDATA:[/^\/literal/]
    ENDBLOCK:[/^\/block/]
    ENDIF:[/^\/if/]

    ELSE:[/^else/]
    ELIF:[/^elif/]
    IN:[/^in/]
    AS:[/^as/]
    LOOP:[/^loop/]
    INCLUDE:[/^include/]
    EXTENDS:[/^extends/]

    IDENTIFIER: [/^[A-Za-z_$][A-Za-z0-9_$]*/,(parser,token)->parser.vars[token]=null]
    NUMBER:     [/^[0-9]+/]
    STRING:     [/^"[^"]*"|'[^']*'/]
    OPERATION:  [/^\=\=|!=|<|>|>=|>=|!==|===/]
    BINOPERATOR:   [/^\+|-|\*|\/|%|\||\^|\&|=|\+=|-=|\*=|\/=|%=|\|=|\&=|\^=|\&\&|\|\||>>|<<|>>>|\*\*|\#/]
    PREOPERATOR:   [/^\+\+|--|-|~|!/]
    POSTOPERATOR:  [/^\+\+|--|\?/]
    ARRAYBEGIN:    [/^\[/,(parser)->]
    ARRAYEND:      [/^\]/,(parser)->]
    COMMA:         [/^,/]
    DOT:           [/^\./]
}
T=tokens
blockTags=[
    'FOREACH'
    'FOR'
    'WHILE'
    'SECTION'
    'CDATA'
    'BLOCK'
    'IF'
]
endblockTags=[
    'ENDFOREACH'
    'ENDFOR'
    'ENDWHILE'
    'ENDSECTION'
    'ENDCDATA'
    'ENDBLOCK'
    'ENDIF'
]
g=(gram)->return ->tagGram(gram)
tagGram={
    expression:[
        [T.IDENTIFIER]
        [T.NUMBER]
        [g 'expression',T.BINOPERATOR,g 'expression']
        [g 'expression',T.OPERATION,g 'expression']
        [T.PREOPERATOR,g 'expression']
        [g 'expression',T.POSTOPERATOR]
    ]
    body:[
        [g 'line']
        [g 'block']
    ]
    line:[
        ['']
        [g 'expression']
        [g 'expression',';',g 'line']
    ]
    block:[
        [g 'foreach']
    ]
    foreach:    [
        ['foreach',T.IDENTIFIER,'as',T.IDENTIFIER]
        ['foreach',T.IDENTIFIER,'as',T.IDENTIFIER,'=>',T.IDENTIFIER]
    ]
}
# Лескический анализатор шаблонного движка.
# Управляющие конструкции - теги, заключаются в {фигурные скобки}.
# Все, что вне фигурных скобок считается текстом и не обрабатывается
class Parser
    constructor:->
        Object.defineProperty(@,'stack',{get:->@stacksStack[@stacksStack.length-1].node})
        Object.defineProperty(@,'stacktype',{get:->@stacksStack[@stacksStack.length-1].type})

    # Закрыть стек блока и вернуться к родительскому
    popStack:->@stacksStack.pop()

    # Добавить стек блока
    pushStack:(oNode)->@stacksStack.push(oNode)

    # Начать разбор строки
    parse:(sTplString)->
        @vars={}
        @const={}
        # Стек найденных узлов в порядке их следования
        # Узлы бывают трех типов: текст, токен и стек. Свои стеки формируются только для блочных конструкций типа foreach
        @parseStack={type:'ROOT',node:[]}
        # Стек стеков блоков. На верху находится стек, в который заносятся узлы в данный момент.
        # Например, для строки text{$var=[1,2,3]}{foreach $var as $v}{$v}text2{/foreach}text3 будет созадно два стека
        # с содержимым:
        # [{type:TEXT,value="text"},{type:IDENTIFIER,name="var"},
        # {type:BINOPERATOR,op="="},..,{type:FOREACH,node:[{type:IDENTIFIER,name="var"},{type:TEXT,value="text2"}]},
        # {type:TEXT,value="text3"}]
        @stacksStack=[@parseStack]

        @lineNumber=1
        tagNumber=0
        while sTplString
            [prefix,tag,sTplString]=@findTag(sTplString)
            # Связывает узел с предыдущим и следующим
            link=(node)=>
                if @stack[@stack.length-1]
                    node.prev=@stack[@stack.length-1]
                    @stack[@stack.length-1].next=node
                node.next=null
                node.tag=tagNumber
            #Добавляем текстовый узел, если он есть
            if prefix
                node={type:'TEXT',value:prefix}
                link(node)
                @stack.push node
            tagTokens=@parseTag(tag)
            # Обработка найденных токенов
            continue if not tagTokens.length
            if tagTokens[0][0] in blockTags
                # Если первый токен блочный, создаем для него отдельный стек, в который будут помещаться
                # его внутренние токены
                node={type:tagTokens[0][0],node:[]}
                link(node)
                # Обработка специфичных для блока параметров
                # ...
                @stack.push node
                @pushStack(node)
            else if tagTokens[0][0] in endblockTags
                # Если это закрывающий блочный токен и он совпадает с последним открывающим
                if @stacktype==tagTokens[0][0].replace(/^END/,'')
                    # Возвращаемся к родительскому стеку
                    @popStack()
                else
                    # Если закрывающий токен не соответствует открывающему - выкидываем ошибку
                    throw @lineNumber+': Unmatched close tag "'+tagTokens[0][0]+'"'
            else
                # Обрабатываем одиночные теги, оптимизируя выражения и приводя их к постфиксной записи
                tagTokens.map((node)=>node={type:node[0],value:node[2]};link(node);@stack.push(node))
            tagNumber++
        return @parseStack

    # Поиск {тега} в строке sTplString.
    # Возвращаемое значение: [Текст перед тегом, Содержимое тега, Оставшаяся строка после закрывающей скобки тега]
    findTag:(sTplString)->
        # Ищем начало и конец тега
        startIndex=sTplString.indexOf('{')
        # Если тега нет, возвращаем текст
        return [sTplString,'',''] if startIndex==-1
        endIndex=sTplString.indexOf('}')
        # Ищем переводы строки для вычисления номера строки
        lineBreakIndex=sTplString.indexOf('\n')
        # При ошибке внутри тега будет указан номер строки, где ег кончается
        while lineBreakIndex>=0 and lineBreakIndex<endIndex
            lineBreakIndex=sTplString.indexOf('\n',lineBreakIndex+1)
            @lineNumber++
        # Если нашли закрывающую скобку без открывающей - выкидываем ошибку
        throw @lineNumber+': Unmatched } near "...'+sTplString.substr((if endIndex>=10 then endIndex-10 else 0),20)+'..."' if endIndex<startIndex
        return [sTplString.substr(0,startIndex),
                sTplString.substr(startIndex+1,endIndex-startIndex-1),
                sTplString.slice(endIndex+1)]

    # Поиск токена в строке sTagStr
    # Возвращаемое значение: [имя токена,длина токена,токен] или null, если токен - завершающая пустая строка
    nextToken:(sTagStr)->
        # Завершаем разбор, если sTagStr состоит только из пробелов
        return null if sTagStr.match(/^\s*$/)
        # Пустой токен - пробелы
        return [null,match[0].length,match[0]] if match=sTagStr.match(/^\s+/)
        # Проверяем токен на соответствие регулярным выражениям
        for tokenName,tokenRE of tokens
            if match=sTagStr.match(tokenRE[0])
                tokenRE[1](@,match[0]) if tokenRE[1]
                return [tokenName,match[0].length,match[0]]
        # Если не было найдено ни одного совпадения - выкидываем ошибку о некорректности токена
        throw @lineNumber+': No match for token "'+sTagStr+'"'

    # Поиск токенов в теге
    # Возвращаемое значение: массив узлов токенов
    parseTag:(sTagStr)->
        # Найденные токены тега будут храниться здесь
        tagTokens=[]
        token=@nextToken(sTagStr)
        # Продолжаем, пока nextToken не вернет null, т.е. не будет найден конец токена
        while token!=null
            # Если токен - не связка пробелов, заносим его в стек
            tagTokens.push(token); token if token[0]
            # Удаляем найденный токен из строки поиска
            sTagStr=sTagStr.substr(token[1])
            token=@nextToken(sTagStr)
        return tagTokens
window.Parser=new Parser()