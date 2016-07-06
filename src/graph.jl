"""
`DispatchGraph` wraps a directed graph from `LightGraphs` and a bidirectional
dictionary mapping between `DispatchNode` instances and vertex numbers in the
graph.
"""
type DispatchGraph
    graph::DiGraph  # from LightGraphs
    nodes::NodeSet
end

DispatchGraph() = DispatchGraph(DiGraph(), NodeSet())

Base.length(g::DispatchGraph) = length(g.nodes)

function Base.push!(g::DispatchGraph, node::DispatchNode)
    node_number = push!(g.nodes, node)
    add_vertices!(g.graph, clamp(node_number - nv(g.graph), 0, node_number))
    return g
end

function LightGraphs.add_edge!(g::DispatchGraph, parent::DispatchNode, child::DispatchNode)
    add_edge!(g.graph, g.nodes[parent], g.nodes[child])
end

nodes(g::DispatchGraph) = nodes(g.nodes)

function LightGraphs.in_neighbors(g::DispatchGraph, node::DispatchNode)
    imap(n->g.nodes[n], in_neighbors(g.graph, g.nodes[node]))
end

function LightGraphs.out_neighbors(g::DispatchGraph, node::DispatchNode)
    imap(n->g.nodes[n], out_neighbors(g.graph, g.nodes[node]))
end

function Base.:(==)(g1::DispatchGraph, g2::DispatchGraph)
    if length(g1) != length(g2)
        return false
    end

    nodes1 = Set{DispatchNode}(nodes(g1))

    if nodes1 != Set{DispatchNode}(nodes(g2))
        return false
    end

    for node in nodes1
        if Set{DispatchNode}(out_neighbors(g1, node)) !=
                Set{DispatchNode}(out_neighbors(g2, node))
            return false
        end
    end

    return true
end
