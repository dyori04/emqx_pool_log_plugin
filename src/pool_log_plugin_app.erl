-module(pool_log_plugin_app).

-behaviour(application).

-emqx_plugin(?MODULE).

-export([ start/2
        , stop/1
        ]).

start(_StartType, _StartArgs) ->
    {ok, Sup} = pool_log_plugin_sup:start_link(),
    pool_log_plugin:load(application:get_all_env()),

    emqx_ctl:register_command(pool_log_plugin, {pool_log_plugin_cli, cmd}),
    {ok, Sup}.

stop(_State) ->
    emqx_ctl:unregister_command(pool_log_plugin),
    pool_log_plugin:unload().

