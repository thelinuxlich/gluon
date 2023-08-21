// shamelessly copied from glisten tests! Thanks @rawhat!

import gleam/bit_builder.{BitBuilder}
import gleam/dynamic.{Dynamic}
import gleam/erlang/atom
import gleam/erlang/charlist.{Charlist}
import gleam/erlang/process
import gleam/function
import gleam/otp/actor
import gleam/result
import glisten/socket.{Socket}
import glisten/tcp

@external(erlang, "gen_tcp", "connect")
fn tcp_connect(
  host host: Charlist,
  port port: Int,
  options options: List(Dynamic),
) -> Result(Socket, Nil)

fn connect(host: String, port: Int) -> Socket {
  let assert Ok(client) =
    tcp_connect(
      charlist.from_string(host),
      port,
      [dynamic.from(atom.create_from_string("binary"))],
    )
  client
}

pub type ClientMessage {
  ReceiveMessage(BitString)
  SendMessage(BitBuilder)
  Close
}

pub fn init(host: String, port: Int) {
  let receiver = process.new_subject()
  let assert Ok(sender) =
    actor.start_spec(actor.Spec(
      init: fn() {
        let client = connect(host, port)
        let subj = process.new_subject()
        let client_selector =
          process.new_selector()
          |> process.selecting_record3(
            atom.create_from_string("tcp"),
            fn(_port, msg) {
              msg
              |> dynamic.bit_string
              |> result.unwrap(<<>>)
              |> ReceiveMessage
            },
          )
          |> process.selecting_record2(
            atom.create_from_string("tcp_closed"),
            function.constant(Close),
          )
          |> process.selecting(subj, function.identity)

        actor.Ready(client, client_selector)
      },
      init_timeout: 2000,
      loop: fn(msg, client) {
        case msg {
          ReceiveMessage(msg) -> {
            process.send(receiver, ReceiveMessage(msg))
            actor.Continue(client)
          }
          SendMessage(msg) -> {
            let assert Ok(_) = tcp.send(client, msg)
            actor.Continue(client)
          }
          Close -> {
            let assert Ok(_) = tcp.close(client)
            actor.Stop(process.Normal)
          }
        }
      },
    ))

  #(sender, receiver)
}
