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
