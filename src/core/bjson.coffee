# Компрессия и декомпрессия JSON-данных

TOKEN_SYM_START=-1
class window.BJSON
    binDegrees:(iNum)->
        binDeg=1
        while iNum>>binDeg
            ++binDeg
        --binDeg
        binDegNum=1<<binDeg
        rem=iNum-binDegNum
        [binDeg,rem,binDegNum]
    dontUseLeftBranch:(iMaxFreq,iOtherFreq,iSymbolCount)->
        [binDegree1,remainder1,modulus1]=@binDegrees(iSymbolCount-1)
        [binDegree2,remainder2,modulus2]=@binDegrees(iSymbolCount)
        a1=Math.floor(((modulus1-remainder1)*(binDegree1+1)+(remainder1<<1)*(binDegree1+2)) / (iSymbolCount-1))
        a2=binDegree1+if remainder1<<1 then 2 else 1
        b1=Math.floor(((modulus2-remainder2)*(binDegree2)+(remainder2<<1)*(binDegree2+1)) / iSymbolCount)
        b2=binDegree2+if remainder2<<1 then 1 else 0
        return iMaxFreq+iOtherFreq*a1+(iOtherFreq%(iSymbolCount-1))*a2<(iMaxFreq+iOtherFreq)*b1+((iMaxFreq+iOtherFreq)%iSymbolCount)*b2
    freqSum:(freqList,freq)->
        sum=0
        for freqName in freqList
            sum+=freq[freqName]
        sum
    createTree:(sMaxFreqSym,aOtherFreqSyms,iSymbolCount,oFrequencies,oTree,iPath,oPath,iLevel)->
        iLevel++
        return if sMaxFreqSym==undefined
        if not aOtherFreqSyms.length
            oTree[0]=sMaxFreqSym
            oPath[sMaxFreqSym]=[(iPath<<1),iLevel]
            return
        if @dontUseLeftBranch(oFrequencies[sMaxFreqSym],@freqSum(aOtherFreqSyms,oFrequencies),iSymbolCount)
            oTree[0]=sMaxFreqSym
            oPath[sMaxFreqSym]=[(iPath<<1),iLevel]
            oTree[1]={}
            @createTree(aOtherFreqSyms[0],aOtherFreqSyms.slice(1),iSymbolCount-1,oFrequencies,oTree[1],(iPath<<1)|1,oPath,iLevel)
            if oTree[1][0]==undefined and typeof(oTree[1][1])==typeof('')
                oTree[1]=oTree[1][1]
                oPath[oTree[1]]=[(iPath<<1)|1,iLevel]
        else
            oTree[1]={}
            oTree[0]={}
            aOtherFreqSyms.unshift(sMaxFreqSym)
            leftFreqList=aOtherFreqSyms.slice(0,aOtherFreqSyms.length / 2)
            rightFreqList=aOtherFreqSyms.slice(aOtherFreqSyms.length / 2)
            @createTree(leftFreqList[0],leftFreqList.slice(1),leftFreqList.length,oFrequencies,oTree[0],(iPath<<1),oPath,iLevel)
            if oTree[0][1]==undefined and typeof(oTree[0][0])==typeof('')
                oTree[0]=oTree[0][0]
                oPath[oTree[0]]=[(iPath<<1),iLevel]
            @createTree(rightFreqList[0],rightFreqList.slice(1),rightFreqList.length,oFrequencies,oTree[1],(iPath<<1)|1,oPath,iLevel)
            if oTree[1][1]==undefined and typeof(oTree[1][0])==typeof('')
                oTree[1]=oTree[1][0]
                oPath[oTree[1]]=[(iPath<<1)|1,iLevel]
    encode:(sString,aTokens)->
        freq={}
        freqSort=[]
        tokenStart=TOKEN_SYM_START
        aTokens=[] if not aTokens?
        for token in aTokens
            sString=sString.replace(new RegExp(token,'g'),String.fromCharCode(tokenStart--))
        for char in sString
            if not freq[char]?
                freq[char]=0
                freqSort.push(char)
            freq[char]++
        maxFreq=0
        freqSort=freqSort.sort (a,b)->
            return 1 if freq[a]<freq[b]
            return -1 if freq[a]>freq[b]
            return 0
        tree={}
        path={}
        @createTree freqSort[0],freqSort.slice(1),sString.length,freq,tree,1,path,0

        #[tree,path]
        res=[]
        current=0
        len=0
        str=''
        rev=(byte)->
            res=0
            i=0
            while (byte)
                res=((res<<1)|(byte&1))
                byte>>=1
            res
        for char in sString
            s=path[char][1]
            sym=rev(path[char][0]&((1<<s)-1))
            current+=sym<<len
            len+=s
            if len>8
                str=String.fromCharCode(current&255)+str
                len-=8
                current>>=8
        if current
            str=String.fromCharCode(current&255)+str
        treeStr=''
        for sym of path
            treeStr+=sym+String.fromCharCode(path[sym][0])
        treeStr=String.fromCharCode(treeStr.length)+treeStr
        treeStr+str
            #TODO: byte string
    decode:(sString,aTokens)->
        # Пока не работает
        aTokens=[] if not aTokens
        path={}
        pathStr=sString.slice(1,sString[0].charCodeAt(0)+1)
        encoded=sString.slice(sString[0].charCodeAt(0)+1)
        for i in [0...pathStr.length / 2]
            path[pathStr[2*i+1].charCodeAt(0)]=pathStr[2*i]
        #decoding..
        tokensLen=aTokens.length
        lastToken=TOKEN_SYM_START-tokensLen

        decodeBitStr=0
        res=''
        while encoded.length
            encChar=encoded[0].charCodeAt(0)
            encoded=encoded.slice(1)
            while encChar
                while decodeBitStr not of path
                    decodeBitStr=(decodeBitStr<<1)|encChar&1
                    encChar>>>=1
                decodedChar=path[decodeBitStr]
                if TOKEN_SYM_START-decodedChar.charCodeAt(0)>lastToken
                    decodedChar=aTokens[TOKEN_SYM_START-decodedChar.charCodeAt(0)]
                res+=decodedChar
        [sString[0].charCodeAt(0)+1,sString,pathStr,encoded]
        res
    test:->
        str='test string'
        res=BJSON.prototype.encode(str)
        dec=BJSON.prototype.decode(res)
        [str,res,dec]