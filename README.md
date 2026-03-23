# CallableModules

[![Stable Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://PatrickHaecker.github.io/CallableModules.jl/stable)
[![Development documentation](https://img.shields.io/badge/docs-dev-blue.svg)](https://PatrickHaecker.github.io/CallableModules.jl/dev)
[![Test workflow status](https://github.com/PatrickHaecker/CallableModules.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/PatrickHaecker/CallableModules.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/PatrickHaecker/CallableModules.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/PatrickHaecker/CallableModules.jl)
[![Docs workflow Status](https://github.com/PatrickHaecker/CallableModules.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/PatrickHaecker/CallableModules.jl/actions/workflows/Docs.yml?query=branch%3Amain)
[![BestieTemplate](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/JuliaBesties/BestieTemplate.jl/main/docs/src/assets/badge.json)](https://github.com/JuliaBesties/BestieTemplate.jl)

Make Julia modules callable so you can write `MyModule(args...)` as if the module were a function.

This is particularly useful for packages that provide a CLI / app entry point: the same command name can be used both on the shell (via a generated binary or script) and interactively in the Julia REPL.

## Background

Julia modules are values of type `Module`, not types themselves, so you cannot directly define `(::MyModule)() = ...`. In [JuliaLang/julia#61256](https://github.com/JuliaLang/julia/issues/61256), Keno Fischer suggested a workaround using `Val`:

```julia
(::Val{MyModule})() = 42
(this::Module)() = Val(this)()
MyModule()  # => 42
```

The generic `(this::Module)(args...; kwargs...) = Val(this)(args...; kwargs...)` fallback is technically type piracy on `Module`. If every package that wants callable modules defines this fallback independently, you get duplicate method definition errors when two such packages are loaded together. CallableModules.jl solves this by defining the fallback exactly once in a shared dependency.

## Installation

```julia
using Pkg
Pkg.add("CallableModules")
```

## Usage

### With `@callable_module` (recommended)

Annotate the function that should be invoked when the module is called:

```julia
module MyApp
using CallableModules

@callable_module function main(args...; kwargs...)
    println("Called with args=$args, kwargs=$kwargs")
end

end
```

```julia-repl
julia> using MyApp

julia> MyApp(1, 2; verbose=true)
Called with args=(1, 2), kwargs=Base.Pairs(:verbose => true)
```

The macro works with any function name, not just `main`:

```julia
@callable_module run(args...; kwargs...) = do_stuff(args...; kwargs...)
```

### Manual definition

If you prefer not to use the macro, define the `Val` dispatch yourself:

```julia
module MyApp
using CallableModules

(::Val{MyApp})(args...; kwargs...) = main(args...; kwargs...)

function main(args...; kwargs...)
    # ...
end

end
```

## Aqua.jl compatibility

Because CallableModules defines a method on `Module` (which it does not own), Aqua's piracy test will flag it. Add `Module` to the piracy exception:

```julia
Aqua.test_all(CallableModules, piracies = (treat_as_own = [Module],))
```

