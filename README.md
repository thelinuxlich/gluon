# gluon

[![Package Version](https://img.shields.io/hexpm/v/gluon)](https://hex.pm/packages/gluon)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/gluon/)

A Gleam Redis client

## Quick start

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

## Installation

```sh
gleam add gluon
```

## Usage

```rust
import gluon

pub fn main() {
  let socket = gluon.open("localhost", 6379) // Socket
  let result = gluon.set(socket, "key", "value") // Result(String, String)
  let result = gluon.get(socket, "key") // Result(String, String)
  let custom_command = gluon.send_command(socket, "MSET key1 value1 key2 value2") // ResulT(String, String)
  let _ = gluon.close(socket)
}
```

and its documentation can be found at <https://hexdocs.pm/gluon>.
