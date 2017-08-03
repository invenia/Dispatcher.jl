# API

## Nodes

### DispatchNode

```@docs
DispatchNode
get_label{T<:DispatchNode}(::T)
set_label!{T<:DispatchNode}(::T, ::Any)
has_label(::DispatchNode)
dependencies(::DispatchNode)
prepare!(::DispatchNode)
run!(::DispatchNode)
isready(::DispatchNode)
wait(::DispatchNode)
fetch{T<:DispatchNode}(::T)
```

### Op

```@docs
Op
Op(::Function)
@op
get_label(::Op)
set_label!(::Op, ::AbstractString)
has_label(::Op)
dependencies(::Op)
prepare!(::Op)
run!(::Op)
isready(::Op)
wait(::Op)
fetch(::Op)
summary(::Op)
```

### DataNode

```@docs
DataNode
fetch(::DataNode)
```

### IndexNode

```@docs
IndexNode
IndexNode(::DispatchNode, ::Int)
dependencies(::IndexNode)
prepare!(::IndexNode)
run!(::IndexNode)
run!{T<:Union{Op, IndexNode}}(::IndexNode{T})
isready(::IndexNode)
wait(::IndexNode)
fetch(::IndexNode)
summary(::IndexNode)
```

### CollectNode

```@docs
CollectNode
CollectNode(::Vector{DispatchNode})
get_label(::CollectNode)
set_label!(::CollectNode, ::AbstractString)
has_label(::CollectNode)
dependencies(::CollectNode)
prepare!(::CollectNode)
run!(::CollectNode)
isready(::CollectNode)
wait(::CollectNode)
fetch(::CollectNode)
summary(::CollectNode)
```

## Graph

### DispatchGraph

```@docs
DispatchGraph
nodes(::DispatchGraph)
length(::DispatchGraph)
push!(::DispatchGraph, ::DispatchNode)
add_edge!(::DispatchGraph, ::DispatchNode, ::DispatchNode)
==(::DispatchGraph, ::DispatchGraph)
```

## Executors

### Executor

```@docs
Executor
run!{T<:DispatchNode, S<:DispatchNode}(exec::Executor, nodes::AbstractArray{T}, input_nodes::AbstractArray{S})
run!(::Executor, ::DispatchGraph)
build_graph
prepare!(::Executor, ::DispatchGraph)
dispatch!(::Executor, ::DispatchGraph)
Dispatcher.retries(::Executor)
Dispatcher.retry_on(::Executor)
```

### AsyncExecutor

```@docs
AsyncExecutor
AsyncExecutor()
dispatch!(::AsyncExecutor, node::DispatchNode)
Dispatcher.retries(::AsyncExecutor)
Dispatcher.retry_on(::AsyncExecutor)
```

### ParallelExecutor

```@docs
ParallelExecutor
dispatch!(::ParallelExecutor, node::DispatchNode)
Dispatcher.retries(::ParallelExecutor)
Dispatcher.retry_on(::ParallelExecutor)
```

## Errors

### DependencyError

```@docs
DependencyError
summary(::DependencyError)
```
