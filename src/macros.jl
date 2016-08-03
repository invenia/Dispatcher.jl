macro node(ex)
    annotate(ex, :dispatchnode)
end

macro op(ex)
    annotate(ex, :dispatchop, :(Dispatcher.Op))
end

function annotate(ex::Expr, head::Symbol, args...)
    Expr(head, args..., ex)
end

macro dispatch_context(ex::Expr)
    ctx_sym = gensym("ctx")
    new_ex = macroexpand(ex)
    process_nodes!(new_ex, ctx_sym)

    return Expr(
        :block,
        Expr(
            :(=),
            ctx_sym,
            :(DispatchContext()),
        ),
        new_ex,
        ctx_sym,
    )
end

typealias BaseCaseNodes Union{Number, Symbol, MethodError}

function process_nodes!(ex::Expr, ctx_sym::Symbol)
    if ex.head === :dispatchop
        inner_ex_type = ex.args[2].head

        if inner_ex_type === :call
            process_op!(ex, ctx_sym)
        else
            throw(ArgumentError(
                "Expr type $inner_ex_type cannot be made into a $(ex.args[1])"
            ))
        end
    elseif ex.head == :dispatchnode
        process_node!(ex, ctx_sym)
    else
        map!(x->process_nodes!(x, ctx_sym), ex.args)
    end

    return ex
end

process_nodes!(ex::BaseCaseNodes, ctx_sym::Symbol) = ex

function process_op!(ex::Expr, ctx_sym::Symbol)
    dispatch_node_type = ex.args[1]
    fn_call_expr = ex.args[end]

    ex.head = :call
    ex.args = [
        :(add!),
        ctx_sym,
        Expr(
            :call,
            dispatch_node_type,
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
