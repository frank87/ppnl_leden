%% -*- mode: nitrogen -*-
-module(crud).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").


main() -> #template{file = "./priv/templates/ppnl_leden.html"}.


title() -> "bekijken/wijzigen lid".


body() ->
    #container_12{
      body = [#grid_8{alpha = true, prefix = 2, suffix = 2, omega = true, body = inner_body()}]
     }.


inner_body() ->
    case string:to_integer(wf:path_info()) of
        {LidNr, []} ->
            wf:state(crud, clean),
            wf:state(current, LidNr),
            {Fields, [Data]} = ppdb:query("select * from lid where lidnummer = $1", [LidNr]),
            Zipped = lists:zip(Fields, tuple_to_list(Data)),
            lists:map(fun({F, D}) -> ppnl_nitrogen:set_field(F, D) end, Zipped);
        _ ->
            wf:state(crud, new),
            {Fields, []} = ppdb:query("select * from lid where 1 = 0", [])
    end,
    #panel{
      body = [#table{rows = lists:map(fun(X) -> field(X) end, Fields)},
              #table{rows = buttons(wf:state(crud))}]
     }.


buttons(new) ->
    #tablerow{
      cells = [#tablecell{body = [#button{text = "Zoek", postback = search}]},
               #tablecell{
                 body = [#button{
                           id = submit,
                           text = "Insert",
                           postback = insert,
                           handle_invalid = true,
                           on_invalid = #alert{text = "Niet alle velden zijn goed gevuld"}
                          }]
                }]
     };
buttons(clean) ->
    #tablerow{
      cells = [#tablecell{
                 body = [#button{
                           id = submit,
                           text = "update",
                           postback = update,
                           handle_invalid = true,
                           on_invalid = #alert{
                                          text = "Niet alle velden zijn goed gevuld"
                                         }
                          }]
                },
	       #tablecell{},
	       #tablecell{ body = [
				   #button{ id = next, 
					    text = "volgende", 
					    postback = next, 
					    disabled = case wf:session(next) of
						[_|_ ] -> false;
							       _ -> true
						       end } ] },
	       #tablecell{ body = [
				   #button{ id = previous, 
					    text = "vorige", 
					    postback = previous, 
					    disabled = case wf:session(previous) of
						[_|_ ] -> false;
							       _ -> true
						       end
					  } ] }
		]}.

event_invalid( _ ) -> false.

field(X = {lidnummer, _}) ->
    case wf:state(crud) of
        clean -> RW = ro;
        new -> RW = rw
    end,
    ppnl_nitrogen:field(X, RW);
field(X = {mutator_code, _}) -> ppnl_nitrogen:field(X, ro);
field(X = {_, uuid}) -> ppnl_nitrogen:field(X, ro);
field({email, _}) -> ppnl_nitrogen:field({email, email}, rw);
field({land_id, _}) -> ppnl_nitrogen:field(land, {land_id, {id, land, naam}}, rw);
field({gemeente_id, _}) -> ppnl_nitrogen:field(gemeente, {gemeente_id, {id, gemeente, naam}}, rw);
field({provincie_id, _}) -> ppnl_nitrogen:field(provincie, {provincie_id, {id, provincie, naam}}, rw);
field(X) -> ppnl_nitrogen:field(X, rw).


event(X = {changed, Field = {FName, _}}) ->
    Res = ppnl_nitrogen:get_field(Field),
    UpdatedFields = wf:state_default(dirty, #{}),
    wf:state(dirty, UpdatedFields#{FName => Res}),
    io:format("Search: ~p~n", [wf:state(dirty)]),
    io:format("Event: ~p -> ~p ~n", [X, Res]);
event(update) ->
    LidNummer = wf:state(current),
    Set = wf:state(dirty),
    ppdb:lid_update( LidNummer, Set#{ mutator_code => wf:session(naam) } ),
    wf:redirect( wf:url() );
event(search) ->
    %io:format("Search: ~p~n", [wf:state(dirty)]);
    Next = ppdb:lidquery( wf:state_default(dirty, #{} ) ),
    wf:session(next,Next),
    wf:session(previous, [] ),
    wf:session(current, undefined ),
    event( next );
event(previous) ->
    move(previous, next);
event(next) ->
    move(next, previous);
event(X) ->
    io:format("Event: ~p~n", [X]).


move( Forward, Back ) ->
    case wf:session( current ) of
	    undefined	-> ok;
	    Current	-> Previous = wf:session_default( Back, [] ),
			   wf:session( Back, [Current| Previous ] )
    end,
    case wf:session_default(Forward, [] ) of
	    [ To | Next ] ->	wf:session(Forward, Next),
				wf:session(current, To),
				wf:redirect( io_lib:format("/crud/~B", [ To ] ) );
	    []	-> false;
	    X	-> io:format("~p~n", [X] )
    end.
