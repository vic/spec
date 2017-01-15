# Spec <a href="https://travis-ci.org/vic/spec"><img src="https://travis-ci.org/vic/spec.svg"></a>

Spec is an Elixir data validation library inspired after [clojure.spec].

Just like clojure.spec, this library does not implement a type system,
and the data specifications created with it are not useful for checking
at compile time. For that use Elixir builtin [@spec typespecs][typespecs]

Specs cannot be used for pattern matching nor in function head guards, 
as validating with Spec could involve calling some Elixir runtime functions
which are not allowed inside a pattern match. If you are looking 
for a way to create composable patterns take a look at [Expat][expat].
You can for example, conform your data with Spec and then pattern match
on the conformed value using [Expat][expat] to easy extract values from it.

Having said that, you can use Spec to validate that your data has certain
structure, is of a given type or that it satisfies certain predicates.
You can validate your function arguments or return values (it's all done
at *run-time*) look bellow for an example `LovePOEM`.

- [Intro](#purpose)
 - [Purpose](#purpose)
 - [Installation](#installation)
- [Usage](#usage)
 - [Predicates](#predicates)
 - [Conformers](#conformers)
 - [Data structure specifications](#data-structure-specifications)
 - [Alternating specs](#alternating-specs)
 - [Key specs](#key-specs)
 - [Regex repetition operators](#regex-repetition-operators)
 - [Defspec](#define-specs)
 - [Parametrized Specs](#parametrized-specs)
- [Things to do](#things-to-do)

## Purpose

Spec's purpose is to to provide a library for creating composable data
structure specifications. That is, once you create an Spec, you can
match data with it, get human descriptive messages or programatically
detailed errors if something inside of it does
not conforms to the specification, exercise the Spec and obtain some
random data that conforms to Spec that can be used for example in tests.

While Spec is heavily inspired after clojure.spec, it's not the purpose
to exactly match the clojure.spec API. Spec will instead prefer to follow the
Elixir/Erlang idioms and have a more familiar API for alchemists.

## Installation

[Available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `spec` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:spec, "~> 0.1"}]
end
```

## Usage

The rest of this document will detail the Spec API and example usage.
You can also take a look at the several [tests] for more examples.

```elixir
use Spec
```

### Predicates

The most basic way of validating data we have in Elixir are predicates.
Predicates are functions that take data and return either `true` or `false`.

For example `is_number/1` is an Elixir builtin predicate that will return 
`true` when invoked like `is_number(42)`.

Predicates can be used as specs by feeding them to `Spec.conform(spec, data)` along
with some data to check.

```elixir
iex> use Spec
iex> conform(is_number(), 24)
{:ok, 24}
```

*Technically* `conform/2` is an Elixir macro, so notice how we are
giving it `is_number()` with no args, that is because Spec will 
provide the data value as the first argument for any specification.
So, when performing the validation, Spec will do `24 |> is_number()`.

If you've already noticed, the return value of `conform/2` was an ok
tagged tuple, even when `is_number/1` actually returns a boolean. 
(more on this later)

Of course, you can use any predicate of yours to conform data

```elixir
def tuple_sum({a, b}, c) when a + b == c, do: true
def tuple_sum(_, _), do: false

conform(tuple_sum(44), {12, 32})
# => {:ok, {12, 32}}
```

When using predicate functions, Spec will call `{12, 32} |> tuple_sum(44)`
and if the predicate returns true, then data will be tagge with `:ok`, or
with `:error` otherwise.

Actually, Spec adapts boolean predicates and makes them conform to the
erlang idiom of returning tagged tuples like
`{:ok, conformed}` or `{:error, mismatch}`.

So, predicates are a particular case of data conformers in Spec.

### Conformers

Conformers are functions that take data and return `{:ok, conformed}` or 
`{:error, %Spec.Mismatch{}}`.

`Spec.Mismatch` is just a data structure useful for describing what went
wrong and where. `Spec.conform!/2` raises it on error

```elixir
iex(2)> conform!(is_number(), "two")
** (Spec.Mismatch) `"two"` does not satisfy predicate `is_number()`
```

The `conformed` value does not necessarliy needs to equal the input `data`.
As for example, the conformer could choose to transform data and return
a destructured value. 

### Data structure specifications

Let's go back to conforming data with specifications and how we can 
construct them.

Atoms, numbers and binaries match on their equal values

```elixir
iex> conform!(:hello, :hello)
:hello
```

But tuples and friends can specify their inner elements

```elixir
iex> conform!({is_atom(), is_number()}, {:ok, 22})
{:ok, 22}


conform!({is_atom(), is_number()}, [:ok, 22])
** (Spec.Mismatch) `[:ok, 22]` is not a tuple


conform!({is_atom(), is_binary()}, {:ok, 22})
** (Spec.Mismatch) `22` does not satisfy predicate `is_binary()`

at `1` in `{:ok, 22}`
```

So, using the tuple literal syntax, Spec will check that the value
actually is a tuple, has the same size and that every element in it
conforms the corresponding spec.

Similarly for list literals, so the spec `[is_integer()]` is
a list containing a single integer value. 

Naturally, the `_` placeholder matches anything.
And `[{is_atom(), _}]` could describe a keyword list with a single key.

```elixir
iex> conform!([{is_atom(), _}], foo: 22)
[foo: 22]
```

If you are wondering about maps, you can also use the map literal 
syntax. (For checking on map key presence and which combinations
of keys are valid, look bellow for `Spec.keys`)

```elixir
iex> conform!(%{is_binary() => is_number()}, %{"hola" => 22})
%{"hola" => 22}

iex> conform!(%{is_binary() => is_binary(), is_atom() => is_binary()}, 
...>          %{"hola" => "es", :hello => 44})
** (Spec.Mismatch) Inside `%{:hello => 44, "hola" => 22}`, one failure:

(failure 1) at `:hello`

  `44` does not satisfy predicate `is_binary()`
```

### Alternating specs

Inside an spec the `and`/`or` operators are allowed.

For example as previously shown on the data structure section,
you could use the `{_, _}` spec to check for a two-element tuple.
But for learning purposes lets define it by combining two other specs.

We know Elixir's `is_tuple/1` and `tuple_size/1` could be handy here.
Remember that each spec expects it's data as first argument, so by
anding them you can conform like

```elixir
iex> conform(is_tuple() and &(tuple_size(&1) == 2), {1, 2})
{:ok, {1, 2}}

iex> conform!(is_tuple() and &(tuple_size(&1) == 2), {1})
** (Spec.Mismatch) `{1}` does not satisfy predicate `&(tuple_size(&1) == 2)`
```

In a similar fashion you can check against two specification alternatives

```elixir
iex> conform(is_atom() or is_number(), 20)
{:ok, 20}
```

However it would be really handy to know which of the two specs did `20` matched.
For that, let's introduce the tagged specs.

A tag can be cobined with any spec, and if the spec matches, a tagged tuple will
be created for its conformed value, for example. 

*note:* tagged specs use `::` syntax familiar to Elixir [typespecs]

```elixir
iex> conform!(:hello :: is_binary(), "world")
{:hello, "world"}
```

Tagged specs are the first example we have seen of a conformed value that
is different from the original data given to the spec. In this case, the
conformer creates a tagged tuple wraping data with a name.

This way you can set a tag on any spec alternation:

```elixir
iex> a = :foo
iex> b = :bar
iex> conform((a :: is_atom()) or (b :: is_number()), 20)
{:ok, {:bar, 20}}
```

And using tags inside a list spec creates handy keywords

```elixir
iex> conform!([:a :: is_atom(), :b :: is_number()], [:michael, 23])
[a: :michael, b: 23]
```

Finally, in Spec you can use the Elixir pipe to feed the conformed
value into any function. The piped function will be called *only* if
the data has been verified to conform with the preceding specification.

Try not to abuse this, it's better to create a function and have at most
a single pipe. The purpose of piped specs is so that you can create
functions that work on already defined predicates and return possibly 
different conformed values.


```elixir
# the conformed value from is_tuple is feed to elem(1) then get(:subject)
iex> conform(is_tuple() |> elem(1) |> Map.get(:subject), {:error, %{subject: 12}})
iex> {:ok, 12}
```

The following example from the test suite, shows how pipes could
normalize indifferent keys on a map

```elixir
def right(_left, right), do: right
def indif(a, b), do: String.downcase(to_string(a)) == String.downcase(to_string(b))

data = %{"a" => 1, :B => 2, :c => 3}
conform(%{
  indif("A") |> right(:foo) => is_number(),
  indif(:b)  |> right(:bar) => is_number()
}, data)
# => {:ok, %{foo: 1, bar: 2}}
```

### Key specs

Key specs let you state which keys are mandatory with possible key combinations
and works not only on Maps, but on also on Keywords.

Key specs are special, as they can be only match on atoms, binaries, number and
their combinations by being `or`ed, `and`ed.

For example matching a Map for a required and optional keyword

```elixir
iex> data = %{a: 1, b: 2, c: 3}
iex> conform(keys(required: [:a], optional: [:c]), data)
{:ok, %{a: 1, c: 3}}
```

Note the conformed data does not include `:b` as it was neither supplied in the
`required:` nor the `optional:` combinations of keys.

Similarly, and just like in maps, you can match on a Keyword keys

```elixir
iex> data = [a: 1, c: 0, b: 2, c: 3]
iex> conform(keys(required: [:d or :c]), data)
{:ok, [c: 0, c: 3]}
```

The keys conformer will fail if a required key combination is missing.

```elixir
iex> data = %{a: 1, c: 3}
iex> conform!(keys(required: [:d or (:a and :b)]), data)
** (Spec.Mismatch) `%{a: 1, c: 3}` does not have any of keys `[:d, :b]`
```

### Regex Repetition operators

The `cat` and `alt` specs are defined in terms of previously seen
tagged specs and previous list specs but they are included 
just for convenience.

`cat` matches a list of values, but the nicity of it is it takes
a keyword list, saving some keystrokes so you dont have to type `::` 
for each element spec.

```elixir
iex> data = [3, "firulais"]
iex> conform!(cat(age: is_integer(), name: is_binary()), data)
[age: 3, name: "firulais"]
```

Similarly `alt` is sugar for tagged `or` specs.

```elixir
iex> data = "HellBoy"
iex> conform!(alt(age: is_integer(), name: ~r/hell/i), data)
[name: "HellBoy"]
```

Finally, Spec provides the following repetition operators which 
take a another spec as argument and will check that all elements
inside the collection conform to the same spec. 
These combinators work on tuples, or any other enumerable in Elixir,
including lazy Streams.

`zero_or_one`, `one_or_more`, and `many`. 

Of these `many` is the more interesting as the former two are
defined in terms of it.

```elixir
iex> data = ["hola", 1, "mundo", 2] |> Stream.cycle

# fails as soon as the first value from data does not conform
iex> conform!(one_or_more(is_binary()), data)
** (Spec.Mismatch) `1` does not satisfy predicate `is_binary()`
```

`many` can take `min:` (defaults to `0`) and `max:` (defaults to `nil`) options.

And the three of them can take a `fail_fast: false` option if you
need to check exhaustively on all elements, note that it's true for
default as Spec prefers to fail fast on potentially large streams.

```elixir
iex> conform!(many(is_function(), fail_fast: false), [1, 2])
** (Spec.Mismatch) `[1, 2]` items do not conform

(failure 1)

  `1` does not satisfy predicate `is_function()`

(failure 2)

  `2` does not satisfy predicate `is_function()`
```

`many` can also take an `as_stream: true` option, when enabled
it will conform to a new stream which in turn produces the result
of conforming every item lazily.

```elixir
{:ok, stream} = conform(many(is_number(), as_stream: true), 0..2)
[{:ok, 0}, {:ok, 1}, {:ok, 2}] = Enum.to_list(stream)
```

### Define Specs

You can also define specs on a module, giving them a name
and having a easy way to be called and composed.

```elixir
# Remember, POEM stands for Plain Old Elixir Module
defmodule LovePOEM do 
  use Spec
  
  defspec lovers, do: {is_binary(), is_binary()}
  
  def send_love({from, to}) do
    lovers!({foo, to}) # same as Spec.conform!(lovers(), {from, to})
  end
end
```

The first advantage of using `defspec` is that you give specs a name,
and the second is, you can use these generated functions: 

```elixir
# The generated function takes its data as first argument
# so it's fully pipeable (and reusable in other specs)
lovers(data) # => {:ok, ...} 

# There's a predicate version of it that returns a boolean
lovers?(data) # => true

# And the bang version that returns the conformed data or raises on error
lovers!({"elixir", "erlang"}) # => {"elixir", "erlang"}
lovers!({22, 33}) # raises *Spec.Mismatch*
```

For private specs you can use `defspecp`, but it will only generate
the `lovers?` and `lovers!` private functions if you give to
`defspecp` an option like: `include: [:pred, :bang]`


### Parametrized Specs

As we have already seen, specs are just functions, they take the data to
validate as first argument, but nothing restrains them from expecting
more arguments.

For example, you could define an spec to conform maps like:

```elixir
defmodule MapSpec do
  use Spec

  defspec map_of(key_spec, val_spec, options \\ []), 
  do: is_map() and many({key_spec, val_spec}, options)
  
end


# validate that foo is a map of atoms to numbers with size between 2 and three
foo = %{a: 1, b: 2, c: 3}
foo |> MapSpec.map_of!(&is_atom/1, &is_number/1, min: 2, max: 3)
```

Notice that this time we are using `MapSpec.map_of!/4` which takes the data to
validate as first argument, once you define your specs, you can use them
directly to conform data.

## Things to do

Yay, thanks for reading till this point, hope you have found
Spec interesting, if you want to give back some love, it can come in
may forms. Feedback and code are always appreciated, feel free to
open a new issue if you come up with something.

Here's a short list you can help Spec to be more awesome, Thank you :heart:!

- [x] Have lots of fun
- [ ] Have *more* fun
- [ ] API Docs
- [ ] Improve readme, talk about all other Spec functions like valid? and friends.
- [ ] Talk about unforming data (reverse of conforming)
- [ ] Add more [tests]
- [ ] Implement `gen` and `exercise`.
      Search on hex.pm for current packages that generate data and we can use
- [ ] Use credo
- [ ] Add typespecs :P


[clojure.spec]: https://clojure.org/guides/spec
[typespecs]: https://hexdocs.pm/elixir/typespecs.html
[expat]: https://github.com/vic/expat
[tests]: https://github.com/vic/spec/tree/master/test
