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
    "text": "How is Dispatcher different from ComputeFramework/Dagger?Dagger is built around distributing vectorized computations across large arrays. Dispatcher is built to deal with discrete, heterogeneous data using any Julia functions.How is Dispatcher different from Arbiter?Arbiter requires manually adding tasks and their dependencies and handling data passing. Dispatcher automatically identifies dependencies from user code and passes data efficiently between dependencies.Isn't this just DaskPretty much. The plan is to implement another Executor and integrate with the dask.distributed scheduler service to piggyback off of their great work.How does Dispatcher handle passing data?Dispatcher uses Julia RemoteChannels to pass data between dispatched DispatchNodes. For more information on how data transfer works with Julia's parallel tools see their documentation."
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
    "text": "Using Dispatcher, a DispatchContext maintains a computation graph of DispatchNodes. DispatchNodes represent units of computation that can be run. The most common DispatchNode is Op, which represents a function call on some arguments. Some of those arguments may exist when building the graph, and others may represent the results of other DispatchNodes. An Executor executes a whole DispatchContext. Two Executors are provided. AsyncExecutor executes computations asynchronously using Julia Tasks. ParallelExecutor executes computations in parallel using all available Julia processes (by calling @spawn).Here is an example defining and executing a graph:ctx = @dispatch_context begin\n    filenames = [\"mydata-$d.dat\" for d in 1:100]\n    data = [(@op load(filename)) for filename in filenames]\n\n    reference = @op load_from_sql(\"sql://mytable\")\n    processed = [(@op process(d, reference)) for d in data]\n\n    rolled = map(1:(length(processed) - 2)) do i\n        a = processed[i]\n        b = processed[i + 1]\n        c = processed[i + 2]\n        roll_result = @op roll(a, b, c)\n        return roll_result\n    end\n\n    compared = map(1:200) do i\n        a = rand(rolled)\n        b = rand(rolled)\n        compare_result = @op compare(a, b)\n        return compare_result\n    end\n\n    best = @op reduction(@node CollectNode(compared))\nend\n\nexecutor = ParallelExecutor()\n(run_best,) = run!(executor, ctx, [best])The components of this example will be discussed below. This example is based on a Dask example."
},

{
    "location": "pages/manual.html#Dispatch-Nodes-1",
    "page": "Manual",
    "title": "Dispatch Nodes",
    "category": "section",
    "text": "A DispatchNode generally represents a unit of computation that can be run. DispatchNodes are constructed when defining the graph and are run as part of graph execution. The @node macro takes a DispatchNode instance and adds it to the graph in the current context. The following code, where CollectNode <: DispatchNode:collection = @node CollectNode(compared)is equivalent to:collection = add!(ctx, CollectNode(compared))where ctx is the current dispatch context."
},

{
    "location": "pages/manual.html#Op-1",
    "page": "Manual",
    "title": "Op",
    "category": "section",
    "text": "An Op is a DispatchNode which represents some function call to be run as part of graph execution. This is the most common type of DispatchNode. The @op applies an extra transformation on top of the @node macro and deconstructs a function call to add to the graph. The following code:roll_result = @op roll(a, b, c)is equivalent to:roll_result = add!(ctx, Op(roll, a, b, c))where ctx is the current dispatch context. Note that code in the argument list gets evaluated immediately; only the function call is delayed."
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
    "text": "An Executor runs a DispatchContext. This package currently provides two Executors: AsyncExecutor and ParallelExecutor. They work the same way, except AsyncExecutor runs nodes using @async and ParallelExecutor uses @spawn.This call:(run_best,) = run!(executor, ctx, [best])takes an Executor, a DispatchContext, and a Vector{DispatchNode}, runs those nodes and all of their ancestors, and returns a collection of DispatchResults (in this case containing only the DispatchResult for best). A DispatchResult is a ResultType containing either a DispatchNode or a DependencyError (an error that occurred when attempting to satisfy the requirements for running that node).It is also possible to feed in inputs in place of nodes in the graph; see run! for more."
},

{
    "location": "pages/manual.html#Further-Reading-1",
    "page": "Manual",
    "title": "Further Reading",
    "category": "section",
    "text": "Check out the API for more information."
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
    "location": "pages/api.html#Dispatcher.get_label-Tuple{T<:Dispatcher.DispatchNode}",
    "page": "API",
    "title": "Dispatcher.get_label",
    "category": "Method",
    "text": "get_label(node::DispatchNode) -> String\n\nReturns a node's label. By default, DispatchNodes do not support labels, so this method will error.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.set_label!-Tuple{T<:Dispatcher.DispatchNode,Any}",
    "page": "API",
    "title": "Dispatcher.set_label!",
    "category": "Method",
    "text": "set_label!(node::DispatchNode, label)\n\nSets a node's label. By default, DispatchNodes do not support labels, so this method will error. Actual method implementations should return their second argument.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.has_label-Tuple{Dispatcher.DispatchNode}",
    "page": "API",
    "title": "Dispatcher.has_label",
    "category": "Method",
    "text": "has_label(node::DispatchNode) -> Bool\n\nReturns true or false as to whether the node has a label (ie: a get_label(::DispatchNode) method)\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.dependencies-Tuple{Dispatcher.DispatchNode}",
    "page": "API",
    "title": "Dispatcher.dependencies",
    "category": "Method",
    "text": "dependencies(node::DispatchNode) -> Tuple{Vararg{DispatchNode}}\n\nReturn all dependencies which must be ready before executing this node. Unless given a dependencies method, a DispatchNode will be assumed to have no dependencies.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.prepare!-Tuple{Dispatcher.DispatchNode}",
    "page": "API",
    "title": "Dispatcher.prepare!",
    "category": "Method",
    "text": "prepare!(node::DispatchNode)\n\nExecute some action on a node before dispatching nodes via an Executor. The default method performs no action.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.run!-Tuple{Dispatcher.DispatchNode}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "Method",
    "text": "run!(node::DispatchNode)\n\nExecute a node's action as part of dispatch. The default method performs no action.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.isready-Tuple{Dispatcher.DispatchNode}",
    "page": "API",
    "title": "Base.isready",
    "category": "Method",
    "text": "isready(node::DispatchNode) -> Bool\n\nDetermine whether a node has an available result. The default method assumes no synchronization is involved in retrieving that result.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.wait-Tuple{Dispatcher.DispatchNode}",
    "page": "API",
    "title": "Base.wait",
    "category": "Method",
    "text": "wait(node::DispatchNode)\n\nBlock the current task until a node has a result available.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.fetch-Tuple{T<:Dispatcher.DispatchNode}",
    "page": "API",
    "title": "Base.fetch",
    "category": "Method",
    "text": "fetch(node::DispatchNode) -> Any\n\nFetch a node's result if available, blocking until it is available. All subtypes of DispatchNode should implement this, so the default method throws an error.\n\n\n\n"
},

{
    "location": "pages/api.html#DispatchNode-1",
    "page": "API",
    "title": "DispatchNode",
    "category": "section",
    "text": "DispatchNode\nget_label{T<:DispatchNode}(::T)\nset_label!{T<:DispatchNode}(::T, ::Any)\nhas_label(::DispatchNode)\ndependencies(::DispatchNode)\nprepare!(::DispatchNode)\nrun!(::DispatchNode)\nisready(::DispatchNode)\nwait(::DispatchNode)\nfetch{T<:DispatchNode}(::T)"
},

{
    "location": "pages/api.html#Dispatcher.Op",
    "page": "API",
    "title": "Dispatcher.Op",
    "category": "Type",
    "text": "An Op is a DispatchNode which wraps a function which is executed when the Op is run. The result of that function call is stored in the result DeferredFuture. Any DispatchNodes which appear in the args or kwargs values will be noted as dependencies. This is the most common DispatchNode.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.Op-Tuple{Function}",
    "page": "API",
    "title": "Dispatcher.Op",
    "category": "Method",
    "text": "Op(func::Function, args...; kwargs...) -> Op\n\nConstruct an Op which represents the delayed computation of func(args...; kwargs). Any DispatchNodes which appear in the args or kwargs values will be noted as dependencies. The default label of an Op is the name of func.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.get_label-Tuple{Dispatcher.Op}",
    "page": "API",
    "title": "Dispatcher.get_label",
    "category": "Method",
    "text": "get_label(op::Op) -> String\n\nReturns the op.label.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.set_label!-Tuple{Dispatcher.Op,AbstractString}",
    "page": "API",
    "title": "Dispatcher.set_label!",
    "category": "Method",
    "text": "set_label!(op::Op, label::AbstractString)\n\nSet the op's label. Returns its second argument.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.has_label-Tuple{Dispatcher.Op}",
    "page": "API",
    "title": "Dispatcher.has_label",
    "category": "Method",
    "text": "has_label(::Op) -> Bool\n\nAlways return true as an Op will always have a label.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.dependencies-Tuple{Dispatcher.Op}",
    "page": "API",
    "title": "Dispatcher.dependencies",
    "category": "Method",
    "text": "dependencies(op::Op) -> Tuple{Verarg{DispatchNode}}\n\nReturn all dependencies which must be ready before executing this Op. This will be all DispatchNodes in the Op's function args and kwargs.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.prepare!-Tuple{Dispatcher.Op}",
    "page": "API",
    "title": "Dispatcher.prepare!",
    "category": "Method",
    "text": "prepare!(op::Op)\n\nReplace an Op's result field with a fresh, empty one.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.run!-Tuple{Dispatcher.Op}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "Method",
    "text": "run!(op::Op)\n\nFetch an Op's dependencies and execute its function. Store the result in its result::DeferredFuture field.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.isready-Tuple{Dispatcher.Op}",
    "page": "API",
    "title": "Base.isready",
    "category": "Method",
    "text": "isready(op::Op) -> Bool\n\nDetermine whether an Op has an available result.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.wait-Tuple{Dispatcher.Op}",
    "page": "API",
    "title": "Base.wait",
    "category": "Method",
    "text": "wait(op::Op)\n\nWait until an Op has an available result.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.fetch-Tuple{Dispatcher.Op}",
    "page": "API",
    "title": "Base.fetch",
    "category": "Method",
    "text": "fetch(op::Op) -> Any\n\nReturn the result of the Op. Block until it is available. Throw DependencyError in the event that the result is a DependencyError.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.summary-Tuple{Dispatcher.Op}",
    "page": "API",
    "title": "Base.summary",
    "category": "Method",
    "text": "summary(op::Op)\n\nReturns a string representation of the Op with its label and the args/kwargs types.\n\nNOTE: if an arg/kwarg is a DispatchNode with a label it will be printed with that arg.\n\n\n\n"
},

{
    "location": "pages/api.html#Op-1",
    "page": "API",
    "title": "Op",
    "category": "section",
    "text": "Op\nOp(::Function)\nget_label(::Op)\nset_label!(::Op, ::AbstractString)\nhas_label(::Op)\ndependencies(::Op)\nprepare!(::Op)\nrun!(::Op)\nisready(::Op)\nwait(::Op)\nfetch(::Op)\nsummary(::Op)"
},

{
    "location": "pages/api.html#Dispatcher.DataNode",
    "page": "API",
    "title": "Dispatcher.DataNode",
    "category": "Type",
    "text": "A DataNode is a DispatchNode which wraps a piece of static data.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.fetch-Tuple{Dispatcher.DataNode}",
    "page": "API",
    "title": "Base.fetch",
    "category": "Method",
    "text": "fetch{T}(node::DataNode{T}) -> T\n\nImmediately return the data contained in a DataNode.\n\n\n\n"
},

{
    "location": "pages/api.html#DataNode-1",
    "page": "API",
    "title": "DataNode",
    "category": "section",
    "text": "DataNode\nfetch(::DataNode)"
},

{
    "location": "pages/api.html#Dispatcher.IndexNode",
    "page": "API",
    "title": "Dispatcher.IndexNode",
    "category": "Type",
    "text": "An IndexNode refers to an element of the return value of a DispatchNode. It is meant to handle multiple return values from a DispatchNode.\n\nExample:\n\nn1, n2 = add!(ctx, Op(()->divrem(5, 2)))\nrun(exec, ctx)\n\n@assert fetch(n1) == 2\n@assert fetch(n2) == 1\n\nIn this example, n1 and n2 are created as IndexNodes pointing to the Op at index 1 and index 2 respectively.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.IndexNode-Tuple{Dispatcher.DispatchNode,Int64}",
    "page": "API",
    "title": "Dispatcher.IndexNode",
    "category": "Method",
    "text": "IndexNode(node::DispatchNode, index) -> IndexNode\n\nCreate a new IndexNode referring to the result of node at index.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.dependencies-Tuple{Dispatcher.IndexNode}",
    "page": "API",
    "title": "Dispatcher.dependencies",
    "category": "Method",
    "text": "dependencies(node::IndexNode) -> Tuple{DispatchNode}\n\nReturn the dependency that this node will fetch data (at a certain index) from.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.prepare!-Tuple{Dispatcher.IndexNode}",
    "page": "API",
    "title": "Dispatcher.prepare!",
    "category": "Method",
    "text": "prepare!(node::IndexNode)\n\nReplace an IndexNode's result field with a fresh, empty one.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.run!-Tuple{Dispatcher.IndexNode}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "Method",
    "text": "run!(node::IndexNode) -> DeferredFuture\n\nFetch data from the IndexNode's parent at the IndexNode's index, performing the indexing operation on the process where the data lives. Store the data from that index in a DeferredFuture in the IndexNode.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.run!-Tuple{Dispatcher.IndexNode{T<:Union{Dispatcher.IndexNode,Dispatcher.Op}}}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "Method",
    "text": "run!(node::IndexNode) -> DeferredFuture\n\nFetch data from the IndexNode's parent at the IndexNode's index, performing the indexing operation on the process where the data lives. Store the data from that index in a DeferredFuture in the IndexNode.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.isready-Tuple{Dispatcher.IndexNode}",
    "page": "API",
    "title": "Base.isready",
    "category": "Method",
    "text": "isready(node::IndexNode) -> Bool\n\nDetermine whether an IndexNode has an available result.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.wait-Tuple{Dispatcher.IndexNode}",
    "page": "API",
    "title": "Base.wait",
    "category": "Method",
    "text": "wait(node::IndexNode)\n\nWait until an IndexNode has an available result.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.fetch-Tuple{Dispatcher.IndexNode}",
    "page": "API",
    "title": "Base.fetch",
    "category": "Method",
    "text": "fetch(node::IndexNode) -> Any\n\nReturn the stored result of indexing.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.summary-Tuple{Dispatcher.IndexNode}",
    "page": "API",
    "title": "Base.summary",
    "category": "Method",
    "text": "summary(node::IndexNode)\n\nReturns a string representation of the IndexNode with a summary of the wrapped node and the node index.\n\n\n\n"
},

{
    "location": "pages/api.html#IndexNode-1",
    "page": "API",
    "title": "IndexNode",
    "category": "section",
    "text": "IndexNode\nIndexNode(::DispatchNode, ::Int)\ndependencies(::IndexNode)\nprepare!(::IndexNode)\nrun!(::IndexNode)\nrun!{T<:Union{Op, IndexNode}}(::IndexNode{T})\nisready(::IndexNode)\nwait(::IndexNode)\nfetch(::IndexNode)\nsummary(::IndexNode)"
},

{
    "location": "pages/api.html#Dispatcher.CollectNode",
    "page": "API",
    "title": "Dispatcher.CollectNode",
    "category": "Type",
    "text": "CollectNode{T<:DispatchNode}(nodes::Vector{T}) -> CollectNode{T}\n\nCreate a node which gathers an array of nodes and stores an array of their results in its result field.\n\n\n\nCollectNode(nodes) -> CollectNode{DispatchNode}\n\nCreate a CollectNode from any iterable of nodes.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.CollectNode-Tuple{Array{Dispatcher.DispatchNode,1}}",
    "page": "API",
    "title": "Dispatcher.CollectNode",
    "category": "Method",
    "text": "CollectNode{T<:DispatchNode}(nodes::Vector{T}) -> CollectNode{T}\n\nCreate a node which gathers an array of nodes and stores an array of their results in its result field.\n\n\n\nCollectNode(nodes) -> CollectNode{DispatchNode}\n\nCreate a CollectNode from any iterable of nodes.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.get_label-Tuple{Dispatcher.CollectNode}",
    "page": "API",
    "title": "Dispatcher.get_label",
    "category": "Method",
    "text": "get_label(node::CollectNode) -> String\n\nReturns the node.label.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.set_label!-Tuple{Dispatcher.CollectNode,AbstractString}",
    "page": "API",
    "title": "Dispatcher.set_label!",
    "category": "Method",
    "text": "set_label!(node::CollectNode, label::AbstractString) -> AbstractString\n\nSet the node's label. Returns its second argument.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.has_label-Tuple{Dispatcher.CollectNode}",
    "page": "API",
    "title": "Dispatcher.has_label",
    "category": "Method",
    "text": "has_label(::CollectNode) -> Bool\n\nAlways return true as a CollectNode will always have a label.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.dependencies-Tuple{Dispatcher.CollectNode}",
    "page": "API",
    "title": "Dispatcher.dependencies",
    "category": "Method",
    "text": "dependencies{T<:DispatchNode}(node::CollectNode{T}) -> Vector{T}\n\nReturn the nodes this depends on which this node will collect.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.prepare!-Tuple{Dispatcher.CollectNode}",
    "page": "API",
    "title": "Dispatcher.prepare!",
    "category": "Method",
    "text": "prepare!(node::CollectNode)\n\nInitialize a CollectNode with a fresh result DeferredFuture.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.run!-Tuple{Dispatcher.CollectNode}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "Method",
    "text": "run!(node::CollectNode)\n\nCollect all of a CollectNode's dependencies' results into a Vector and store that in this node's result field. Returns nothing.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.isready-Tuple{Dispatcher.CollectNode}",
    "page": "API",
    "title": "Base.isready",
    "category": "Method",
    "text": "isready(node::CollectNode) -> Bool\n\nDetermine whether a CollectNode has an available result.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.wait-Tuple{Dispatcher.CollectNode}",
    "page": "API",
    "title": "Base.wait",
    "category": "Method",
    "text": "wait(node::CollectNode)\n\nBlock until a CollectNode has an available result.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.fetch-Tuple{Dispatcher.CollectNode}",
    "page": "API",
    "title": "Base.fetch",
    "category": "Method",
    "text": "fetch(node::CollectNode) -> Vector\n\nReturn the result of the collection. Block until it is available.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.summary-Tuple{Dispatcher.CollectNode}",
    "page": "API",
    "title": "Base.summary",
    "category": "Method",
    "text": "summary(node::CollectNode)\n\nReturns a string representation of the CollectNode with its label.\n\n\n\n"
},

{
    "location": "pages/api.html#CollectNode-1",
    "page": "API",
    "title": "CollectNode",
    "category": "section",
    "text": "CollectNode\nCollectNode(::Vector{DispatchNode})\nget_label(::CollectNode)\nset_label!(::CollectNode, ::AbstractString)\nhas_label(::CollectNode)\ndependencies(::CollectNode)\nprepare!(::CollectNode)\nrun!(::CollectNode)\nisready(::CollectNode)\nwait(::CollectNode)\nfetch(::CollectNode)\nsummary(::CollectNode)"
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
    "location": "pages/api.html#Dispatcher.nodes-Tuple{Dispatcher.DispatchGraph}",
    "page": "API",
    "title": "Dispatcher.nodes",
    "category": "Method",
    "text": "nodes(graph::DispatchGraph) ->\n\nReturn an iterable of all nodes stored in the DispatchGraph.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.length-Tuple{Dispatcher.DispatchGraph}",
    "page": "API",
    "title": "Base.length",
    "category": "Method",
    "text": "length(graph::DispatchGraph) -> Integer\n\nReturn the number of nodes in the graph.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.push!-Tuple{Dispatcher.DispatchGraph,Dispatcher.DispatchNode}",
    "page": "API",
    "title": "Base.push!",
    "category": "Method",
    "text": "push!(graph::DispatchGraph, node::DispatchNode) -> DispatchGraph\n\nAdd a node to the graph and return the graph.\n\n\n\n"
},

{
    "location": "pages/api.html#LightGraphs.add_edge!-Tuple{Dispatcher.DispatchGraph,Dispatcher.DispatchNode,Dispatcher.DispatchNode}",
    "page": "API",
    "title": "LightGraphs.add_edge!",
    "category": "Method",
    "text": "add_edge!(graph::DispatchGraph, parent::DispatchNode, child::DispatchNode) -> Bool\n\nAdd an edge to the graph from parent to child. Return whether the operation was successful.\n\n\n\n"
},

{
    "location": "pages/api.html#Base.:==-Tuple{Dispatcher.DispatchGraph,Dispatcher.DispatchGraph}",
    "page": "API",
    "title": "Base.:==",
    "category": "Method",
    "text": "graph1::DispatchGraph == graph2::DispatchGraph\n\nDetermine whether two graphs have the same nodes and edges. This is an expensive operation.\n\n\n\n"
},

{
    "location": "pages/api.html#DispatchGraph-1",
    "page": "API",
    "title": "DispatchGraph",
    "category": "section",
    "text": "DispatchGraph\nnodes(::DispatchGraph)\nlength(::DispatchGraph)\npush!(::DispatchGraph, ::DispatchNode)\nadd_edge!(::DispatchGraph, ::DispatchNode, ::DispatchNode)\n==(::DispatchGraph, ::DispatchGraph)"
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
    "location": "pages/api.html#Dispatcher.nodes-Tuple{Dispatcher.DispatchContext}",
    "page": "API",
    "title": "Dispatcher.nodes",
    "category": "Method",
    "text": "nodes(ctx::DispatchContext)\n\nReturn an iterable of all nodes stored in the DispatchContext's graph.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.add!",
    "page": "API",
    "title": "Dispatcher.add!",
    "category": "Function",
    "text": "add!(ctx::DispatchContext, node::DispatchNode) -> DispatchNode\n\nAdd a DispatchNode to the DispatchContext's graph and record its dependencies in the graph.\n\nReturn the DispatchNode which was added.\n\n\n\n"
},

{
    "location": "pages/api.html#DispatchContext-1",
    "page": "API",
    "title": "DispatchContext",
    "category": "section",
    "text": "DispatchContext\nnodes(::DispatchContext)\nadd!"
},

{
    "location": "pages/api.html#Dispatcher.@dispatch_context",
    "page": "API",
    "title": "Dispatcher.@dispatch_context",
    "category": "Macro",
    "text": "@dispatch_context begin ... end\n\nAnonymously create and return a DispatchContext. Accepts a block argument and causes all @op and @node macros within that block to use said DispatchContext.\n\nSee examples in the Manual.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.@node",
    "page": "API",
    "title": "Dispatcher.@node",
    "category": "Macro",
    "text": "@node Node(...)\n\nThe @node macro makes it more convenient to add nodes to the computation graph while in a @dispatch_context block.\n\na = @node DataNode([1, 3, 5])\n\nis equivalent to\n\na = add!(ctx, DataNode([1, 3, 5]))\n\nwhere ctx is a variable created by the surrounding @dispatch_context.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.@op",
    "page": "API",
    "title": "Dispatcher.@op",
    "category": "Macro",
    "text": "@op func(...)\n\nThe @op macro makes it more convenient to add Op nodes to the computation graph while in a @dispatch_context block. It translates a function call into an Op call, effectively deferring the computation.\n\na = @op sort(1:10; rev=true)\n\nis equivalent to\n\na = add!(ctx, Op(sort, 1:10; rev=true))\n\nwhere ctx is a variable created by the surrounding @dispatch_context.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.@component",
    "page": "API",
    "title": "Dispatcher.@component",
    "category": "Macro",
    "text": "@component function ... end\n\nTranslate a function definition so that its first argument is a DispatchContext and cause all @op and @node macros within the function to use said DispatchContext.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.@include",
    "page": "API",
    "title": "Dispatcher.@include",
    "category": "Macro",
    "text": "@include component_function(...)\n\nThe @include macro makes it more convenient to splice component subgraphs into the computation graph while in a @dispatch_context block.\n\na = @include sort(1:10; rev=true)\n\nis equivalent to\n\na = sort(ctx, 1:10; rev=true)\n\nwhere ctx is a variable created by the surrounding @dispatch_context.\n\nUsually, these component functions are created using a @component annotation.\n\n\n\n"
},

{
    "location": "pages/api.html#Macros-1",
    "page": "API",
    "title": "Macros",
    "category": "section",
    "text": "@dispatch_context\n@node\n@op\n@component\n@include"
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
    "location": "pages/api.html#Dispatcher.run!-Tuple{Dispatcher.Executor,Dispatcher.DispatchContext,AbstractArray{T<:Dispatcher.DispatchNode,N},AbstractArray{S<:Dispatcher.DispatchNode,N}}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "Method",
    "text": "run!(exec, ctx, nodes, input_nodes; input_map, throw_error) -> DispatchResult\n\nRun a subset of a graph, ending in nodes, and using input_nodes/input_map to replace nodes with fixed values (and ignoring nodes for which all paths descend to input_nodes).\n\nArguments\n\nexec::Executor: the executor which will execute this context\nctx::DispatchContext: the context which will be executed\nnodes::AbstractArray{T<:DispatchNode}: the nodes whose results we are interested in\ninput_nodes::AbstractArray{T<:DispatchNode}: \"root\" nodes of the subgraph which will be replaced with their fetched values\n\nKeyword Arguments\n\ninput_map::Associative=Dict{DispatchNode, Any}(): dict keys are \"root\" nodes of the subgraph which will be replaced with the dict values\nthrow_error::Bool: whether to throw any DependencyErrors immediately (see dispatch!(::Executor, ::DispatchContext) for more information)\n\nReturns\n\nVector{DispatchResult}: an array containing a DispatchResult for each node in nodes, in that order.\n\nThrows\n\nExecutorError: if the context's graph contains a cycle\nCompositeException/DependencyError: see documentation for dispatch!(::Executor, ::DispatchContext)\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.run!-Tuple{Dispatcher.Executor,Dispatcher.DispatchContext}",
    "page": "API",
    "title": "Dispatcher.run!",
    "category": "Method",
    "text": "run!(exec::Executor, ctx::DispatchContext; kwargs...)\n\nThe run! function prepares a DispatchContext for dispatch and then dispatches run!(::DispatchNode) calls for all nodes in its graph.\n\nUsers will almost never want to add methods to this function for different Executor subtypes; overriding dispatch!(::Executor, ::DispatchContext) is the preferred pattern.\n\nReturn an array containing a Result{DispatchNode, DependencyError} for each leaf node.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.prepare!-Tuple{Dispatcher.Executor,Dispatcher.DispatchContext}",
    "page": "API",
    "title": "Dispatcher.prepare!",
    "category": "Method",
    "text": "prepare!(exec::Executor, ctx::DispatchContext)\n\nThis function prepares a context for execution. Call prepare!(::DispatchNode) on each node.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.dispatch!-Tuple{Dispatcher.Executor,Dispatcher.DispatchContext}",
    "page": "API",
    "title": "Dispatcher.dispatch!",
    "category": "Method",
    "text": "dispatch!(exec::Executor, ctx::DispatchContext; throw_error=true) -> Vector\n\nThe default dispatch! method uses asyncmap over all nodes in the context to call dispatch!(exec, node). These dispatch! calls for each node are wrapped in various retry and error handling methods.\n\nWrapping Details\n\nAll nodes are wrapped in a try catch which waits on the value returned from the dispatch!(exec, node) call. Any errors are caught and used to create DependencyErrors which are thrown. If no errors are produced then the node is returned.\nNOTE: All errors thrown by trying to run dispatch!(exec, node) are wrapped in a DependencyError.\nThe aformentioned wrapper function is used in a retry wrapper to rerun failed nodes (up to some limit). The wrapped function will only be retried iff the error produced by dispatch!(::Executor, ::DispatchNode) passes one of the retry functions specific to that Executor. By default the AsyncExecutor has no retry_on functions and the ParallelExecutor only has retry_on functions related to the loss of a worker process during execution.\nA node may enter a failed state if it exits the retry wrapper with an exception. This may occur if an exception is thrown while executing a node and it does not pass any of the retry_on conditions for the Executor or too many attempts to run the node have been made. In the situation where a node has entered a failed state and the node is an Op then the op.result is set to the DependencyError, signifying the node's failure to any dependent nodes. Finally, if throw_error is true then the DependencyError will be immediately thrown in the current process without allowing other nodes to finish. If throw_error is false then the DependencyError is not thrown and it will be returned in the array of passing and failing nodes.\n\nArguments\n\nexec::Executor: the executor we're running\nctx::DispatchContext: the context of nodes to run\n\nKeyword Arguments\n\nthrow_error::Bool=true: whether or not to throw the DependencyError for failed nodes\n\nReturns\n\nVector{Union{DispatchNode, DependencyError}}: a list of DispatchNodes or DependencyErrors for failed nodes\n\nThrows\n\ndispatch! has the same behaviour on exceptions as asyncmap and pmap. In 0.5 this will throw a CompositeException containing DependencyErrors, while in 0.6 this will simply throw the first DependencyError.\n\nUsage\n\nExample 1\n\nAssuming we have some uncaught application error:\n\nexec = AsyncExecutor()\nctx = DispatchContext()\nn1 = add!(ctx, Op()->3)\nn2 = add!(ctx, Op()->4)\nfailing_node = add!(ctx, Op(()->throw(ErrorException(\"ApplicationError\"))))\ndep_node = add!(n -> println(n), failing_node)  # This will fail as well\n\nThen dispatch!(exec, ctx) will throw a DependencyError and dispatch!(exec, ctx; throw_error=false) will return an array of passing nodes and the DependencyErrors (ie: [n1, n2, DependencyError(...), DependencyError(...)]).\n\nExample 2\n\nNow if we want to retry our node on certain errors we can do:\n\nexec = AsyncExecutor(5, [e -> isa(e, HttpError) && e.status == \"503\"])\nctx = DispatchContext()\nn1 = add!(ctx, Op()->3)\nn2 = add!(ctx, Op()->4)\nhttp_node = add!(ctx, Op(()->http_get(...)))\n\nAssuming that the http_get function does not error 5 times the call to dispatch!(exec, ctx) will return [n1, n2, http_node]. If the http_get function either:\n\nfails with a different status code\nfails with something other than an HttpError or\nthrows an HttpError with status \"503\" more than 5 times\n\nthen we'll see the same failure behaviour as in the previous example.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.retries-Tuple{Dispatcher.Executor}",
    "page": "API",
    "title": "Dispatcher.retries",
    "category": "Method",
    "text": "retries(exec::Executor) -> Int\n\nReturn the number of retries an executor should perform while attempting to run a node before giving up. The default retries method returns 0.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.retry_on-Tuple{Dispatcher.Executor}",
    "page": "API",
    "title": "Dispatcher.retry_on",
    "category": "Method",
    "text": "retry_on(exec::Executor) -> Vector{Function}\n\nReturn the vector of predicates which accept an Exception and return true if a node can and should be retried (and false otherwise). The default retry_on method returns Function[].\n\n\n\n"
},

{
    "location": "pages/api.html#Executor-1",
    "page": "API",
    "title": "Executor",
    "category": "section",
    "text": "Executor\nrun!{T<:DispatchNode, S<:DispatchNode}(exec::Executor, ctx::DispatchContext, nodes::AbstractArray{T}, input_nodes::AbstractArray{S})\nrun!(::Executor, ::DispatchContext)\nprepare!(::Executor, ::DispatchContext)\ndispatch!(::Executor, ::DispatchContext)\nDispatcher.retries(::Executor)\nDispatcher.retry_on(::Executor)"
},

{
    "location": "pages/api.html#Dispatcher.AsyncExecutor",
    "page": "API",
    "title": "Dispatcher.AsyncExecutor",
    "category": "Type",
    "text": "AsyncExecutor is an Executor which schedules a local Julia Task for each DispatchNode and waits for them to complete. AsyncExecutor's dispatch!(::AsyncExecutor, ::DispatchNode) method will complete as long as each DispatchNode's run!(::DispatchNode) method completes and there are no cycles in the computation graph.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.AsyncExecutor-Tuple{}",
    "page": "API",
    "title": "Dispatcher.AsyncExecutor",
    "category": "Method",
    "text": "AsyncExecutor(retries=5, retry_on::Vector{Function}=Function[]) -> AsyncExecutor\n\nretries is the number of times the executor is to retry a failed node. retry_on is a vector of predicates which accept an Exception and return true if a node can and should be retried (and false otherwise).\n\nReturn a new AsyncExecutor.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.dispatch!-Tuple{Dispatcher.AsyncExecutor,Dispatcher.DispatchNode}",
    "page": "API",
    "title": "Dispatcher.dispatch!",
    "category": "Method",
    "text": "dispatch!(exec::AsyncExecutor, node::DispatchNode) -> Task\n\ndispatch! takes the AsyncExecutor and a DispatchNode to run. The run!(::DispatchNode) method on the node is called within an @async block and the resulting Task is returned. This is the defining method of AsyncExecutor.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.retries-Tuple{Dispatcher.AsyncExecutor}",
    "page": "API",
    "title": "Dispatcher.retries",
    "category": "Method",
    "text": "retries(exec::Executor) -> Int\n\nReturn the number of retries an executor should perform while attempting to run a node before giving up. The default retries method returns 0.\n\n\n\nretries(exec::Union{AsyncExecutor, ParallelExecutor}) -> Int\n\nReturn the number of retries per node.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.retry_on-Tuple{Dispatcher.AsyncExecutor}",
    "page": "API",
    "title": "Dispatcher.retry_on",
    "category": "Method",
    "text": "retry_on(exec::Executor) -> Vector{Function}\n\nReturn the vector of predicates which accept an Exception and return true if a node can and should be retried (and false otherwise). The default retry_on method returns Function[].\n\n\n\nretry_on(exec::Union{AsyncExecutor, ParallelExecutor}) -> Vector{Function}\n\nReturn the array of retry conditions.\n\n\n\n"
},

{
    "location": "pages/api.html#AsyncExecutor-1",
    "page": "API",
    "title": "AsyncExecutor",
    "category": "section",
    "text": "AsyncExecutor\nAsyncExecutor()\ndispatch!(::AsyncExecutor, node::DispatchNode)\nDispatcher.retries(::AsyncExecutor)\nDispatcher.retry_on(::AsyncExecutor)"
},

{
    "location": "pages/api.html#Dispatcher.ParallelExecutor",
    "page": "API",
    "title": "Dispatcher.ParallelExecutor",
    "category": "Type",
    "text": "ParallelExecutor is an Executor which creates a Julia Task for each DispatchNode, spawns each of those tasks on the processes available to Julia, and waits for them to complete. ParallelExecutor's dispatch!(::ParallelExecutor, ::DispatchContext) method will complete as long as each DispatchNode's run!(::DispatchNode) method completes and there are no cycles in the computation graph.\n\nParallelExecutor(retries=5, retry_on::Vector{Function}=Function[]) -> ParallelExecutor\n\nretries is the number of times the executor is to retry a failed node. retry_on is a vector of predicates which accept an Exception and return true if a node can and should be retried (and false otherwise). Returns a new ParallelExecutor.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.dispatch!-Tuple{Dispatcher.ParallelExecutor,Dispatcher.DispatchNode}",
    "page": "API",
    "title": "Dispatcher.dispatch!",
    "category": "Method",
    "text": "dispatch!(exec::ParallelExecutor, node::DispatchNode) -> Future\n\ndispatch! takes the ParallelExecutor and a DispatchNode to run. The run!(::DispatchNode) method on the node is called within an @spawn block and the resulting Future is returned. This is the defining method of ParallelExecutor.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.retries-Tuple{Dispatcher.ParallelExecutor}",
    "page": "API",
    "title": "Dispatcher.retries",
    "category": "Method",
    "text": "retries(exec::Executor) -> Int\n\nReturn the number of retries an executor should perform while attempting to run a node before giving up. The default retries method returns 0.\n\n\n\nretries(exec::Union{AsyncExecutor, ParallelExecutor}) -> Int\n\nReturn the number of retries per node.\n\n\n\n"
},

{
    "location": "pages/api.html#Dispatcher.retry_on-Tuple{Dispatcher.ParallelExecutor}",
    "page": "API",
    "title": "Dispatcher.retry_on",
    "category": "Method",
    "text": "retry_on(exec::Executor) -> Vector{Function}\n\nReturn the vector of predicates which accept an Exception and return true if a node can and should be retried (and false otherwise). The default retry_on method returns Function[].\n\n\n\nretry_on(exec::Union{AsyncExecutor, ParallelExecutor}) -> Vector{Function}\n\nReturn the array of retry conditions.\n\n\n\n"
},

{
    "location": "pages/api.html#ParallelExecutor-1",
    "page": "API",
    "title": "ParallelExecutor",
    "category": "section",
    "text": "ParallelExecutor\ndispatch!(::ParallelExecutor, node::DispatchNode)\nDispatcher.retries(::ParallelExecutor)\nDispatcher.retry_on(::ParallelExecutor)"
},

{
    "location": "pages/api.html#Errors-1",
    "page": "API",
    "title": "Errors",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api.html#Dispatcher.DependencyError",
    "page": "API",
    "title": "Dispatcher.DependencyError",
    "category": "Type",
    "text": "DependencyError wraps any errors (and corresponding traceback) that occur on the dependency of a given nodes.\n\nThis is important for passing failure conditions to dependent nodes after a failed number of retries.\n\nNOTE: our trace field is a Union of Vector{Any} and StackTrace because we could be storing the traceback from a CompositeException (inside a RemoteException) which is of type Vector{Any}\n\n\n\n"
},

{
    "location": "pages/api.html#Base.summary-Tuple{Dispatcher.DependencyError}",
    "page": "API",
    "title": "Base.summary",
    "category": "Method",
    "text": "summary(de::DependencyError)\n\nRetuns a string representation of the error with only the internal Exception type and the id\n\n\n\n"
},

{
    "location": "pages/api.html#DependencyError-1",
    "page": "API",
    "title": "DependencyError",
    "category": "section",
    "text": "DependencyError\nsummary(::DependencyError)"
},

]}
