"""
    @node Node(...)

The `@node` macro makes it more convenient to add nodes to the computation
graph while in a `@dispatch_context` block.

```julia
a = @node DataNode([1, 3, 5])
```
is equivalent to
```julia
a = add!(ctx, DataNode([1, 3, 5]))
```
where `ctx` is a variable created by the surrounding `@dispatch_context`.
"""
macro node(ex)
    annotate(ex, :dispatchnode)
end

"""
    @op func(...)

The `@op` macro makes it more convenient to add `Op` nodes to the computation
graph while in a `@dispatch_context` block. It translates a function call into
an `Op` call, effectively deferring the computation.

```julia
a = @op sort(1:10; rev=true)
```
is equivalent to
```julia
a = add!(ctx, Op(sort, 1:10; rev=true))
```
where `ctx` is a variable created by the surrounding `@dispatch_context`.
"""
macro op(ex)
    annotate(ex, :dispatchop)
end

"""
    @include component_function(...)

The `@include` macro makes it more convenient to splice component subgraphs into the
computation graph while in a `@dispatch_context` block.

```julia
a = @include sort(1:10; rev=true)
```
is equivalent to
```julia
a = sort(ctx, 1:10; rev=true)
```
where `ctx` is a variable created by the surrounding `@dispatch_context`.

Usually, these component functions are created using a `@component` annotation.
"""
macro include(ex)
    annotate(ex, :dispatchinclude)
end

function annotate(ex::Expr, head::Symbol, args...)
    esc(Expr(head, args..., ex))
end

"""
    @component function ... end

Translate a function definition so that its first argument is a DispatchContext and cause
all `@op` and `@node` macros within the function to use said DispatchContext.
"""
macro component(func::Expr)
    if func.head != :function
        error("@component only works on functions, not $(func.head)")
    end

    ctx_sym = gensym("ctx")
    insert!(func.args[1].args, 2, Expr(:(::), ctx_sym, :(Dispatcher.DispatchContext)))
    func.args[1].args[1] = esc(func.args[1].args[1])

    new_func = macroexpand(func)

    process_nodes!(new_func.args[2], ctx_sym)

    return new_func
end

"""
    @dispatch_context begin ... end

Anonymously create and return a DispatchContext. Accepts a block argument and
causes all `@op` and `@node` macros within that block to use said
DispatchContext.

See examples in the manual.
"""
macro dispatch_context(ex::Expr)
    ctx_sym = gensym("ctx")
    new_ex = macroexpand(ex)
    process_nodes!(new_ex, ctx_sym)

    return esc(Expr(
        :block,
        Expr(
            :(=),
            ctx_sym,
            :(DispatchContext()),
        ),
        new_ex,
        ctx_sym,
    ))
end

typealias BaseCaseNodes Union{Number, Symbol, MethodError}

function process_nodes!(ex::Expr, ctx_sym::Symbol)
    if ex.head === :dispatchop
        inner_ex_type = ex.args[end].head

        if inner_ex_type === :call
            process_op!(ex, ctx_sym)
        else
            throw(ArgumentError(
                "Expr type $inner_ex_type cannot be made into a $(ex.args[1])"
            ))
        end
    elseif ex.head === :dispatchnode
        process_node!(ex, ctx_sym)
    elseif ex.head === :dispatchinclude
        process_include!(ex, ctx_sym)
    else
        map!(x->process_nodes!(x, ctx_sym), ex.args)
    end

    return ex
end

process_nodes!(ex::BaseCaseNodes, ctx_sym::Symbol) = ex

function process_op!(ex::Expr, ctx_sym::Symbol)
    fn_call_expr = ex.args[end]

    ex.head = :call
    ex.args = [
        :(add!),
        ctx_sym,
        Expr(
            :call,
            Dispatcher.Op,
            fn_call_expr.args...
        )
    ]
end

function process_node!(ex::Expr, ctx_sym::Symbol)
    ex.args = [
        :(add!),
        ctx_sym,
        ex.args[end],
    ]
    ex.head = :call
end

function process_include!(ex::Expr, ctx_sym::Symbol)
    fn_call_expr = ex.args[end]

    insert!(fn_call_expr.args, 2, ctx_sym)

    ex.head = fn_call_expr.head
    ex.args = fn_call_expr.args

    ex
end
