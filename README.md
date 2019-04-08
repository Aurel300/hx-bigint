# haxe `BigInt` #

## **_WORK IN PROGRESS_** ##

This is a pure Haxe port of the (now obsolete) [BigInteger.js](https://github.com/peterolson/BigInteger.js/) JavaScript library. It allows representing and working with arbitrarily large numbers, even if the target platform does not natively support it.

## Implementation details ##

The library has a base class `haxe.BigInt`, intended for any use in user code.

Internally, there are two subclasses:

 - `BigIntS` - "small" integer, covering values between `MIN_INT` and `MAX_INT`, i.e. the signed range of `BigIntT`.
 - `BigIntB` - "big" integer, covering anything else. The underlying type is an array of `BigIntT` values.

`BigIntT` is either be `Int` (32-bit) or `haxe.Int64`. At the moment, the latter is enabled with the define `-D BIGINT_INT64`.

## Running tests ##

The [`test/Spec.hx`](test/Spec.hx) file is more or less a copy of the [BigInteger.js spec test](https://github.com/peterolson/BigInteger.js/blob/master/spec/spec.js). The most significant differences are related to the lack of function overloading in Haxe. Some of these omissions may be put back once `BigInt` is turned into an `abstract`.

Run with (from the `test` directory):

`haxe -cp .. --run Spec`

Or build a target of your choosing and run the binary.

## TODO ##

 - [ ] fix all failing tests
 - [ ] check consistency on all targets
 - [ ] code clean up - the library was ported with major stylistic changes directly from JavaScript; a lot of the code badness might have been to improve performance on old JS engines, but this should not be reflected in this library's code
 - [ ] wrap class into an `abstract` with:
   - `from String` transparently parsing base-10 `String` values
   - `from Int` transparently parsing small `Int` (`Int64`) values
   - `from Float` transparently parsing (precise) `Float` values
   - operator overloads
 - [ ] use a native `BigInt` class, if present on the target (https://github.com/kevinresol/bigint)
 - [ ] benchmarks
