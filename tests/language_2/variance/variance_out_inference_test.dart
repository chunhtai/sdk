// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests local inference for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

class Covariant<out T> {}

class Exactly<inout T> {}

class Upper {}
class Middle extends Upper {}
class Lower extends Middle {}

Exactly<T> inferCovCov<T>(Covariant<T> x, Covariant<T> y) => new Exactly<T>();

main() {
  Exactly<Upper> upper;

  // Upper <: T
  // Upper <: T
  // Choose Upper
  var inferredUpper = inferCovCov(Covariant<Upper>(), Covariant<Upper>());
  upper = inferredUpper;

  // Upper <: T
  // Middle <: T
  // Choose Upper since it is the lowest upper bound of Upper and Middle.
  var inferredUpper2 = inferCovCov(Covariant<Upper>(), Covariant<Middle>());
  upper = inferredUpper2;

  // Upper <: T
  // Lower <: T
  // Choose Upper since it is the lowest upper bound of Upper and Lower.
  var inferredUpper3 = inferCovCov(Covariant<Upper>(), Covariant<Lower>());
  upper = inferredUpper3;
}
