import magpie
import gleam/should

pub fn hello_world_test() {
  magpie.hello_world()
  |> should.equal("Hello, from magpie!")
}
