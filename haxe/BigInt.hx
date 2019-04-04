package haxe;

class BigInt {
  // static stuff
  public static var one(default, null):BigInt = newSmall(1);
  public static var zero(default, null):BigInt = newSmall(0);
  public static var minusOne(default, null):BigInt = newSmall(-1);
  public static var constants(default, null):Map<Int, BigInt> = [ for (i in -999...1000) i => newSmall(i) ];
  
  static var BASE = 10000000;
  
  static var highestPower2:Int;
  static var powers2Length:Int;
  static var powersOfTwo:Array<Int> = {
      var pow = 1;
      var powers = [pow];
      while (2 * pow <= BASE) powers.push(pow = 2 * pow);
      powers2Length = powers.length;
      highestPower2 = pow;
      powers;
    };
  
  public static function fromString(
    val:String,
    ?base:Int = 10,
    ?alphabet:String = "0123456789abcdefghijklmnopqrstuvwxyz",
    ?caseSensitive:Bool = false
  ):BigInt return null;
  public static function fromArray(
     digits:Array<Int>
    ,?base:Int = 10
    ,?isNegative:Bool = false
  ):BigInt return null;
  public static function fromInt(val:Int):BigInt return newSmall(val);
  
  public static function gcd(a:BigInt, b:BigInt):BigInt return null;
  //public static function isInstance(x):Bool return null;
  public static function lcm(a:BigInt, b:BigInt):BigInt return null;
  
  public static function max(a:BigInt, b:BigInt):BigInt return a.greater(b) ? a : b;
  public static function min(a:BigInt, b:BigInt):BigInt return a.lesser(b) ? a : b;
  
  public static function randBetween(min:BigInt, max:BigInt):BigInt return null;
  
  // instance storage
  var isSmall:Bool;
  var sign:Bool; // true = negative
  
  // if !isSmall
  var value:Array<Int>;
  
  // if isSmall
  var smallValue:Int;
  
  private static function newSmall(value:Int):BigInt {
    var ret = new BigInt();
    ret.isSmall = true;
    ret.sign = value < 0;
    ret.smallValue = value;
    return ret;
  }
  
  private static function newBig(value:Array<Int>, sign:Bool):BigInt {
    var ret = new BigInt();
    ret.isSmall = false;
    ret.value = value.copy();
    ret.sign = sign;
    return ret;
  }
  
  private function new() {}
  
  // helper methods
  static function bitwise(x:BigInt, y:BigInt, fn:Int->Int->Int):BigInt {
     y = y.ensureBig();
     var xSign:Bool = x.isNegative();
     var ySign:Bool = y.isNegative();
     var xRem:BigInt = xSign ? x.not() : x;
     var yRem:BigInt = ySign ? y.not() : y;
     var xDigit:Int = 0;
     var yDigit:Int = 0;
     var xDivMod = null;
     var yDivMod = null;
     var result:Array<Int> = [];
     while (!xRem.isZero() || !yRem.isZero()) {
       xDivMod = divModAny(xRem, newSmall(highestPower2)); // TODO: BI
       xDigit = xDivMod[1].toInt();
       if (xSign) {
         xDigit = highestPower2 - 1 - xDigit; // two's complement for negative numbers
       }
       
       yDivMod = divModAny(yRem, newSmall(highestPower2)); // TODO: BI
       yDigit = yDivMod[1].toInt();
       if (ySign) {
         yDigit = highestPower2 - 1 - yDigit; // two's complement for negative numbers
       }
       
       xRem = xDivMod[0];
       yRem = yDivMod[0];
       result.push(fn(xDigit, yDigit));
     }
     var sum = fn(xSign ? 1 : 0, ySign ? 1 : 0) != 0 ? minusOne : zero;
     for (i in 0...result.length) {
       var ri = result.length - 1 - i;
       sum = sum.multiplyI(highestPower2).add(newSmall(result[ri])); // TODO: BI
     }
     return sum;
  }
  
  static function divModAny(self:BigInt, v:BigInt):Array<BigInt> return null;
  
  function ensureBig():BigInt {
    if (isSmall) {
      return newBig([smallValue], smallValue < 0);
    }
    return this;
  }
  
  // public instance methods (BigInteger.js API)
  public function abs():BigInt {
    if (isSmall) {
      return newSmall(Std.int(Math.abs(smallValue)));
    }
    return newBig(value, false);
  }
  
  function addAnyHelper(a:Array<Int>, b:Array<Int>):Array<Int> {
    var r:Array<Int> = [ for (i in 0...a.length) 0 ];
    var carry:Int = 0;
    var sum:Int;
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

  function addAny(a:Array<Int>, b:Array<Int>):Array<Int> {
    if (a.length >= b.length) {
      return addAnyHelper(a, b);
    }
    return addAnyHelper(b, a);
  }
  
  function addSmall(a:Array<Int>, carry:Int):Array<Int> {
    var r = [ for (i in 0...a.length) 0 ];
    var sum:Int;
    for (i in 0...a.length) {
      sum = a[i] - BASE + carry;
      carry = Math.floor(sum / BASE);
      r[i] = sum - carry * BASE;
      carry += 1;
    }
    var i = a.length;
    while (carry > 0) {
      r[i++] = carry % BASE;
      carry = Math.floor(carry / BASE);
    }
    return r;
  }
  
  public function add(number:BigInt):BigInt {
    if (sign != number.sign) {
      return subtract(number.negate());
    }
    var a = ensureBig();
    if (number.isSmall) {
      return newBig(addSmall(a.value, Std.int(Math.abs(number.smallValue))), sign);
    }
    return newBig(addAny(a.value, number.value), sign);
  }
  
  public function and(number:BigInt):BigInt return bitwise(this, number, (a, b) -> a & b);
  
  public function bitLength():Int return null;
  public function compare(number:BigInt):Int return null;
  public function compareAbs(number:BigInt):Int return null;
  public function divide(number:BigInt):BigInt return null;
  public function divmod(number:BigInt):{quotient:BigInt, remainder:BigInt} return null;
  public function equals(number:BigInt):Bool return null;
  public function greater(number:BigInt):Bool return null;
  public function greaterOrEquals(number:BigInt):Bool return null;
  public function isDivisibleBy(number:BigInt):Bool return null;
  public function isEven():Bool return null;
  public function isNegative():Bool return null;
  public function isOdd():Bool return null;
  public function isPositive():Bool return null;
  public function isPrime():Bool return null;
  public function isProbablePrime(?iterations:Int = 5):Bool return null;
  public function isUnit():Bool return null;
  public function isZero():Bool return null;
  public function lesser(number:BigInt):Bool return null;
  public function lesserOrEquals(number:BigInt):Bool return null;
  public function mod(number:BigInt):BigInt return null;
  public function modInv(mod):BigInt return null;
  public function modPow(exp, mod):BigInt return null;
  public function multiply(number:BigInt):BigInt return null;
  public inline function multiplyI(number:Int):BigInt return multiply(newSmall(number));
  public function negate():BigInt return null;
  public function next():BigInt return null;
  
  public function not():BigInt return negate().prev();
  
  public function notEquals(number:BigInt):Bool return null;
  
  public function or(number:BigInt):BigInt return bitwise(this, number, (a, b) -> a | b);
  
  public function pow(number:BigInt):BigInt return null;
  public function prev():BigInt return null;
  public function remainder(number:BigInt):BigInt return null;
  public function shiftLeft(n:Int):BigInt return null;
  public function shiftRight(n:Int):BigInt return null;
  public function square():BigInt return null;
  public function subtract(number:BigInt):BigInt return null;
  public function toArray(radix:Int):{value:Array<Int>, isNegative:Bool} return null;
  public function toInt():Int return null;
  
  public function xor(number:BigInt):BigInt return bitwise(this, number, (a, b) -> a ^ b);
  
  public function toString(?radix = 10, ?alphabet:String):String return null;
  
  // aliases
  public inline function compareTo(number:BigInt):Int return compare(number);
  public inline function eq(number:BigInt):Bool return equals(number);
  public inline function geq(number:BigInt):Bool return greaterOrEquals(number);
  public inline function gt(number:BigInt):Bool return greater(number);
  public inline function leq(number:BigInt):Bool return lesserOrEquals(number);
  public inline function lt(number:BigInt):Bool return lesser(number);
  public inline function minus(number:BigInt):BigInt return subtract(number);
  public inline function neq(number:BigInt):Bool return notEquals(number);
  public inline function over(number:BigInt):BigInt return divide(number);
  public inline function plus(number:BigInt):BigInt return add(number);
  public inline function times(number:BigInt):BigInt return multiply(number);
}
