defmodule Eager do
  # {:atm, :a}
  @type atm :: {:atm, atom}

  #{:var, :atom}
  @type variable :: {:var, atom}

  # _
  @type ignore :: :ignore

  # [ head | tail ] = {:cons, head, tail}.
  @type cons(t) :: {:cons, t, t}

  # case expression
  @type case :: {:case, expr, [clause]}
  @type clause :: {:clause, pattern, seq}

  # lambda
  @type lambda :: {:lambda, [atom], [atom], seq}
  @type closure :: {:closure, [atom], seq, env}
  @type apply :: {:apply, expr, [expr]}

  #expression
  @type expr :: atm | variable | cons(expr) | case | lambda | apply

  # Pattern matching
  @type pattern :: atm | variable | ignore | cons(pattern)

  # Sequences
  @type match :: {:match, pattern, expr}
  @type seq :: [expr] | [match | seq]


  @type str :: atom | [str] | closure

  # An environment is a key-value of variableiable to structure.
  @type env :: [{atom, str}]


  # eval seq with empty enivorment
  def eval(seq), do: eval_seq(seq, Env.new())

  # * EVALUATION

  # evaluate atom
  def eval_expr({:atm, id}, _) do {:ok, id} end

  # evaluate variable
  def eval_expr({:var, id}, env) do
    case Env.lookup(id, env) do
      nil -> :error
    {_, str} ->
      {:ok, str}
    end
  end

  # evaluate cons
  def eval_expr({:cons, head, tail}, env) do
    case eval_expr(head, env) do
    :error -> :error
        {:ok, hs} ->
          case eval_expr(tail, env) do
            :error -> :error
              {:ok, ts} ->
                {:ok, {hs, ts}}
          end
      end
  end

  # evaluate case expression
  def eval_expr({:case, expr, cls}, env) do
    case eval_expr(expr, env) do
      :error ->
        :error
      {:ok, t} ->
        eval_cls(cls, t, env)
    end
  end

  # handles case clauases when we have gone through them all we don't we couuld match with a cluase
  # we give then :error ie bottoms because of no evaluation
  def eval_cls([], _, _) do
    :error
  end

  #evalauate a cluase
def eval_cls([{:clause, ptr, seq} | cls], t, env) do
  newEnv = eval_scope(ptr, env)
  case eval_match(ptr, t, newEnv) do
    :fail ->
      # we failed matching with current clause no we check with other clauses
      eval_cls(cls, t, env)
    {:ok, env} ->
      eval_seq(seq, env)
  end
end

# evaluate lambda expression
def eval_expr({:lambda, par, free, seq}, env) do
  case Env.closure(free, env) do
    :error ->
      :error
    enviroment ->
      {:ok, {:closure, par, seq, enviroment}}
  end
end


def eval_expr({:apply, expr, args}, env) do
  # we evaluate expr we make need to make sure that it's a closyre
  case eval_expr(expr, env) do
    :error ->
      :error
    {:ok, {:closure, par, seq, enviroment}} ->
      # we evaluate the argument that was provided in apply
      case eval_args(args, enviroment) do
        :error ->
          :error
        {:ok, strs} ->
          #IO.inspect(strs)
          # here take parms and the evaluated args and put them into our current enviroment
          env = Env.args(par, strs, enviroment)

          # we evalutate sequence with given new eviroment
          eval_seq(seq, env)
      end
  end
end

# * evaluate args for apply

# here we evalute args on a given enviroment
def eval_args(args, env) do
  eval_args(args, env, [])
end

defp eval_args([], _, acc) do {:ok, Enum.reverse(acc)}  end

defp eval_args([arg | args], env, acc) do
  case eval_expr(arg, env) do
    :error ->
      :error
    {:ok, str} ->
      eval_args(args, env, [str | acc])
  end
end

# evaluate functions
def eval_expr({:fun, id}, env)  do
  {par, seq} = apply(Prgm, id, [])
  {:ok,  {:closure, par, [], seq}}
end

  """

  Example
  Success All
  eval expr({:atm, :a}, []) : returns {:ok, :a}
  eval expr({:var, :x}, [{:x, :a}]) : returns {:ok, :a}
  eval expr({:var, :x}, []) : returns :error
  eval expr({:cons, {:var, :x}, {:atm, :b}}, [{:x, :a}]) : re- turns {:ok, {:a, :b}}

  """

  # * PATTERN MATCHNING

  # matching with ignore
  def eval_match(:ignore, _, env) do
    {:ok, env}
  end

  # matching with an atom
  def eval_match({:atm, id}, id, env) do
    {:ok, env}
  end

  # matching with a variable
  def eval_match({:var, id}, str, env) do
    case Env.lookup(id, env) do
      nil ->
        # here variables was not in our enviroment we give back our new extended enviroment
        {:ok, Env.add(id, str, env)}
      {^id, ^str} ->
        # if it was the same variable with same structure we tried to pattern match with then we give back
        # our enviroment at it is
        {:ok, env}
      {_, _} ->
        :fail
    end
   end

   # matching with a cons tuple
  def eval_match({:cons, hp, tp}, {st1, st2}, env) do
    case eval_match(hp, st1, env) do
      :fail ->
        :fail
      {:ok, env} ->
        eval_match(tp, st2, env)
    end
  end

  # everything else will fail
  def eval_match(_, _, _) do
    :fail
  end


  """
  Examples

  eval_match({:atm, :a}, :a, []) : returns {:ok, []}
  eval_match({:var, :x}, :a, []) : returns {:ok, [{:x, :a}]}
  eval_match({:var, :x}, :a, [{:x, :a}]) : returns {:ok, [{:x, :a}]}
  eval_match({:var, :x}, :a, [{:x, :b}]) : returns :fail
  eval_match({:cons, {:var, :x}, {:var, :x}}, {:a, :b}, []) : returns :fail
  """


  # * EVALUATE SEQUENCES

  def extract_vars(pattern), do: extract_vars(pattern, [])

  def extract_vars({:var, id}, acc) do
    [id | acc]
  end

  def extract_vars({:cons, head, tail}, acc) do
    extract_vars(tail, extract_vars(head, acc))
  end

    #def extract_vars({:atm, _}, acc), do: acc
  #def extract_vars(:ignore, acc), do: acc

  # for everything is doesn't have any variabels we have handeled them above we just return acc
  def extract_vars(_, acc), do: acc

  def eval_scope(pattern, env) do
   Env.remove(extract_vars(pattern), env)
  end

  def eval_seq([exp], env) do
    eval_expr(exp, env)
  end

  def eval_seq([{:match, pattern, expr} | seq], env) do
    case eval_expr(expr, env) do
        :error ->
          :error
        {:ok, t} ->
          env = eval_scope(t, env)
          case eval_match(pattern, t, env) do
            :fail ->
             :error
            {:ok, env} ->
              eval_seq(seq, env)
          end
      end
  end




end
