import gleam/dynamic
import gleam/option.{Some, None}
import gleam/http.{Get, Post, Put, Delete, Patch, Head, Options}
import gleam/jsone
import magpie
import gleam/should
import gleam/io

pub fn get_test() {
  let request = http.request(Get, "http://localhost:8080/get?foo=bar")
    |> http.set_body("")
  let Ok(response) = magpie.sync(request)
  let Ok(data) = jsone.decode(http.get_body(response))
  let Ok(args) = dynamic.field(data, "args")
  should.equal(dynamic.field(args, "foo"), Ok(dynamic.from("bar")))
}

pub fn head_test() {
  let request = http.request(Head, "http://localhost:8080/get?foo=bar")
    |> http.set_body("")
  let Ok(response) = magpie.sync(request)
  should.equal("", http.get_body(response))
  let Some(content_length) = http.get_header(response, "content-length")
  should.not_equal("0", content_length)
}

pub fn post_test() {
  let request = http.request(Post, "http://localhost:8080/post")
    |> http.set_body("Hello")
  let Ok(response) = magpie.sync(request)
  let Ok(data) = jsone.decode(http.get_body(response))
  should.equal(dynamic.field(data, "data"), Ok(dynamic.from("Hello")))
}

pub fn put_test() {
  let request = http.request(Put, "http://localhost:8080/put")
    |> http.set_body("Hello")
  let Ok(response) = magpie.sync(request)
  let Ok(data) = jsone.decode(http.get_body(response))
  should.equal(dynamic.field(data, "data"), Ok(dynamic.from("Hello")))
}

pub fn patch_test() {
  let request = http.request(Patch, "http://localhost:8080/patch")
    |> http.set_body("Hello")
  let Ok(response) = magpie.sync(request)
  let Ok(data) = jsone.decode(http.get_body(response))
  should.equal(dynamic.field(data, "data"), Ok(dynamic.from("Hello")))
}

pub fn delete_test() {
  let request = http.request(Delete, "http://localhost:8080/delete")
    |> http.set_body("Hello")
  let Ok(response) = magpie.sync(request)
  let Ok(data) = jsone.decode(http.get_body(response))
  should.equal(dynamic.field(data, "data"), Ok(dynamic.from("Hello")))
}

pub fn status_test() {
  let request = http.request(Get, "http://localhost:8080/status/200")
    |> http.set_body("")

  let Ok(response) = magpie.sync(request)
  should.equal(response.head.status, 200)

  let request = http.request(Get, "http://localhost:8080/status/429")
    |> http.set_body("")

  let Ok(response) = magpie.sync(request)
  should.equal(response.head.status, 429)

  let request = http.request(Post, "http://localhost:8080/status/200")
    |> http.set_body("Hello")
  let Ok(response) = magpie.sync(request)
  should.equal(response.head.status, 200)
}
