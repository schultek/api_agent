# api_agent

Technology-agnostic api bindings for your fullstack Dart application.

---

1. `api_agent` bridges the service gap between your Dart frontend and backend by generating 
   type-safe client and server bindings for your api from a single source definition. It 
   automatically keeps your api definitions in sync between client and server.

2. This package is only concerned about the structure of your api, not the technology or protocols 
   used. Therefore it is completely technology- as well as protocol-agnostic and you have full 
   control over the data transportation layer. It provides some ready to use implementations for 
   common protocols like HTTP, or you can implement your own to support any protocol (e.g. 
   Websockets, MQTT, GRPC, GraphQL, or any proprietary protocol).
   
- [Usage Overview](#usage-overview)
- [Setup & Getting Started](#setup--getting-started)
- [Usage](#usage)
- [Api Definitions](#api-definitions)
  - [Api Codec](#api-codec)
- [Api Clients](#api-clients)
  - [Included Api Clients](#included-api-clients)
    - [HttpApiClient](#httpapiclient)
  - [Writing Custom Api Clients](#writing-custom-api-clients)
- [Api Endpoints](#api-endpoints)


## Usage Overview

In a shared location, defining your api is as easy as defining an abstract class.

```dart
@ApiDefinition()
abstract class MyApi {
  Future<MyResult> myApiEndpoint();
}
```

On the client, accessing your api is as easy as calling a method.

```dart
void main() async {
  var client = MyApiClient( // generated from your api definition
    HttpApiClient( // ready-to-use http client
      domain: "http://my.domain.com", // http-client specific options
    ),
  );
  
  var result = await client.myApiEndpoint(); // generated method from your api definition
}
```

On the server, implementing your api is as easy as implementing an abstract method.

```dart
void main() async {
  var server = await serve( // from package:shelf
    ShelfApiRouter([ // ready-to-use shelf router
      MyApiEndpointImpl(),
    ]),
    InternetAddress.anyIPv4, port
  );
}

class MyApiEndpointImpl extends MyApiEndpoint { // generated from your api definition
  @override
  Future<MyResult> myApiEndpoint(ApiRequest request) {
    // your implementation here
  }
}
```

> For a complete implementation have a look at the example.

## Setup & Getting Started

For a fullstack Dart application using `api_agent` you need the following setup:

Start by creating a new workspace folder:

```shell
mkdir my_app && cd my_app
```

First create a `shared` dart project, which is going to contain all code used by both the 
frontend and backend. In our case, we want to put the api definitions in this project.

```shell
dart create my_app_shared
cd my_app_shared
```

This will create a dart project with a simple dart app. Since we want to use this as a shared 
library, we don't need the generated `bin` directory, but rather a `lib` with our 
`api_definitions.dart` inside. 

```shell
rm -r bin
mkdir lib && touch lib/api_definitions.dart
```

We also need to add `api_agent` as a dependency together with
`build_runner`as a dev dependency.

```shell
dart pub add api_agent
dart pub add build_runner --dev
```

Next we add our api definitions to the created file:

```dart
import 'package:api_agent/api_agent';

@ApiDefinition()
abstract class GreetApi {
  Future<String> greet(String name);
}
```

Finally in the shared project we need to run `build_runner` to generate all the necessary api
bindings for the frontend and backend. This will generate `api_definitions.client.dart` and 
`api_definitions.server.dart` to be used by the respective platform.

```shell
dart pub run build_runner build
```

---

Secondly we create our frontend project. This can of course be anything from a command-line app 
to a flutter app or website written in Dart. For simplicity we will create a simple command-line 
app, but the usage is the same for all client apps.

```shell
cd .. # make sure we are in our workspace directory
dart create my_app_frontend
```

We again need to add `api_agent` as a dependency. Additionally we need to add our `my_app_shared` 
project as a local path dependency.

```shell
cd my_app_frontend
dart pub add api_agent
dart pub add my_app_shared --path=../my_app_shared
```

Now open the generated `bin/my_app_frontend.dart` and change the content to the following. This will
import our generated api bindings from the shared package and setup a basic http client with it.

```dart
import 'package:api_agent/clients/http_client.dart';
import 'package:my_app_shared/api_definitions.client.dart';

void main(List<String> args) async {
   var client = GreetApiClient( 
      HttpApiClient(domain: "http://localhost:8080"),
   );

   var result = await client.greet(args[0]);
   print(result);
}
```

---

Lastly we setup our backend project. This can again have any structure or use any package, but for 
simplicity we will go with the standard `package:shelf` app.

```shell
cd .. # make sure we are in our workspace directory
dart create -t server-shelf my_app_backend
```

As usual, we add the needed dependencies on `api_agent` and our `my_app_shared`
project.

```shell
cd my_app_backend
dart pub add api_agent
dart pub add my_app_shared --path=../my_app_shared
```

Next we modify the generated `bin/server.dart`. We can keep most of the setup and just plug-in our
custom router with our api implementation. Therefore replace only lines 7 to 14 with the following:

```dart
import 'package:api_agent/servers/shelf_router.dart';
import 'package:my_app_shared/api_definitions.server.dart';

final _router = ShelfApiRouter([GreetApiImpl()]);

class GreetApiImpl extends GreetApiEndpoint {
  @override
  String greet(String name, ApiRequest _) {
    return 'Hello $name.';
  }
}
```

---

This is all to get a working fullstack Dart app with `api_agent`. 

To test you app, start both the server and client in two separate terminal windows:

```shell
# Terminal 1: run server
cd my_app_backend && dart run bin/server.dart
# Terminal 2: run client
cd my_app_frontend && dart run James
```

## Usage

As demonstrated in the [Setup](#setup--getting-started) there are three main parts to a fullstack 
app using `api_agent`.

- The *Api Definitions* in a shared project
- The *Api Client* in a frontend project
- The *Api Endpoints* in a backend project

## Api Definitions

You define an api definition by using the `@ApiDefinition()` annotation on an abstract class. The 
abstract methods in this class define the endpoints the api supports. A method can have any amount
of required or optional parameters and **must** return a `Future` of any type.

```dart
@ApiDefinition()
abstract class GreetApi {
  Future<String> greet(String name);
  
  Future<MyResult> compute(MyData data, {bool? someOptionalParam});
}
```

An `ApiDefinition` can also have any amount of nested child `ApiDefinition`s by defining an 
abstract `getter` with any name. The return type must be another `ApiDefinition`.

```dart
@ApiDefinition()
abstract class MainApi {
  UserApi get users;
}


@ApiDefinition()
abstract class UserApi {
  Future<List<User>> list();
}
```

How nested `ApiDefinition`s are handled is up to the protocol implementation. For example the http 
implementation constructs the request url from the nested api definitions and target method. In the 
above case, calling 'MainApiClient().users.list()' would result in a url path of `/users/list`;

### Api Codec

All protocols will at sometime need to serialize and deserialize your parameters and result objects.
Protocol implementations should define some default codec for this (e.g. `JsonCodec`), but when 
you want to use any custom types or non-primitive types for your endpoints, you need to define 
your own codec.

You can do this by implementing the `ApiCodec` interface and providing your custom codec to the 
`@ApiDefinition()` annotation.

```dart
@ApiDefinition(codec: GreetCodec())
abstract class GreetApi {
  // GreetResult will be en-/decoded by the provided GreetCodec
  Future<GreetResult> greet(String name);
}

class GreetCodec implements ApiCodec {
  @override 
  dynamic encode(dynamic value) {
    // encode value
  }
  
  @override
  T decode<T>(dynamic value) {
    // decode value
  }
}
```

## Api Clients

`api_agent` generates api clients for each of your api definitions. To use a client, instantiate it
with a protocol client as its only parameter:

```dart
var client = GreetApiClient( // generated from your api definition
   HttpApiClient(), // specific protocol client
);
```

After that you can call the endpoints that you defined in your api definition as normal methods.

```dart
var result = await client.greet();
```

### Included api clients

`api_agent` already comes with the following clients:

#### HttpApiClient

This will use the [http](https://pub.dev/packages/http) package to make requests to your api.

- Will use **GET** when a method is prefixed with `get` (e.g. `getUsers`), otherwise **POST**
- With **GET** requests, parameters are encoded as query parameters
- With **POST** requests, parameters are sent as json payload
- The url is constructed from the class name(s) and method name in the following way: 
  - `Api` suffixes on class names are ignored in the url (`GreetApi` -> `/greet`).
  - `get` prefixes on method names are ignored in the url (`getUsers()` -> `/users`).
  - Method and class names are transformed into snake case (`myMethodName()` -> `/my_method_name`)
  
The `HttpApiClient` constructor accepts

- a `domain`, where your api is hosted, 
- an optional `path`, where your api is mounted, defaults to `/`,
- an optional list of `ApiProvider`s,
- an optional `ApiCodec` to use as a fallback if none is defined by the api definition

`ApiProviders` can be used to intersect and modify a request before it is sent. A common use-case
would be to add an authentication header to the request:

```dart
class AuthProvider extends ApiProvider<HttpApiRequest> {
  @override
  FutureOr<HttpApiRequest> apply(HttpApiRequest request) {
    return request.change(headers: {'Authorization': 'Bearer my-bearer-token'});
  }
}
```

### Writing custom api clients

To define a custom client that uses your chosen protocol, simply implement the `ApiClient` 
interface:

```dart

class MyProtocolApiClient implements ApiClient {
   @override
   ApiClient mount(String prefix, [ApiCodec? codec]) {
     
   }
   
   @override
   Future<T> request<T>(String endpoint, Map<String, dynamic> params) {

   }
}
```

The `mount()` method should just return a new instance of your api client respecting the given 
prefix and codec.

The `request()` method should do the actual work of calling the api though the chosen protocol and
technology. It gets the name of the requested endpoint (the name of the called client method) and
a map of the provided parameters. A standard implementation would:

1. Construct an instance of `ApiRequest`, possibly a protocol-specific subclass like `HttpApiRequest`
2. Apply any given `ApiProviders` through `request.apply(providers)`
3. Execute the request (protocol specific implementation)
4. Return the result, possibly decoded using `codec.decode<T>(result)`

It is generally a great starting point to look at existing implementation of api clients, like the 
included `HttpApiClient`.

### Api Endpoints

- Shipped servers
- Api Middleware
- Writing custom servers