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
  - [HttpApiClient](#httpapiclient)
  - [Api Providers](#api-providers)
  - [Writing custom Api Clients](#writing-custom-api-clients)
- [Api Endpoints](#api-endpoints)
  - [Api Middleware](#api-middleware)
  - [Api Builders](#api-builders)
    - [ShelfApiRouter](#shelfapirouter)
  - [Writing custom Api Builders](#writing-custom-api-builders)


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
`definitions.api.dart` inside. 

```shell
rm -r bin
mkdir lib && touch lib/definitions.api.dart
```

We also need to add `api_agent` as a dependency together with
`build_runner`as a dev dependency.

```shell
dart pub add api_agent
dart pub add build_runner --dev
```

Next we add our api definitions to the created file:

```dart
import 'package:api_agent/api_agent.dart';

@ApiDefinition()
abstract class GreetApi {
  Future<String> greet(String name);
}
```

Finally in the shared project we need to run `build_runner` to generate all the necessary api
bindings for the frontend and backend. This will generate `definitions.client.dart` and 
`definitions.server.dart` to be used by the respective platform.

```shell
dart run build_runner build
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
import 'package:my_app_shared/definitions.client.dart';

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
custom router with our api implementation. Therefore replace only lines 7 to 19 with the following:

```dart
import 'package:api_agent/servers/shelf_router.dart';
import 'package:my_app_shared/definitions.server.dart';

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
cd my_app_frontend && dart run my_app_frontend James
```

> While it is not very scalable, you could also do everything in a single dart project. Have a look
> at [examples/single_project](https://github.com/schultek/api_agent/tree/main/examples/single_project) for an example of this.

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

### Api Providers

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

### Writing custom Api Clients

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

## Api Endpoints

`api_agent` generates `ApiEndpoint`s for each of your `ApiDefinition`s. `ApiEndpoint`s need to be 
implemented on the server and the passed to an `ApiBuilder` that e.g. spins up a http server and
passes incoming requests to your endpoints.

To implement your endpoints you will need to do the following:

First our api definition from above will generate a
`GreetEndpoint` that expects an implementation in form of 
`FutureOr<String> Function(String name, ApiRequest request)`.

There are multiple ways to implement an endpoint.

1. Passing a handler function
  ```dart
  var greetEndpoint = GreetEndpoint.from((name, r) {
    return 'Hello $name.';
  });
  ```

2. Extending the abstract class
  ```dart
  var greetEndpoint = GreetEndpointImpl();

  class GreetEndpointImpl extends GreetEndpoint {
    @override
    FutureOr<String> greet(String name, ApiRequest request) {
      return 'Hello $name.';
    }
  } 
  ```

You can freely choose between these two options on a case-by-case basis.

Next `api_agent` will also generate an `GreetApiEndpoint` that expects a `GreetEndpoint` as its
child. You can again choose to provide the endpoint directly, or implement the abstract class:

1. Passing a child endpoint
  ```dart
  var greetApi = GreetApiEndpoint.from(
    greet: greetEndpoint,
  );
  ```

2. Extending the abstract class
  ```dart
  var greetApi = GreetApiEndpointImpl();

  class GreetApiEndpointImpl extends GreetApiEndpoint {
    @override
    FutureOr<String> greet(String name, ApiRequest request) {
      return 'Hello $name.';
    }
  }
  ```

---

This might seem ambiguous, but it gives you the freedom to choose the right level of cohesion.
With a small simple api you might not want to create a custom class for every endpoint.
But with a larger and more complex api you might find this more appropriate to separate your logic.

### Api Middleware

In more complex apis with nested inner apis, your endpoints will form a tree-like structure:

```dart
var myApi = MyApiEndpoint.from(
  users: UsersEndpoint.from(
    list: ...,
    getById: ...,
  ),
  publications: PublicationsEndpoint.from(
    articles: ArticlesEndpoint.from(
      list: ...,
      ...
    ),
  ),
)
```

You can add an `ApiMiddleware` anywhere in this tree to monitor or guard requests to the endpoints
in the chosen subtree. A typical use-case is to authenticate the requesting user.

Implement a custom `ApiMiddleware` by implementing the `ApiMiddleware` interface:

```dart
class AuthMiddleware implements ApiMiddleware {
  @override
  FutureOr<dynamic> apply(covariant ShelfApiRequest request, EndpointHandler next) {
    String? token = request.headers['Authorization'];
    if (validateToken(token)) {
      return next(request);
    } else {
      throw ApiException(401, 'Authentication token is invalid.');
    }
  }
}
```

Then, insert your middleware using the `ApplyMiddleware` endpoint:

```dart
var myApi = MyApiEndpoint.from(
  users: ApplyMiddleware(
    middleware: AuthMiddleware(),
    child: UserEndpoint.from( // middleware applied to all child endpoints
      ...
    ),
  ),
  publications: PublicationsEndpoint.from( // middleware not applied to endpoints
    ... 
  ),
);
```

### Api Builders

An `ApiBuilder` consumes your api endpoints and constructs the communication channel to which the 
client can connect to. `api_agent` already comes with the following builders:

#### ShelfApiRouter

This will use the [shelf_router](https://pub.dev/packages/shelf_router) package to construct a 
router that can be use with the [shelf](https://pub.dev/packages/shelf) package and e.g. passed 
to [serve](https://pub.dev/documentation/shelf/latest/shelf_io/serve.html).

It is intended to be used with the [HttpApiClient](#httpapiclient) and has the same request rules.

To use it simple pass your api endpoint to `ShelfApiRouter`s constructor and use it as a shelf 
handler:

```dart
void main() {
  var router = ShelfApiRouter([greetApi]);
  
  serve(router, InternetAddress.anyIPv4, port: 8080);
}
```

### Writing custom Api Builders

To define a custom api builder that uses your chosen protocol, simply implement the `ApiBuilder`
interface:

```dart
class MyProtocolApiBuilder implements ApiBuilder {
  @override
  void mount(String prefix, List<ApiEndpoint> children) {
    // mounts [children] under [prefix]
    // should call [ApiEndpoint.build()] for each child with
    // a new instance of your api builder
  }
  
  @override
  void handle(String endpoint, EndpointHandler handler) {
    // registers the [handler] for this [endpoint] 
  }
}
```

After that you should call the `build(ApiBuilder builder)` method of your root `ApiEndpoint`(s) and
provide an instance of your custom `ApiBuilder`. These will then subsequently call `mount()` or 
`handle()` to register themselves with your api.

I would recommend looking at existing implementation of api builders, like the
included `ShelfApiRouter`.


