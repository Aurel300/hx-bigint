package haxe;

class BigInt {
  // static stuff
  public static var one:BigInt;
  public static var zero:BigInt;
  public static var minusOne:BigInt;
  
  static var constants:Map<Int, BigInt>;
  
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
  public static function fromInt(val:Int):BigInt return null;
  
  public static function gcd(a:BigInt, b:BigInt):BigInt return null;
  //public static function isInstance(x):Bool return null;
  public static function lcm(a:BigInt, b:BigInt):BigInt return null;
  public static function max(a:BigInt, b:BigInt):BigInt return null;
  public static function min(a:BigInt, b:BigInt):BigInt return null;
  public static function randBetween(min:BigInt, max:BigInt):BigInt return null;
  
  // instance storage
  var isSmall:Bool;
  
  // if !isSmall
  var value:Array<Int>;
  var sign:Bool; // true = negative
  
  // if isSmall
  var smallValue:Int;
  
  private static function newSmall(value:Int):BigInt {
    var ret = new BigInt();
    ret.isSmall = true;
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
  
  // instance methods
  public function abs():BigInt return null;
  public function add(number:BigInt):BigInt return null;
  public function and(number:BigInt):BigInt return null;
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
  public function next():BigInt return null;
  public function not():BigInt return null;
  public function notEquals(number:BigInt):Bool return null;
  public function or(number:BigInt):BigInt return null;
  public function pow(number:BigInt):BigInt return null;
  public function prev(number:BigInt):BigInt return null;
  public function remainder(number:BigInt):BigInt return null;
  public function shiftLeft(n:Int):BigInt return null;
  public function shiftRight(n:Int):BigInt return null;
  public function square():BigInt return null;
  public function subtract(number:BigInt):BigInt return null;
  public function toArray(radix:Int):{value:Array<Int>, isNegative:Bool} return null;
  public function toInt():Int return null;
  public function xor(number:BigInt):BigInt return null;
  
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
