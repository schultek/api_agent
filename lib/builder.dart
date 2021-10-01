import 'package:build/build.dart';

import 'src/builders/api_builder.dart';

/// Entry point for the builder
ApiBuilder buildApi(BuilderOptions options) => ApiBuilder(options);
