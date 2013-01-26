-module(general_lib).
-compile(export_all).

to_list(Binary) when is_binary(Binary) ->
  binary_to_list(Binary);
to_list(Val) ->
  Val.