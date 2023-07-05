import gleeunit
import gleeunit/should
import gluon
import gleam/result.{try}

pub fn main() {
  gleeunit.main()
}

pub fn it_sends_ping_successfully_test() {
  let socket = gluon.main("localhost", 6379)
  use resp <- try(gluon.send_command(socket, "PING"))
  should.equal(resp, "PONG")
  gluon.close(socket)
}

pub fn it_sets_a_value_test() {
  let socket = gluon.main("localhost", 6379)
  use resp <- try(gluon.send_command(socket, "SET foo bar"))
  should.equal(resp, "OK")
  gluon.close(socket)
}

pub fn it_gets_a_value_test() {
  let socket = gluon.main("localhost", 6379)
  use resp <- try(gluon.send_command(socket, "GET foo"))
  should.equal(resp, "bar")
  gluon.close(socket)
}
