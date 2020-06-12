import gleam/dynamic
import gleam/http.{Get, Post}
import gleam/jsone
import magpie
import gleam/should

pub fn get_test() {
  let request = http.request(Get, "http://localhost:8080/get?foo=bar")
    |> http.set_body("")
  let Ok(response) = magpie.sync(request)
  let Ok(data) = jsone.decode(http.get_body(response))
  let Ok(args) = dynamic.field(data, "args")
  should.equal(dynamic.field(args, "foo"), Ok(dynamic.from("bar")))
}

pub fn post_test() {
  let request = http.request(Post, "http://localhost:8080/post")
    |> http.set_body("Hello")
  let Ok(response) = magpie.sync(request)
  let Ok(data) = jsone.decode(http.get_body(response))
  should.equal(dynamic.field(data, "data"), Ok(dynamic.from("Hello")))
}
