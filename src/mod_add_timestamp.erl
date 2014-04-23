-module(mod_add_timestamp).
-author('willbrazil.usa@gmail.com').
-version('1.0').

%% Every ejabberd module must implement gen_mod.
%% gen_mod requires two functions: start and stop.
-behavior(gen_mod).

-include("ejabberd.hrl").
-include("logger.hrl").
-include("jlib.hrl").

-export([start/2, stop/1]).
-export([add_time_property/1]).


start(Host, Opts) ->
    
	?INFO_MSG("START MOD_ADD_TIMESTAMP. ~p ~p",[Host, Opts]),

	ejabberd_hooks:add(filter_packet, global, ?MODULE, add_time_property, 10).

stop(Host) ->

	?INFO_MSG("STOP MOD_ADD_TIMESTAMP.", []),

	ejabberd_hooks:delete(filter_packet, global, ?MODULE, add_time_property, 10).


%%add_time_property({From, To, {xmlelement, PacketType, Attrs, SubEl}} = Packet) ->
add_time_property({From, To, #xmlel{name = Name, attrs = Attrs, children = SubEl} = Xml} = Packet) ->


%%	?INFO_MSG("\n\n\nPACKET NO EDIT: ~p", [Packet]),

	FullXml = case Name of
		<<"message">> ->
			?INFO_MSG("\n\nPACKET IS:: ~p", [Packet]),

			BodyEl = xml:get_subtag(Xml, <<"body">>),
			ThreadEl = xml:get_subtag(Xml, <<"thread">>),
			#xmlel{name = PName, attrs = PAttrs, children = PList} = xml:get_subtag(Xml, <<"properties">>),

			[Timestamp] = get_timestamp(),

			TSTerm = list_to_binary(Timestamp),
			
			?INFO_MSG("\n Timestamp is: ~p", [list_to_binary(Timestamp)]),

			NewProp = #xmlel{name = PName, attrs = PAttrs, children = lists:append(PList, [#xmlel{name = <<"property">>, attrs = [], children = [#xmlel{ name = <<"name">>, attrs = [], children = [{xmlcdata, <<"time">>}]},  #xmlel{ name = <<"value">>, attrs = [{<<"type">>, <<"string">>}], children = [{xmlcdata, TSTerm}]}]}])},
			

			NewXml = #xmlel{name = Name, attrs = Attrs, children = [BodyEl, ThreadEl, NewProp]},	

			NewXml;			
		_ ->
%%			?INFO_MSG("\nNot message packet: ~p", [Packet]),
			Xml
	end,

	NewPacket = {From, To, FullXml},
NewPacket.




add_time_property2({From, To, {xmlelement, PacketType, Attrs, SubEl}} = Packet) ->
        ?INFO_MSG("add_time_property()", []),
        EditedPacket = case {PacketType} of
                {"message"} ->
                        ?INFO_MSG("Adding time to packet: ~p ", [Packet]),

                        [Body,
                                     Thread,
                                     PropertiesXml|_] = SubEl,

                        {xmlelement,"properties",
                                      Xmlns,
                                      Properties} = PropertiesXml,

                        MyTimestamp = io_lib:format("~p", [get_timestamp()]),

                        NewProperties = lists:append(Properties, [{xmlelement,"property",[],
                                               [{xmlelement,"name",[],
                                                 [{xmlcdata,<<"time">>}]},
                                                {xmlelement,"value",
                                                 [{"type","string"}],
                                                 [{xmlcdata,
                                                  MyTimestamp}]}]}]),

                        ?INFO_MSG("Added time to packet. New properties are: ~p", [NewProperties]),

			

                        NewSubEl = [Body, Thread, {xmlelement, "properties", Xmlns, NewProperties}],
                        NewPacket = {From, To, {xmlelement, PacketType, Attrs, NewSubEl}},
                        NewPacket;
                _ ->
                Packet
        end,
EditedPacket.





get_timestamp()->
{Mega, Secs, _} = now(),
        CurrentTimestamp = io_lib:format("~p", [Mega*1000000 + Secs]),
CurrentTimestamp.