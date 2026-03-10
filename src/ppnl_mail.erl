-module(ppnl_mail).
-export([fullname/3, send_template/5, send_text/5, merge/3, record_to_env/2, test/0]).


fullname(A, <<"">>, B) -> io_lib:format("~s ~s", [A, B]);
fullname(A, B, C) -> io_lib:format("~s ~s ~s", [A, B, C]).


send_template(File, {Headers, Data}, Subject, From, ExtraData) ->
    {ok, Template} = sgte:compile_file(File),
    lists:foreach(fun(X) -> send_record(Template, Headers, X, Subject, From, ExtraData) end, Data).


send_text(Text, {Headers, Data}, Subject, From, ExtraData) ->
    {ok, Template} = sgte:compile(Text),
    lists:foreach(fun(X) -> send_record(Template, Headers, X, Subject, From, ExtraData) end, Data).


record_to_env(Headers, Record) ->
    record_to_env(Headers, Record, []).


record_to_env(Headers, Record, ExtraData) ->
    Env = merge(Headers, tuple_to_list(Record), ExtraData),
    Vn = proplists:get_value(voornaam, Env),
    Tv = proplists:get_value(tussenvoegsel, Env),
    An = proplists:get_value(achternaam, Env),
    Fullname = fullname(Vn, Tv, An),
    [{naam, Fullname} | Env].


send_record(Template, Headers, Record, Subject, From, ExtraData) ->
    Env = record_to_env(Headers, Record, ExtraData),
    Fullname = proplists:get_value(naam, Env),
    Email = proplists:get_value(email, Env),
    Message = sgte:render_str(Template, Env),
    Mime = mimemail:encode({<<"text">>,
                            <<"plain">>,
                            [{<<"Subject">>, Subject},
                             {<<"From">>, smtp_util:combine_rfc822_addresses([From])},
                             {<<"To">>, smtp_util:combine_rfc822_addresses([{Fullname, Email}])}],
                            #{},
                            unicode:characters_to_binary(Message)}),
    io:format("~p\n", [Mime]),
    {_, FromMail} = From,
    {ok, MailConfig} = application:get_env(ppnl_leden, mailconfig),
    gen_smtp_client:send_blocking({FromMail, [Email], Mime}, MailConfig).


test() ->
    Mime = mimemail:encode({<<"text">>,
                            <<"plain">>,
                            [{<<"Subject">>, <<"Testing 123">>},
                             {<<"From">>,
                              smtp_util:combine_rfc822_addresses([{"frank", "frank87@piratenpartij.nl"}])},
                             {<<"To">>,
                              smtp_util:combine_rfc822_addresses([{"frank", "frank87@xs4all.nl"}])}],
                            #{},
                            unicode:characters_to_binary("Test mail-configuratie")}),
    {ok, MailConfig} = application:get_env(ppnl_leden, mailconfig),
    gen_smtp_client:send_blocking({<<"frank87@piratenpartij.nl">>, [<<"frank87@xs4all.nl">>], Mime}, MailConfig).


merge([], [], Data) -> Data;
merge(D1, [null | D2], Data) -> merge(D1, [<<"">> | D2], Data);
merge([D | R], D2, Data) when is_binary(D) -> merge([binary_to_atom(D) | R], D2, Data);
merge([D1 | R1], [D2 | R2], Data) -> merge(R1, R2, [{D1, D2} | Data]).
