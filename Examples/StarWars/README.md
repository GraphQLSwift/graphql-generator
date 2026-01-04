# Star Wars

This is a `graphql-generator` example using the schema at https://graphql.org/graphql/, which wraps the [Star Wars API](https://www.swapi.tech) (SWAPI). For a Javascript implementation, see https://github.com/graphql/swapi-graphql

It uses [async-http-client](https://github.com/swift-server/async-http-client) to make the web requests and a [DataLoader](https://github.com/GraphQLSwift/DataLoader) to cache SWAPI responses.

## Getting Started

To get started, simply open this directory and build the project:

```swift
swift build
```

Running the tests will print some example query responses to the console.
