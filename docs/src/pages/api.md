# API

## Nodes

### Types

```@docs
DispatchNode
Op
DataNode
```

### Functions and Macros

```@docs
dependencies
@op
@node
```

## Graph

### Types

```@docs
DispatchGraph
```

### Functions and Macros

```@docs
nodes(::DispatchGraph)
```

## Context

### Types

```@docs
DispatchContext
```

### Functions and Macros

```@docs
add!
@dispatch_context
```

## Executors

### Types

```@docs
Executor
AsyncExecutor
ParallelExecutor
```

### Functions and Macros

```@docs
prepare!
run!
dispatch!
```
