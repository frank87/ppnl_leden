-module(ppdb).
-export([connect/0, query/2, toTable/3]).

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


names(HeaderList) ->
    lists:map(fun(#column{name = Naam}) -> Naam end, HeaderList).
