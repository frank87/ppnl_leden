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
                         #button{text = "mij", postback = to_user},
                         #button{text = "alle leden", postback = to_leden}]
                }]
      }].


event(to_user) ->
    Data = ppdb:query(
             "SELECT * FROM lid where lidnummer = $1;",
             [wf:session(lidnummer)]),
    ppnl_mail:send_text(wf:q(inhoud), Data, wf:q(onderwerp), {wf:session(naam), <<"info@piratenpartij.nl">>}, []);
event(to_leden) ->
    {{Year, _, _}, _} = calendar:local_time(),
    Data = ppdb:query(
             "SELECT * FROM lid where betaald_tm_jaar >= $1 or datum_lid_geworden > current_date - 14;",
             [Year]),
    ppnl_mail:send_text(wf:q(inhoud), Data, wf:q(onderwerp), {wf:session(naam), <<"info@piratenpartij.nl">>}, []).
