import gleam/erlang/process.{Subject}
import gleam/bit_builder
import tcp_client.{ReceiveMessage,Close, SendMessage, ClientMessage}
import gleam/bit_string.{to_string}
import gleam/string.{drop_left, drop_right}
import gleam/result.{try}

type Socket = #(Subject(ClientMessage), Subject(ClientMessage))

pub fn main(host: String, port: Int) {
  tcp_client.init(host, port)
}

pub fn send_command(socket: Socket, command: String) {
  let #(sender, receiver) = socket
  process.send(sender, SendMessage(bit_builder.from_string(command <> "\r\n")))
  let assert Ok(resp) = process.receive(receiver, 200)
  case resp {
    ReceiveMessage(resp) -> {
        use str_resp <- try(to_string(resp))
        case str_resp {
            "$" <> _ -> drop_left(str_resp, 3) |> drop_right(1) |> Ok 
            "+" <> _ -> drop_left(str_resp, 1) |> drop_right(1) |> Ok
            _ -> Ok(str_resp)
        }
    }
    _ -> Error(Nil)
  }
}

pub fn close(socket) {
  let #(sender, _) = socket
  process.send(sender, Close)
  Ok(Nil)
}
