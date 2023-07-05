import gleam/erlang/process.{Subject}
import gleam/bit_builder
import tcp_client.{ClientMessage, Close, ReceiveMessage, SendMessage}
import gleam/bit_string.{to_string}
import gleam/string.{drop_left, drop_right}
import gleam/result.{replace_error, try}

type Socket =
  #(Subject(ClientMessage), Subject(ClientMessage))

pub fn main(host: String, port: Int) {
  tcp_client.init(host, port)
}

fn parse_str_resp(resp: String) {
  drop_left(resp, 1)
  |> drop_right(1)
}

fn parse_bulk_str_resp(resp: String) {
  drop_left(resp, 3)
  |> drop_right(1)
}

fn receive(receiver: Subject(ClientMessage)) -> Result(String, String) {
  use resp <- try(
    process.receive(receiver, 200)
    |> replace_error("Failed to receive response."),
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
    "$" <> _ -> Ok(parse_bulk_str_resp(resp))
    "*" <> _ -> Ok(parse_bulk_str_resp(resp))
    "+" <> _ -> Ok(parse_str_resp(resp))
    ":" <> _ -> Ok(parse_str_resp(resp))
    "-" <> _ -> Error(parse_str_resp(resp))
    _ -> Error("Unknown response: " <> resp)
  }
}

pub fn close(socket) {
  let #(sender, _) = socket
  process.send(sender, Close)
  Ok(Nil)
}
