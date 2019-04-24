var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#Dispatcher.jl-1",
    "page": "Home",
    "title": "Dispatcher.jl",
    "category": "section",
    "text": "CurrentModule = Dispatcher"
},

{
    "location": "#Overview-1",
    "page": "Home",
    "title": "Overview",
    "category": "section",
    "text": "Using Dispatcher, run! builds and runs a computation graph of DispatchNodes. DispatchNodes represent units of computation that can be run. The most common DispatchNode is Op, which represents a function call on some arguments. Some of those arguments may exist when building the graph, and others may represent the results of other DispatchNodes. An Executor executes a whole DispatchGraph. Two Executors are provided. AsyncExecutor executes computations asynchronously using Julia Tasks. ParallelExecutor executes computations in parallel using all available Julia processes (by calling @spawn)."
},

{
    "location": "#Frequently-Asked-Questions-1",
    "page": "Home",
    "title": "Frequently Asked Questions",
    "category": "section",
    "text": "How is Dispatcher different from ComputeFramework/Dagger?Dagger is built around distributing vectorized computations across large arrays. Dispatcher is built to deal with discrete, heterogeneous data using any Julia functions.How is Dispatcher different from Arbiter?Arbiter requires manually adding tasks and their dependencies and handling data passing. Dispatcher automatically identifies dependencies from user code and passes data efficiently between dependencies.Isn\'t this just Dask?Pretty much. The plan is to implement another Executor and integrate with the dask.distributed scheduler service to piggyback off of their great work.How does Dispatcher handle passing data?Dispatcher uses Julia RemoteChannels to pass data between dispatched DispatchNodes. For more information on how data transfer works with Julia\'s parallel tools see their documentation."
},

{
    "location": "#Documentation-Contents-1",
    "page": "Home",
    "title": "Documentation Contents",
    "category": "section",
    "text": "Pages = [\"pages/manual.md\", \"pages/api.md\"]"
},

{
    "location": "pages/manual/#",
    "page": "Manual",
    "title": "Manual",
    "category": "page",
    "text": ""
},

{
    "location": "pages/manual/#Manual-1",
    "page": "Manual",
    "title": "Manual",
    "category": "section",
    "text": ""
},

{
    "location": "pages/manual/#Motivation-1",
    "page": "Manual",
    "title": "Motivation",
    "category": "section",
    "text": "Dispatcher.jl is designed to distribute and manage execution of a graph of computations. These computations are specified in a manner as close to regular imperative Julia code as possible. Using a parallel executor with several processes, a central controller manages execution, but data is transported only among processes which will use it. This avoids having one large process where all data currently being used is stored."
},

{
    "location": "pages/manual/#Design-1",
    "page": "Manual",
    "title": "Design",
    "category": "section",
    "text": ""
},

{
    "location": "pages/manual/#Overview-1",
    "page": "Manual",
    "title": "Overview",
    "category": "section",
    "text": "Using Dispatcher, run! builds and runs a computation graph of DispatchNodes. DispatchNodes represent units of computation that can be run. The most common DispatchNode is Op, which represents a function call on some arguments. Some of those arguments may exist when building the graph, and others may represent the results of other DispatchNodes. An Executor builds and executes a whole DispatchGraph. Two Executors are provided. AsyncExecutor executes computations asynchronously using Julia Tasks. ParallelExecutor executes computations in parallel using all available Julia processes (by calling @spawn).Here is an example defining and executing a graph:filenames = [\"mydata-$d.dat\" for d in 1:100]\ndata = [(@op load(filename)) for filename in filenames]\n\nreference = @op load_from_sql(\"sql://mytable\")\nprocessed = [(@op process(d, reference)) for d in data]\n\nrolled = map(1:(length(processed) - 2)) do i\n    a = processed[i]\n    b = processed[i + 1]\n    c = processed[i + 2]\n    roll_result = @op roll(a, b, c)\n    return roll_result\nend\n\ncompared = map(1:200) do i\n    a = rand(rolled)\n    b = rand(rolled)\n    compare_result = @op compare(a, b)\n    return compare_result\nend\n\nbest = @op reduction(CollectNode(compared))\n\nexecutor = ParallelExecutor()\n(run_best,) = run!(executor, [best])The components of this example will be discussed below. This example is based on a Dask example."
},

{
    "location": "pages/manual/#Dispatch-Nodes-1",
    "page": "Manual",
    "title": "Dispatch Nodes",
    "category": "section",
    "text": "A DispatchNode generally represents a unit of computation that can be run. DispatchNodes are constructed when defining the graph and are run as part of graph execution. CollectNode from the above example is a subtype of DispatchNode.Any arguments to DispatchNode constructors (including in @op) which are DispatchNodes are recorded as dependencies in the graph."
},

{
    "location": "pages/manual/#Op-1",
    "page": "Manual",
    "title": "Op",
    "category": "section",
    "text": "An Op is a DispatchNode which represents some function call to be run as part of graph execution. This is the most common type of DispatchNode. The @op macro deconstructs a function call to construct an Op. The following code:roll_result = @op roll(a, b, c)is equivalent to:roll_result = Op(roll, a, b, c)Note that code in the argument list gets evaluated immediately; only the function call is delayed."
},

{
    "location": "pages/manual/#Executors-1",
    "page": "Manual",
    "title": "Executors",
    "category": "section",
    "text": "An Executor runs a DispatchGraph. This package currently provides two Executors: AsyncExecutor and ParallelExecutor. They work the same way, except AsyncExecutor runs nodes using @async and ParallelExecutor uses @spawn.This call:(run_best,) = run!(executor, [best])takes an Executor and a Vector{DispatchNode}, creates a DispatchGraph of those nodes and all of their ancestors, runs it, and returns a collection of DispatchResults (in this case containing only the DispatchResult for best). A DispatchResult is a ResultType containing either a DispatchNode or a DependencyError (an error that occurred when attempting to satisfy the requirements for running that node).It is also possible to feed in inputs in place of nodes in the graph; see run! for more."
},

{
    "location": "pages/manual/#Further-Reading-1",
    "page": "Manual",
    "title": "Further Reading",
    "category": "section",
    "text": "Check out the API for more information."
},

{
    "location": "pages/api/#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "pages/api/#API-1",
    "page": "API",
    "title": "API",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api/#Nodes-1",
    "page": "API",
    "title": "Nodes",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api/#Dispatcher.DispatchNode",
    "page": "API",
    "title": "Dispatcher.DispatchNode",
    "category": "type",
    "text": "A DispatchNode represents a unit of computation that can be run. A DispatchNode may depend on other DispatchNodes, which are returned from the dependencies function.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.get_label-Union{Tuple{T}, Tuple{T}} where T<:DispatchNode",
    "page": "API",
    "title": "Dispatcher.get_label",
    "category": "method",
    "text": "get_label(node::DispatchNode) -> String\n\nReturns a node\'s label. By default, DispatchNodes do not support labels, so this method will error.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.set_label!-Union{Tuple{T}, Tuple{T,Any}} where T<:DispatchNode",
    "page": "API",
    "title": "Dispatcher.set_label!",
    "category": "method",
    "text": "set_label!(node::DispatchNode, label)\n\nSets a node\'s label. By default, DispatchNodes do not support labels, so this method will error. Actual method implementations should return their second argument.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.has_label-Tuple{DispatchNode}",
    "page": "API",
    "title": "Dispatcher.has_label",
    "category": "method",
    "text": "has_label(node::DispatchNode) -> Bool\n\nReturns true or false as to whether the node has a label (ie: a get_label(::DispatchNode) method)\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.dependencies-Tuple{DispatchNode}",
    "page": "API",
    "title": "Dispatcher.dependencies",
    "category": "method",
    "text": "dependencies(node::DispatchNode) -> Tuple{Vararg{DispatchNode}}\n\nReturn all dependencies which must be ready before executing this node. Unless given a dependencies method, a DispatchNode will be assumed to have no dependencies.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.prepare!-Tuple{DispatchNode}",
    "page": "API",
    "title": "Dispatcher.prepare!",
    "category": "method",
    "text": "prepare!(node::DispatchNode)\n\nExecute some action on a node before dispatching nodes via an Executor. The default method performs no action.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.run!-Tuple{DispatchNode}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "method",
    "text": "run!(node::DispatchNode)\n\nExecute a node\'s action as part of dispatch. The default method performs no action.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.isready-Tuple{DispatchNode}",
    "page": "API",
    "title": "Base.isready",
    "category": "method",
    "text": "isready(node::DispatchNode) -> Bool\n\nDetermine whether a node has an available result. The default method assumes no synchronization is involved in retrieving that result.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.wait-Tuple{DispatchNode}",
    "page": "API",
    "title": "Base.wait",
    "category": "method",
    "text": "wait(node::DispatchNode)\n\nBlock the current task until a node has a result available.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.fetch-Union{Tuple{T}, Tuple{T}} where T<:DispatchNode",
    "page": "API",
    "title": "Base.fetch",
    "category": "method",
    "text": "fetch(node::DispatchNode) -> Any\n\nFetch a node\'s result if available, blocking until it is available. All subtypes of DispatchNode should implement this, so the default method throws an error.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#DispatchNode-1",
    "page": "API",
    "title": "DispatchNode",
    "category": "section",
    "text": "DispatchNode\nget_label{T<:DispatchNode}(::T)\nset_label!{T<:DispatchNode}(::T, ::Any)\nhas_label(::DispatchNode)\ndependencies(::DispatchNode)\nprepare!(::DispatchNode)\nrun!(::DispatchNode)\nisready(::DispatchNode)\nwait(::DispatchNode)\nfetch{T<:DispatchNode}(::T)"
},

{
    "location": "pages/api/#Dispatcher.Op",
    "page": "API",
    "title": "Dispatcher.Op",
    "category": "type",
    "text": "An Op is a DispatchNode which wraps a function which is executed when the Op is run. The result of that function call is stored in the result DeferredFuture. Any DispatchNodes which appear in the args or kwargs values will be noted as dependencies. This is the most common DispatchNode.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.Op-Tuple{Function}",
    "page": "API",
    "title": "Dispatcher.Op",
    "category": "method",
    "text": "Op(func::Function, args...; kwargs...) -> Op\n\nConstruct an Op which represents the delayed computation of func(args...; kwargs). Any DispatchNodes which appear in the args or kwargs values will be noted as dependencies. The default label of an Op is the name of func.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.@op",
    "page": "API",
    "title": "Dispatcher.@op",
    "category": "macro",
    "text": "@op func(...)\n\nThe @op macro makes it more convenient to construct Op nodes. It translates a function call into an Op call, effectively deferring the computation.\n\na = @op sort(1:10; rev=true)\n\nis equivalent to\n\na = Op(sort, 1:10; rev=true)\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.get_label-Tuple{Op}",
    "page": "API",
    "title": "Dispatcher.get_label",
    "category": "method",
    "text": "get_label(op::Op) -> String\n\nReturns the op.label.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.set_label!-Tuple{Op,AbstractString}",
    "page": "API",
    "title": "Dispatcher.set_label!",
    "category": "method",
    "text": "set_label!(op::Op, label::AbstractString)\n\nSet the op\'s label. Returns its second argument.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.has_label-Tuple{Op}",
    "page": "API",
    "title": "Dispatcher.has_label",
    "category": "method",
    "text": "has_label(::Op) -> Bool\n\nAlways return true as an Op will always have a label.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.dependencies-Tuple{Op}",
    "page": "API",
    "title": "Dispatcher.dependencies",
    "category": "method",
    "text": "dependencies(op::Op) -> Tuple{Verarg{DispatchNode}}\n\nReturn all dependencies which must be ready before executing this Op. This will be all DispatchNodes in the Op\'s function args and kwargs.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.prepare!-Tuple{Op}",
    "page": "API",
    "title": "Dispatcher.prepare!",
    "category": "method",
    "text": "prepare!(op::Op)\n\nReplace an Op\'s result field with a fresh, empty one.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.run!-Tuple{Op}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "method",
    "text": "run!(op::Op)\n\nFetch an Op\'s dependencies and execute its function. Store the result in its result::DeferredFuture field.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.isready-Tuple{Op}",
    "page": "API",
    "title": "Base.isready",
    "category": "method",
    "text": "isready(op::Op) -> Bool\n\nDetermine whether an Op has an available result.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.wait-Tuple{Op}",
    "page": "API",
    "title": "Base.wait",
    "category": "method",
    "text": "wait(op::Op)\n\nWait until an Op has an available result.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.fetch-Tuple{Op}",
    "page": "API",
    "title": "Base.fetch",
    "category": "method",
    "text": "fetch(op::Op) -> Any\n\nReturn the result of the Op. Block until it is available. Throw DependencyError in the event that the result is a DependencyError.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.summary-Tuple{Op}",
    "page": "API",
    "title": "Base.summary",
    "category": "method",
    "text": "summary(op::Op)\n\nReturns a string representation of the Op with its label and the args/kwargs types.\n\nNOTE: if an arg/kwarg is a DispatchNode with a label it will be printed with that arg.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Op-1",
    "page": "API",
    "title": "Op",
    "category": "section",
    "text": "Op\nOp(::Function)\n@op\nget_label(::Op)\nset_label!(::Op, ::AbstractString)\nhas_label(::Op)\ndependencies(::Op)\nprepare!(::Op)\nrun!(::Op)\nisready(::Op)\nwait(::Op)\nfetch(::Op)\nsummary(::Op)"
},

{
    "location": "pages/api/#Dispatcher.DataNode",
    "page": "API",
    "title": "Dispatcher.DataNode",
    "category": "type",
    "text": "A DataNode is a DispatchNode which wraps a piece of static data.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.fetch-Tuple{DataNode}",
    "page": "API",
    "title": "Base.fetch",
    "category": "method",
    "text": "fetch{T}(node::DataNode{T}) -> T\n\nImmediately return the data contained in a DataNode.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#DataNode-1",
    "page": "API",
    "title": "DataNode",
    "category": "section",
    "text": "DataNode\nfetch(::DataNode)"
},

{
    "location": "pages/api/#Dispatcher.IndexNode",
    "page": "API",
    "title": "Dispatcher.IndexNode",
    "category": "type",
    "text": "An IndexNode refers to an element of the return value of a DispatchNode. It is meant to handle multiple return values from a DispatchNode.\n\nExample:\n\nn1, n2 = Op(() -> divrem(5, 2))\nrun!(exec, [n1, n2])\n\n@assert fetch(n1) == 2\n@assert fetch(n2) == 1\n\nIn this example, n1 and n2 are created as IndexNodes pointing to the Op at index 1 and index 2 respectively.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.IndexNode-Tuple{DispatchNode,Int64}",
    "page": "API",
    "title": "Dispatcher.IndexNode",
    "category": "method",
    "text": "IndexNode(node::DispatchNode, index) -> IndexNode\n\nCreate a new IndexNode referring to the result of node at index.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.dependencies-Tuple{IndexNode}",
    "page": "API",
    "title": "Dispatcher.dependencies",
    "category": "method",
    "text": "dependencies(node::IndexNode) -> Tuple{DispatchNode}\n\nReturn the dependency that this node will fetch data (at a certain index) from.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.prepare!-Tuple{IndexNode}",
    "page": "API",
    "title": "Dispatcher.prepare!",
    "category": "method",
    "text": "prepare!(node::IndexNode)\n\nReplace an IndexNode\'s result field with a fresh, empty one.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.run!-Tuple{IndexNode}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "method",
    "text": "run!(node::IndexNode) -> DeferredFuture\n\nFetch data from the IndexNode\'s parent at the IndexNode\'s index, performing the indexing operation on the process where the data lives. Store the data from that index in a DeferredFuture in the IndexNode.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.run!-Union{Tuple{IndexNode{T}}, Tuple{T}} where T<:Union{Op, IndexNode}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "method",
    "text": "run!(node::IndexNode) -> DeferredFuture\n\nFetch data from the IndexNode\'s parent at the IndexNode\'s index, performing the indexing operation on the process where the data lives. Store the data from that index in a DeferredFuture in the IndexNode.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.isready-Tuple{IndexNode}",
    "page": "API",
    "title": "Base.isready",
    "category": "method",
    "text": "isready(node::IndexNode) -> Bool\n\nDetermine whether an IndexNode has an available result.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.wait-Tuple{IndexNode}",
    "page": "API",
    "title": "Base.wait",
    "category": "method",
    "text": "wait(node::IndexNode)\n\nWait until an IndexNode has an available result.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.fetch-Tuple{IndexNode}",
    "page": "API",
    "title": "Base.fetch",
    "category": "method",
    "text": "fetch(node::IndexNode) -> Any\n\nReturn the stored result of indexing.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.summary-Tuple{IndexNode}",
    "page": "API",
    "title": "Base.summary",
    "category": "method",
    "text": "summary(node::IndexNode)\n\nReturns a string representation of the IndexNode with a summary of the wrapped node and the node index.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#IndexNode-1",
    "page": "API",
    "title": "IndexNode",
    "category": "section",
    "text": "IndexNode\nIndexNode(::DispatchNode, ::Int)\ndependencies(::IndexNode)\nprepare!(::IndexNode)\nrun!(::IndexNode)\nrun!{T<:Union{Op, IndexNode}}(::IndexNode{T})\nisready(::IndexNode)\nwait(::IndexNode)\nfetch(::IndexNode)\nsummary(::IndexNode)"
},

{
    "location": "pages/api/#Dispatcher.CollectNode",
    "page": "API",
    "title": "Dispatcher.CollectNode",
    "category": "type",
    "text": "CollectNode{T<:DispatchNode}(nodes::Vector{T}) -> CollectNode{T}\n\nCreate a node which gathers an array of nodes and stores an array of their results in its result field.\n\n\n\n\n\nCollectNode(nodes) -> CollectNode{DispatchNode}\n\nCreate a CollectNode from any iterable of nodes.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.CollectNode-Tuple{Array{DispatchNode,1}}",
    "page": "API",
    "title": "Dispatcher.CollectNode",
    "category": "method",
    "text": "CollectNode{T<:DispatchNode}(nodes::Vector{T}) -> CollectNode{T}\n\nCreate a node which gathers an array of nodes and stores an array of their results in its result field.\n\n\n\n\n\nCollectNode(nodes) -> CollectNode{DispatchNode}\n\nCreate a CollectNode from any iterable of nodes.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.get_label-Tuple{CollectNode}",
    "page": "API",
    "title": "Dispatcher.get_label",
    "category": "method",
    "text": "get_label(node::CollectNode) -> String\n\nReturns the node.label.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.set_label!-Tuple{CollectNode,AbstractString}",
    "page": "API",
    "title": "Dispatcher.set_label!",
    "category": "method",
    "text": "set_label!(node::CollectNode, label::AbstractString) -> AbstractString\n\nSet the node\'s label. Returns its second argument.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.has_label-Tuple{CollectNode}",
    "page": "API",
    "title": "Dispatcher.has_label",
    "category": "method",
    "text": "has_label(::CollectNode) -> Bool\n\nAlways return true as a CollectNode will always have a label.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.dependencies-Tuple{CollectNode}",
    "page": "API",
    "title": "Dispatcher.dependencies",
    "category": "method",
    "text": "dependencies{T<:DispatchNode}(node::CollectNode{T}) -> Vector{T}\n\nReturn the nodes this depends on which this node will collect.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.prepare!-Tuple{CollectNode}",
    "page": "API",
    "title": "Dispatcher.prepare!",
    "category": "method",
    "text": "prepare!(node::CollectNode)\n\nInitialize a CollectNode with a fresh result DeferredFuture.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.run!-Tuple{CollectNode}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "method",
    "text": "run!(node::CollectNode)\n\nCollect all of a CollectNode\'s dependencies\' results into a Vector and store that in this node\'s result field. Returns nothing.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.isready-Tuple{CollectNode}",
    "page": "API",
    "title": "Base.isready",
    "category": "method",
    "text": "isready(node::CollectNode) -> Bool\n\nDetermine whether a CollectNode has an available result.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.wait-Tuple{CollectNode}",
    "page": "API",
    "title": "Base.wait",
    "category": "method",
    "text": "wait(node::CollectNode)\n\nBlock until a CollectNode has an available result.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.fetch-Tuple{CollectNode}",
    "page": "API",
    "title": "Base.fetch",
    "category": "method",
    "text": "fetch(node::CollectNode) -> Vector\n\nReturn the result of the collection. Block until it is available.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.summary-Tuple{CollectNode}",
    "page": "API",
    "title": "Base.summary",
    "category": "method",
    "text": "summary(node::CollectNode)\n\nReturns a string representation of the CollectNode with its label.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#CollectNode-1",
    "page": "API",
    "title": "CollectNode",
    "category": "section",
    "text": "CollectNode\nCollectNode(::Vector{DispatchNode})\nget_label(::CollectNode)\nset_label!(::CollectNode, ::AbstractString)\nhas_label(::CollectNode)\ndependencies(::CollectNode)\nprepare!(::CollectNode)\nrun!(::CollectNode)\nisready(::CollectNode)\nwait(::CollectNode)\nfetch(::CollectNode)\nsummary(::CollectNode)"
},

{
    "location": "pages/api/#Graph-1",
    "page": "API",
    "title": "Graph",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api/#Dispatcher.DispatchGraph",
    "page": "API",
    "title": "Dispatcher.DispatchGraph",
    "category": "type",
    "text": "DispatchGraph wraps a directed graph from LightGraphs and a bidirectional dictionary mapping between DispatchNode instances and vertex numbers in the graph.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.nodes-Tuple{DispatchGraph}",
    "page": "API",
    "title": "Dispatcher.nodes",
    "category": "method",
    "text": "nodes(graph::DispatchGraph) ->\n\nReturn an iterable of all nodes stored in the DispatchGraph.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.length-Tuple{DispatchGraph}",
    "page": "API",
    "title": "Base.length",
    "category": "method",
    "text": "length(graph::DispatchGraph) -> Integer\n\nReturn the number of nodes in the graph.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.push!-Tuple{DispatchGraph,DispatchNode}",
    "page": "API",
    "title": "Base.push!",
    "category": "method",
    "text": "push!(graph::DispatchGraph, node::DispatchNode) -> DispatchGraph\n\nAdd a node to the graph and return the graph.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#LightGraphs.SimpleGraphs.add_edge!-Tuple{DispatchGraph,DispatchNode,DispatchNode}",
    "page": "API",
    "title": "LightGraphs.SimpleGraphs.add_edge!",
    "category": "method",
    "text": "add_edge!(graph::DispatchGraph, parent::DispatchNode, child::DispatchNode) -> Bool\n\nAdd an edge to the graph from parent to child. Return whether the operation was successful.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.:==-Tuple{DispatchGraph,DispatchGraph}",
    "page": "API",
    "title": "Base.:==",
    "category": "method",
    "text": "graph1::DispatchGraph == graph2::DispatchGraph\n\nDetermine whether two graphs have the same nodes and edges. This is an expensive operation.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#DispatchGraph-1",
    "page": "API",
    "title": "DispatchGraph",
    "category": "section",
    "text": "DispatchGraph\nnodes(::DispatchGraph)\nlength(::DispatchGraph)\npush!(::DispatchGraph, ::DispatchNode)\nadd_edge!(::DispatchGraph, ::DispatchNode, ::DispatchNode)\n==(::DispatchGraph, ::DispatchGraph)"
},

{
    "location": "pages/api/#Executors-1",
    "page": "API",
    "title": "Executors",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api/#Dispatcher.Executor",
    "page": "API",
    "title": "Dispatcher.Executor",
    "category": "type",
    "text": "An Executor handles execution of DispatchGraphs.\n\nA type T <: Executor must implement dispatch!(::T, ::DispatchNode) and may optionally implement dispatch!(::T, ::DispatchGraph; throw_error=true).\n\nThe function call tree will look like this when an executor is run:\n\nrun!(exec, context)\n    prepare!(exec, context)\n        prepare!(nodes[i])\n    dispatch!(exec, context)\n        dispatch!(exec, nodes[i])\n            run!(nodes[i])\n\nNOTE: Currently, it is expected that dispatch!(::T, ::DispatchNode) returns something to wait on (ie: Task, Future, Channel, DispatchNode, etc)\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.run!-Union{Tuple{S}, Tuple{T}, Tuple{Executor,AbstractArray{T,N} where N,AbstractArray{S,N} where N}} where S<:DispatchNode where T<:DispatchNode",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "method",
    "text": "run!(exec, output_nodes, input_nodes; input_map, throw_error) -> DispatchResult\n\nCreate a graph, ending in output_nodes, and using input_nodes/input_map to replace nodes with fixed values (and ignoring nodes for which all paths descend to input_nodes), then execute it.\n\nArguments\n\nexec::Executor: the executor which will execute the graph\ngraph::DispatchGraph: the graph which will be executed\noutput_nodes::AbstractArray{T<:DispatchNode}: the nodes whose results we are interested in\ninput_nodes::AbstractArray{T<:DispatchNode}: \"root\" nodes of the graph which will be replaced with their fetched values (dependencies of these nodes are not included in the graph)\n\nKeyword Arguments\n\ninput_map::Associative=Dict{DispatchNode, Any}(): dict keys are \"root\" nodes of the subgraph which will be replaced with the dict values (dependencies of these nodes are not included in the graph)\nthrow_error::Bool: whether to throw any DependencyErrors immediately (see dispatch!(::Executor, ::DispatchGraph) for more information)\n\nReturns\n\nVector{DispatchResult}: an array containing a DispatchResult for each node in output_nodes, in that order.\n\nThrows\n\nExecutorError: if the constructed graph contains a cycle\nCompositeException/DependencyError: see documentation for dispatch!(::Executor, ::DispatchGraph)\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.run!-Tuple{Executor,DispatchGraph}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "method",
    "text": "run!(exec::Executor, graph::DispatchGraph; kwargs...)\n\nThe run! function prepares a DispatchGraph for dispatch and then dispatches run!(::DispatchNode) calls for all nodes in its graph.\n\nUsers will almost never want to add methods to this function for different Executor subtypes; overriding dispatch!(::Executor, ::DispatchGraph) is the preferred pattern.\n\nReturn an array containing a Result{DispatchNode, DependencyError} for each leaf node.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.prepare!-Tuple{Executor,DispatchGraph}",
    "page": "API",
    "title": "Dispatcher.prepare!",
    "category": "method",
    "text": "prepare!(exec::Executor, graph::DispatchGraph)\n\nThis function prepares a context for execution. Call prepare!(::DispatchNode) on each node.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.dispatch!-Tuple{Executor,DispatchGraph}",
    "page": "API",
    "title": "Dispatcher.dispatch!",
    "category": "method",
    "text": "dispatch!(exec::Executor, graph::DispatchGraph; throw_error=true) -> Vector\n\nThe default dispatch! method uses asyncmap over all nodes in the context to call dispatch!(exec, node). These dispatch! calls for each node are wrapped in various retry and error handling methods.\n\nWrapping Details\n\nAll nodes are wrapped in a try catch which waits on the value returned from the dispatch!(exec, node) call. Any errors are caught and used to create DependencyErrors which are thrown. If no errors are produced then the node is returned.\nNOTE: All errors thrown by trying to run dispatch!(exec, node) are wrapped in a DependencyError.\nThe aformentioned wrapper function is used in a retry wrapper to rerun failed nodes (up to some limit). The wrapped function will only be retried iff the error produced by dispatch!(::Executor, ::DispatchNode) passes one of the retry functions specific to that Executor. By default the AsyncExecutor has no retry_on functions and the ParallelExecutor only has retry_on functions related to the loss of a worker process during execution.\nA node may enter a failed state if it exits the retry wrapper with an exception. This may occur if an exception is thrown while executing a node and it does not pass any of the retry_on conditions for the Executor or too many attempts to run the node have been made. In the situation where a node has entered a failed state and the node is an Op then the op.result is set to the DependencyError, signifying the node\'s failure to any dependent nodes. Finally, if throw_error is true then the DependencyError will be immediately thrown in the current process without allowing other nodes to finish. If throw_error is false then the DependencyError is not thrown and it will be returned in the array of passing and failing nodes.\n\nArguments\n\nexec::Executor: the executor we\'re running\ngraph::DispatchGraph: the context of nodes to run\n\nKeyword Arguments\n\nthrow_error::Bool=true: whether or not to throw the DependencyError for failed nodes\n\nReturns\n\nVector{Union{DispatchNode, DependencyError}}: a list of DispatchNodes or DependencyErrors for failed nodes\n\nThrows\n\ndispatch! has the same behaviour on exceptions as asyncmap and pmap. In 0.5 this will throw a CompositeException containing DependencyErrors, while in 0.6 this will simply throw the first DependencyError.\n\nUsage\n\nExample 1\n\nAssuming we have some uncaught application error:\n\nexec = AsyncExecutor()\nn1 = Op(() -> 3)\nn2 = Op(() -> 4)\nfailing_node = Op(() -> throw(ErrorException(\"ApplicationError\")))\ndep_node = Op(n -> println(n), failing_node)  # This node will fail as well\ngraph = DispatchGraph([n1, n2, failing_node, dep_node])\n\nThen dispatch!(exec, graph) will throw a DependencyError and dispatch!(exec, graph; throw_error=false) will return an array of passing nodes and the DependencyErrors (ie: [n1, n2, DependencyError(...), DependencyError(...)]).\n\nExample 2\n\nNow if we want to retry our node on certain errors we can do:\n\nexec = AsyncExecutor(5, [e -> isa(e, HttpError) && e.status == \"503\"])\nn1 = Op(() -> 3)\nn2 = Op(() -> 4)\nhttp_node = Op(() -> http_get(...))\ngraph = DispatchGraph([n1, n2, http_node])\n\nAssuming that the http_get function does not error 5 times the call to dispatch!(exec, graph) will return [n1, n2, httpnode]. If the `httpget` function either:\n\nfails with a different status code\nfails with something other than an HttpError or\nthrows an HttpError with status \"503\" more than 5 times\n\nthen we\'ll see the same failure behaviour as in the previous example.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.run_inner_node!-Tuple{Executor,DispatchNode,Int64}",
    "page": "API",
    "title": "Dispatcher.run_inner_node!",
    "category": "method",
    "text": "run_inner_node!(exec::Executor, node::DispatchNode, id::Int)\n\nRun the DispatchNode in the DispatchGraph at position id. Any error thrown during the node\'s execution is caught and wrapped in a DependencyError.\n\nTypical Executor implementations should not need to override this.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.retries-Tuple{Executor}",
    "page": "API",
    "title": "Dispatcher.retries",
    "category": "method",
    "text": "retries(exec::Executor) -> Int\n\nReturn the number of retries an executor should perform while attempting to run a node before giving up. The default retries method returns 0.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.retry_on-Tuple{Executor}",
    "page": "API",
    "title": "Dispatcher.retry_on",
    "category": "method",
    "text": "retry_on(exec::Executor) -> Vector{Function}\n\nReturn the vector of predicates which accept an Exception and return true if a node can and should be retried (and false otherwise). The default retry_on method returns Function[].\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Executor-1",
    "page": "API",
    "title": "Executor",
    "category": "section",
    "text": "Executor\nrun!{T<:DispatchNode, S<:DispatchNode}(exec::Executor, nodes::AbstractArray{T}, input_nodes::AbstractArray{S})\nrun!(::Executor, ::DispatchGraph)\nprepare!(::Executor, ::DispatchGraph)\ndispatch!(::Executor, ::DispatchGraph)\nDispatcher.run_inner_node!(::Executor, ::DispatchNode, ::Int)\nDispatcher.retries(::Executor)\nDispatcher.retry_on(::Executor)"
},

{
    "location": "pages/api/#Dispatcher.AsyncExecutor",
    "page": "API",
    "title": "Dispatcher.AsyncExecutor",
    "category": "type",
    "text": "AsyncExecutor is an Executor which schedules a local Julia Task for each DispatchNode and waits for them to complete. AsyncExecutor\'s dispatch!(::AsyncExecutor, ::DispatchNode) method will complete as long as each DispatchNode\'s run!(::DispatchNode) method completes and there are no cycles in the computation graph.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.AsyncExecutor-Tuple{}",
    "page": "API",
    "title": "Dispatcher.AsyncExecutor",
    "category": "method",
    "text": "AsyncExecutor(retries=5, retry_on::Vector{Function}=Function[]) -> AsyncExecutor\n\nretries is the number of times the executor is to retry a failed node. retry_on is a vector of predicates which accept an Exception and return true if a node can and should be retried (and false otherwise).\n\nReturn a new AsyncExecutor.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.dispatch!-Tuple{AsyncExecutor,DispatchNode}",
    "page": "API",
    "title": "Dispatcher.dispatch!",
    "category": "method",
    "text": "dispatch!(exec::AsyncExecutor, node::DispatchNode) -> Task\n\ndispatch! takes the AsyncExecutor and a DispatchNode to run. The run!(::DispatchNode) method on the node is called within a @async block and the resulting Task is returned. This is the defining method of AsyncExecutor.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.retries-Tuple{AsyncExecutor}",
    "page": "API",
    "title": "Dispatcher.retries",
    "category": "method",
    "text": "retries(exec::Executor) -> Int\n\nReturn the number of retries an executor should perform while attempting to run a node before giving up. The default retries method returns 0.\n\n\n\n\n\nretries(exec::Union{AsyncExecutor, ParallelExecutor}) -> Int\n\nReturn the number of retries per node.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.retry_on-Tuple{AsyncExecutor}",
    "page": "API",
    "title": "Dispatcher.retry_on",
    "category": "method",
    "text": "retry_on(exec::Executor) -> Vector{Function}\n\nReturn the vector of predicates which accept an Exception and return true if a node can and should be retried (and false otherwise). The default retry_on method returns Function[].\n\n\n\n\n\nretry_on(exec::Union{AsyncExecutor, ParallelExecutor}) -> Vector{Function}\n\nReturn the array of retry conditions.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#AsyncExecutor-1",
    "page": "API",
    "title": "AsyncExecutor",
    "category": "section",
    "text": "AsyncExecutor\nAsyncExecutor()\ndispatch!(::AsyncExecutor, node::DispatchNode)\nDispatcher.retries(::AsyncExecutor)\nDispatcher.retry_on(::AsyncExecutor)"
},

{
    "location": "pages/api/#Dispatcher.ParallelExecutor",
    "page": "API",
    "title": "Dispatcher.ParallelExecutor",
    "category": "type",
    "text": "ParallelExecutor is an Executor which creates a Julia Task for each DispatchNode, spawns each of those tasks on the processes available to Julia, and waits for them to complete. ParallelExecutor\'s dispatch!(::ParallelExecutor, ::DispatchGraph) method will complete as long as each DispatchNode\'s run!(::DispatchNode) method completes and there are no cycles in the computation graph.\n\nParallelExecutor(retries=5, retry_on::Vector{Function}=Function[]) -> ParallelExecutor\n\nretries is the number of times the executor is to retry a failed node. retry_on is a vector of predicates which accept an Exception and return true if a node can and should be retried (and false otherwise). Returns a new ParallelExecutor.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.dispatch!-Tuple{ParallelExecutor,DispatchNode}",
    "page": "API",
    "title": "Dispatcher.dispatch!",
    "category": "method",
    "text": "dispatch!(exec::ParallelExecutor, node::DispatchNode) -> Future\n\ndispatch! takes the ParallelExecutor and a DispatchNode to run. The run!(::DispatchNode) method on the node is called within an @spawn block and the resulting Future is returned. This is the defining method of ParallelExecutor.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.retries-Tuple{ParallelExecutor}",
    "page": "API",
    "title": "Dispatcher.retries",
    "category": "method",
    "text": "retries(exec::Executor) -> Int\n\nReturn the number of retries an executor should perform while attempting to run a node before giving up. The default retries method returns 0.\n\n\n\n\n\nretries(exec::Union{AsyncExecutor, ParallelExecutor}) -> Int\n\nReturn the number of retries per node.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Dispatcher.retry_on-Tuple{ParallelExecutor}",
    "page": "API",
    "title": "Dispatcher.retry_on",
    "category": "method",
    "text": "retry_on(exec::Executor) -> Vector{Function}\n\nReturn the vector of predicates which accept an Exception and return true if a node can and should be retried (and false otherwise). The default retry_on method returns Function[].\n\n\n\n\n\nretry_on(exec::Union{AsyncExecutor, ParallelExecutor}) -> Vector{Function}\n\nReturn the array of retry conditions.\n\n\n\n\n\n"
},

{
    "location": "pages/api/#ParallelExecutor-1",
    "page": "API",
    "title": "ParallelExecutor",
    "category": "section",
    "text": "ParallelExecutor\ndispatch!(::ParallelExecutor, node::DispatchNode)\nDispatcher.retries(::ParallelExecutor)\nDispatcher.retry_on(::ParallelExecutor)"
},

{
    "location": "pages/api/#Errors-1",
    "page": "API",
    "title": "Errors",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api/#Dispatcher.DependencyError",
    "page": "API",
    "title": "Dispatcher.DependencyError",
    "category": "type",
    "text": "DependencyError wraps any errors (and corresponding traceback) that occur on the dependency of a given nodes.\n\nThis is important for passing failure conditions to dependent nodes after a failed number of retries.\n\nNOTE: our trace field is a Union of Vector{Any} and StackTrace because we could be storing the traceback from a CompositeException (inside a RemoteException) which is of type Vector{Any}\n\n\n\n\n\n"
},

{
    "location": "pages/api/#Base.summary-Tuple{DependencyError}",
    "page": "API",
    "title": "Base.summary",
    "category": "method",
    "text": "summary(de::DependencyError)\n\nRetuns a string representation of the error with only the internal Exception type and the id\n\n\n\n\n\n"
},

{
    "location": "pages/api/#DependencyError-1",
    "page": "API",
    "title": "DependencyError",
    "category": "section",
    "text": "DependencyError\nsummary(::DependencyError)"
},

]}
