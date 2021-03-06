// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceCreationDriverResolutionTest);
  });
}

@reflectiveTest
class InstanceCreationDriverResolutionTest extends DriverResolutionTest {
  test_error_newWithInvalidTypeParameters_implicitNew_inference_top() async {
    await resolveTestCode(r'''
final foo = Map<int>();
''');
    assertTestErrorsWithCodes([
      StaticWarningCode.NEW_WITH_INVALID_TYPE_PARAMETERS,
    ]);

    var creation = findNode.instanceCreation('Map<int>');
    assertInstanceCreation(
      creation,
      mapElement,
      'Map<dynamic, dynamic>',
      expectedConstructorMember: true,
      expectedSubstitution: {'K': 'dynamic', 'V': 'dynamic'},
    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew() async {
    await resolveTestCode(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  new Foo.bar<int>();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
    ]);

    // TODO(brianwilkerson) Test this more carefully after we can re-write the
    // AST to reflect the expected structure.
//    var creation = findNode.instanceCreation('Foo.bar<int>');
//    assertInstanceCreation(
//      creation,
//      findElement.class_('Foo'),
//      'Foo',
//      constructorName: 'bar',
//    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew_prefix() async {
    newFile('/test/lib/a.dart', content: '''
class Foo<X> {
  Foo.bar();
}
''');
    await resolveTestCode('''
import 'a.dart' as p;

main() {
  new p.Foo.bar<int>();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
    ]);

    // TODO(brianwilkerson) Test this more carefully after we can re-write the
    // AST to reflect the expected structure.
//    var creation = findNode.instanceCreation('Foo.bar<int>');
//    var import = findElement.import('package:test/a.dart');
//    assertInstanceCreation(
//      creation,
//      import.importedLibrary.getType('Foo'),
//      'Foo',
//      constructorName: 'bar',
//      expectedPrefix: import.prefix,
//    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew() async {
    await resolveTestCode(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  Foo.bar<int>();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
    ]);

    var creation = findNode.instanceCreation('Foo.bar<int>');
    assertInstanceCreation(
      creation,
      findElement.class_('Foo'),
      // TODO(scheglov) Move type arguments
      'Foo<dynamic>',
//      'Foo<int>',
      constructorName: 'bar',
      expectedConstructorMember: true,
      // TODO(scheglov) Move type arguments
      expectedSubstitution: {'X': 'dynamic'},
//      expectedSubstitution: {'X': 'int'},
    );
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew_prefix() async {
    newFile('/test/lib/a.dart', content: '''
class Foo<X> {
  Foo.bar();
}
''');
    await resolveTestCode('''
import 'a.dart' as p;

main() {
  p.Foo.bar<int>();
}
''');
    assertTestErrorsWithCodes([
      StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_CONSTRUCTOR,
    ]);

    var import = findElement.import('package:test/a.dart');

    var creation = findNode.instanceCreation('Foo.bar<int>');
    assertInstanceCreation(
      creation,
      import.importedLibrary.getType('Foo'),
      'Foo<int>',
      constructorName: 'bar',
      expectedConstructorMember: true,
      expectedPrefix: import.prefix,
      expectedSubstitution: {'X': 'int'},
    );
  }
}
