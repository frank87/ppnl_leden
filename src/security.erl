-module (security).
-behaviour (security_handler).
-export ([
    init/2,
    finish/2
]).


init(_Config, State) ->
    % By default, let all requests through. If we wanted to impose
    % security, then check the page module (via wf:page_module()),
    % and if the user doesn't have access, then set a new page module and path info,
    % via wf_context:page_module(Module), wf_context:path_info(PathInfo).
    check_login( wf:user(), State ).

check_login( undefined, State ) -> 
    wf_context:page_module( login ), 
    { ok, State };
check_login( _, State ) ->
    io:format("<~p>~n", [ wf_context:page_module() ] ),
    case wf_context:page_module() of
	file_not_found_page ->	wf_context:page_module( not_found ), { ok, State };
	index ->	{ ok, State };
	login ->	{ ok, State };
	logout ->	{ ok, State };
	sendmail ->	{ ok, State };
	Module	->	check_auth( wf:role( Module ), State )
    end.

check_auth( true, State ) -> { ok, State };
check_auth( _, State ) -> wf_context:page_module( not_found ), { ok, State }.
    

finish(_Config, State) ->
    {ok, State}.
