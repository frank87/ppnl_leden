%% -*- mode: nitrogen -*-
-module(sendmail).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").


main() -> #template{file = "./priv/templates/ppnl_leden.html"}.


title() -> "Stuur mail".


body() ->
    #container_12{
      body = [#grid_8{alpha = true, prefix = 2, suffix = 2, omega = true, body = inner_body()}]
     }.


inner_body() ->
    [#article{
       body = [#html5_header{body = "Mail naar lid"},
               io_lib:format("~p", [wf:session(lidnummer)]),
               #p{
                 body = ["onderwerp ",
                         #textbox{id = onderwerp, next = inhoud}]
                },
               #p{
                 body = ["tekst ",
                         #textarea{id = inhoud}]
                },
               #p{
                 body = ["Stuur naar: ",
                         #button{text = "mij", postback = to_user}]
                }]
      }].


event(to_user) ->
    Data = ppdb:query(
             "SELECT * FROM lid where lidnummer = $1;",
             [wf:session(lidnummer)]),
    io:format("~p~n", [Data]),
    ppnl_mail:send_text(wf:q(inhoud), Data, wf:q(onderwerp), {wf:session(naam), <<"info@piratenpartij.nl">>}, []).


check_auth() ->
    io:format("~p~n", [wf:user()]),
    true.
