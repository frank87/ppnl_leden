%% -*- mode: nitrogen -*-
-module(not_found).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").


main() -> #template{file = "./priv/templates/ppnl_leden.html"}.


title() -> "Welcome to Nitrogen".


body() ->
    #container_12{
      body = [#grid_8{alpha = true, prefix = 2, suffix = 2, omega = true, body = inner_body()}]
     }.


inner_body() ->
    [#h1{text = "Welkom bij de Piratenpartij"},
     #p{},
     "
Sorry, die pagina kennen we hier niet.
",
     #p{},
     #link{text = "ga verder", url = "/index"}].


event(click) ->
    wf:replace(button,
               #panel{
                 body = "You clicked the button!",
                 actions = #effect{effect = highlight}
                }).


check_auth() ->
    io:format("~p~n", [wf:user()]),
    true.
