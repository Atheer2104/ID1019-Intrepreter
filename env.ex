defmodule Env do

  @type value :: any()
  @type key :: atom()
  @type env :: [{key, value}]

  def new(), do: []

  # return an environment where the binding of the variable id to the structure str has been added to the environment env.
  def add(id, str, env), do: [{id, str} | env]

  # return either {id, str}, if the variable id was bound, or nil
  def lookup(id, env), do: List.keyfind(env, id, 0)

  # returns an environment where all bindings for variables in the list ids have been removed
  def remove([], env), do: env

  def remove([head | tail], env) do
    newEnv = removeP(head, env)
    remove(tail, newEnv)
  end

  defp removeP(id, env), do: List.delete(env, lookup(id, env))

  # closure it should return a new enviroment where the "free" variables are inclcuded
  def closure(free, env) do
    closureP(free, env, [])
  end

  defp closureP([], _, acc), do: acc

  defp closureP([head | tail], env, acc) do
    case lookup(head, env) do
      :nil ->
        :error
      {key, value} ->
        closureP(tail, env, [{key, value} | acc])
    end
  end

  # args
  def args(pars, strs, env), do:  List.zip([pars, strs]) ++ env

end
