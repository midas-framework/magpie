import gleam/dynamic.{Dynamic}
import gleam/iodata.{Iodata}
import gleam/list
import gleam/option.{Some, None}
import gleam/result
import gleam/uri.{Uri}
import gleam/http.{Method, Message, RequestHead, ResponseHead, Get, Post, Put, Delete, Patch, Head, Options}

external type Charlist

external fn binary_to_list(String) -> Charlist =
  "erlang" "binary_to_list"

external fn list_to_binary(Charlist) -> String =
  "erlang" "list_to_binary"

fn charlist_header(header: tuple(String, String)) -> tuple(Charlist, Charlist) {
  let tuple(k, v) = header
  tuple(binary_to_list(k), binary_to_list(v))
}

fn string_header(header: tuple(Charlist, Charlist)) -> tuple(String, String) {
  let tuple(k, v) = header
  tuple(list_to_binary(k), list_to_binary(v))
}

external type ErlHttpOption

type BodyFormat {
  Binary
}

type ErlOption {
  BodyFormat(BodyFormat)
}

type ErlRequest {
  NoBody(url: Charlist, headers: List(tuple(Charlist, Charlist)))
  WithBody(
    url: Charlist,
    headers: List(tuple(Charlist, Charlist)),
    Charlist,
    Iodata,
  )
}

external fn httpc_request_no_body(
  Method,
  tuple(Charlist, List(tuple(Charlist, Charlist))),
  List(ErlHttpOption),
  List(ErlOption),
) -> Result(
  tuple(tuple(Charlist, Int, Charlist), List(tuple(Charlist, Charlist)), String),
  Dynamic,
) =
  "httpc" "request"

external fn httpc_request_with_body(
  Method,
  tuple(Charlist, List(tuple(Charlist, Charlist)), Charlist, String),
  List(ErlHttpOption),
  List(ErlOption),
) -> Result(
  tuple(tuple(Charlist, Int, Charlist), List(tuple(Charlist, Charlist)), String),
  Dynamic,
) =
  "httpc" "request"

// stdlib pop_map like find_map and pop like find
fn do_key_pop(haystack, desired_key, accumulator) {
  case haystack {
    [] -> Error(Nil)
    [tuple(k, v), ..rest] if k == desired_key -> {
      let remaining = list.append(list.reverse(accumulator), rest)
      Ok(tuple(v, remaining))
    }
    [x, ..rest] -> do_key_pop(rest, desired_key, [x, ..accumulator])
  }
}

pub fn key_pop(haystack, desired_key) {
  do_key_pop(haystack, desired_key, [])
}

// Can take a body function as 2nd argument for traits
pub fn sync(
  request: http.Request(Iodata),
  secure: Bool,
) -> Result(http.Response(Iodata), Dynamic) {
  let Message(head: head, headers: headers, body: body) = request
  let RequestHead(
    method: method,
    host: host,
    port: port,
    path: path,
    query: query,
  ) = head
  let scheme = case secure {
    True -> "https"
    False -> "http"
  }
  let target = Uri(Some(scheme), None, Some(host), port, path, query, None)
  let charlist_target = binary_to_list(uri.to_string(target))
  let charlist_headers = list.map(headers, charlist_header)

  // httpc errors if passing method get with 4 element request tuple, i.e. with body.
  let response = case method {
    Get | Head -> httpc_request_no_body(
      method,
      tuple(charlist_target, charlist_headers),
      [],
      [BodyFormat(Binary)],
    )
    Post | Put | Patch | Delete -> {
      let tmp = key_pop(charlist_headers, binary_to_list("content-type"))
      let tuple(
        content_type,
        charlist_headers,
      ) = result.unwrap(tmp, tuple(binary_to_list(""), charlist_headers))
      httpc_request_with_body(
        method,
        tuple(
          charlist_target,
          charlist_headers,
          content_type,
          // Don't pass an io list, httpc counts length of list not bytes length.
          iodata.to_string(body),
        ),
        [],
        [BodyFormat(Binary)],
      )
    }
  }

  case response {
    Ok(
      tuple(tuple(_http_version, status, _status), headers, resp_body),
    ) -> Ok(
      Message(
        ResponseHead(status),
        list.map(headers, string_header),
        iodata.from_strings([resp_body]),
      ),
    )
  }
}
