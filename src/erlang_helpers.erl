-module(erlang_helpers).

-export([regex_replace/3]).

regex_replace(Str, Regex, Repl) ->
    re:replace(Str, Regex, Repl, [global]).