-module(todo_poll_controller, [Req, SessionId]).
-compile(export_all).

getUpdate('GET', [LastTimeStamp]) ->
  {ok, Timestamp, Objects} = boss_mq:pull("updates", list_to_integer(LastTimeStamp) ),
  {json, [{timestamp, Timestamp}, {objects, Objects}]}.