import 'dart:async';

import 'package:build/build.dart';

import 'client_builder.dart';
import 'server_builder.dart';

/// The main builder used for code generation
class ApiBuilder implements Builder {
  /// The global options defined in the 'build.yaml' file
  late BuilderOptions options;

  ApiBuilder(this.options);

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    var resolver = buildStep.resolver;
    var inputId = buildStep.inputId;
    var visibleLibraries = await resolver.libraries.toList();

    try {
      var clientId = AssetId(inputId.package,
          inputId.path.replaceFirst('.api.dart', '.client.dart'));
      var clientSource =
          await ClientApiBuilder().generateClients(visibleLibraries, buildStep);
      await buildStep.writeAsString(clientId, clientSource);

      var serverId = AssetId(inputId.package,
          inputId.path.replaceFirst('.api.dart', '.server.dart'));
      var serverSource =
          await ServerApiBuilder().generateServers(visibleLibraries, buildStep);
      await buildStep.writeAsString(serverId, serverSource);
    } catch (e, st) {
      print(st);
      rethrow;
    }
  }

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.api.dart': ['.client.dart', '.server.dart']
      };
}
