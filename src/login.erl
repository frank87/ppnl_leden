%% -*- mode: nitrogen -*-
-module (login).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").


main() -> #template { file="./priv/templates/bare.html" }.

title() -> "Inloggen Piratenpartij".

body() ->
    #container_12 { body=[
        #grid_8 { alpha=true, prefix=2, suffix=2, omega=true, body=inner_body() }
    ]}.

inner_body() -> 
    [
        #h1 { text="Welkom bij de Piratenpartij" },
        #p{},
	#panel{ id = vraag1,
		body = [
			        #p{ text = "Wat is je email" },
			        #p{}, 	
			        #textbox { id=email,  type=email, postback=click1 },
			        #p{ text = "Wat is je lidnummer" },
			        #p{}, 	
			        #textbox { id=lidNr,  type=number, pattern="[0-9]*" },
				#button{ text = "bevestig invoer", postback=click1 }
			] },
	#p{},
	#panel{ id = vraag2 }
    ].
	
event(click1) ->
    try
	    { LidNr, [] } = string:to_integer(wf:q( lidNr )),
	    Data = 
		 { Header, [ Record ] } =  
			ppdb:query( 
				"SELECT * FROM lid where lidnummer = $1 and email = $2;", 
				[ LidNr, wf:q(email) ] ),
	    UserInfo = ppnl_mail:record_to_env( Header, Record ),
	    wf:state(userinfo, UserInfo ),
	    Secret = rand:uniform(987654321),
	    wf:state(code, Secret ),
	    { ok, AfzenderMail } = application:get_env( ppnl_leden, system_mail ),
	    { ok, Afzendernaam } = application:get_env( ppnl_leden, system_mail_r ),
	    ppnl_mail:send_template( "priv/templates/login.mail",
				    Data,
				    <<"Inloggen Piratenpartij">>,
				    { Afzendernaam, AfzenderMail },
				    [ { secret, Secret } ] ),
	    wf:update( vraag2, [
				    #p{ id = vraag2, text = "Wat is de code die je ontvangen hebt in de mail?" },
			  	    #textbox { id=code, type=number, postback=click2 }
				] )
    catch
	error:{badmatch,X}:St ->
		[ Location | _ ] = St,
		timer:sleep(2000), 
		io:format("Badmatch ~p ~p~n", [X, Location] ),
	       	wf:update( vraag2, "Dat email adres kennen we niet van jou" )
    end;

event(click2) ->
    Secret = wf:state(code),
    case string:to_integer( wf:q( code ) ) of
	{ Secret, [] } -> login_succes();
	_ ->   timer:sleep(2000), wf:update( vraag2, "Dat is niet goed, je krijgt nog een kans" )
    end.


login_succes() ->
    lists:foreach( fun ( { Key, Value } ) -> 
			wf:session( Key, Value ), 
			io:format( "~p - ~p: ~p~n", [ Key, Value, wf:session(Key) ] ) 
		   end, wf:state(userinfo) ),
    wf:session( user, wf:state(userinfo) ),
    wf:user( wf:q( lidNr ) ),
    % Loginpagina is op de originele URL gepresenteerd
    wf:redirect_from_login( wf_context:uri() ).


% Included in template
redirect() ->
	case wf:user() of
		undefined -> wf:redirect_to_login("login");
		_	-> 
			    #container_12 { body=[
			        #grid_8 { alpha=true, prefix=2, suffix=2, omega=true, body= [
					"Gebruiker ", 
					wf:session(naam), " ",
					" - ",
					#link{ text = "stuur mail", url = "sendmail" },
					" - ",
					#link{ text = "uitloggen", url = "logout" }
				] }
			    ]}
	end.
