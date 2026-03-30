-module(ppnl_nitrogen).
-export([field/2, set_field/2, field/3, get_field/1]).

-include_lib("nitrogen_core/include/wf.hrl").


field(DisplayName, Field, AccesType) ->
    #tablerow{
      cells = [#tablecell{
                 text = io_lib:format("~s ", [DisplayName]),
                 align = "right"
                },
               #tablecell{text = ":"},
               #tablecell{body = [elementFor(Field, AccesType)]}]
     }.


field(Field = {Name, _}, AccesType) ->
    field(Name, Field, AccesType).


elementFor(Field = {Name, bool}, rw) ->
    #dropdown{
      id = Name,
      value = "null",
      options = [#option{text = "", value = null},
                 #option{text = "Ja", value = true},
                 #option{text = "Nee", value = false}],
      actions = element_actions(Field)
     };
elementFor({Name, {id, Table, TextField}}, rw) ->
    #dropdown{
      id = Name,
      value = "null",
      actions = element_actions({Name, int4}),
      options = [#option{text = "", value = null} | getOptions(Table, TextField)]
     };
elementFor(Field = {Name, date}, rw) ->
    #datepicker_textbox{
      id = Name,
      actions = element_actions(Field),
      options = [{dateFormat, "dd/mm/yy"}]
     };
elementFor({Name, int2}, rw) ->
    elementFor({Name, int4}, rw);
elementFor(Field = {Name, int4}, rw) ->
    wf:wire(submit,
            Name,
            #validate{
              validators = [#is_integer{text = "Moet een geheel getal zijn", allow_blank = true}]
             }),
    #textbox{
      id = Name,
      actions = element_actions(Field)
     };
elementFor(Field = {Name, email}, rw) ->
    wf:wire(submit,
            Name,
            #validate{
              validators = [#is_email{text = "Moet een email-adres zijn"}]
             }),
    #textbox{
      id = Name,
      actions = element_actions(Field)
     };
elementFor(Field = {Name, _}, rw) ->
    #textbox{
      actions = element_actions(Field),
      id = Name
     };
elementFor({Name, _}, ro) ->
    #label{
      id = Name
     }.


element_actions(Field) ->
    [#event{type = change, postback = {changed, Field}, actions = [#add_class{class = italic}]}].


getOptions(Table, TextField) ->
    {_Headers, DbList} = ppdb:query(io_lib:format("select id, ~s from ~s order by ~s", [TextField, Table, TextField]), []),
    lists:map(fun({Id, Text}) -> #option{text = Text, value = Id} end, DbList).


set_field({Name, _}, null) ->
    wf:set(Name, "");
set_field({Name, date}, {Y, M, D}) ->
    wf:set(Name, io_lib:format("~B/~B/~B", [D, M, Y]));
set_field({Name, bool}, Data) ->
    wf:set(Name, Data);
set_field({Name, _}, Data) ->
    wf:set(Name, Data).


get_field({Name, date}) ->
    case io_lib:fread("~d/~d/~d", wf:q(Name)) of
        {ok, [D, M, Y], []} -> {Y, M, D};
        X -> X
    end;
get_field({Name, int4}) ->
    case io_lib:fread("~d", wf:q(Name)) of
        {ok, [N], []} -> N;
        X -> X
    end;
get_field({Name, int2}) ->
    get_field({Name, int4});
get_field({Name, bool}) ->
    list_to_atom(wf:q(Name));
get_field({Name, _}) ->
    wf:q(Name).
