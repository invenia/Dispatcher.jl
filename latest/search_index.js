var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Dispatcher.jl-1",
    "page": "Home",
    "title": "Dispatcher.jl",
    "category": "section",
    "text": "CurrentModule = Dispatcher"
},

{
    "location": "index.html#Overview-1",
    "page": "Home",
    "title": "Overview",
    "category": "section",
    "text": "Using Dispatcher, a DispatchContext maintains a computation graph of DispatchNodes. DispatchNodes represent units of computation that can be run. The most common DispatchNode is Op, which represents a function call on some arguments. Some of those arguments may exist when building the graph, and others may represent the results of other DispatchNodes. An Executor executes a whole DispatchContext. Two Executors are provided. AsyncExecutor executes computations asynchronously using Julia Tasks. ParallelExecutor executes computations in parallel using all available Julia processes (by calling @spawn)."
},

{
    "location": "index.html#Frequently-Asked-Questions-1",
    "page": "Home",
    "title": "Frequently Asked Questions",
    "category": "section",
    "text": "How is Dispatcher different from ComputeFramework/Dagger?Dagger is built around distributing vectorized computations across large arrays. Dispatcher is built to deal with discrete, heterogeneous data using any Julia functions.How is Dispatcher different from Arbiter?Arbiter requires manually adding tasks and their dependencies and handling data passing. Dispatcher automatically identifies dependencies from user code and passes data efficiently between dependencies.How does Dispatcher handle passing data?Dispatcher uses Julia RemoteChannels to pass data between dispatched DispatchNodes. For more information on how data transfer works with Julia's parallel tools see their documentation."
},

{
    "location": "index.html#Documentation-Contents-1",
    "page": "Home",
    "title": "Documentation Contents",
    "category": "section",
    "text": "Pages = [\"pages/manual.md\", \"pages/api.md\"]"
},

{
    "location": "pages/manual.html#",
    "page": "Manual",
    "title": "Manual",
    "category": "page",
    "text": ""
},

{
    "location": "pages/manual.html#Manual-1",
    "page": "Manual",
    "title": "Manual",
    "category": "section",
    "text": ""
},

{
    "location": "pages/manual.html#Motivation-1",
    "page": "Manual",
    "title": "Motivation",
    "category": "section",
    "text": "Dispatcher.jl is designed to distribute and manage execution of a graph of computations. These computations are specified in a manner as close to regular imperative Julia code as possible. Using a parallel executor with several processes, a central controller manages execution, but data is transported only among processes which will use it. This avoids having one large process where all data currently being used is stored."
},

{
    "location": "pages/manual.html#FAQ-1",
    "page": "Manual",
    "title": "FAQ",
    "category": "section",
    "text": "How is Dispatcher different from ComputeFramework/Dagger?Dagger is built around distributing vectorized computations across large arrays. Dispatcher is built to deal with discrete, heterogeneous data using any Julia functions.How is Dispatcher different from Arbiter?Arbiter requires manually adding tasks and their dependencies and handling data passing. Dispatcher automatically identifies dependencies from user code and passes data efficiently between dependencies.How does Dispatcher handle passing data?Dispatcher uses Julia RemoteChannels to pass data between dispatched DispatchNodes. For more information on how data transfer works with Julia's parallel tools see their documentation."
},

{
    "location": "pages/manual.html#Design-1",
    "page": "Manual",
    "title": "Design",
    "category": "section",
    "text": ""
},

{
    "location": "pages/manual.html#Overview-1",
    "page": "Manual",
    "title": "Overview",
    "category": "section",
    "text": "Using Dispatcher, a DispatchContext maintains a computation graph of DispatchNodes. DispatchNodes represent units of computation that can be run. The most common DispatchNode is Op, which represents a function call on some arguments. Some of those arguments may exist when building the graph, and others may represent the results of other DispatchNodes. An Executor executes a whole DispatchContext. Two Executors are provided. AsyncExecutor executes computations asynchronously using Julia Tasks. ParallelExecutor executes computations in parallel using all available Julia processes (by calling @spawn).Here is an example defining and executing a graph:The components of this example will be discussed below."
},

{
    "location": "pages/manual.html#Dispatch-Nodes-1",
    "page": "Manual",
    "title": "Dispatch Nodes",
    "category": "section",
    "text": "A DispatchNode generally represents a unit of computation that can be run. DispatchNodes are constructed when defining the graph and are run as part of graph execution. The @node macro takes a DispatchNode instance and adds it to the graph in the current context. The following code, where Feature <: DispatchNode:is equivalent to:where ctx is the current dispatch context."
},

{
    "location": "pages/manual.html#Op-1",
    "page": "Manual",
    "title": "Op",
    "category": "section",
    "text": "An Op is a DispatchNode which represents some function call to be run as part of graph execution. This is the most common type of DispatchNode. The @op applies an extra transformation on top of the @node macro and deconstructs a function call to add to the graph. The following code:is equivalent to:where ctx is the current dispatch context. Note that code in the argument list gets evaluated immediately; only the function call is delayed."
},

{
    "location": "pages/manual.html#Dispatch-Context-and-Dispatch-Graph-1",
    "page": "Manual",
    "title": "Dispatch Context and Dispatch Graph",
    "category": "section",
    "text": "The above macros add nodes to a DispatchContext. The DispatchContext contains a DispatchGraph, which stores nodes and dependencies in a graph. Any arguments to DispatchNode constructors (including in @node and @op) which are DispatchNodes are recorded as dependencies in the graph."
},

{
    "location": "pages/manual.html#Executors-1",
    "page": "Manual",
    "title": "Executors",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api.html#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "pages/api.html#API-1",
    "page": "API",
    "title": "API",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api.html#Nodes-1",
    "page": "API",
    "title": "Nodes",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api.html#Dispatcher.DispatchNode",
    "page": "API",
    "title": "Dispatcher.DispatchNode",
    "category": "Type",
    "text": "A DispatchNode represents a unit of computation that can be run. A DispatchNode may depend on other DispatchNodes, which are returned from the dependencies function.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.Op",
    "page": "API",
    "title": "Dispatcher.Op",
    "category": "Type",
    "text": "An Op is a DispatchNode which wraps a function which is executed when the Op is run. The result of that function call is stored in the result DeferredFuture. Any DispatchNodes which appear in the args or kwargs values will be noted as dependencies. This is the most common DispatchNode.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.DataNode",
    "page": "API",
    "title": "Dispatcher.DataNode",
    "category": "Type",
    "text": "A DataNode is a DispatchNode which wraps a piece of static data.\n\n\n\n"
},

{
    "location": "pages/api.html#Types-1",
    "page": "API",
    "title": "Types",
    "category": "section",
    "text": "DispatchNode\nOp\nDataNode"
},

{
    "location": "pages/api.html#Dispatcher.dependencies",
    "page": "API",
    "title": "Dispatcher.dependencies",
    "category": "Function",
    "text": "dependencies(node::DispatchNode) -> Tuple{Vararg{DispatchNode}}\n\nReturn all dependencies which must be ready before executing this node. Unless given a dependencies method, a DispatchNode will be assumed to have no dependencies.\n\n\n\ndependencies(op::Op) -> Tuple{Verarg{DispatchNode}}\n\nReturn all dependencies which must be ready before executing this Op. This will be all DispatchNodes in the Op's function args and kwargs.\n\n\n\ndependencies(node::IndexNode) -> Tuple{DispatchNode}\n\nReturn the dependency that this node will fetch data (at a certain index) from.\n\n\n\ndependencies(node::CleanupNode) -> Tuple{Vararg{DispatchNode}}\n\nReturn the nodes the CleanupNode must wait for before cleaning up (the parent and child nodes).\n\n\n\ndependencies{T<:DispatchNode}(node::CollectNode{T}) -> Vector{T}\n\nReturn the nodes this depends on which this node will collect.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.@op",
    "page": "API",
    "title": "Dispatcher.@op",
    "category": "Macro",
    "text": "@op func(...)\n\nThe @op macro makes it more convenient to add Op nodes to the computation graph while in a @dispatch_context block. It translates a function call into an Op call, effectively deferring the computation.\n\na = @op sort(1:10; rev=true)\n\nis equivalent to\n\na = add!(ctx, Op(sort, 1:10; rev=true))\n\nwhere ctx is a variable created by the surrounding @dispatch_context.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.@node",
    "page": "API",
    "title": "Dispatcher.@node",
    "category": "Macro",
    "text": "@node Node(...)\n\nThe @node macro makes it more convenient to add nodes to the computation graph while in a @dispatch_context block.\n\na = @node DataNode([1, 3, 5])\n\nis equivalent to\n\na = add!(ctx, DataNode([1, 3, 5]))\n\nwhere ctx is a variable created by the surrounding @dispatch_context.\n\n\n\n"
},

{
    "location": "pages/api.html#Functions-and-Macros-1",
    "page": "API",
    "title": "Functions and Macros",
    "category": "section",
    "text": "dependencies\n@op\n@node"
},

{
    "location": "pages/api.html#Graph-1",
    "page": "API",
    "title": "Graph",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api.html#Dispatcher.DispatchGraph",
    "page": "API",
    "title": "Dispatcher.DispatchGraph",
    "category": "Type",
    "text": "DispatchGraph wraps a directed graph from LightGraphs and a bidirectional dictionary mapping between DispatchNode instances and vertex numbers in the graph.\n\n\n\n"
},

{
    "location": "pages/api.html#Types-2",
    "page": "API",
    "title": "Types",
    "category": "section",
    "text": "DispatchGraph"
},

{
    "location": "pages/api.html#Dispatcher.nodes-Tuple{Dispatcher.DispatchGraph}",
    "page": "API",
    "title": "Dispatcher.nodes",
    "category": "Method",
    "text": "nodes(graph::DispatchGraph) ->\n\nReturn an iterable of all nodes stored in the DispatchGraph.\n\n\n\n"
},

{
    "location": "pages/api.html#Functions-and-Macros-2",
    "page": "API",
    "title": "Functions and Macros",
    "category": "section",
    "text": "nodes(::DispatchGraph)"
},

{
    "location": "pages/api.html#Context-1",
    "page": "API",
    "title": "Context",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api.html#Dispatcher.DispatchContext",
    "page": "API",
    "title": "Dispatcher.DispatchContext",
    "category": "Type",
    "text": "DispatchContext holds the computation graph and arbitrary key-value pairs of metadata.\n\n\n\n"
},

{
    "location": "pages/api.html#Types-3",
    "page": "API",
    "title": "Types",
    "category": "section",
    "text": "DispatchContext"
},

{
    "location": "pages/api.html#Dispatcher.add!",
    "page": "API",
    "title": "Dispatcher.add!",
    "category": "Function",
    "text": "add!(ctx::DispatchContext, node::DispatchNode) -> DispatchNode\n\nAdd a DispatchNode to the DispatchContext's graph and record its dependencies in the graph.\n\nReturn the DispatchNode which was added.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.@dispatch_context",
    "page": "API",
    "title": "Dispatcher.@dispatch_context",
    "category": "Macro",
    "text": "@dispatch_context begin ... end\n\nAnonymously create and return a DispatchContext. Accepts a block argument and causes all @op and @node macros within that block to use said DispatchContext.\n\nSee examples in the manual.\n\n\n\n"
},

{
    "location": "pages/api.html#Functions-and-Macros-3",
    "page": "API",
    "title": "Functions and Macros",
    "category": "section",
    "text": "add!\n@dispatch_context"
},

{
    "location": "pages/api.html#Executors-1",
    "page": "API",
    "title": "Executors",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api.html#Dispatcher.Executor",
    "page": "API",
    "title": "Dispatcher.Executor",
    "category": "Type",
    "text": "An Executor handles execution of DispatchContexts.\n\nA type T <: Executor must implement dispatch!(::T, ::DispatchNode) and may optionally implement dispatch!(::T, ::DispatchContext; throw_error=true).\n\nThe function call tree will look like this when an executor is run:\n\nrun!(exec, context)\n    prepare!(exec, context)\n        prepare!(nodes[i])\n    dispatch!(exec, context)\n        dispatch!(exec, nodes[i])\n            run!(nodes[i])\n\nNOTE: Currently, it is expected that dispatch!(::T, ::DispatchNode) returns something to wait on (ie: Task, Future, Channel, DispatchNode, etc)\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.AsyncExecutor",
    "page": "API",
    "title": "Dispatcher.AsyncExecutor",
    "category": "Type",
    "text": "AsyncExecutor is an Executor which schedules a local Julia Task for each DispatchNode and waits for them to complete. AsyncExecutor's dispatch! method will complete as long as each DispatchNode's run! method completes and there are no cycles in the computation graph.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.ParallelExecutor",
    "page": "API",
    "title": "Dispatcher.ParallelExecutor",
    "category": "Type",
    "text": "ParallelExecutor is an Executor which creates a Julia Task for each DispatchNode, spawns each of those tasks on the processes available to Julia, and waits for them to complete. ParallelExecutor's dispatch! method will complete as long as each DispatchNode's run! method completes and there are no cycles in the computation graph.\n\n\n\n"
},

{
    "location": "pages/api.html#Types-4",
    "page": "API",
    "title": "Types",
    "category": "section",
    "text": "Executor\nAsyncExecutor\nParallelExecutor"
},

{
    "location": "pages/api.html#Dispatcher.prepare!",
    "page": "API",
    "title": "Dispatcher.prepare!",
    "category": "Function",
    "text": "prepare!(node::DispatchNode)\n\nExecute some action on a node before dispatching nodes via an Executor. The default method performs no action.\n\n\n\nprepare!(op::Op)\n\nReplace an Op's result field with a fresh, empty one.\n\n\n\nprepare!(node::IndexNode)\n\nReplace an IndexNode's result field with a fresh, empty one.\n\n\n\nprepare!(node::IndexNode)\n\nReplace an CleanupNode's completion status field with a fresh, empty one.\n\n\n\nprepare!(node::CollectNode)\n\nInitialize a CollectNode with a fresh result DeferredFuture.\n\n\n\nprepare!(exec::Executor, ctx::DispatchContext)\n\nThis function prepare!s a context for execution. Call prepare! on each node.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.run!",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "Function",
    "text": "run!(node::DispatchNode)\n\nExecute a node's action as part of dispatch. The default method performs no action.\n\n\n\nrun!(op::Op)\n\nFetch an Op's dependencies and execute its function. Store the result in its result::DeferredFuture field.\n\n\n\nrun!(node::IndexNode) -> DeferredFuture\n\nFetch data from the IndexNode's parent at the IndexNode's index, performing the indexing operation on the process where the data lives. Store the data from that index in a DeferredFuture in the IndexNode.\n\n\n\nrun!(node::IndexNode) -> DeferredFuture\n\nFetch data from the IndexNode's parent at the IndexNode's index, performing the indexing operation on the process where the data lives. Store the data from that index in a DeferredFuture in the IndexNode.\n\n\n\nrun!(node::CleanupNode{Op})\n\nWait for all of the CleanupNode's dependencies to finish, then clean up the parent node's data.\n\n\n\nrun!(node::CollectNode)\n\nCollect all of a CollectNode's dependencies' results into a Vector and store that in this node's result field. Returns nothing.\n\n\n\nrun!(exec, ctx, nodes, input_nodes; input_map, throw_error) -> DispatchResult\n\nRun a subset of a graph, ending in nodes, and using input_nodes/input_map to replace nodes with fixed values (and ignoring nodes for which all paths descend to input_nodes).\n\nArguments\n\nexec::Executor: the executor which will execute this context\nctx::DispatchContext: the context which will be executed\nnodes::AbstractArray{T<:DispatchNode}: the nodes whose results we are interested in\ninput_nodes::AbstractArray{T<:DispatchNode}: \"root\" nodes of the subgraph which will be replaced with their fetched values\n\nKeyword Arguments\n\ninput_map::Associative=Dict{DispatchNode, Any}(): dict keys are \"root\" nodes of the subgraph which will be replaced with the dict values\nthrow_error::Bool: whether to throw any DependencyErrors immediately (see dispatch! documentation for more information)\n\nReturns\n\nVector{DispatchResult}: an array containing a DispatchResult for each node in nodes, in that order.\n\nThrows\n\nExecutorError: if the context's graph contains a cycle\nCompositeException/DependencyError: see documentation for dispatch!\n\n\n\nrun!(exec::Executor, ctx::DispatchContext; kwargs...)\n\nThe run! function prepares a DispatchContext for dispatch and then dispatches run! calls for all nodes in its graph.\n\nUsers will almost never want to add methods to this function for different Executor subtypes; overriding dispatch! is the preferred pattern.\n\nReturn an array containing a Result{DispatchNode, DependencyError} for each leaf node.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.dispatch!",
    "page": "API",
    "title": "Dispatcher.dispatch!",
    "category": "Function",
    "text": "dispatch!(exec::Executor, ctx::DispatchContext; throw_error=true) -> Vector\n\nThe default dispatch! method uses asyncmap over all nodes in the context to call dispatch!(exec, node). These dispatch! calls for each node are wrapped in various retry and error handling methods.\n\nWrapping Details\n\nAll nodes are wrapped in a try catch which waits on the value returned from the dispatch!(exec, node) call. Any errors are caught and used to create DependencyErrors which are thrown. If no errors are produced then the node is returned.\nNOTE: All errors thrown by trying to run dispatch!(exec, node) are wrapped in a DependencyError.\nThe aformentioned wrapper function is used in a retry wrapper to rerun failed nodes (up to some limit). The wrapped function will only be retried iff the error produced by dispatch!(::executor, ::DispatchNode) passes one of the retry functions specific to that Executor. By default the AsyncExecutor has no retry_on functions and the ParallelExecutor only has retry_on functions related to the loss of a worker process during execution.\nA node may enter a failed state if it exits the retry wrapper with an exception. This may occur if an exception is thrown while executing a node and it does not pass any of the retry_on conditions for the Executor or too many attempts to run the node have been made. In the situation where a node has entered a failed state and the node is an Op then the op.result is set to the DependencyError, signifying the node's failure to any dependent nodes. Finally, if throw_error is true then the DependencyError will be immediately thrown in the current process without allowing other nodes to finish. If throw_error is false then the DependencyError is not thrown and it will be returned in the array of passing and failing nodes.\n\nArguments\n\nexec::Executor: the executor we're running\nctx::DispatchContext: the context of nodes to run\n\nKeyword Arguments\n\nthrow_error::Bool=true: whether or not to throw the DependencyError for failed nodes\n\nReturns\n\nVector{Union{DispatchNode, DependencyError}}: a list of DispatchNodes or DependencyErrors for failed nodes\n\nThrows\n\ndispatch! has the same behaviour on exceptions as asyncmap and pmap. In 0.5 this will throw a CompositeException containing DependencyErrors, while in 0.6 this will simply throw the first DependencyError.\n\nUsage\n\nExample 1\n\nAssuming we have some uncaught application error:\n\nexec = AsyncExecutor()\nctx = DispatchContext()\nn1 = add!(ctx, Op()->3)\nn2 = add!(ctx, Op()->4)\nfailing_node = add!(ctx, Op(()->throw(ErrorException(\"ApplicationError\"))))\ndep_node = add!(n -> println(n), failing_node)  # This will fail as well\n\nThen dispatch!(exec, ctx) will throw a DependencyError and dispatch!(exec, ctx; throw_error=false) will return an array of passing nodes and the DependencyErrors (ie: [n1, n2, DependencyError(...), DependencyError(...)]).\n\nExample 2\n\nNow if we want to retry our node on certain errors we can do:\n\nexec = AsyncExecutor(5, [e -> isa(e, HttpError) && e.status == \"503\"])\nctx = DispatchContext()\nn1 = add!(ctx, Op()->3)\nn2 = add!(ctx, Op()->4)\nhttp_node = add!(ctx, Op(()->http_get(...)))\n\nAssuming that the http_get function does not error 5 times the call to dispatch!(exec, ctx) will return [n1, n2, http_node]. If the http_get function either:\n\nfails with a different status code\nfails with something other than an HttpError or\nthrows an HttpError with status \"503\" more than 5 times\n\nthen we'll see the same failure behaviour as in the previous example.\n\n\n\ndispatch!(exec::ParallelExecutor, node::DispatchNode) -> Task\n\ndispatch! takes the AsyncExecutor and a DispatchNode to run. The run! method on the node is called within an @async block and the resulting Task is returned. This is the defining method of AsyncExecutor.\n\n\n\ndispatch!(exec::ParallelExecutor, node::DispatchNode) -> Future\n\ndispatch! takes the ParallelExecutor and a DispatchNode to run. The run! method on the node is called within an @spawn block and the resulting Future is returned. This is the defining method of ParallelExecutor.\n\n\n\n"
},

{
    "location": "pages/api.html#Functions-and-Macros-4",
    "page": "API",
    "title": "Functions and Macros",
    "category": "section",
    "text": "prepare!\nrun!\ndispatch!"
},

]}
