-module(mixr_store).
-behaviour(gen_server).
-define(SERVER, ?MODULE).

-export([
         start_link/0
         , exist/1
         , exist/2
         , save/5
         , find/1
         , delete/1
         , append/2
         , prepend/2
        ]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-record(storage, {
          module,
          state}).

start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [mixr_config:store()], []).

exist(Key) ->
  exist(Key, 0).

exist(Key, CAS) ->
  gen_server:call(?SERVER, {exist, [Key, CAS]}).

save(Key, Value, CAS, Expiration, Flags) ->
  gen_server:call(?SERVER, {save, [Key, Value, CAS, Expiration, Flags]}).

find(Key) ->
  gen_server:call(?SERVER, {find, [Key]}).

delete(Key) ->
  gen_server:call(?SERVER, {delete, [Key]}).

append(Key, Value) ->
  gen_server:call(?SERVER, {append, [Key, Value]}).

prepend(Key, Value) ->
  gen_server:call(?SERVER, {prepend, [Key, Value]}).

%% -- Gen server 

init([StoreModule]) ->
  {ok, #storage{module = StoreModule, state = StoreModule:init()}}.

handle_call({Action, Args}, _From, #storage{module = StoreModule, state = StorageState} = State) ->
  {Replay, NewState} = erlang:apply(StoreModule, Action, [StorageState|Args]),
  {reply, Replay, State#storage{state = NewState}}.

handle_cast(_Msg, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

