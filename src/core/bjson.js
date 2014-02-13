// Generated by CoffeeScript 1.7.1
(function() {
  var TOKEN_SYM_START;

  TOKEN_SYM_START = -1;

  window.BJSON = (function() {
    function BJSON() {}

    BJSON.prototype.binDegrees = function(iNum) {
      var binDeg, binDegNum, rem;
      binDeg = 1;
      while (iNum >> binDeg) {
        ++binDeg;
      }
      --binDeg;
      binDegNum = 1 << binDeg;
      rem = iNum - binDegNum;
      return [binDeg, rem, binDegNum];
    };

    BJSON.prototype.dontUseLeftBranch = function(iMaxFreq, iOtherFreq, iSymbolCount) {
      var a1, a2, b1, b2, binDegree1, binDegree2, modulus1, modulus2, remainder1, remainder2, _ref, _ref1;
      _ref = this.binDegrees(iSymbolCount - 1), binDegree1 = _ref[0], remainder1 = _ref[1], modulus1 = _ref[2];
      _ref1 = this.binDegrees(iSymbolCount), binDegree2 = _ref1[0], remainder2 = _ref1[1], modulus2 = _ref1[2];
      a1 = Math.floor(((modulus1 - remainder1) * (binDegree1 + 1) + (remainder1 << 1) * (binDegree1 + 2)) / (iSymbolCount - 1));
      a2 = binDegree1 + (remainder1 << 1 ? 2 : 1);
      b1 = Math.floor(((modulus2 - remainder2) * binDegree2 + (remainder2 << 1) * (binDegree2 + 1)) / iSymbolCount);
      b2 = binDegree2 + (remainder2 << 1 ? 1 : 0);
      return iMaxFreq + iOtherFreq * a1 + (iOtherFreq % (iSymbolCount - 1)) * a2 < (iMaxFreq + iOtherFreq) * b1 + ((iMaxFreq + iOtherFreq) % iSymbolCount) * b2;
    };

    BJSON.prototype.freqSum = function(freqList, freq) {
      var freqName, sum, _i, _len;
      sum = 0;
      for (_i = 0, _len = freqList.length; _i < _len; _i++) {
        freqName = freqList[_i];
        sum += freq[freqName];
      }
      return sum;
    };

    BJSON.prototype.createTree = function(sMaxFreqSym, aOtherFreqSyms, iSymbolCount, oFrequencies, oTree, iPath, oPath, iLevel) {
      var leftFreqList, rightFreqList;
      iLevel++;
      if (sMaxFreqSym === void 0) {
        return;
      }
      if (!aOtherFreqSyms.length) {
        oTree[0] = sMaxFreqSym;
        oPath[sMaxFreqSym] = [iPath << 1, iLevel];
        return;
      }
      if (this.dontUseLeftBranch(oFrequencies[sMaxFreqSym], this.freqSum(aOtherFreqSyms, oFrequencies), iSymbolCount)) {
        oTree[0] = sMaxFreqSym;
        oPath[sMaxFreqSym] = [iPath << 1, iLevel];
        oTree[1] = {};
        this.createTree(aOtherFreqSyms[0], aOtherFreqSyms.slice(1), iSymbolCount - 1, oFrequencies, oTree[1], (iPath << 1) | 1, oPath, iLevel);
        if (oTree[1][0] === void 0 && typeof oTree[1][1] === typeof '') {
          oTree[1] = oTree[1][1];
          return oPath[oTree[1]] = [(iPath << 1) | 1, iLevel];
        }
      } else {
        oTree[1] = {};
        oTree[0] = {};
        aOtherFreqSyms.unshift(sMaxFreqSym);
        leftFreqList = aOtherFreqSyms.slice(0, aOtherFreqSyms.length / 2);
        rightFreqList = aOtherFreqSyms.slice(aOtherFreqSyms.length / 2);
        this.createTree(leftFreqList[0], leftFreqList.slice(1), leftFreqList.length, oFrequencies, oTree[0], iPath << 1, oPath, iLevel);
        if (oTree[0][1] === void 0 && typeof oTree[0][0] === typeof '') {
          oTree[0] = oTree[0][0];
          oPath[oTree[0]] = [iPath << 1, iLevel];
        }
        this.createTree(rightFreqList[0], rightFreqList.slice(1), rightFreqList.length, oFrequencies, oTree[1], (iPath << 1) | 1, oPath, iLevel);
        if (oTree[1][1] === void 0 && typeof oTree[1][0] === typeof '') {
          oTree[1] = oTree[1][0];
          return oPath[oTree[1]] = [(iPath << 1) | 1, iLevel];
        }
      }
    };

    BJSON.prototype.encode = function(sString, aTokens) {
      var char, current, freq, freqSort, len, maxFreq, path, res, rev, s, str, sym, token, tokenStart, tree, treeStr, _i, _j, _k, _len, _len1, _len2;
      freq = {};
      freqSort = [];
      tokenStart = TOKEN_SYM_START;
      if (aTokens == null) {
        aTokens = [];
      }
      for (_i = 0, _len = aTokens.length; _i < _len; _i++) {
        token = aTokens[_i];
        sString = sString.replace(new RegExp(token, 'g'), String.fromCharCode(tokenStart--));
      }
      for (_j = 0, _len1 = sString.length; _j < _len1; _j++) {
        char = sString[_j];
        if (freq[char] == null) {
          freq[char] = 0;
          freqSort.push(char);
        }
        freq[char]++;
      }
      maxFreq = 0;
      freqSort = freqSort.sort(function(a, b) {
        if (freq[a] < freq[b]) {
          return 1;
        }
        if (freq[a] > freq[b]) {
          return -1;
        }
        return 0;
      });
      tree = {};
      path = {};
      this.createTree(freqSort[0], freqSort.slice(1), sString.length, freq, tree, 1, path, 0);
      res = [];
      current = 0;
      len = 0;
      str = '';
      rev = function(byte) {
        var i;
        res = 0;
        i = 0;
        while (byte) {
          res = (res << 1) | (byte & 1);
          byte >>= 1;
        }
        return res;
      };
      for (_k = 0, _len2 = sString.length; _k < _len2; _k++) {
        char = sString[_k];
        s = path[char][1];
        sym = rev(path[char][0] & ((1 << s) - 1));
        current += sym << len;
        len += s;
        if (len > 8) {
          str = String.fromCharCode(current & 255) + str;
          len -= 8;
          current >>= 8;
        }
      }
      if (current) {
        str = String.fromCharCode(current & 255) + str;
      }
      treeStr = '';
      for (sym in path) {
        treeStr += sym + String.fromCharCode(path[sym][0]);
      }
      treeStr = String.fromCharCode(treeStr.length) + treeStr;
      return treeStr + str;
    };

    BJSON.prototype.decode = function(sString, aTokens) {
      var decodeBitStr, decodedChar, encChar, encoded, i, lastToken, path, pathStr, res, tokensLen, _i, _ref;
      if (!aTokens) {
        aTokens = [];
      }
      path = {};
      pathStr = sString.slice(1, sString[0].charCodeAt(0) + 1);
      encoded = sString.slice(sString[0].charCodeAt(0) + 1);
      for (i = _i = 0, _ref = pathStr.length / 2; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        path[pathStr[2 * i + 1].charCodeAt(0)] = pathStr[2 * i];
      }
      tokensLen = aTokens.length;
      lastToken = TOKEN_SYM_START - tokensLen;
      decodeBitStr = 0;
      res = '';
      while (encoded.length) {
        encChar = encoded[0].charCodeAt(0);
        encoded = encoded.slice(1);
        while (encChar) {
          while (!(decodeBitStr in path)) {
            decodeBitStr = (decodeBitStr << 1) | encChar & 1;
            encChar >>>= 1;
          }
          decodedChar = path[decodeBitStr];
          if (TOKEN_SYM_START - decodedChar.charCodeAt(0) > lastToken) {
            decodedChar = aTokens[TOKEN_SYM_START - decodedChar.charCodeAt(0)];
          }
          res += decodedChar;
        }
      }
      [sString[0].charCodeAt(0) + 1, sString, pathStr, encoded];
      return res;
    };

    BJSON.prototype.test = function() {
      var dec, res, str;
      str = 'test string';
      res = BJSON.prototype.encode(str);
      dec = BJSON.prototype.decode(res);
      return [str, res, dec];
    };

    return BJSON;

  })();

}).call(this);