import gleam/result.{replace_error, try}
import gleam/regex.{CompileError, Regex}
import gleam/string_builder.{StringBuilder, from_string}

pub fn attempt(
  result: Result(a, e),
  default_error: String,
  fun: fn(a) -> Result(b, String),
) {
  try(
    result
    |> replace_error(default_error),
    fun,
  )
}

@external(erlang, "erlang_helpers", "regex_replace")
fn regex_replace(
  in string: StringBuilder,
  each pattern: Regex,
  with substitute: StringBuilder,
) -> StringBuilder

pub fn replace_with_regex(
  in string: String,
  each pattern: Regex,
  with substitute: String,
) -> String {
  string
  |> from_string
  |> regex_replace(each: pattern, with: from_string(substitute))
  |> string_builder.to_string
}

pub fn generate_regex(pattern: String) -> Result(Regex, String) {
  let re = regex.from_string(pattern)
  case re {
    Ok(regex) -> Ok(regex)
    Error(CompileError(error, _)) -> Error(error)
  }
}
