// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/fasta/type_inference/type_constraint_gatherer.dart';
import 'package:front_end/src/fasta/type_inference/type_schema.dart';
import 'package:front_end/src/fasta/type_inference/type_schema_environment.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/testing/mock_sdk_component.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeConstraintGathererTest);
  });
}

@reflectiveTest
class TypeConstraintGathererTest {
  static const UnknownType unknownType = const UnknownType();

  static const DynamicType dynamicType = const DynamicType();

  static const VoidType voidType = const VoidType();

  final testLib =
      new Library(Uri.parse('org-dartlang:///test.dart'), name: 'lib');

  Component component;

  CoreTypes coreTypes;

  TypeParameterType T1;

  TypeParameterType T2;

  Class classP;

  Class classQ;

  TypeConstraintGathererTest() {
    component = createMockSdkComponent();
    component.libraries.add(testLib..parent = component);
    coreTypes = new CoreTypes(component);
    T1 = new TypeParameterType(
        new TypeParameter('T1', objectType), Nullability.legacy);
    T2 = new TypeParameterType(
        new TypeParameter('T2', objectType), Nullability.legacy);
    classP = _addClass(_class('P'));
    classQ = _addClass(_class('Q'));
  }

  Class get functionClass => coreTypes.functionClass;

  InterfaceType get functionType => coreTypes.functionLegacyRawType;

  Class get iterableClass => coreTypes.iterableClass;

  Class get listClass => coreTypes.listClass;

  Class get mapClass => coreTypes.mapClass;

  InterfaceType get nullType => coreTypes.nullType;

  Class get objectClass => coreTypes.objectClass;

  InterfaceType get objectType => coreTypes.objectLegacyRawType;

  InterfaceType get P => coreTypes.legacyRawType(classP);

  InterfaceType get Q => coreTypes.legacyRawType(classQ);

  void test_any_subtype_parameter() {
    _checkConstraints(Q, T1, ['lib::Q* <: T1']);
  }

  void test_any_subtype_top() {
    _checkConstraints(P, dynamicType, []);
    _checkConstraints(P, objectType, []);
    _checkConstraints(P, voidType, []);
  }

  void test_any_subtype_unknown() {
    _checkConstraints(P, unknownType, []);
    _checkConstraints(T1, unknownType, []);
  }

  void test_different_classes() {
    _checkConstraints(_list(T1), _iterable(Q), ['T1 <: lib::Q*']);
    _checkConstraints(_iterable(T1), _list(Q), null);
  }

  void test_equal_types() {
    _checkConstraints(P, P, []);
  }

  void test_function_generic() {
    var T = new TypeParameterType(
        new TypeParameter('T', objectType), Nullability.legacy);
    var U = new TypeParameterType(
        new TypeParameter('U', objectType), Nullability.legacy);
    // <T>() -> dynamic <: () -> dynamic, never
    _checkConstraints(
        new FunctionType([], dynamicType, Nullability.legacy,
            typeParameters: [T.parameter]),
        new FunctionType([], dynamicType, Nullability.legacy),
        null);
    // () -> dynamic <: <T>() -> dynamic, never
    _checkConstraints(
        new FunctionType([], dynamicType, Nullability.legacy),
        new FunctionType([], dynamicType, Nullability.legacy,
            typeParameters: [T.parameter]),
        null);
    // <T>(T) -> T <: <U>(U) -> U, always
    _checkConstraints(
        new FunctionType([T], T, Nullability.legacy,
            typeParameters: [T.parameter]),
        new FunctionType([U], U, Nullability.legacy,
            typeParameters: [U.parameter]),
        []);
  }

  void test_function_parameter_mismatch() {
    // (P) -> dynamic <: () -> dynamic, never
    _checkConstraints(new FunctionType([P], dynamicType, Nullability.legacy),
        new FunctionType([], dynamicType, Nullability.legacy), null);
    // () -> dynamic <: (P) -> dynamic, never
    _checkConstraints(new FunctionType([], dynamicType, Nullability.legacy),
        new FunctionType([P], dynamicType, Nullability.legacy), null);
    // ([P]) -> dynamic <: () -> dynamic, always
    _checkConstraints(
        new FunctionType([P], dynamicType, Nullability.legacy,
            requiredParameterCount: 0),
        new FunctionType([], dynamicType, Nullability.legacy),
        []);
    // () -> dynamic <: ([P]) -> dynamic, never
    _checkConstraints(
        new FunctionType([], dynamicType, Nullability.legacy),
        new FunctionType([P], dynamicType, Nullability.legacy,
            requiredParameterCount: 0),
        null);
    // ({x: P}) -> dynamic <: () -> dynamic, always
    _checkConstraints(
        new FunctionType([], dynamicType, Nullability.legacy,
            namedParameters: [new NamedType('x', P)]),
        new FunctionType([], dynamicType, Nullability.legacy),
        []);
    // () -> dynamic !<: ({x: P}) -> dynamic, never
    _checkConstraints(
        new FunctionType([], dynamicType, Nullability.legacy),
        new FunctionType([], dynamicType, Nullability.legacy,
            namedParameters: [new NamedType('x', P)]),
        null);
  }

  void test_function_parameter_types() {
    // (T1) -> dynamic <: (Q) -> dynamic, under constraint Q <: T1
    _checkConstraints(
        new FunctionType([T1], dynamicType, Nullability.legacy),
        new FunctionType([Q], dynamicType, Nullability.legacy),
        ['lib::Q* <: T1']);
    // ({x: T1}) -> dynamic <: ({x: Q}) -> dynamic, under constraint Q <: T1
    _checkConstraints(
        new FunctionType([], dynamicType, Nullability.legacy,
            namedParameters: [new NamedType('x', T1)]),
        new FunctionType([], dynamicType, Nullability.legacy,
            namedParameters: [new NamedType('x', Q)]),
        ['lib::Q* <: T1']);
  }

  void test_function_return_type() {
    // () -> T1 <: () -> Q, under constraint T1 <: Q
    _checkConstraints(new FunctionType([], T1, Nullability.legacy),
        new FunctionType([], Q, Nullability.legacy), ['T1 <: lib::Q*']);
    // () -> P <: () -> void, always
    _checkConstraints(new FunctionType([], P, Nullability.legacy),
        new FunctionType([], voidType, Nullability.legacy), []);
    // () -> void <: () -> P, never
    _checkConstraints(new FunctionType([], voidType, Nullability.legacy),
        new FunctionType([], P, Nullability.legacy), null);
  }

  void test_function_trivial_cases() {
    var F = new FunctionType([], dynamicType, Nullability.legacy);
    // () -> dynamic <: dynamic, always
    _checkConstraints(F, dynamicType, []);
    // () -> dynamic <: Function, always
    _checkConstraints(F, functionType, []);
    // () -> dynamic <: Object, always
    _checkConstraints(F, objectType, []);
  }

  void test_nonInferredParameter_subtype_any() {
    var U = new TypeParameterType(
        new TypeParameter('U', _list(P)), Nullability.legacy);
    _checkConstraints(U, _list(T1), ['lib::P* <: T1']);
  }

  void test_null_subtype_any() {
    _checkConstraints(nullType, T1, ['dart.core::Null? <: T1']);
    _checkConstraints(nullType, Q, []);
  }

  void test_parameter_subtype_any() {
    _checkConstraints(T1, Q, ['T1 <: lib::Q*']);
  }

  void test_same_classes() {
    _checkConstraints(_list(T1), _list(Q), ['T1 <: lib::Q*']);
  }

  void test_typeParameters() {
    _checkConstraints(
        _map(T1, T2), _map(P, Q), ['T1 <: lib::P*', 'T2 <: lib::Q*']);
  }

  void test_unknown_subtype_any() {
    _checkConstraints(unknownType, Q, []);
    _checkConstraints(unknownType, T1, []);
  }

  Class _addClass(Class c) {
    testLib.addClass(c);
    return c;
  }

  void _checkConstraints(
      DartType a, DartType b, List<String> expectedConstraints) {
    var typeSchemaEnvironment =
        new TypeSchemaEnvironment(coreTypes, new ClassHierarchy(component));
    var typeConstraintGatherer = new TypeConstraintGatherer(
        typeSchemaEnvironment, [T1.parameter, T2.parameter]);
    var constraints = typeConstraintGatherer.trySubtypeMatch(a, b)
        ? typeConstraintGatherer.computeConstraints()
        : null;
    if (expectedConstraints == null) {
      expect(constraints, isNull);
      return;
    }
    expect(constraints, isNotNull);
    var constraintStrings = <String>[];
    constraints.forEach((t, constraint) {
      if (constraint.lower is! UnknownType ||
          constraint.upper is! UnknownType) {
        var s = t.name;
        if (constraint.lower is! UnknownType) {
          s = '${typeSchemaToString(constraint.lower)} <: $s';
        }
        if (constraint.upper is! UnknownType) {
          s = '$s <: ${typeSchemaToString(constraint.upper)}';
        }
        constraintStrings.add(s);
      }
    });
    expect(constraintStrings, unorderedEquals(expectedConstraints));
  }

  Class _class(String name,
      {Supertype supertype,
      List<TypeParameter> typeParameters,
      List<Supertype> implementedTypes}) {
    return new Class(
        name: name,
        supertype: supertype ?? objectClass.asThisSupertype,
        typeParameters: typeParameters,
        implementedTypes: implementedTypes);
  }

  DartType _iterable(DartType element) =>
      new InterfaceType(iterableClass, Nullability.legacy, [element]);

  DartType _list(DartType element) =>
      new InterfaceType(listClass, Nullability.legacy, [element]);

  DartType _map(DartType key, DartType value) =>
      new InterfaceType(mapClass, Nullability.legacy, [key, value]);
}
