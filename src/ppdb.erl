-module(ppdb).
-export([connect/0, query/2, toTable/3, lidquery/1, lid_update/2 ]).

-include_lib("epgsql/include/epgsql.hrl").
% -include_lib("nitrogen_core/include/wf.hrl").


connect() ->
    {ok, DbInfo = #{username := User, host := Host, password := Password}} = application:get_env(ppnl_leden, database),
    io:format("~p\n", [DbInfo]),
    {ok, C} = epgsql:connect(Host, User, Password, DbInfo),
    C.


toTable(SQL, HeaderFun, RecordFun) ->
    C = connect(),
    Result = epgsql:squery(C, SQL),
    epgsql:close(C),
    case Result of
        {ok, Headers, Data} ->
            [HeaderFun(names(Headers)) | lists:map(RecordFun, Data)];
        X -> X
    end.


query(SQL, Parms) ->
    C = connect(),
    Result = epgsql:equery(C, SQL, Parms),
    epgsql:close(C),
    case Result of
        {ok, Headers, Data} ->
            {names(Headers), Data};
        X ->
            X
    end.


lidquery(FieldMap) ->
    {Where, Data, _} = maps:fold(fun(X, Y, Z) -> add_field(X, Y, Z) end, {" 1 = 1 ", [], 1}, FieldMap),
    io:format("SELECT lidnummer FROM lid WHERE ~s <- ~p~n", [Where, Data]),
    case query(io_lib:format("SELECT lidnummer FROM lid WHERE ~s", [Where]), Data) of
        {_Headers, Result} -> lists:map(fun({X}) -> X end, Result);
        X -> X
    end.

add_field(Field, Value, {SQL, Values, No}) ->
    {io_lib:format("~s AND ~s = $~B ", [SQL, Field, No]), Values ++ [Value], No + 1}.


lid_update( LidNummer, FieldMap ) ->
	{ Set, Data, No } = maps:fold( fun( X, Y, Z ) -> add_set(X,Y,Z) end, { null, [], 1 }, FieldMap ),
	{ ok, 1 } = query( io_lib:format("UPDATE LID SET ~s WHERE lidnummer = $~B", [ Set, No ] ),  Data ++ [ LidNummer ]  ).

add_set( Field, Value, { SQLin, Values, No } ) ->
	case SQLin of
		null -> SQL = "";
		X -> SQL = SQLin ++ ", "
	end,
	{ io_lib:format( "~s~n~s = $~B", [ SQL, Field, No ] ), Values ++ [Value], No + 1 }.

names(HeaderList) ->
    lists:map(fun(#column{name = Naam, type = Type}) -> {binary_to_atom(Naam), Type} end, HeaderList).


dbToHtml(true) -> "J";
dbToHtml(false) -> "N";
dbToHtml(null) -> "";
dbToHtml({Y, M, D}) -> io_lib:format("~2..0b-~2..0b-~4..0b", [D, M, Y]);
dbToHtml({{Y, M, D}, {H, Mi, S}}) -> io_lib:format("~2..0b-~2..0b-~4..0b ~2b:~2b:~5.2.0f", [D, M, Y, H, Mi, S]);
dbToHtml(X) when is_number(X) -> io_lib:format("~p", [X]);
dbToHtml(X) -> X.
