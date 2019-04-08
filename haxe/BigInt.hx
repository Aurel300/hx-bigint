package haxe;

typedef BigIntT =
#if BIGINT_INT64
  haxe.Int64;
#else
  Int;
#end

// #define DEBUG_TOSTRING

// TODO: this assumes a 64-bit JS Int
// should it use Int64 for individual number components? at least for BigIntS?
// (e.g. in smallToArray, and the constannts)
class BigInt {
  // static stuff
  public static var one(default, null):BigInt;
  public static var zero(default, null):BigInt;
  public static var minusOne(default, null):BigInt;
  public static var constants(default, null):Map<Int, BigInt>;
  
  public static function init():Void {
    BASE_BIG = fromInt(BASE);
    one = new BigIntS(1);
    zero = new BigIntS(0);
    minusOne = new BigIntS(-1);
    constants = [ for (i in -999...1000) i => (new BigIntS(i):BigInt ) ];
    highestPower2Big = fromInt(highestPower2);
    powersOfTwoBig = powersOfTwo.map(fromInt);
  }
  
#if BIGINT_INT64
  // must be chosen so that 2 * BASE * BASE < MAX_INT
  static var BASE:BigIntT = 10000000; // 1e7
  // TODO: (perf) make BASE inline ?
  static var BASE_SQUARED:BigIntT = BASE * BASE;
  static var LOG_BASE = 7;
  static var MAX_INT:BigIntT = Int64.make(0x7FFFFFFF, 0xFFFFFFFF);
  static var MAX_INT_HALF:BigIntT = 0xFFFFFFFF;
  static var MAX_INT_HALF_BITS:Int = 32;
  static var MIN_INT:BigIntT = -MAX_INT;
  static var LOBMASK_I = 1 << 30;
  static var LOBMASK_BI = (BASE & -BASE) * (BASE & -BASE) | LOBMASK_I;
#else
  static var BASE:BigIntT = 10000; // 1e4
  static var BASE_SQUARED:BigIntT = BASE * BASE;
  static var LOG_BASE = 4;
  static var MAX_INT:BigIntT = 0x7FFFFFFF;
  static var MAX_INT_HALF:BigIntT = 0xFFFF; // TODO: 7FFF?
  static var MAX_INT_HALF_BITS:Int = 16;
  static var MIN_INT:BigIntT = -0x7FFFFFFF;
  static var LOBMASK_I = 1 << 30;
  static var LOBMASK_BI = (BASE & -BASE) * (BASE & -BASE) | LOBMASK_I;
#end
  static var BASE_BIG:BigInt;
  static var BASE_ZEROS = StringTools.rpad("", "0", LOG_BASE);
  static var MAX_INT_ARR = smallToArray(MAX_INT);
  static var DEFAULT_ALPHABET = "0123456789abcdefghijklmnopqrstuvwxyz";
  
  static var highestPower2:BigIntT;
  static var highestPower2Big:BigInt;
  static var powers2Length:BigIntT;
  static var powersOfTwoBig:Array<BigInt>;
  static var powersOfTwo:Array<BigIntT> = {
      var powers:Array<BigIntT> = [1];
      while (2 * powers[powers.length - 1] <= BASE) powers.push(2 * powers[powers.length - 1]);
      powers2Length = powers.length;
      highestPower2 = powers[powers.length - 1];
      powers;
    };
  
  static function smallToArray(n:BigIntT):Array<BigIntT> {
    if (n < BASE) return [n];
    if (n < BASE_SQUARED) return [n % BASE, intDiv(n, BASE)];
    return [n % BASE, intDiv(n, BASE) % BASE, intDiv(n, BASE_SQUARED)];
  }
  
  // type-specific helper methods
#if BIGINT_INT64
  static inline function intDiv(a:BigIntT, b:BigIntT):BigIntT {
    return a / b;
  }
  
  static inline function intAbs(a:BigIntT):BigIntT {
    return a < 0 ? -a : a;
  }
  
  static function intParse(s:String):Null<BigIntT> {
    return try Int64.parseString(s) catch (ex:Dynamic) null;
  }
  
  static function intToString(a:BigIntT):String {
    return Int64.toStr(a);
  }
#else
  static inline function intDiv(a:BigIntT, b:BigIntT):BigIntT {
    return Math.floor(a / b);
  }
  
  static inline function intAbs(a:BigIntT):BigIntT {
    return a < 0 ? -a : a;
  }
  
  static function intParse(s:String):Null<BigIntT> {
    return Std.parseInt(s);
  }
  
  static function intToString(a:BigIntT):String {
    return '$a';
  }
#end
  // helper methods
  
  static inline function intMin(a:BigIntT, b:BigIntT):BigIntT {
    return a < b ? a : b;
  }
  
  static function intAddSafe(a:BigIntT, b:BigIntT):Null<BigIntT> {
    if (a >= 0) {
      if (b > (MAX_INT - a)) return null;
    } else {
      if (b < (MIN_INT - a)) return null;
    }
    return a + b;
  }
  
  static function intMultiplySafe(a:BigIntT, b:BigIntT):Null<BigIntT> {
    // https://stackoverflow.com/questions/8534107/detecting-multiplication-of-uint64-t-integers-overflow-with-c
    if (a > b) return intMultiplySafe(b, a);
    if (a > MAX_INT_HALF) return null;
    var c = b >> MAX_INT_HALF_BITS;
    var d = MAX_INT_HALF & b;
    var r = a * c;
    var s = a * d;
    if (r > MAX_INT_HALF) return null;
    return intAddSafe(s, r << MAX_INT_HALF_BITS);
  }
  
  static function arrayToSmall(arr:Array<BigIntT>):Null<BigIntT> {
    // If BASE changes this function may need to change
    arr = trim(arr);
    var length = arr.length;
    if (length < 4 && compareAbsHelper(arr, MAX_INT_ARR) < 0) {
      return (switch (length) {
        case 0: 0;
        case 1: arr[0];
        case 2: arr[0] + arr[1] * BASE;
        case _: arr[0] + (arr[1] + arr[2] * BASE) * BASE;
      });
    }
    return null;
  }
  
  static function compareAbsHelper(a:Array<BigIntT>, b:Array<BigIntT>):Int {
    if (a.length != b.length) {
      return a.length > b.length ? 1 : -1;
    }
    for (i in 0...a.length) {
      var ri = a.length - 1 - i;
      if (a[ri] != b[ri]) return a[ri] > b[ri] ? 1 : -1;
    }
    return 0;
  }
  
  static function createArray(length:Int):Array<BigIntT> {
    return [ for (i in 0...length) 0 ];
  }
  
  // TODO: this probably cannot really work in Haxe
  // (assumes overflow turns a number into Float)
  static function isPrecise(n:Float):Bool {
    return MIN_INT < n && n < MAX_INT;
  }
  
  static function trim(v:Array<BigIntT>):Array<BigIntT> {
    var i = v.length;
    while (v[--i] == 0) {}
    return v.slice(0, i + 1);
  }
  
  static function truncate(n:Float):BigIntT {
    if (n > 0) return Math.floor(n);
    return Math.ceil(n);
  }
  
  static function parseStringValue(v:String):BigInt {
    var sign = v.charAt(0) == "-";
    if (sign) v = v.substr(1);
    var split = v.split("e");
    if (split.length > 2) throw "Invalid integer: " + v;
    if (split.length == 2) {
      var exp = split[1];
      if (exp.charAt(0) == "+") exp = exp.substr(1);
      var expi = Std.parseInt(exp);
      // TODO: only relevant for JS ?
      if (expi == null/* || expi != truncate(expi) || !isPrecise(expi)*/) throw "Invalid integer: " + exp + " is not a valid exponent.";
      var text = split[0];
      var decimalPlace = text.indexOf(".");
      if (decimalPlace >= 0) {
        expi -= text.length - decimalPlace - 1;
        text = text.substr(0, decimalPlace) + text.substr(decimalPlace + 1);
      }
      if (expi < 0) throw "Cannot include negative exponent part for integers";
      text += StringTools.rpad("", "0", expi);
      v = text;
    }
    
    // moved here because Std.parseInt does not handle exponent notation
    var vi:BigIntT = intParse(v);
    if (vi != null/* && isPrecise(vi)*/) { // TODO: duplicate in parseNumberValue?
      var x = vi;
      //if (x == truncate(x)) {
        return new BigIntS(sign ? -x : x);
      //}
      //throw "Invalid integer: " + v;
    }
    
    var reValid = ~/^([0-9][0-9]*)$/;
    var isValid = reValid.match(v);
    if (!isValid) throw "Invalid integer: " + v;
    var r:Array<BigIntT> = [];
    var max = v.length;
    var min = max - LOG_BASE;
    while (max > 0) {
      r.push(Std.parseInt(v.substring(min, max)));
      min -= LOG_BASE;
      if (min < 0) min = 0;
      max -= LOG_BASE;
    }
    return new BigIntB(trim(r), sign);
  }
  
  static function parseNumberValue(v:BigIntT):BigInt {
    //if (isPrecise(v)) {
      //if (v != truncate(v)) throw '$v is not an integer'; // TODO: maybe only relevant for Floats?
      return new BigIntS(v);
    //}
    return parseStringValue(intToString(v));
  }
  /*
  static function parseValue(v):BigInt {
    // this would be call to
    // - parseNumberValue if v:Int or :Float
    // - parseStringValue if v:String
    // - return v if v:BigInt
    return null;
  }
  */
  static function bitwise(x:BigInt, y:BigInt, fn:BigIntT->BigIntT->BigIntT):BigInt {
     var xSign:Bool = x.isNegative();
     var ySign:Bool = y.isNegative();
     var xRem:BigInt = xSign ? x.not() : x;
     var yRem:BigInt = ySign ? y.not() : y;
     var xDigit:BigIntT = 0;
     var yDigit:BigIntT = 0;
     var xDivMod = null;
     var yDivMod = null;
     var result:Array<BigIntT> = [];
     while (!xRem.isZero() || !yRem.isZero()) {
       xDivMod = divModAny(xRem, highestPower2Big);
       xDigit = xDivMod[1].toInt();
       if (xSign) {
         xDigit = highestPower2 - 1 - xDigit; // two's complement for negative numbers
       }
       
       yDivMod = divModAny(yRem, highestPower2Big);
       yDigit = yDivMod[1].toInt();
       if (ySign) {
         yDigit = highestPower2 - 1 - yDigit; // two's complement for negative numbers
       }
       
       xRem = xDivMod[0];
       yRem = yDivMod[0];
       result.push(fn(xDigit, yDigit));
     }
     var sum:BigInt = fn(xSign ? 1 : 0, ySign ? 1 : 0) != 0 ? minusOne : zero;
     for (ri in 0...result.length) {
       var i = result.length - 1 - ri;
       sum = sum.multiply(highestPower2Big).add(fromInt(result[i]));
     }
     return sum;
  }
  
  static function addAnyHelper(a:Array<BigIntT>, b:Array<BigIntT>):Array<BigIntT> {
    var r = createArray(a.length);
    var carry:BigIntT = 0;
    var sum:BigIntT;
    for (i in 0...b.length) {
      sum = a[i] + b[i] + carry;
      carry = sum >= BASE ? 1 : 0;
      r[i] = sum - carry * BASE;
    }
    var i = b.length;
    while (i < a.length) {
      sum = a[i] + carry;
      carry = sum == BASE ? 1 : 0;
      r[i++] = sum - carry * BASE;
    }
    if (carry > 0) {
      r.push(carry);
    }
    return r;
  }
  
  static function addAny(a:Array<BigIntT>, b:Array<BigIntT>):Array<BigIntT> {
    if (a.length >= b.length) {
      return addAnyHelper(a, b);
    }
    return addAnyHelper(b, a);
  }
  
  static function addSmall(a:Array<BigIntT>, carry:BigIntT):Array<BigIntT> {
    var r = createArray(a.length);
    var sum:BigIntT;
    for (i in 0...a.length) {
      sum = a[i] - BASE + carry;
      carry = BigInt.intDiv(sum, BASE);
      r[i] = sum - carry * BASE;
      carry += 1;
    }
    var i = a.length;
    while (carry > 0) {
      r[i++] = carry % BASE;
      carry = BigInt.intDiv(carry, BASE);
    }
    return r;
  }
  
  static function subtractHelper(a:Array<BigIntT>, b:Array<BigIntT>):Array<BigIntT> {
    // assumes a and b are arrays with a >= b
    var r = createArray(a.length);
    var borrow:BigIntT = 0;
    var difference:BigIntT;
    for (i in 0...b.length) {
      difference = a[i] - borrow - b[i];
      if (difference < 0) {
        difference += BASE;
        borrow = 1;
      } else {
        borrow = 0;
      }
      r[i] = difference;
    }
    var i = b.length;
    while (i < a.length) {
      difference = a[i] - borrow;
      if (difference < 0) {
        difference += BASE;
      } else {
        r[i++] = difference;
        break;
      }
      r[i] = difference;
      i++;
    }
    while (i < a.length) {
      r[i] = a[i];
    }
    return trim(r);
  }
  
  static function subtractAny(a:Array<BigIntT>, b:Array<BigIntT>, sign:Bool):BigInt {
    var value:Array<BigIntT> = (if (compareAbsHelper(a, b) >= 0) {
        subtractHelper(a, b);
      } else {
        sign = !sign;
        subtractHelper(b, a);
      });
    var smallValue = arrayToSmall(value);
    if (smallValue != null) {
      return new BigIntS(sign ? -smallValue : smallValue);
    }
    return new BigIntB(value, sign);
  }
  
  static function subtractSmall(a:Array<BigIntT>, b:BigIntT, sign:Bool):BigInt {
    // assumes a is array, b is number with 0 <= b < MAX_INT
    var r = createArray(a.length);
    var carry = -b;
    var difference;
    for (i in 0...a.length) {
      difference = a[i] + carry;
      carry = intDiv(difference, BASE);
      difference %= BASE;
      r[i] = difference < 0 ? difference + BASE : difference;
    }
    // TODO: duplicate in subtractAny - extract into an inline function
    var smallValue = arrayToSmall(r);
    if (smallValue != null) {
      return new BigIntS(sign ? -smallValue : smallValue);
    }
    return new BigIntB(r, sign);
  }
  
  static function multiplyLong(a:Array<BigIntT>, b:Array<BigIntT>):Array<BigIntT> {
    var r = createArray(a.length + b.length);
    for (i in 0...a.length) {
      for (j in 0...b.length) {
        var product = a[i] * b[j] + r[i + j];
        var carry = intDiv(product, BASE);
        r[i + j] = product - carry * BASE;
        r[i + j + 1] += carry;
      }
    }
    return trim(r);
  }
  
  static function multiplySmall(a:Array<BigIntT>, b:BigIntT):Array<BigIntT> {
    var r = createArray(a.length);
    var carry:BigIntT = 0;
    for (i in 0...a.length) {
      var product = a[i] * b + carry;
      carry = intDiv(product, BASE);
      r[i] = product - carry * BASE;
    }
    var i = a.length;
    while (carry > 0) {
      r[i++] = carry % BASE;
      carry = intDiv(carry, BASE);
    }
    return r;
  }
  
  static function shiftLeftHelper(x:Array<BigIntT>, n:Int):Array<BigIntT> {
    var r:Array<BigIntT> = [];
    while (n-- > 0) r.push(0);
    return r.concat(x);
  }
  
  static function multiplyKaratsuba(x:Array<BigIntT>, y:Array<BigIntT>):Array<BigIntT> {
    var n = x.length > y.length ? x.length : y.length;
    
    if (n <= 30) return multiplyLong(x, y);
    n = Math.ceil(n / 2);
    
    var b = x.slice(n),
        a = x.slice(0, n),
        d = y.slice(n),
        c = y.slice(0, n);
    
    var ac = multiplyKaratsuba(a, c),
        bd = multiplyKaratsuba(b, d),
        abcd = multiplyKaratsuba(addAny(a, b), addAny(c, d));
    
    var product = addAny(addAny(ac, shiftLeftHelper(subtractHelper(subtractHelper(abcd, ac), bd), n)), shiftLeftHelper(bd, 2 * n));
    return trim(product);
  }
  
  static function useKaratsuba(l1:Int, l2:Int):Bool {
    // The following function is derived from a surface fit of a graph plotting the performance difference
    // between long multiplication and karatsuba multiplication versus the lengths of the two arrays.
    // TODO: profile per target? different BASE changes this?
    return -0.012 * l1 - 0.012 * l2 + 0.000015 * l1 * l2 > 0;
  }
  
  static function multiplySmallAndArray(a:BigIntT, b:Array<Int>, sign:Bool):BigInt {
    // a >= 0
    if (a < BASE) {
      return new BigIntB(multiplySmall(b, a), sign);
    }
    return new BigIntB(multiplyLong(b, smallToArray(a)), sign);
  }
  
  static function squareHelper(a:Array<BigIntT>):Array<BigIntT> {
    var r = createArray(a.length + a.length);
    for (i in 0...a.length) {
      var carry = 0 - a[i] * a[i];
      for (j in i...a.length) {
        var product = 2 * (a[i] * a[j]) + r[i + j] + carry;
        carry = intDiv(product, BASE);
        r[i + j] = product - carry * BASE;
      }
      r[i + a.length] = carry;
    }
    return trim(r);
  }
  
  static function divMod1(a:Array<BigIntT>, b:Array<BigIntT>):Array<Array<BigIntT>> {
    // Left over from previous version. Performs faster than divMod2 on smaller input sizes.
    var result = createArray(b.length);
    var divisorMostSignificantDigit = b[b.length - 1];
    
    // normalization
    var lambda = Math.ceil(BASE / (2 * divisorMostSignificantDigit));
    var remainder = multiplySmall(a, lambda);
    var divisor = multiplySmall(b, lambda);
    var quotientDigit, shift, carry, borrow, i, l, q;
    
    if (remainder.length <= a.length) remainder.push(0);
    divisor.push(0);
    
    divisorMostSignificantDigit = divisor[b.length - 1];
    
    var shift = a.length - b.length;
    while (shift >= 0) {
      quotientDigit = BASE - 1;
      if (remainder[shift + b.length] != divisorMostSignificantDigit) {
        quotientDigit = intDiv(
          (remainder[shift + b.length] * BASE + remainder[shift + b.length - 1]),
          divisorMostSignificantDigit
        );
      }
      // quotientDigit <= base - 1
      carry = 0;
      borrow = 0;
      l = divisor.length;
      for (i in 0...divisor.length) {
        carry += quotientDigit * divisor[i];
        q = intDiv(carry, BASE);
        borrow += remainder[shift + i] - (carry - q * BASE);
        carry = q;
        if (borrow < 0) {
          remainder[shift + i] = borrow + BASE;
          borrow = -1;
        } else {
          remainder[shift + i] = borrow;
          borrow = 0;
        }
      }
      while (borrow != 0) {
        quotientDigit -= 1;
        carry = 0;
        for (i in 0...divisor.length) {
          carry += remainder[shift + i] - BASE + divisor[i];
          if (carry < 0) {
            remainder[shift + i] = carry + BASE;
            carry = 0;
          } else {
            remainder[shift + i] = carry;
            carry = 1;
          }
        }
        borrow += carry;
      }
      result[shift] = quotientDigit;
      shift--;
    }
    // denormalization
    remainder = divModSmall(remainder, lambda).quotient;
    return [result, remainder];
  }
  /*
  function divMod2(a:Array<BigIntT>, b:Array<BigIntT>):Array<BigInt> {
    // Implementation idea shamelessly stolen from Silent Matt's library http://silentmatt.com/biginteger/
      // Performs faster than divMod1 on larger input sizes.
      var a_l = a.length,
          b_l = b.length,
          result = [],
          part = [],
          base = BASE,
          guess, xlen, highx, highy, check;
      while (a_l) {
          part.unshift(a[--a_l]);
          trim(part);
          if (compareAbs(part, b) < 0) {
              result.push(0);
              continue;
          }
          xlen = part.length;
          highx = part[xlen - 1] * base + part[xlen - 2];
          highy = b[b_l - 1] * base + b[b_l - 2];
          if (xlen > b_l) {
              highx = (highx + 1) * base;
          }
          guess = Math.ceil(highx / highy);
          do {
              check = multiplySmall(b, guess);
              if (compareAbs(check, part) <= 0) break;
              guess--;
          } while (guess);
          result.push(guess);
          part = subtract(part, check);
      }
      result.reverse();
      return [arrayToSmall(result), arrayToSmall(part)];
  }
*/
  static function divModSmall(value:Array<Int>, lambda:BigIntT):{quotient:Array<BigIntT>, remainder:BigIntT} {
    var quotient = createArray(value.length);
    var remainder = 0;
    for (ri in 0...value.length) {
      var i = value.length - 1 - ri;
      var divisor = remainder * BASE + value[i];
      var q = truncate(divisor / lambda);
      remainder = divisor - q * lambda;
      quotient[i] = q | 0;
    }
    return {
      quotient: quotient,
      remainder: remainder | 0
    };
  }
  
  static function divModAny(self:BigInt, n:BigInt):Array<BigInt> {
    if (n.isZero()) throw "Cannot divide by zero";
    
    if (self.isSmall) {
      if (n.isSmall) {
        return [
          new BigIntS(truncate(self.smallValue / n.smallValue)),
          new BigIntS(self.smallValue % n.smallValue)
        ];
      }
      return [zero, self];
    }
    
    var a = self.value;
    var b:Array<BigIntT> = (if (n.isSmall) {
        if (n.smallValue == 1) return [self, zero];
        if (n.smallValue == -1) return [self.negate(), zero];
        var abs = intAbs(n.smallValue);
        if (abs < BASE) {
          var value = divModSmall(self.value, abs);
          var quotienti = arrayToSmall(value.quotient);
          var remainder = value.remainder;
          if (self.sign) remainder = -remainder;
          if (quotienti != null) {
            if (self.sign != n.sign) quotienti = -quotienti;
            return [new BigIntS(quotienti), new BigIntS(remainder)];
          }
          return [new BigIntB(value.quotient, self.sign != n.sign), new BigIntS(remainder)];
        }
        smallToArray(abs);
      } else n.value);
    
    var comparison = compareAbsHelper(a, b);
    if (comparison == -1) return [zero, self];
    if (comparison == 0) return [self.sign == n.sign ? one : minusOne, zero];
    
    var value:Array<Array<BigIntT>>;
    // divMod1 is faster on smaller input sizes
    //if (a.length + b.length <= 200)
        value = divMod1(a, b);
    //else value = divMod2(a, b);

    var qSign = self.sign != n.sign;
    var quotienti = arrayToSmall(value[0]);
    var modi = arrayToSmall(value[1]);
    return [
        (if (quotienti != null) {
          if (qSign) quotienti = -quotienti;
          new BigIntS(quotienti);
        } else new BigIntB(value[0], qSign)),
        (if (modi != null) {
          if (self.sign) modi = -modi;
          new BigIntS(modi);
        } else new BigIntB(value[1], self.sign)),
      ];
  }
  
  static function roughLOB(n:BigInt):Int {
    // TODO: this might be messed up since LOBMASK should be different for 32-bit?
    // get lowestOneBit (rough)
    // SmallInteger: return Min(lowestOneBit(n), 1 << 30)
    // BigInteger: return Min(lowestOneBit(n), 1 << 14) [BASE=1e7]
    var x = (if (n.isSmall) {
        n.smallValue | LOBMASK_I;
      } else {
        (n.value[0] + (n.value[1] * BASE)) | LOBMASK_BI;
      });
    return x & -x;
  }
  
  static function integerLogarithm(value:BigInt, base:BigInt):{p:BigInt, e:Int} {
    if (base.compareTo(value) <= 0) {
      var tmp = integerLogarithm(value, base.square());
      var p = tmp.p;
      var e = tmp.e;
      var t = p.multiply(base);
      return t.compareTo(value) <= 0
        ? {p: t, e: e * 2 + 1}
        : {p: p, e: e * 2};
    }
    return {p: one, e: 0};
  }
  
  static function shiftIsSmall(shift:Int):Bool {
    return intAbs(shift) <= BASE;
  }
  
  static function isBasicPrime(v:BigInt):Null<Bool> {
    var n = v.abs();
    if (n.isUnit()) return false;
    if (n.equals(constants[2]) || n.equals(constants[3]) || n.equals(constants[5])) return true;
    if (n.isEven() || n.isDivisibleBy(constants[3]) || n.isDivisibleBy(constants[5])) return false;
    if (n.lesser(constants[49])) return true;
    // we don't know if it's prime: let the other functions figure it out
    return null;
  }
  
  static function millerRabinTest(n:BigInt, as:Array<BigInt>):Bool {
    var nPrev = n.prev();
    var b = nPrev;
    var r = 0;
    while (b.isEven()) {
      b = b.divide(constants[2]);
      r++;
    }
    for (ai in as) {
      if (n.lesser(ai)) continue;
      var x = ai.modPow(b, n);
      if (x.isUnit() || x.equals(nPrev)) continue;
      var d = r - 1;
      var next = false;
      while (d != 0) {
        x = x.square().mod(n);
        if (x.isUnit()) return false;
        if (x.equals(nPrev)) {
          next = true;
          break;
        }
      }
      if (next) continue;
      return false;
    }
    return true;
  }
  
  static function toBase(n:BigInt, base:BigInt):{value:Array<BigIntT>, isNegative:Bool} {
    // 0 base
    if (base.isZero()) {
      if (n.isZero()) return { value: [0], isNegative: false };
      throw "Cannot convert nonzero numbers to base 0.";
    }
    
    // -1 base ?
    if (base.equals(minusOne)) {
      if (n.isZero()) return { value: [0], isNegative: false };
      if (n.isNegative()) {
        return {
          value: [ for (i in 0...n.toInt()) for (d in [1, 0]) d ],
          isNegative: false
        };
      }
      var arr = [ for (i in 0...n.toInt() - 1) for (d in [0, 1]) d ];
      arr.unshift(1);
      return {
        value: arr,
        isNegative: false
      };
    }
    
    var neg = false;
    if (n.isNegative() && base.isPositive()) {
      neg = true;
      n = n.abs();
    }
    
    // unary
    if (base.isUnit()) {
      if (n.isZero()) return { value: [0], isNegative: false };
      return {
        value: [ for (i in 0...n.toInt()) 1 ],
        isNegative: neg
      };
    }
    
    // any base
    var left = n;
    var divmod;
    var out = [ while (left.isNegative() || left.compareAbs(base) >= 0) {
        divmod = left.divmod(base);
        left = divmod.quotient;
        var digit = divmod.remainder;
        if (digit.isNegative()) {
          digit = base.minus(digit).abs();
          left = left.next();
        }
        digit.toInt();
      } ];
    out.push(left.toInt());
    out.reverse();
    return { value: out, isNegative: neg };
  }
  
  static function stringify(digit:BigIntT, ?alphabet:String):String {
    if (alphabet == null) DEFAULT_ALPHABET;
    if (digit < alphabet.length) {
      return alphabet.charAt(digit);
    }
    return "<" + digit + ">";
  }
  
  static function toBaseString(number:BigInt, radix:BigInt, ?alphabet:String):String {
    var arr = toBase(number, radix);
    return (arr.isNegative ? "-" : "") + arr.value.map(stringify.bind(_, alphabet)).join("");
  }
  
  static function parseBaseFromArray(digits:Array<BigInt>, base:BigInt, isNegative:Bool):BigInt {
    var val = zero;
    var pow = one;
    for (ri in 0...digits.length) {
      var i = digits.length - 1 - ri;
      val = val.add(digits[i].times(pow));
      pow = pow.times(base);
    }
    return isNegative ? val.negate() : val;
  }
  
  static function parseBase(text:String, ?base:Int = 10, ?alphabet:String, ?caseSensitive:Bool = false):BigInt {
    if (alphabet == null) alphabet = DEFAULT_ALPHABET;
    if (!caseSensitive) {
      text = text.toLowerCase();
      alphabet = alphabet.toLowerCase();
    }
    
    var length = text.length;
    var i;
    var absBase = intAbs(base);
    var alphabetValues = [ for (i in 0...alphabet.length) alphabet.charAt(i) => i ];
    for (i in 0...text.length) {
      var c = text.charAt(i);
      if (c == "-") continue;
      if (alphabetValues.exists(c)) {
        if (alphabetValues[c] >= absBase) {
          if (c == "1" && absBase == 1) continue;
          throw c + " is not a valid digit in base " + base + ".";
        }
      }
    }
    var baseBig = fromInt(base);
    var digits = [];
    var isNegative = text.charAt(0) == "-";
    var i = isNegative ? 1 : 0;
    var digits = [ while (i < text.length) {
        var c = text.charAt(i++);
        if (alphabetValues.exists(c)) fromInt(alphabetValues[c]);
        else if (c == "<") {
          var start = i;
          do { i++; } while (text.charAt(i) != ">" && i < text.length);
          fromString(text.substring(start + 1, i));
        } else throw c + " is not a valid character";
      } ];
    return parseBaseFromArray(digits, baseBig, isNegative);
  }
  
  public static function fromString(?text:String, ?base:Int = 10, ?alphabet:String, ?caseSensitive:Bool = false):BigInt {
    if (text == null) return zero;
    if (base != 10 || alphabet != null) return parseBase(text, base, alphabet, caseSensitive);
    return parseStringValue(text);
  }
  
  public static function fromArray(digits:Array<Int>, ?base:Int = 10, ?isNegative:Bool = false):BigInt {
    return parseBaseFromArray(digits.map(fromInt), fromInt(base), isNegative);
  }
  
  public static function fromInt(?val:BigIntT):BigInt {
    return parseNumberValue(val != null ? val : 0);
  }
  
  public static function gcd(a:BigInt, b:BigInt):BigInt {
    a = a.abs();
    b = b.abs();
    if (a.equals(b)) return a;
    if (a.isZero()) return b;
    if (b.isZero()) return a;
    var c = one;
    var d:BigInt;
    while (a.isEven() && b.isEven()) {
      var lobA = roughLOB(a);
      var lobB = roughLOB(b);
      d = fromInt(lobA < lobB ? lobA : lobB);
      a = a.divide(d);
      b = b.divide(d);
      c = c.multiply(d);
    }
    while (a.isEven()) {
      a = a.divide(fromInt(roughLOB(a)));
    }
    do {
      while (b.isEven()) {
        b = b.divide(fromInt(roughLOB(b)));
      }
      if (a.greater(b)) {
        var t = b;
        b = a;
        a = t;
      }
      b = b.subtract(a);
    } while (!b.isZero());
    return c.isUnit() ? a : a.multiply(c);
  }
  
  public static function lcm(a:BigInt, b:BigInt):BigInt {
    a = a.abs();
    b = b.abs();
    return a.divide(gcd(a, b)).multiply(b);
  }
  
  public static function max(a:BigInt, b:BigInt):BigInt return a.greater(b) ? a : b;
  
  public static function min(a:BigInt, b:BigInt):BigInt return a.lesser(b) ? a : b;
  
  public static function randBetween(a:BigInt, b:BigInt):BigInt {
    var low = min(a, b);
    var high = max(a, b);
    var range = high.subtract(low).add(one);
    if (range.isSmall) return low.add(fromInt(Math.floor(Math.random() * range.smallValue)));
    var digits = toBase(range, BASE_BIG).value;
    var result = [];
    var restricted = true;
    for (i in 0...digits.length) {
      var top = restricted ? digits[i] : BASE;
      var digit = truncate(Math.random() * top);
      result.push(digit);
      if (digit < top) restricted = false;
    }
    return low.add(fromArray(result, BASE, false));
  }
  
  // instance storage
  
  var isSmall:Bool;
  var sign:Bool; // true = negative (possibly -0)
  
  var smallValue:BigIntT; // if isSmall, in BigIntS
  var value:Array<BigIntT>; // if !isSmall, in BigIntB
  
  // helper instance methods implemented in subclasses
  function multiplyBySmall(a:BigIntS):BigInt return null;
  
  // public instance methods (BigInteger.js API)
  
  public function and(number:BigInt):BigInt return bitwise(this, number, (a, b) -> a & b);
  
  public function bitLength():BigInt {
    var n = this;
    if (n.compareTo(zero) < 0) {
      n = n.negate().subtract(one);
    }
    if (n.compareTo(zero) == 0) {
      return zero;
    }
    return new BigIntS(integerLogarithm(n, constants[2]).e).add(one);
  }
  
  public function divide(number:BigInt):BigInt return divModAny(this, number)[0];
  
  public function divmod(number:BigInt):{quotient:BigInt, remainder:BigInt} {
    var result = divModAny(this, number);
    return {
        quotient: result[0],
        remainder: result[1]
      };
  }
  
  public function isDivisibleBy(number:BigInt):Bool {
    if (number.isZero()) return false;
    if (number.isUnit()) return true;
    if (number.compareAbs(constants[2]) == 0) return isEven();
    return mod(number).isZero();
  }
  
  public function isPrime(?strict:Bool = false):Bool {
    // Set "strict" to true to force GRH-supported lower bound of 2*log(N)^2
    var isPrime = isBasicPrime(this);
    if (isPrime != null) return isPrime;
    
    var n = abs();
    var bits = n.bitLength();
    
    if (bits.smallValue <= 64) {
      return millerRabinTest(n, [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37].map(constants.get));
    }
    
    var logN = Math.log(2) * bits.toInt();
    var t = Math.ceil(strict ? (2 * Math.pow(logN, 2)) : logN);
    var a:Array<BigInt> = [ for (i in 0...t) fromInt(i + 2) ];
    
    return millerRabinTest(n, a);
  }
  
  public function isProbablePrime(?iterations:Int = 5):Bool {
    var isPrime = isBasicPrime(this);
    if (isPrime != null) return isPrime;
    var n = abs();
    var a = [ for (i in 0...iterations) {
        BigInt.randBetween(constants[2], n.minus(constants[2]));
      } ];
    return millerRabinTest(n, a);
  }
  
  public function mod(number:BigInt):BigInt return divModAny(this, number)[1];
  
  public function modInv(mod:BigInt):BigInt {
    var t = zero;
    var newT = one;
    var r = mod;
    var newR = abs();
    var lastT:BigInt;
    var lastR:BigInt;
    
    while (!newR.isZero()) {
      var q = r.divide(newR);
      lastT = t;
      lastR = r;
      t = newT;
      r = newR;
      newT = lastT.subtract(q.multiply(newT));
      newR = lastR.subtract(q.multiply(newR));
    }
    
    if (!r.isUnit()) throw '$this and $mod are not co-prime';
    if (t.compare(zero) == -1) {
      t = t.add(mod);
    }
    if (isNegative()) {
      return t.negate();
    }
    return t;
  }
  
  public function modPow(exp:BigInt, mod:BigInt):BigInt {
    if (mod.isZero()) throw "Cannot take modPow with modulus 0";
    var r = one;
    var base = this.mod(mod);
    while (exp.isPositive()) {
      if (base.isZero()) return zero;
      if (exp.isOdd()) r = r.multiply(base).mod(mod);
      exp = exp.divide(constants[2]);
      base = base.square().mod(mod);
    }
    return r;
  }
  
  public function not():BigInt return negate().prev();
  
  public function or(number:BigInt):BigInt return bitwise(this, number, (a, b) -> a | b);
  
  public function pow(number:BigInt):BigInt {
    if (number.isZero()) return one;
    if (isZero()) return zero;
    if (isSmall && smallValue == 1) return one;
    if (isSmall && smallValue == -1) return number.isEven() ? one : minusOne;
    if (number.sign) return zero;
    if (!number.isSmall) throw 'The exponent $number is too large.';
    var b = number.smallValue; // b argument
    if (isSmall) {
      var value = Math.pow(this.smallValue, number.smallValue);
      if (isPrecise(value)) {
        return new BigIntS(truncate(value));
      }
    }
    var x = this;
    var y = one;
    while (true) {
      if (b & 1 == 1) {
        y = y.times(x);
        --b;
      }
      if (b == 0) break;
      b = b >> 1;
      x = x.square();
    }
    return y;
  }
  
  public function remainder(number:BigInt):BigInt return null;
  
  public function shiftLeft(n:BigIntT):BigInt {
    if (!shiftIsSmall(n)) {
      throw '$n is too large for shifting';
    }
    if (n < 0) return shiftRight(-n);
    var result = this;
    if (result.isZero()) return result;
    while (n >= powers2Length) {
      result = result.multiply(highestPower2Big);
      n -= powers2Length - 1;
    }
    return result.multiply(powersOfTwoBig[n]);
  }
  
  public function shiftRight(n:Int):BigInt {
    if (!shiftIsSmall(n)) {
      throw '$n is too large for shifting';
    }
    if (n < 0) return shiftLeft(-n);
    var remQuo:Array<BigInt>;
    var result = this;
    while (n >= powers2Length) {
      if (result.isZero() || (result.isNegative() && result.isUnit())) return result;
      remQuo = divModAny(result, highestPower2Big);
      result = remQuo[1].isNegative() ? remQuo[0].prev() : remQuo[0];
      n -= powers2Length - 1;
    }
    remQuo = divModAny(result, powersOfTwoBig[n]);
    return remQuo[1].isNegative() ? remQuo[0].prev() : remQuo[0];
  }
  
  public function toArray(radix:BigInt):{value:Array<Int>, isNegative:Bool} return toBase(this, radix);
  
  public function xor(number:BigInt):BigInt return bitwise(this, number, (a, b) -> a ^ b);
  
  // methods implemented in subclasses
  public function abs():BigInt return null;
  public function add(number:BigInt):BigInt return null;
  public function compareAbs(number:BigInt):Int return null;
  public function compare(number:BigInt):Int return null;
  public function next():BigInt return null;
  public function isEven():Bool return null;
  public function isNegative():Bool return null;
  public function isOdd():Bool return null;
  public function isPositive():Bool return null;
  public function isUnit():Bool return null;
  public function isZero():Bool return null;
  public function multiply(number:BigInt):BigInt return null;
  public function negate():BigInt return null;
  public function prev():BigInt return null;
  public function square():BigInt return null;
  public function subtract(number:BigInt):BigInt return null;
  public function toDebugString():String return null;
  public function toInt():Null<BigIntT> return null;
  public function toJSON():String return toString();
  public function toString(?radix:BigInt, ?alphabet:String):String return null;
  
  // aliases
  public inline function compareTo(number:BigInt):Int return compare(number);
  public inline function eq(number:BigInt):Bool return equals(number);
  public inline function equals(number:BigInt):Bool return compare(number) == 0;
  public inline function geq(number:BigInt):Bool return greaterOrEquals(number);
  public inline function greater(number:BigInt):Bool return compare(number) > 0;
  public inline function greaterOrEquals(number:BigInt):Bool return compare(number) >= 0;
  public inline function gt(number:BigInt):Bool return greater(number);
  public inline function leq(number:BigInt):Bool return lesserOrEquals(number);
  public inline function lesser(number:BigInt):Bool return compare(number) < 0;
  public inline function lesserOrEquals(number:BigInt):Bool return compare(number) <= 0;
  public inline function lt(number:BigInt):Bool return lesser(number);
  public inline function minus(number:BigInt):BigInt return subtract(number);
  public inline function neq(number:BigInt):Bool return notEquals(number);
  public inline function notEquals(number:BigInt):Bool return compare(number) != 0;
  public inline function over(number:BigInt):BigInt return divide(number);
  public inline function plus(number:BigInt):BigInt return add(number);
  public inline function times(number:BigInt):BigInt return multiply(number);
}

@:allow(haxe.BigInt)
class BigIntS extends BigInt {
  private function new(smallValue:BigIntT) {
    isSmall = true;
    sign = smallValue < 0;
    this.smallValue = smallValue;
  }
  
  override function multiplyBySmall(number:BigIntS):BigInt {
    var product = BigInt.intMultiplySafe(number.smallValue, smallValue);
    if (product != null) {
      return new BigIntS(product);
    }
    return BigInt.multiplySmallAndArray(
      BigInt.intAbs(number.smallValue),
      BigInt.smallToArray(BigInt.intAbs(smallValue)),
      sign != number.sign
    );
  }
  
  override public function add(number:BigInt):BigInt {
    if (smallValue < 0 != number.sign) {
      return subtract(number.negate());
    }
    var b = (if (number.isSmall) {
        var sum = BigInt.intAddSafe(smallValue, number.smallValue);
        if (sum != null) return new BigIntS(sum);
        BigInt.smallToArray(BigInt.intAbs(number.smallValue));
      } else {
        number.value;
      });
    return new BigIntB(BigInt.addSmall(b, BigInt.intAbs(smallValue)), smallValue < 0);
  }
  
  override public function compareAbs(number:BigInt):Int {
    if (number.isSmall) {
      var a = BigInt.intAbs(smallValue);
      var b = BigInt.intAbs(number.smallValue);
      return a == b ? 0 : (a > b ? 1 : -1);
    }
    return -1;
  }
  
  override public function compare(number:BigInt):Int {
    if (number.isSmall) {
      return smallValue == number.smallValue ? 0 : (smallValue > number.smallValue ? 1 : -1);
    }
    if (smallValue < 0 != number.sign) {
      return smallValue < 0 ? -1 : 1;
    }
    return smallValue < 0 ? 1 : -1;
  }
  
  override public function multiply(number:BigInt):BigInt {
    return number.multiplyBySmall(this);
  }
  
  override public function negate():BigInt {
    var ret = new BigIntS(-smallValue);
    ret.sign = !sign;
    return ret; 
  }
  
  override public function next():BigInt {
    if (smallValue + 1 < BigInt.MAX_INT) {
      return new BigIntS(smallValue + 1);
    }
    return new BigIntB(BigInt.MAX_INT_ARR, false);
  }
  
  override public function prev():BigInt {
    if (smallValue - 1 > BigInt.MIN_INT) {
      return new BigIntS(smallValue - 1);
    }
    return new BigIntB(BigInt.MAX_INT_ARR, true);
  }
  
  override public function square():BigInt {
    var product = BigInt.intMultiplySafe(smallValue, smallValue);
    if (product != null) {
      return new BigIntS(product);
    }
    return new BigIntB(BigInt.squareHelper(BigInt.smallToArray(BigInt.intAbs(smallValue))), false);
  }
  
  override public function subtract(number:BigInt):BigInt {
    if (smallValue < 0 != number.sign) {
      return add(number.negate());
    }
    if (number.isSmall) {
      return new BigIntS(smallValue - number.smallValue);
    }
    return BigInt.subtractSmall(number.value, BigInt.intAbs(smallValue), smallValue >= 0);
  }
  
  override public function toDebugString():String {
    return 'sml${smallValue >= 0 ? "+" : ""}$smallValue';
  }
  
  override public function toInt():Null<BigIntT> {
    return smallValue;
  }
  
  override public function toString(?radix:BigInt, ?alphabet:String):String {
    if (radix == null || radix.equals(BigInt.constants[10])) return '$smallValue';
    return BigInt.toBaseString(this, radix, alphabet);
  }
  
  override public function abs():BigInt return new BigIntS(BigInt.intAbs(smallValue));
  override public function isEven():Bool return (smallValue & 1) == 0;
  override public function isNegative():Bool return smallValue < 0;
  override public function isOdd():Bool return (smallValue & 1) != 0;
  override public function isPositive():Bool return smallValue > 0;
  override public function isUnit():Bool return smallValue == 1 || smallValue == -1;
  override public function isZero():Bool return smallValue == 0;
}

@:allow(haxe.BigInt)
class BigIntB extends BigInt { // BigInteger
  private function new(value:Array<BigIntT>, sign:Bool) {
    isSmall = false;
    this.value = value;
    this.sign = sign;
  }
  
  override function multiplyBySmall(number:BigIntS):BigInt {
    if (number.smallValue == 0) return BigInt.zero;
    if (number.smallValue == 1) return this;
    if (number.smallValue == -1) return this.negate();
    return BigInt.multiplySmallAndArray(
      BigInt.intAbs(number.smallValue),
      value,
      sign != number.sign
    );
  }
  
  override public function add(number:BigInt):BigInt {
    if (sign != number.sign) {
      return subtract(number.negate());
    }
    if (number.isSmall) {
      return new BigIntB(BigInt.addSmall(value, BigInt.intAbs(number.smallValue)), sign);
    }
    return new BigIntB(BigInt.addAny(value, number.value), sign);
  }
  
  override public function compareAbs(number:BigInt):Int {
    if (number.isSmall) return 1;
    return BigInt.compareAbsHelper(value, number.value);
  }
  
  override public function compare(number:BigInt):Int {
    if (sign != number.sign) {
      return number.sign ? 1 : -1;
    }
    if (number.isSmall) {
      return sign ? -1 : 1;
    }
    return BigInt.compareAbsHelper(value, number.value) * (sign ? -1 : 1);
  }
  
  override public function multiply(number:BigInt):BigInt {
    var sign = this.sign != number.sign;
    var b:Array<BigIntT> = (if (number.isSmall) {
        if (number.smallValue == 0) return BigInt.zero;
        if (number.smallValue == 1) return this;
        if (number.smallValue == -1) return this.negate();
        var abs = BigInt.intAbs(number.smallValue);
        if (abs < BigInt.BASE) {
          return new BigIntB(BigInt.multiplySmall(value, abs), sign);
        }
        BigInt.smallToArray(abs);
      } else {
        number.value;
      });
    if (BigInt.useKaratsuba(value.length, b.length)) {
      // Karatsuba is only faster for certain array sizes
      return new BigIntB(BigInt.multiplyKaratsuba(value, b), sign);
    }
    return new BigIntB(BigInt.multiplyLong(value, b), sign);
  }
  
  override public function negate():BigInt {
    return new BigIntB(value, !sign);
  }
  
  override public function next():BigInt {
    if (sign) {
      return BigInt.subtractSmall(value, 1, sign);
    }
    return new BigIntB(BigInt.addSmall(value, 1), sign);
  }
  
  override public function prev():BigInt {
    if (sign) {
      return new BigIntB(BigInt.addSmall(value, 1), true);
    }
    return BigInt.subtractSmall(value, 1, sign);
  }
  
  override public function square():BigInt {
    return new BigIntB(BigInt.squareHelper(value), false);
  }
  
  override public function subtract(number:BigInt):BigInt {
    if (sign != number.sign) {
      return add(number.negate());
    }
    if (number.isSmall) {
      return BigInt.subtractSmall(value, BigInt.intAbs(number.smallValue), sign);
    }
    return BigInt.subtractAny(value, number.value, sign);
  }
  
  override public function toDebugString():String {
    return (sign ? "big-" : "big+") + [ for (i in 0...value.length) value[value.length - 1 - i] ].join(";");
  }
  
  override public function toInt():Null<BigIntT> {
    return BigInt.intParse(toString());
  }
  
  override public function toString(?radix:BigInt, ?alphabet:String):String {
    if (radix != null && !radix.equals(BigInt.constants[10])) return BigInt.toBaseString(this, radix, alphabet);
    var l = value.length;
    var str = '${value[--l]}';
    var digit;
    while (--l >= 0) {
      digit = '${value[l]}';
      str += BigInt.BASE_ZEROS.substr(digit.length) + digit;
    }
    return (sign ? "-" : "") + str;
  }
  
  override public function abs():BigInt return new BigIntB(value, false);
  override public function isEven():Bool return (value[0] & 1) == 0;
  override public function isNegative():Bool return sign;
  override public function isOdd():Bool return (value[0] & 1) != 0;
  override public function isPositive():Bool return !sign;
  override public function isUnit():Bool return false;
  override public function isZero():Bool return false;
}
