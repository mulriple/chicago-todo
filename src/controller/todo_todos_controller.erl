-module(todo_todos_controller, [Req, SessionId]).
-compile(export_all).
-default_action(index).

index('GET', []) ->
  Todos = boss_db:find(todo, []),
  {json, Todos};

index('POST', []) ->
  % creation of new todo
  Json = mochijson2:decode(general_lib:to_list(Req:request_body())),
  Todo = boss_record:new(todo, [
    {id, id},
    {title, json:destructure("Obj.title", Json)},
    {order, json:destructure("Obj.order", Json)},
    {done, json:destructure("Obj.done", Json)}
    ]),
  case Todo:save() of
    {ok, SavedTodo} ->
      {json, SavedTodo};
    {error, Error} ->
      {json, [{error, Error}]}
  end;

index('PUT', [Id]) ->
  Json = mochijson2:decode(general_lib:to_list(Req:request_body())),
  Todo = boss_db:find(Id),
  UpdatedTodo = Todo:set([
    {title, json:destructure("Obj.title", Json)},
    {order, json:destructure("Obj.order", Json)},
    {done, json:destructure("Obj.done", Json)}
    ]),
  case UpdatedTodo:save() of
    {ok, SavedTodo} ->
      {json, SavedTodo};
    {error, Error} ->
      {json, [{error, Error}]}
  end;

index('DELETE', [Id]) ->
  Todo = boss_db:find(Id),
  boss_db:delete(Id),
  {json, Todo}.