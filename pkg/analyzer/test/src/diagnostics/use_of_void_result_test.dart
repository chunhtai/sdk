// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseOfVoidResultTest);
    defineReflectiveTests(UseOfVoidResultWithExtensionMethodsTest);
    defineReflectiveTests(UseOfVoidResultTest_NonNullable);
  });
}

@reflectiveTest
class UseOfVoidResultTest extends DriverResolutionTest {
  test_andVoidLhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x && true;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_andVoidRhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  true && x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 34, 1),
    ]);
  }

  test_assignmentExpression_function() async {
    await assertErrorsInCode('''
void f() {}
class A {
  n() {
    var a;
    a = f();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 38, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 49, 1),
    ]);
  }

  test_assignmentExpression_method() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    var a;
    a = m();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 40, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 51, 1),
    ]);
  }

  test_assignmentToVoidParameterOk() async {
    // Note: the spec may decide to disallow this, but at this point that seems
    // highly unlikely.
    await assertNoErrorsInCode('''
void main() {
  void x;
  f(x);
}
void f(void x) {}
''');
  }

  test_assignToVoid_notStrong_error() async {
    // See StrongModeStaticTypeAnalyzer2Test.test_assignToVoidOk
    // for testing that this does not have errors in strong mode.
    await assertNoErrorsInCode('''
void main() {
  void x;
  x = 42;
}
''');
  }

  test_await() async {
    await assertNoErrorsInCode('''
main() async {
  void x;
  await x;
}''');
  }

  test_implicitReturnValue() async {
    await assertNoErrorsInCode(r'''
f() {}
class A {
  n() {
    var a = f();
  }
}
''');
  }

  test_inForLoop_error() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    for(Object a = m();;) {}
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 47, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 51, 1),
    ]);
  }

  test_inForLoop_ok() async {
    await assertNoErrorsInCode('''
class A {
  void m() {}
  n() {
    for(void a = m();;) {}
  }
}''');
  }

  test_interpolateVoidValueError() async {
    await assertErrorsInCode(r'''
void main() {
  void x;
  "$x";
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 28, 1),
    ]);
  }

  test_negateVoidValueError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  !x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 27, 1),
    ]);
  }

  test_nonVoidReturnValue() async {
    await assertNoErrorsInCode(r'''
int f() => 1;
g() {
  var a = f();
}
''');
  }

  test_orVoidLhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x || true;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_orVoidRhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  false || x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 35, 1),
    ]);
  }

  test_throwVoidValueError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  throw x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 32, 1),
    ]);
  }

  test_unaryNegativeVoidValueError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  -x;
}
''', [
      // TODO(mfairhurst) suppress UNDEFINED_OPERATOR
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 26, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 27, 1),
    ]);
  }

  test_useOfInForeachIterableError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  for (var v in x) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 35, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 40, 1),
    ]);
  }

  test_useOfVoidAsIndexAssignError() async {
    await assertErrorsInCode('''
void main(List list) {
  void x;
  list[x] = null;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 40, 1),
    ]);
  }

  test_useOfVoidAsIndexError() async {
    await assertErrorsInCode('''
void main(List list) {
  void x;
  list[x];
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 40, 1),
    ]);
  }

  test_useOfVoidAssignedToDynamicError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  dynamic z = x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 34, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 38, 1),
    ]);
  }

  test_useOfVoidByIndexingError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x[0];
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 27, 3),
    ]);
  }

  test_useOfVoidCallSetterError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x.foo = null;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 28, 3),
    ]);
  }

  test_useOfVoidCastsOk() async {
    await assertNoErrorsInCode('''
void use(dynamic x) { }
void main() {
  void x;
  use(x as int);
}
''');
  }

  test_useOfVoidInConditionalConditionError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x ? null : null;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  @failingTest
  test_useOfVoidInConditionalLhsError() async {
    // TODO(mfairhurst) Enable this.
    await assertErrorsInCode('''
void main(bool c) {
  void x;
  c ? x : null;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 36, 1),
    ]);
  }

  @failingTest
  test_useOfVoidInConditionalRhsError() async {
    // TODO(mfairhurst) Enable this.
    await assertErrorsInCode('''
void main(bool c) {
  void x;
  c ? null : x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 43, 1),
    ]);
  }

  test_useOfVoidInDoWhileConditionError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  do {} while (x);
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 39, 1),
    ]);
  }

  test_useOfVoidInExpStmtOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  x;
}
''');
  }

  @failingTest // This test may be completely invalid.
  test_useOfVoidInForeachVariableError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  for (x in [1, 2]) {}
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 31, 1),
    ]);
  }

  test_useOfVoidInForPartsOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  for (x; false; x) {}
}
''');
  }

  test_useOfVoidInIsTestError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x is int;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_useOfVoidInListLiteralError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  <dynamic>[x];
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 36, 1),
    ]);
  }

  test_useOfVoidInListLiteralOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  <void>[x]; // not strong mode; we have to specify <void>.
}
''');
  }

  test_useOfVoidInMapLiteralKeyError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  var m2 = <dynamic, int>{x : 4};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 2),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 50, 1),
    ]);
  }

  test_useOfVoidInMapLiteralKeyOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  var m2 = <void, int>{x : 4}; // not strong mode; we have to specify <void>.
}
''');
  }

  test_useOfVoidInMapLiteralValueError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  var m1 = <int, dynamic>{4: x};
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 2),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 53, 1),
    ]);
  }

  test_useOfVoidInMapLiteralValueOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  var m1 = <int, void>{4: x}; // not strong mode; we have to specify <void>.
}
''');
  }

  test_useOfVoidInNullOperatorLhsError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x ?? 499;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 26, 1),
    ]);
  }

  test_useOfVoidInNullOperatorRhsOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  null ?? x;
}
''');
  }

  test_useOfVoidInSpecialAssignmentError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x += 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 21, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 28, 2),
    ]);
  }

  test_useOfVoidInSwitchExpressionError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  switch(x) {}
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 33, 1),
    ]);
  }

  test_useOfVoidInWhileConditionError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  while (x) {};
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 33, 1),
    ]);
  }

  test_useOfVoidNullPropertyAccessError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x?.foo;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 29, 3),
    ]);
  }

  test_useOfVoidPropertyAccessError() async {
    await assertErrorsInCode('''
void main() {
  void x;
  x.foo;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 28, 3),
    ]);
  }

  @failingTest
  test_useOfVoidReturnInNonVoidFunctionError() async {
    // TODO(mfairhurst) Get this test to pass once codebase is compliant.
    await assertErrorsInCode('''
dynamic main() {
  void x;
  return x;
}
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 36, 1),
    ]);
  }

  test_useOfVoidReturnInVoidFunctionOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  return x;
}
''');
  }

  test_useOfVoidWhenArgumentError() async {
    await assertErrorsInCode('''
void use(dynamic x) { }
void main() {
  void x;
  use(x);
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 54, 1),
    ]);
  }

  test_useOfVoidWithInitializerOk() async {
    await assertNoErrorsInCode('''
void main() {
  void x;
  void y = x;
}
''');
  }

  test_variableDeclaration_function_error() async {
    await assertErrorsInCode('''
void f() {}
class A {
  n() {
    Object a = f();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 41, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 45, 1),
    ]);
  }

  test_variableDeclaration_function_ok() async {
    await assertNoErrorsInCode('''
void f() {}
class A {
  n() {
    void a = f();
  }
}''');
  }

  test_variableDeclaration_method2() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    Object a = m(), b = m();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 47, 1),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 52, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 56, 1),
    ]);
  }

  test_variableDeclaration_method_error() async {
    await assertErrorsInCode('''
class A {
  void m() {}
  n() {
    Object a = m();
  }
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 43, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 47, 1),
    ]);
  }

  test_variableDeclaration_method_ok() async {
    await assertNoErrorsInCode('''
class A {
  void m() {}
  n() {
    void a = m();
  }
}''');
  }

  test_yieldStarVoid_asyncStar() async {
    await assertErrorsInCode('''
main(void x) async* {
  yield* x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 31, 1),
    ]);
  }

  test_yieldStarVoid_syncStar() async {
    await assertErrorsInCode('''
main(void x) sync* {
  yield* x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 30, 1),
    ]);
  }

  test_yieldVoid_asyncStar() async {
    await assertErrorsInCode('''
main(void x) async* {
  yield x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 30, 1),
    ]);
  }

  test_yieldVoid_syncStar() async {
    await assertErrorsInCode('''
main(void x) sync* {
  yield x;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 29, 1),
    ]);
  }
}

@reflectiveTest
class UseOfVoidResultTest_NonNullable extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_bang_nonVoid() async {
    await assertNoErrorsInCode(r'''
int? f() => 1;
g() {
  f()!;
}
''');
  }

  test_bang_void() async {
    await assertErrorsInCode(r'''
void f() => 1;
g() {
  f()!;
}
''', [ExpectedError(StaticWarningCode.USE_OF_VOID_RESULT, 23, 4)]);
  }
}

@reflectiveTest
class UseOfVoidResultWithExtensionMethodsTest extends UseOfVoidResultTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  test_useOfVoidReturnInExtensionMethod() async {
    await assertErrorsInCode('''
extension on void {
  testVoid() {
    // No access on void. Static type of `this` is void!
    this.toString();
  }
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 96, 4),
    ]);
  }

  test_void() async {
    await assertErrorsInCode('''
extension E on String {
  int get g => 0;
}

void f() {}

main() {
  E(f()).g;
}
''', [
      error(StaticWarningCode.USE_OF_VOID_RESULT, 71, 3),
    ]);
  }
}
