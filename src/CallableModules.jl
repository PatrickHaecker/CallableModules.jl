module CallableModules

export @module_main

struct V end

# This is type piracy, but is fully generic. If every package which wants to have its
# module callable uses this package, no problems with multiple definitions should occur.
(x::Module)(varargs...; kwargs...) = V(x)(varargs...; kwargs...)

"""
    @module_main funcdef

Make the enclosing module callable by forwarding `MyModule(args...; kwargs...)` to the
annotated function.

# Examples

```julia
module MyApp
    using CallableModules
    @module_main function main(args...; kwargs...)
        println("args=\$args, kwargs=\$kwargs")
    end
end

MyApp(1, 2; verbose=true)
# args=(1, 2), kwargs=Base.Pairs(:verbose => true)
```

Both long-form (`function f(...) ... end`) and short-form (`f(x) = ...`) definitions are
supported.
"""
macro module_main(funcdef)
    # Extract the function name from the definition
    funcdef.head ∈ (:function, :(=)) || error("@module_main must be applied to a function definition")
    call = funcdef.args[1]
    fname = call isa Symbol ? call : call.args[1]

    esc(quote
        $funcdef
        (::V{$__module__})(varargs...; kwargs...) = $fname(varargs...; kwargs...)
    end)
end

end
