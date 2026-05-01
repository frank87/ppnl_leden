%% -*- mode: nitrogen -*-
-module(logout).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").


main() -> #template{file = "./priv/templates/ppnl_leden.html"}.


title() -> "uitloggen".


body() ->
    #container_12{
      body = [#grid_8{alpha = true, prefix = 2, suffix = 2, omega = true, body = inner_body()}]
     }.


inner_body() ->
    wf:logout(),
    [#p{text = "Uitgelogd"},
     #link{text = "inloggen", url = "/"}].


event(click) ->
    wf:replace(button,
               #panel{
                 body = "You clicked the button!",
                 actions = #effect{effect = highlight}
                }).
