type DispatchContext
    graph
    nodes::NodeSet
    meta::Dict{Any, Any}
end

function DispatchContext(; kwargs...)
    ctx = DispatchContext(DiGraph(), NodeSet(), Dict{Any, Any}())
    for (k, v) in kwargs
        ctx.meta[k] = v
    end

    return ctx
end

Base.getindex(ctx::DispatchContext, key) = ctx.meta[key]

function Base.push!(ctx::DispatchContext, node::DispatchNode)
    node_number = push!(ctx.nodes, node)

    for _ in (nv(ctx.graph) + 1):(node_number)
        add_vertex!(ctx.graph)
    end

    deps = dependencies(node)
    dep_numbers = findin(deps, ctx.nodes)

    for dep_number in dep_numbers
        add_edge!(ctx.graph, dep_number, node_number)
    end

    return node
end
