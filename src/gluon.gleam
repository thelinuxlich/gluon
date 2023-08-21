import gleam/erlang/process.{Subject}
import gleam/bit_builder
import gluon/internal/tcp_client.{
  ClientMessage, Close, ReceiveMessage, SendMessage,
}
import gleam/bit_string.{to_string}
import gleam/string.{drop_left, drop_right}
import gleam/result.{replace_error, try}
import gluon/internal/gluon_utils.{attempt, generate_regex, replace_with_regex}
import gleam/int

pub type Socket =
  #(Subject(ClientMessage), Subject(ClientMessage))

pub fn open(host: String, port: Int) -> Socket {
  tcp_client.init(host, port)
}

fn parse_str_resp(resp: String) {
  drop_left(resp, 1)
  |> drop_right(1)
}

fn parse_bulk_str_resp(resp: String) {
  let assert Ok(re) = generate_regex("^([0-9]+\r\n){1}")
  let value = replace_with_regex(resp, re, "")
  drop_right(value, 1)
}

fn receive(receiver: Subject(ClientMessage)) -> Result(String, String) {
  use resp <- attempt(
    process.receive(receiver, 200),
    "Failed to receive response.",
  )
  case resp {
    ReceiveMessage(resp) ->
      to_string(resp)
      |> replace_error("Failed to parse response.")
    _ -> Error("Unknown response")
  }
}

pub fn send_command(socket: Socket, command: String) -> Result(String, String) {
  let #(sender, receiver) = socket
  process.send(sender, SendMessage(bit_builder.from_string(command <> "\r\n")))
  use resp <- try(receive(receiver))
  case resp {
    "$-1" <> _ -> Error("Key not found.")
    "$" <> resp -> Ok(parse_bulk_str_resp(resp))
    "*" <> resp -> Ok(parse_bulk_str_resp(resp))
    "+" <> _ -> Ok(parse_str_resp(resp))
    ":" <> _ -> Ok(parse_str_resp(resp))
    "-" <> _ -> Error(parse_str_resp(resp))
    _ -> Error("Unknown response: " <> resp)
  }
}

pub fn get(socket: Socket, key: String) -> Result(String, String) {
  send_command(socket, "GET '" <> key <> "'")
}

pub fn del(socket: Socket, key: String) -> Result(Int, String) {
  use response <- try(send_command(socket, "DEL '" <> key <> "'"))
  replace_error(int.parse(response), "Failed to parse response.")
}

pub fn set(socket: Socket, key: String, value: String) -> Result(String, String) {
  send_command(socket, "SET '" <> key <> "' '" <> value <> "'")
}

pub fn ping(socket: Socket) -> Result(String, String) {
  send_command(socket, "PING")
}

pub fn lpush(socket: Socket, key: String, value: String) -> Result(Int, String) {
  use response <- try(send_command(socket, "LPUSH '" <> key <> "' " <> value))
  replace_error(int.parse(response), "Failed to parse response.")
}

pub fn llen(socket: Socket, key: String) -> Result(Int, String) {
  use response <- try(send_command(socket, "LLEN '" <> key <> "'"))
  replace_error(int.parse(response), "Failed to parse response.")
}

pub fn lrange(
  socket: Socket,
  key: String,
  start: Int,
  stop: Int,
) -> Result(List(String), String) {
  use response <- try(send_command(
    socket,
    "LRANGE '" <> key <> "' " <> int.to_string(start) <> " " <> int.to_string(
      stop,
    ),
  ))
  let assert Ok(re) = generate_regex("(\\$[0-9]+\r\n)+")
  let _ =
    replace_with_regex(response, re, "")
    |> string.split("\r\n")
    |> Ok
}

pub fn close(socket) {
  let #(sender, _) = socket
  process.send(sender, Close)
  Ok(Nil)
}
