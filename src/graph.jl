"""
`DispatchGraph` wraps a directed graph from `LightGraphs` and a bidirectional
dictionary mapping between `DispatchNode` instances and vertex numbers in the
graph.
"""
type DispatchGraph
    graph::DiGraph  # from LightGraphs
    nodes::NodeSet
end

"""
    DispatchGraph() -> DispatchGraph

Create an empty `DispatchGraph`.
"""
DispatchGraph() = DispatchGraph(DiGraph(), NodeSet())

"""
    length(graph::DispatchGraph) -> Integer

Return the number of nodes in the graph.
"""
Base.length(graph::DispatchGraph) = length(graph.nodes)

"""
    push!(graph::DispatchGraph, node::DispatchNode) -> DispatchGraph

Add a node to the graph and return the graph.
"""
function Base.push!(graph::DispatchGraph, node::DispatchNode)
    push!(graph.nodes, node)
    node_number = graph.nodes[node]
    add_vertices!(graph.graph, clamp(node_number - nv(graph.graph), 0, node_number))
    return graph
end

"""
    add_edge!(graph::DispatchGraph, parent::DispatchNode, child::DispatchNode) -> Bool

Add an edge to the graph from `parent` to `child`.
Return whether the operation was successful.
"""
function LightGraphs.add_edge!(
    graph::DispatchGraph,
    parent::DispatchNode,
    child::DispatchNode,
)
    add_edge!(graph.graph, graph.nodes[parent], graph.nodes[child])
end

"""
    nodes(graph::DispatchGraph) ->

Return an iterable of all nodes stored in the `DispatchGraph`.
"""
nodes(graph::DispatchGraph) = nodes(graph.nodes)

"""
    in_neighbors(graph::DispatchGraph, node::DispatchNode) ->

Return an iterable of all nodes in the graph with edges from themselves to `node`.
"""
function LightGraphs.in_neighbors(graph::DispatchGraph, node::DispatchNode)
    imap(n->graph.nodes[n], in_neighbors(graph.graph, graph.nodes[node]))
end

"""
    out_neighbors(graph::DispatchGraph, node::DispatchNode) ->

Return an iterable of all nodes in the graph with edges from `node` to themselves.
"""
function LightGraphs.out_neighbors(graph::DispatchGraph, node::DispatchNode)
    imap(n->graph.nodes[n], out_neighbors(graph.graph, graph.nodes[node]))
end

"""
    leaf_nodes(graph::DispatchGraph) ->

Return an iterable of all nodes in the graph with no outgoing edges.
"""
function leaf_nodes(graph::DispatchGraph)
    imap(n->graph.nodes[n], filter(1:nv(graph.graph)) do node_index
        outdegree(graph.graph, node_index) == 0
    end)
end

# vs is an Int iterable
function LightGraphs.induced_subgraph(graph::DispatchGraph, vs)
    new_graph = DispatchGraph()

    for keep_id in vs
        add_vertex!(new_graph.graph)
        push!(new_graph.nodes, graph.nodes[keep_id])
    end

    for keep_id in vs
        for vc in out_neighbors(graph.graph, keep_id)
            if vc in vs
                add_edge!(
                    new_graph.graph,
                    new_graph.nodes[graph.nodes[keep_id]],
                    new_graph.nodes[graph.nodes[vc]],
                )
            end
        end
    end

    return new_graph
end

"""
    graph1::DispatchGraph == graph2::DispatchGraph

Determine whether two graphs have the same nodes and edges.
This is an expensive operation.
"""
function Base.:(==)(graph1::DispatchGraph, graph2::DispatchGraph)
    if length(graph1) != length(graph2)
        return false
    end

    nodes1 = Set{DispatchNode}(nodes(graph1))

    if nodes1 != Set{DispatchNode}(nodes(graph2))
        return false
    end

    for node in nodes1
        if Set{DispatchNode}(out_neighbors(graph1, node)) !=
                Set{DispatchNode}(out_neighbors(graph2, node))
            return false
        end
    end

    return true
end

"""
    subgraph(graph::DispatchGraph, endpoints, roots) -> DispatchGraph

Return a new `DispatchGraph` containing everything "between" `roots` and `endpoints`
(arrays of `DispatchNode`s), plus everything else necessary to generate `endpoints`.

More precisely, only `endpoints` and the ancestors of `endpoints`, without any
nodes which are ancestors of `endpoints` only through `roots`.
If `endpoints` is empty, return a new `DispatchGraph` containing only `roots`, and nodes
which are decendents from nodes which are not descendants of `roots`.
"""
function subgraph{T<:DispatchNode, S<:DispatchNode}(
    graph::DispatchGraph,
    endpoints::AbstractArray{T},
    roots::AbstractArray{S}=DispatchNode[],
)
    endpoint_ids = Int[graph.nodes[e] for e in endpoints]
    root_ids = Int[graph.nodes[i] for i in roots]

    return subgraph(graph, endpoint_ids, root_ids)
end

function subgraph(
    graph::DispatchGraph,
    endpoints::AbstractArray{Int},
    roots::AbstractArray{Int}=Int[],
)
    to_visit = Stack(Int)

    if isempty(endpoints)
        rootset = Set{Int}(roots)
        discards = Set{Int}()

        for v in roots
            for vp in in_neighbors(graph.graph, v)
                push!(to_visit, vp)
            end
        end

        while length(to_visit) > 0
            v = pop!(to_visit)

            if all((vc in rootset || vc in discards) for vc in out_neighbors(graph.graph, v))
                push!(discards, v)

                for vp in in_neighbors(graph.graph, v)
                    push!(to_visit, vp)
                end
            end
        end

        keeps = setdiff(1:nv(graph.graph), discards)
    else
        keeps = Set{Int}()

        union!(keeps, roots)

        for v in endpoints
            if !(v in keeps)
                push!(to_visit, v)
            end
        end

        while length(to_visit) > 0
            v = pop!(to_visit)

            for vp in in_neighbors(graph.graph, v)
                if !(vp in keeps)
                    push!(to_visit, vp)
                end
            end

            push!(keeps, v)
        end
    end

    return induced_subgraph(graph, keeps)
end
