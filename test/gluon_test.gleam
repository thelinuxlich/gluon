import gleeunit
import gleeunit/should
import gluon
import gleam/result.{try}
import gleam/string.{repeat}

pub fn main() {
  gleeunit.main()
}

pub fn it_sends_ping_successfully_test() {
  let socket = gluon.open("localhost", 6379)
  use resp <- try(gluon.ping(socket))
  should.equal(resp, "PONG")
  gluon.close(socket)
}

pub fn it_sets_a_value_test() {
  let socket = gluon.open("localhost", 6379)
  use resp <- try(gluon.set(socket, "foo", "bar"))
  should.equal(resp, "OK")
  gluon.close(socket)
}

pub fn it_sets_a_big_value_test() {
  let socket = gluon.open("localhost", 6379)
  use resp <- try(gluon.set(socket, "foo", repeat("bar",100)))
  should.equal(resp, "OK")
  use resp <- try(gluon.get(socket, "foo"))
  should.equal(resp, repeat("bar", 100))
  gluon.close(socket)
}

pub fn it_gets_a_value_test() {
  let socket = gluon.open("localhost", 6379)
  use resp <- try(gluon.get(socket, "foo"))
  should.equal(resp, repeat("bar", 100))
  gluon.close(socket)
}

pub fn it_inserts_into_a_list_test() {
  let socket = gluon.open("localhost", 6379)
  use _ <- try(gluon.del(socket, "list"))
  use resp <- try(gluon.lpush(socket, "list", "1 2 3"))
  should.equal(resp, 3)
  gluon.close(socket)
}

pub fn it_gets_list_contents_test() {
  let socket = gluon.open("localhost", 6379)
  use resp <- try(gluon.lrange(socket, "list", 0, -1))
  should.equal(resp, ["3", "2", "1"])
  gluon.close(socket)
}
