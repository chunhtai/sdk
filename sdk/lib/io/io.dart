// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

/**
 * File, socket, HTTP, and other I/O support for non-web applications.
 *
 * **Important:** Browser-based applications can't use this library.
 * Only servers, command-line scripts, and Flutter mobile apps can import
 * and use dart:io.
 *
 * This library allows you to work with files, directories,
 * sockets, processes, HTTP servers and clients, and more.
 * Many operations related to input and output are asynchronous
 * and are handled using [Future]s or [Stream]s, both of which
 * are defined in the [dart:async
 * library](../dart-async/dart-async-library.html).
 *
 * To use the dart:io library in your code:
 *
 *     import 'dart:io';
 *
 * For an introduction to I/O in Dart, see the [dart:io library
 * tour](https://www.dartlang.org/dart-vm/io-library-tour).
 *
 * ## File, Directory, and Link
 *
 * An instance of [File], [Directory], or [Link] represents a file,
 * directory, or link, respectively, in the native file system.
 *
 * You can manipulate the file system through objects of these types.
 * For example, you can rename a file or directory:
 *
 *     File myFile = new File('myFile.txt');
 *     myFile.rename('yourFile.txt').then((_) => print('file renamed'));
 *
 * Many methods provided by the File, Directory, and Link classes
 * run asynchronously and return a Future.
 *
 * ## FileSystemEntity
 *
 * File, Directory, and Link all extend [FileSystemEntity].
 * In addition to being the superclass for these classes,
 * FileSystemEntity has a number of static methods for working with paths.
 *
 * To get information about a path,
 * you can use the FileSystemEntity static methods
 * such as 'isDirectory', 'isFile', and 'exists'.
 * Because file system access involves I/O, these methods
 * are asynchronous and return a Future.
 *
 *     FileSystemEntity.isDirectory(myPath).then((isDir) {
 *       if (isDir) {
 *         print('$myPath is a directory');
 *       } else {
 *         print('$myPath is not a directory');
 *       }
 *     });
 *
 * ## HttpServer and HttpClient
 *
 * The classes [HttpServer] and [HttpClient]
 * provide HTTP server and HTTP client functionality.
 *
 * The [HttpServer] class provides the basic functionality for
 * implementing an HTTP server.
 * For some higher-level building-blocks, we recommend that you try
 * the [shelf](https://pub.dartlang.org/packages/shelf)
 * pub package, which contains
 * a set of high-level classes that, together with the [HttpServer] class
 * in this library, make it easier to implement HTTP servers.
 *
 * ## Process
 *
 * The [Process] class provides a way to run a process on
 * the native machine.
 * For example, the following code spawns a process that recursively lists
 * the files under `web`.
 *
 *     Process.start('ls', ['-R', 'web']).then((process) {
 *       stdout.addStream(process.stdout);
 *       stderr.addStream(process.stderr);
 *       process.exitCode.then(print);
 *     });
 *
 * Using `start()` returns a Future, which completes with a [Process] object
 * when the process has started. This [Process] object allows you to interact
 * with the process while it is running. Using `run()` returns a Future, which
 * completes with a [ProcessResult] object when the spawned process has
 * terminated. This [ProcessResult] object collects the output and exit code
 * from the process.
 *
 * When using `start()`,
 * you need to read all data coming on the stdout and stderr streams otherwise
 * the system resources will not be freed.
 *
 * ## WebSocket
 *
 * The [WebSocket] class provides support for the web socket protocol. This
 * allows full-duplex communications between client and server applications.
 *
 * A web socket server uses a normal HTTP server for accepting web socket
 * connections. The initial handshake is a HTTP request which is then upgraded to a
 * web socket connection.
 * The server upgrades the request using [WebSocketTransformer]
 * and listens for the data on the returned web socket.
 * For example, here's a mini server that listens for 'ws' data
 * on a WebSocket:
 *
 *     runZoned(() async {
 *       var server = await HttpServer.bind('127.0.0.1', 4040);
 *       server.listen((HttpRequest req) async {
 *         if (req.uri.path == '/ws') {
 *           var socket = await WebSocketTransformer.upgrade(req);
 *           socket.listen(handleMsg);
 *         }
 *       });
 *     }, onError: (e) => print("An error occurred."));
 *
 * The client connects to the WebSocket using the `connect()` method
 * and a URI that uses the Web Socket protocol.
 * The client can write to the WebSocket with the `add()` method.
 * For example,
 *
 *     var socket = await WebSocket.connect('ws://127.0.0.1:4040/ws');
 *     socket.add('Hello, World!');
 *
 * Check out the
 * [websocket_sample](https://github.com/dart-lang/dart-samples/tree/master/html5/web/websockets/basics)
 * app, which uses WebSockets to communicate with a server.
 *
 * ## Socket and ServerSocket
 *
 * Clients and servers use [Socket]s to communicate using the TCP protocol.
 * Use [ServerSocket] on the server side and [Socket] on the client.
 * The server creates a listening socket using the `bind()` method and
 * then listens for incoming connections on the socket. For example:
 *
 *     ServerSocket.bind('127.0.0.1', 4041)
 *       .then((serverSocket) {
 *         serverSocket.listen((socket) {
 *           socket.transform(utf8.decoder).listen(print);
 *         });
 *       });
 *
 * A client connects a Socket using the `connect()` method,
 * which returns a Future.
 * Using `write()`, `writeln()`, or `writeAll()` are the easiest ways to
 * send data over the socket.
 * For example:
 *
 *     Socket.connect('127.0.0.1', 4041).then((socket) {
 *       socket.write('Hello, World!');
 *     });
 *
 * Besides [Socket] and [ServerSocket], the [RawSocket] and
 * [RawServerSocket] classes are available for lower-level access
 * to async socket IO.
 *
 * ## Standard output, error, and input streams
 *
 * This library provides the standard output, error, and input
 * streams, named 'stdout', 'stderr', and 'stdin', respectively.
 *
 * The stdout and stderr streams are both [IOSink]s and have the same set
 * of methods and properties.
 *
 * To write a string to 'stdout':
 *
 *     stdout.writeln('Hello, World!');
 *
 * To write a list of objects to 'stderr':
 *
 *     stderr.writeAll([ 'That ', 'is ', 'an ', 'error.', '\n']);
 *
 * The standard input stream is a true [Stream], so it inherits
 * properties and methods from the Stream class.
 *
 * To read text synchronously from the command line
 * (the program blocks waiting for user to type information):
 *
 *      String inputText = stdin.readLineSync();
 *
 * {@category VM}
 */
library dart.io;

import 'dart:async';
import 'dart:_internal' hide Symbol;
import 'dart:collection'
    show HashMap, HashSet, Queue, ListQueue, MapBase, UnmodifiableMapView;
import 'dart:convert';
import 'dart:developer' hide log;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

export 'dart:_http';
export 'dart:_internal' show HttpStatus;

part 'bytes_builder.dart';
part 'common.dart';
part 'data_transformer.dart';
part 'directory.dart';
part 'directory_impl.dart';
part 'embedder_config.dart';
part 'eventhandler.dart';
part 'file.dart';
part 'file_impl.dart';
part 'file_system_entity.dart';
part 'io_resource_info.dart';
part 'io_sink.dart';
part 'io_service.dart';
part 'link.dart';
part 'namespace_impl.dart';
part 'network_profiling.dart';
part 'overrides.dart';
part 'platform.dart';
part 'platform_impl.dart';
part 'process.dart';
part 'secure_server_socket.dart';
part 'secure_socket.dart';
part 'security_context.dart';
part 'service_object.dart';
part 'socket.dart';
part 'stdio.dart';
part 'string_transformer.dart';
part 'sync_socket.dart';
