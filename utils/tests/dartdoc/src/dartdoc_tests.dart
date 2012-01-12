// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unit tests for dartdoc.
#library('dartdoc_tests');

#import('../../../dartdoc/dartdoc.dart', prefix: 'dd');
#import('../../../dartdoc/markdown.dart', prefix: 'md');

// TODO(rnystrom): Better path to unittest.
#import('../../../../client/testing/unittest/unittest_node.dart');
#import('../../../../frog/lang.dart');
#import('../../../../frog/file_system_node.dart');

main() {
  var files = new NodeFileSystem();
  parseOptions('../../frog', [], files);
  initializeWorld(files);

  group('countOccurrences', () {
    test('empty text returns 0', () {
      expect(dd.countOccurrences('', 'needle')).equals(0);
    });

    test('one occurrence', () {
      expect(dd.countOccurrences('bananarama', 'nara')).equals(1);
    });

    test('multiple occurrences', () {
      expect(dd.countOccurrences('bananarama', 'a')).equals(5);
    });

    test('overlapping matches do not count', () {
      expect(dd.countOccurrences('bananarama', 'ana')).equals(1);
    });
  });

  group('repeat', () {
    test('zero times returns an empty string', () {
      expect(dd.repeat('ba', 0)).equals('');
    });

    test('one time returns the string', () {
      expect(dd.repeat('ba', 1)).equals('ba');
    });

    test('multiple times', () {
      expect(dd.repeat('ba', 3)).equals('bababa');
    });

    test('multiple times with a separator', () {
      expect(dd.repeat('ba', 3, separator: ' ')).equals('ba ba ba');
    });
  });

  group('isAbsolute', () {
    test('returns false if there is no scheme', () {
      expect(dd.isAbsolute('index.html')).isFalse();
      expect(dd.isAbsolute('foo/index.html')).isFalse();
      expect(dd.isAbsolute('foo/bar/index.html')).isFalse();
    });

    test('returns true if there is a scheme', () {
      expect(dd.isAbsolute('http://google.com')).isTrue();
      expect(dd.isAbsolute('hTtPs://google.com')).isTrue();
      expect(dd.isAbsolute('mailto:fake@email.com')).isTrue();
    });
  });

  group('relativePath', () {
    test('absolute path is unchanged', () {
      dd.startFile('dir/sub/file.html');
      expect(dd.relativePath('http://google.com')).equals('http://google.com');
    });

    test('from root to root', () {
      dd.startFile('root.html');
      expect(dd.relativePath('other.html')).equals('other.html');
    });

    test('from root to directory', () {
      dd.startFile('root.html');
      expect(dd.relativePath('dir/file.html')).equals('dir/file.html');
    });

    test('from root to nested', () {
      dd.startFile('root.html');
      expect(dd.relativePath('dir/sub/file.html')).equals('dir/sub/file.html');
    });

    test('from directory to root', () {
      dd.startFile('dir/file.html');
      expect(dd.relativePath('root.html')).equals('../root.html');
    });

    test('from nested to root', () {
      dd.startFile('dir/sub/file.html');
      expect(dd.relativePath('root.html')).equals('../../root.html');
    });

    test('from dir to dir with different path', () {
      dd.startFile('dir/file.html');
      expect(dd.relativePath('other/file.html')).equals('../other/file.html');
    });

    test('from nested to nested with different path', () {
      dd.startFile('dir/sub/file.html');
      expect(dd.relativePath('other/sub/file.html')).equals(
          '../../other/sub/file.html');
    });

    test('from nested to directory with different path', () {
      dd.startFile('dir/sub/file.html');
      expect(dd.relativePath('other/file.html')).equals(
          '../../other/file.html');
    });
  });

  group('name reference', () {
    // TODO(rnystrom): The paths here are a bit strange. They're relative to
    // where test.dart happens to be invoked from.
    final dummyPath = 'utils/tests/dartdoc/src/dummy.dart';

    // TODO(rnystrom): Bail if we couldn't find the test file. The problem is
    // that loading dummy.dart is sensitive to the location that dart was
    // *invoked* from and not relative to *this* file like we'd like. That
    // means these tests only run correctly from one place. Unfortunately,
    // test.py/test.dart runs this from one directory and frog/presubmit.py
    // runs it from another.
    // See Bug 1145.
    var fileSystem = new NodeFileSystem();
    if (!fileSystem.fileExists(dummyPath)) {
      print("Can't run dartdoc name reference tests because dummy.dart " +
          "could not be found.");
      return;
    }

    var doc = new dd.Dartdoc();
    world.processDartScript(dummyPath);
    world.resolveAll();
    var dummy = world.libraries[dummyPath];
    var klass = dummy.findTypeByName('Class');
    var method = klass.getMember('method');

    String render(md.Node node) => md.renderToHtml([node]);

    test('to a parameter of the current method', () {
      expect(render(doc.resolveNameReference('param', member: method))).
        equals('<span class="param">param</span>');
    });

    test('to a member of the current type', () {
      expect(render(doc.resolveNameReference('method', type: klass))).
        equals('<a class="crossref" href="../../dummy/Class.html#method">' +
            'method</a>');
    });

    test('to a property with only a getter links to the getter', () {
      expect(render(doc.resolveNameReference('getterOnly', type: klass))).
        equals('<a class="crossref" ' +
            'href="../../dummy/Class.html#get:getterOnly">getterOnly</a>');
    });

    test('to a property with only a setter links to the setter', () {
      expect(render(doc.resolveNameReference('setterOnly', type: klass))).
        equals('<a class="crossref" ' +
            'href="../../dummy/Class.html#set:setterOnly">setterOnly</a>');
    });

    test('to a property with a getter and setter links to the getter', () {
      expect(render(doc.resolveNameReference('getterAndSetter', type: klass))).
        equals('<a class="crossref" ' +
            'href="../../dummy/Class.html#get:getterAndSetter">' +
            'getterAndSetter</a>');
    });

    test('to a type in the current library', () {
      expect(render(doc.resolveNameReference('Class', library: dummy))).
        equals('<a class="crossref" href="../../dummy/Class.html">Class</a>');
    });

    test('to a top-level member in the current library', () {
      expect(render(doc.resolveNameReference('topLevelMethod',
                  library: dummy))).
        equals('<a class="crossref" href="../../dummy.html#topLevelMethod">' +
            'topLevelMethod</a>');
    });

    test('to an unknown name', () {
      expect(render(doc.resolveNameReference('unknownName', library: dummy,
                  type: klass, member: method))).
        equals('<code>unknownName</code>');
    });

    test('to a member of another class', () {
      expect(render(doc.resolveNameReference('Class.method', library: dummy))).
        equals('<a class="crossref" href="../../dummy/Class.html#method">' +
            'Class.method</a>');
    });

    test('to a constructor', () {
      expect(render(doc.resolveNameReference('new Class', library: dummy))).
        equals('<a class="crossref" href="../../dummy/Class.html#new:Class">' +
            'new Class</a>');
    });

    test('to a named constructor', () {
      expect(render(doc.resolveNameReference('new Class.namedConstructor',
                  library: dummy))).
        equals('<a class="crossref" ' +
            'href="../../dummy/Class.html#new:Class.namedConstructor">new ' +
            'Class.namedConstructor</a>');
    });
  });
}
