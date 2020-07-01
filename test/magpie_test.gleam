import gleam/dynamic.{Dynamic}
import gleam/map
import gleam/http.{Get, Post, Put, Delete, Patch, Head, Options}
import magpie
import gleam/should
import gleam/io

external fn jsone_decode(json: String) -> Dynamic =
  "jsone" "decode"

pub fn get_test() {
  let request = http.request(Get, "http://localhost:8080/get?foo=bar")
    |> http.set_body("")
  let Ok(response) = magpie.sync(request, False)
  let data = jsone_decode(http.get_body(response))
  let Ok(args) = dynamic.field(data, "args")
  should.equal(dynamic.field(args, "foo"), Ok(dynamic.from("bar")))
}

pub fn head_test() {
  let request = http.request(Head, "http://localhost:8080/get?foo=bar")
    |> http.set_body("")
  let Ok(response) = magpie.sync(request, False)
  should.equal("", http.get_body(response))
  let Ok(content_length) = http.get_header(response, "content-length")
  should.not_equal("0", content_length)
}

pub fn post_test() {
  let request = http.request(Post, "http://localhost:8080/post")
    |> http.set_body("Hello")
  let Ok(response) = magpie.sync(request, False)
  let data = jsone_decode(http.get_body(response))
  should.equal(dynamic.field(data, "data"), Ok(dynamic.from("Hello")))
}

pub fn put_test() {
  let request = http.request(Put, "http://localhost:8080/put")
    |> http.set_body("Hello")
  let Ok(response) = magpie.sync(request, False)
  let data = jsone_decode(http.get_body(response))
  should.equal(dynamic.field(data, "data"), Ok(dynamic.from("Hello")))
}

pub fn patch_test() {
  let request = http.request(Patch, "http://localhost:8080/patch")
    |> http.set_body("Hello")
  let Ok(response) = magpie.sync(request, False)
  let data = jsone_decode(http.get_body(response))
  should.equal(dynamic.field(data, "data"), Ok(dynamic.from("Hello")))
}

pub fn delete_test() {
  let request = http.request(Delete, "http://localhost:8080/delete")
    |> http.set_body("Hello")
  let Ok(response) = magpie.sync(request, False)
  let data = jsone_decode(http.get_body(response))
  should.equal(dynamic.field(data, "data"), Ok(dynamic.from("Hello")))
}

pub fn status_test() {
  let request = http.request(Get, "http://localhost:8080/status/200")
    |> http.set_body("")

  let Ok(response) = magpie.sync(request, False)
  should.equal(response.head.status, 200)

  let request = http.request(Get, "http://localhost:8080/status/429")
    |> http.set_body("")

  let Ok(response) = magpie.sync(request, False)
  should.equal(response.head.status, 429)

  let request = http.request(Post, "http://localhost:8080/status/200")
    |> http.set_body("Hello")
  let Ok(response) = magpie.sync(request, False)
  should.equal(response.head.status, 200)
}

pub fn headers_test() {
  // Ok we can have these header test on Get, but I need post to check it's working for the body case
  let request = http.request(Get, "http://localhost:8080/headers")
    |> http.set_header("x-foo", "bar")
    |> http.set_form([])
  let Ok(response) = magpie.sync(request, False)
  should.equal(response.head.status, 200)
  let data = jsone_decode(http.get_body(response))
  let Ok(headers) = dynamic.field(data, "headers")
  dynamic.field(headers, "Content-Type")
  |> should.equal(Ok(dynamic.from("application/x-www-form-urlencoded")))
}
