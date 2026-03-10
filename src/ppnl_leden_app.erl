-module(ppnl_leden_app).
-behaviour(application).
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================


start(_StartType, _StartArgs) ->
    ppnl_leden_sup:start_link().


stop(_State) ->
    ok.
