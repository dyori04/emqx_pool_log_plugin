-module(pool_log_plugin).

-include_lib("emqx/include/emqx.hrl").
-include_lib("emqx/include/emqx_hooks.hrl").
-include_lib("emqx/include/emqx_mqtt.hrl").
-include_lib("emqx/include/types.hrl").
%% for logging
-include_lib("emqx/include/logger.hrl").

-export([load/1, unload/0, on_message_publish/2, on_message_delivered/3]).

load(_Env) ->
   emqx_hooks:add('message.publish', {?MODULE, on_message_publish, [_Env]},?HP_HIGHEST),
   emqx_hooks:add('message.delivered', {?MODULE, on_message_delivered, [_Env]}, ?HP_AUTO_SUB).
		    

on_message_publish(Message, _Env) ->
	    Timestamp = erlang:system_time(millisecond),
	        io:format("Message received at ~p: ~p~n", [Timestamp, Message]),
		?SLOG(notice, #{type => "published",
			       timestamp => Timestamp
			       %%topic => emqx_message:topic(Message)
			       }),
	    {ok, Message}.

on_message_delivered(ClientInfo, Message, _Env) ->
	    Timestamp = erlang:system_time(millisecond),
	    #{clientid := ClientId} = ClientInfo,
	    [ClientType | _ ] = string:split(ClientId, "_"),
	    case ClientType of 
	        <<"RTT">> ->
			PayloadBin = emqx_message:payload(Message),
			PayloadJson = jiffy:decode(PayloadBin, [return_maps]),
			RTT = maps:get(<<"RTT">>, PayloadJson),
			Seq = maps:get(<<"Seq">>, PayloadJson),
			?SLOG(notice, #{type => "RTT",
					clientType => ClientType,
					rtt => RTT,
					seq => Seq
					}),
			    {ok, Message};
		_ -> 
	            io:format("Message delivered at ~p: ~p~n", [Timestamp, Message]),
		    ?SLOG(notice, #{type => "delivered",
				    clientType => ClientType,
		        	   timestamp => Timestamp
			           %%topic => emqx_message:topic(Message)
			           }),
		        {ok, Message}
		end.

unload() ->
    unhook('message.publish',     {?MODULE, on_message_publish}),
    unhook('message.delivered',   {?MODULE, on_message_delivered}).

hook(HookPoint, MFA) ->
	    %% use highest hook priority so this module's callbacks
	    %% are evaluated before the default hooks in EMQX
	    emqx_hooks:add(HookPoint, MFA, _Property = ?HP_HIGHEST).
	    
unhook(HookPoint, MFA) ->
    emqx_hooks:del(HookPoint, MFA).

