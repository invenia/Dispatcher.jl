"""
    @op func(...)

The `@op` macro makes it more convenient to construct [`Op`](@ref) nodes. It translates a
function call into an `Op` call, effectively deferring the computation.

```julia
a = @op sort(1:10; rev=true)
```
is equivalent to
```julia
a = Op(sort, 1:10; rev=true)
```
"""
macro op(ex)
    # parameters expressions only appear when kwargs are separated with a semicolon
    # parameters expressions must be the second arg in a :call Expr because reasons
    param_idx = findfirst(ex.args) do arg_ex
        isa(arg_ex, Expr) && arg_ex.head === :parameters
    end

    if param_idx > 0
        ex.args[1:param_idx] = circshift(ex.args[1:param_idx], 1)
    end

    ex.head = :call
    ex.args = [
        Dispatcher.Op,
        ex.args...
    ]

    esc(ex)
end
