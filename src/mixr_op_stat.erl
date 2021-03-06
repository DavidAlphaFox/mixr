% @hidden
-module(mixr_op_stat).
-compile([{parse_transform, lager_transform}]).
-include("../include/mixr.hrl"). 

-export([action/2]).

action(#request_header{magic = ?REQUEST,
                       opcode = ?OP_STAT,
                       opaque = Opaque}, <<"keys">>) ->
  lager:info("[STAT] keys"),
  {reply, lists:map(fun({Key, Value}) ->
                        lager:info("~p = ~p", [Key, Value]),
                        mixr_operation:build_response(#response_header{
                                          opcode = ?OP_STAT,
                                          opaque = Opaque,
                                          key_length = size(Key),
                                          body_length = size(Key) + size(Value),
                                          extra_length = 0
                                         }, <<>>, bucs:to_binary(Key), bucs:to_binary(Value))
                    end, mixr_store:keys() ++ [{<<>>, <<>>}])};
action(#request_header{magic = ?REQUEST,
                       opcode = ?OP_STAT,
                       opaque = Opaque}, _) ->
  lager:info("[STAT]"),
  IP = case doteki:get_env([mixr, server, ip], ?MIXR_DEFAULT_IP) of
         undefined -> bucinet:ip_to_binary(bucinet:active_ip());
         Other -> bucinet:ip_to_binary(Other)
       end,
  {reply, lists:map(fun({Key, Value}) ->
                        lager:info("~p = ~p", [Key, Value]),
                        mixr_operation:build_response(#response_header{
                                          opcode = ?OP_STAT,
                                          opaque = Opaque,
                                          key_length = size(Key),
                                          body_length = size(Key) + size(Value),
                                          extra_length = 0
                                         }, <<>>, Key, Value)
                    end, [{<<"pid">>, bucs:to_binary(os:getpid())}, 
                          {<<"version">>, os_version()},
                          {<<"time">>, os_time()},
                          {<<"keys">>, bucs:to_binary(mixr_store:count())},
                          {<<"storage">>, bucs:to_binary(mixr_store:module())},
                          {<<"search_policy">>, doteki:get_as_binary([mixr, search_policy], ?MIXR_DEFAULT_SEARCH_POLICY)},
                          {<<"ip">>, IP},
                          {<<"port">>, doteki:get_as_binary([mixr, server, port], ?MIXR_DEFAULT_SERVER_PORT)},
                          {<<"servers">>, mixr_discover:servers_addrs()},
                          {<<>>, <<>>}])}. 

os_version() ->
  {_, OsName} = os:type(),
  case os:version() of
    {A, B, C} -> 
      bucs:to_binary(lists:flatten(io_lib:format("(~s) ~B.~B.~B", [OsName, A, B, C])));
    Other -> 
      bucs:to_binary(lists:flatten(io_lib:format("(~s) ~s", [OsName, Other])))
  end.

os_time() ->
  {Mega,Sec,Micro} = os:timestamp(),
  bucs:to_binary((Mega*1000000+Sec)*1000000+Micro).

