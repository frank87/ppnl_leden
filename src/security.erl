-module(security).
-behaviour(security_handler).
-export([init/2,
         finish/2,
         is_allowed/1]).


init(_Config, State) ->
    % By default, let all requests through. If we wanted to impose
    % security, then check the page module (via wf:page_module()),
    % and if the user doesn't have access, then set a new page module and path info,
    % via wf_context:page_module(Module), wf_context:path_info(PathInfo).
    case is_allowed(wf_context:page_module()) of
        true -> {ok, State};
        redirect -> wf_context:page_module(login), {ok, State};
        _ -> wf_context:page_module(not_found), {ok, State}
    end.


is_allowed(Module) -> is_allowed(Module, wf:user()).


% debugging...
is_allowed(login, _) -> true;
is_allowed(logout, _) -> true;
is_allowed(_, undefined) -> redirect;
is_allowed(_, file_not_found_page) -> false;
is_allowed(_, index) -> true;
is_allowed(Module, _) -> wf:role(Module).


finish(_Config, State) ->
    {ok, State}.
