%% -*- mode: nitrogen -*-
-module (login).
-compile(export_all).
-include_lib("nitrogen_core/include/wf.hrl").


main() -> #template { file="./priv/templates/bare.html" }.

title() -> "Welcome to Nitrogen".

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
    { LidNr, [] } = string:to_integer(wf:q( lidNr )),
    { _Headers, [ { Voornaam, TussenVoegsel, Achternaam, DbEmail } ] } =  ppdb:query( 
			"SELECT voornaam, tussenvoegsel, achternaam, email FROM lid where lidnummer = $1;", 
			[ LidNr ] ),
    {ok, [{ _, Email_check }]} = smtp_util:parse_rfc822_addresses( wf:q(email) ),
    {ok, [{ _, Email }]}       = smtp_util:parse_rfc822_addresses( DbEmail ),
    case Email of
	Email_check ->
	    Secret = rand:uniform(987654321),
	    wf:state(code, Secret ),
	    sendMail( Voornaam, TussenVoegsel, Achternaam, Email, Secret ),
	    wf:state(userinfo, { Voornaam, TussenVoegsel, Achternaam, Email } ),
	    wf:update( vraag2, [
	    
				        #p{ id = vraag2, text = "Wat is de code die je ontvangen hebt in de mail?" },
					#textbox { id=code, type=number, postback=click2 }
				] );
	_ ->   timer:sleep(2000), 
	       wf:update( vraag2, "Dat email adres kennen we niet van jou" )
    end;

event(click2) ->
    Secret = wf:state(code),
    case string:to_integer( wf:q( code ) ) of
	{ Secret, [] } -> login_succes();
	_ ->   timer:sleep(2000), wf:update( vraag2, "Dat is niet goed, je krijgt nog een kans" )
    end.


login_succes() ->
    { Voornaam, TussenVoegsel, Achternaam, Email } =  wf:state(userinfo),
    wf:session( voornaam, Voornaam ),
    wf:session( tussenvoegsel, TussenVoegsel ),
    wf:session( achternaam, Achternaam ),
    wf:session( email, Email ),
    wf:user( wf:q( lidNr ) ),
    wf:redirect_from_login( "index.html" ).

sendMail( Voornaam, TussenVoegsel, Achternaam, Email, Secret ) ->
	{ ok, MailConfig } = application:get_env( ppnl_leden, mailconfig ),
	{ ok, AfzenderMail } = application:get_env( ppnl_leden, system_mail ),
	{ ok, Afzendernaam } = application:get_env( ppnl_leden, system_mail_r ),
	{ ok, File } = sgte:compile_file("priv/templates/login.mail"),
	Message = sgte:render_str( File,  [ { voornaam, Voornaam}, { secret, Secret } ] ),
	Encoded = mimemail:encode( { <<"text">>, <<"plain">>,                       
                                     [ { <<"Subject">>, <<"Inloggen Piratenpartij">> },            
                                       { <<"From">>, smtp_util:combine_rfc822_addresses([ { Afzendernaam, AfzenderMail } ]) },                          
                                       { <<"To">>, smtp_util:combine_rfc822_addresses([ {Achternaam, Email} ]) } ],                          
                                     #{},                                           
                                     unicode:characters_to_binary( Message ) } ),
	io:format("~p\n ~p\n", [ Encoded, MailConfig ] ),
	Mr = gen_smtp_client:send_blocking(  { AfzenderMail,
	                                         [ Email ],
	                                         Encoded },                              
					     MailConfig 
                            ),
	io:format("resultaat: ~p\n", [Mr]).


% Included in template
redirect() ->
	case wf:user() of
		undefined -> wf:redirect_to_login("login");
		_	-> 
			    #container_12 { body=[
			        #grid_8 { alpha=true, prefix=2, suffix=2, omega=true, body= [
					"Gebruiker ", 
					wf:session(voornaam), " ",
					wf:session(tussenvoegsel), " ",
					wf:session(achternaam), " ",
					" - ",
					#link{ text = "uitloggen", url = "logout" }
				] }
			    ]}
	end.
