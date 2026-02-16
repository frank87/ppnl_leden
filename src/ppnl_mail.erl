-module(ppnl_mail).
-export([ fullname/3 ]).

fullname( A, null, B ) -> io_lib:format( "~s ~s", [ A, B ] );
fullname( A, B, C ) -> io_lib:format( "~s ~s ~s", [ A, B, C ] ).
