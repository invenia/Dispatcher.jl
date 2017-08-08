using Dispatcher
using ResultTypes
using Base.Test
using Memento
using IterTools

import LightGraphs

const LOG_LEVEL = "info"      # could also be "debug", "notice", "warn", etc

Memento.config(LOG_LEVEL; fmt="[{level} | {name}]: {msg}")
const logger = get_logger(current_module())

function test_addproc(x::Int; level=LOG_LEVEL)
    ret = addproc(x)
    @everywhere using Dispatcher
    @everywhere using Memento
    @everywhere Memento.config(level; fmt="[{level} | {name}]: {msg}")
end

module OtherModule

export MyType

type MyType
    x
end

end # module


@testset "Graph" begin
    @testset "Adding" begin
        g = DispatchGraph()

        node1 = Op(()->3)
        node2 = Op(()->4)

        push!(g, node1)
        push!(g, node2)
        LightGraphs.add_edge!(g, node1, node2)
        @test length(g) == 2
        @test length(g.nodes) == 2
        @test LightGraphs.nv(g.graph) == 2
        @test g.nodes[node1] == 1
        @test g.nodes[node2] == 2
        @test g.nodes[1] === node1
        @test g.nodes[2] === node2
        @test LightGraphs.ne(g.graph) == 1
        @test collect(LightGraphs.out_neighbors(g.graph, 1)) == [2]
    end

    @testset "Equality" begin
        #=
        digraph  {
            2 -> 1;
            2 -> 3;
            3 -> 4;
            3 -> 5;
            4 -> 6;
            5 -> 6;
            6 -> 7;
            6 -> 8;
            9 -> 8;
            9 -> 10;
        }
        =#

        f_nodes = map(1:10) do i
            let i = copy(i)
                Op(()->i)
            end
        end

        f_edges = [
            (f_nodes[2], f_nodes[1]),
            (f_nodes[2], f_nodes[3]),
            (f_nodes[3], f_nodes[4]),
            (f_nodes[3], f_nodes[5]),
            (f_nodes[4], f_nodes[6]),
            (f_nodes[5], f_nodes[6]),
            (f_nodes[6], f_nodes[7]),
            (f_nodes[6], f_nodes[8]),
            (f_nodes[9], f_nodes[8]),
            (f_nodes[9], f_nodes[10]),
        ]

        g1 = DispatchGraph()
        for node in f_nodes
            push!(g1, node)
        end
        for (parent, child) in f_edges
            add_edge!(g1, parent, child)
        end

        g2 = DispatchGraph()
        for node in reverse(f_nodes)
            push!(g2, node)
        end
        @test g1 != g2
        for (parent, child) in reverse(f_edges)
            @test g1 != g2
            add_edge!(g2, parent, child)
        end

        @test g1 == g2

        # duplicate node insertion is a no-op
        push!(g2, f_nodes[1])
        @test g1 == g2

        add_edge!(g2, f_nodes[2], f_nodes[10])
        @test g1 != g2
    end

    @testset "Ancestor subgraph" begin
        #=
        digraph  {
            2 -> 1;
            2 -> 3;
            3 -> 4;
            3 -> 5;
            4 -> 6;
            5 -> 6;
            6 -> 7;
            6 -> 8;
            9 -> 8;
            9 -> 10;
        }
        =#

        f_nodes = map(1:10) do i
            let i = copy(i)
                Op(()->i)
            end
        end

        f_edges = [
            (f_nodes[2], f_nodes[1]),
            (f_nodes[2], f_nodes[3]),
            (f_nodes[3], f_nodes[4]),
            (f_nodes[3], f_nodes[5]),
            (f_nodes[4], f_nodes[6]),
            (f_nodes[5], f_nodes[6]),
            (f_nodes[6], f_nodes[7]),
            (f_nodes[6], f_nodes[8]),
            (f_nodes[9], f_nodes[8]),
            (f_nodes[9], f_nodes[10]),
        ]

        g = DispatchGraph()
        for node in f_nodes
            push!(g, node)
        end
        for (parent, child) in f_edges
            add_edge!(g, parent, child)
        end

        g_sliced_truth = DispatchGraph()
        push!(g_sliced_truth, f_nodes[9])
        push!(g_sliced_truth, f_nodes[10])
        add_edge!(g_sliced_truth, f_nodes[9], f_nodes[10])

        @test Dispatcher.subgraph(g, [f_nodes[9], f_nodes[10]]) == g_sliced_truth
        @test Dispatcher.subgraph(g, [9, 10]) == g_sliced_truth
        @test Dispatcher.subgraph(g, [f_nodes[10]]) == g_sliced_truth
        @test Dispatcher.subgraph(g, [10]) == g_sliced_truth

        g_sliced_truth = DispatchGraph()
        for node in f_nodes[1:7]
            push!(g_sliced_truth, node)
        end
        for (parent, child) in f_edges[1:7]
            add_edge!(g_sliced_truth, parent, child)
        end

        @test Dispatcher.subgraph(g, [f_nodes[1], f_nodes[7]]) == g_sliced_truth
        @test Dispatcher.subgraph(g, [f_nodes[7]]) != g_sliced_truth
    end

    @testset "Descendant subgraph" begin
        #=
        digraph  {
            2 -> 1;
            2 -> 3;
            3 -> 4;
            3 -> 5;
            4 -> 6;
            5 -> 6;
            6 -> 7;
            6 -> 8;
            9 -> 8;
            9 -> 10;
        }
        =#

        f_nodes = map(1:10) do i
            let i = copy(i)
                Op(()->i)
            end
        end

        f_edges = [
            (f_nodes[2], f_nodes[1]),
            (f_nodes[2], f_nodes[3]),
            (f_nodes[3], f_nodes[4]),
            (f_nodes[3], f_nodes[5]),
            (f_nodes[4], f_nodes[6]),
            (f_nodes[5], f_nodes[6]),
            (f_nodes[6], f_nodes[7]),
            (f_nodes[6], f_nodes[8]),
            (f_nodes[9], f_nodes[8]),
            (f_nodes[9], f_nodes[10]),
        ]

        g = DispatchGraph()
        for node in f_nodes
            push!(g, node)
        end
        for (parent, child) in f_edges
            add_edge!(g, parent, child)
        end

        g_sliced_truth = DispatchGraph()
        for i = [1,2,6,7,8,9,10]
            push!(g_sliced_truth, f_nodes[i])
        end
        add_edge!(g_sliced_truth, f_nodes[6], f_nodes[7])
        add_edge!(g_sliced_truth, f_nodes[6], f_nodes[8])
        add_edge!(g_sliced_truth, f_nodes[9], f_nodes[8])
        add_edge!(g_sliced_truth, f_nodes[9], f_nodes[10])
        add_edge!(g_sliced_truth, f_nodes[2], f_nodes[1])

        @test Dispatcher.subgraph(g, Op[], [f_nodes[6]]) == g_sliced_truth
        @test Dispatcher.subgraph(g, Int[], [6]) == g_sliced_truth
        @test Dispatcher.subgraph(g, Op[], [f_nodes[6], f_nodes[5]]) == g_sliced_truth
        @test Dispatcher.subgraph(g, Int[], [6, 5]) == g_sliced_truth

        g_sliced_truth = DispatchGraph()
        for i = [1,7,8,10]
            push!(g_sliced_truth, f_nodes[i])
        end

        @test Dispatcher.subgraph(g, Int[], [1, 7, 8, 10]) == g_sliced_truth
    end
end

@testset "Dispatcher" begin
    @testset "Macros" begin
        @testset "Simple" begin
            @testset "Op" begin
                ex = quote
                    @op sum(4)
                end

                expanded_ex = macroexpand(ex)

                op = eval(expanded_ex)

                @test isa(op, Op)

                graph_nodes = collect(nodes(DispatchGraph(op)))
                @test length(graph_nodes) == 1
                @test isa(graph_nodes[1], Op)
                @test graph_nodes[1].func == sum
                @test collect(graph_nodes[1].args) == [4]
                @test isempty(graph_nodes[1].kwargs)
            end

            @testset "Op (kwargs, without semicolon)" begin
                ex = quote
                    @op split("foo bar", limit=1)
                end

                expanded_ex = macroexpand(ex)

                op = eval(expanded_ex)

                @test isa(op, Op)

                graph_nodes = collect(nodes(DispatchGraph(op)))
                @test length(graph_nodes) == 1
                @test isa(graph_nodes[1], Op)
                @test graph_nodes[1].func == split
                @test collect(graph_nodes[1].args) == ["foo bar"]
                @test collect(graph_nodes[1].kwargs) == [(:limit, 1)]
            end

            @testset "Op (kwargs, with semicolon)" begin
                ex = quote
                    @op split("foo bar"; limit=1)
                end

                expanded_ex = macroexpand(ex)

                op = eval(expanded_ex)

                @test isa(op, Op)

                graph_nodes = collect(nodes(DispatchGraph(op)))
                @test length(graph_nodes) == 1
                @test isa(graph_nodes[1], Op)
                @test graph_nodes[1].func == split
                @test collect(graph_nodes[1].args) == ["foo bar"]
                @test collect(graph_nodes[1].kwargs) == [(:limit, 1)]
            end

            @testset "Op (using Type)" begin
                ex = quote
                    @op Integer(2.0)
                end

                expanded_ex = macroexpand(ex)

                op = eval(expanded_ex)

                @test isa(op, Op)

                graph_nodes = collect(nodes(DispatchGraph(op)))
                @test length(graph_nodes) == 1
                @test isa(graph_nodes[1], Op)
                @test graph_nodes[1].func == Integer
                @test collect(graph_nodes[1].args) == [2.0]
                @test isempty(graph_nodes[1].kwargs)
            end

            @testset "Op (using non-callable objects throws exception)" begin
                @test_throws MethodError Op(3)
                @test_throws MethodError Op(true)
                @test_throws MethodError Op(print())
                @test_throws MethodError Op([1,2])
            end
        end

        @testset "Complex" begin
            @testset "Components" begin
                ex = quote
                    function comp(node)
                        x = @op node + 3
                        y = @op node + 1
                        x, y
                    end

                    a = @op 1 + 2
                    b, c = comp(a)
                    d = @op b * c
                end

                expanded_ex = macroexpand(ex)

                result_node = eval(expanded_ex)
                @test isa(result_node, Op)

                graph = DispatchGraph(result_node)
                graph_nodes = collect(nodes(graph))
                @test length(graph_nodes) == 4
                @test all(n->isa(n, Op), graph_nodes)

                op_result = let
                    a = @op 1 + 2
                    x = @op a + 3
                    y = @op a + 1
                    d = @op x * y
                end

                @test graph.graph == DispatchGraph(op_result).graph
            end

            @testset "Functions (importing symbols from other modules)" begin
                import OtherModule

                ex = quote
                    function foo(var::OtherModule.MyType)
                        x = @op var + 3
                        y = @op var + 1
                        x, y
                    end

                    a = OtherModule.MyType(3)
                    b, c = foo(a)
                    d = @op b * c
                end

                expanded_ex = macroexpand(ex)

                result_node = eval(expanded_ex)
                @test isa(result_node, Op)

                graph = DispatchGraph(result_node)
                graph_nodes = collect(nodes(graph))
                @test length(graph_nodes) == 3
                @test all(n->isa(n, Op), graph_nodes)

                op_result = let
                    x = @op a + 3
                    y = @op a + 1
                    d = @op x * y
                end

                @test graph.graph == DispatchGraph(op_result).graph
            end

            @testset "Functions (using symbols from other modules)" begin
                using OtherModule

                ex = quote
                    function foo(var::MyType)
                        x = @op var + 3
                        y = @op var + 1
                        x, y
                    end

                    a = MyType(3)
                    b, c = foo(a)
                    d = @op b * c
                end

                expanded_ex = macroexpand(ex)

                result_node = eval(expanded_ex)
                @test isa(result_node, Op)

                graph = DispatchGraph(result_node)
                graph_nodes = collect(nodes(graph))
                @test length(graph_nodes) == 3
                @test all(n->isa(n, Op), graph_nodes)

                op_result = let
                    x = @op a + 3
                    y = @op a + 1
                    d = @op x * y
                end

                @test graph.graph == DispatchGraph(op_result).graph
            end
        end
    end

    @testset "Executors" begin
        @testset "Async" begin
            @testset "Example" begin
                exec = AsyncExecutor()
                comm = Channel{Float64}(2)

                a = Op(()->3)
                set_label!(a, "3")
                @test isempty(dependencies(a))

                b = Op((x)->x, 4)
                set_label!(b, "four")
                @test isempty(dependencies(b))

                c = Op(max, a, b)
                deps = dependencies(c)
                @test a in deps
                @test b in deps

                d = Op(sqrt, c)
                @test c in dependencies(d)

                e = Op((x)->(factorial(x), factorial(2x)), c)
                set_label!(e, "factorials")
                @test c in dependencies(e)
                f, g = e

                h = Op((x)->put!(comm, x / 2), g)
                set_label!(h, "put!")
                @test g in dependencies(h)

                result_truth = factorial(2 * (max(3, 4))) / 2

                run!(exec, [h])

                @test isready(comm)
                @test take!(comm) === result_truth
                @test !isready(comm)
                close(comm)
            end

            @testset "Partial (dict input)" begin
                # this sort of stateful behaviour outside of the node graph is not recommended
                # but we're using it here because it makes testing easy

                exec = AsyncExecutor()
                comm = Channel{Float64}(3)

                a = Op(()->(put!(comm, 4); comm))
                set_label!(a, "put!(4)")

                b = Op(a) do ch
                    x = take!(ch)
                    put!(ch, x + 1)
                end
                set_label!(b, "put!(x + 1)")

                c = Op(a) do ch
                    x = take!(ch)
                    put!(ch, x + 2)
                end
                set_label!(c, "put!(x + 2)")

                ret = run!(exec, [b])
                @test length(ret) == 1
                @test !iserror(ret[1])
                @test b === unwrap(ret[1])

                @test fetch(comm) == 5

                # run remainder of graph
                results = run!(exec, [c]; input_map=Dict(a=>fetch(a)))
                @test fetch(comm) == 7
                @test length(results) == 1
                @test !iserror(results[1])
                @test unwrap(results[1]) === c
            end

            @testset "Partial (array input)" begin
                info(logger, "Partial array")
                # this sort of stateful behaviour outside of the node graph is not recommended
                # but we're using it here because it makes testing easy

                exec = AsyncExecutor()
                comm = Channel{Float64}(3)

                a = Op(()->(put!(comm, 4); comm))
                set_label!(a, "put!(4)")

                b = Op(a) do ch
                    x = take!(ch)
                    put!(ch, x + 1)
                end
                set_label!(b, "put!(x + 1)")

                c = Op(a) do ch
                    x = take!(ch)
                    put!(ch, x + 2)
                end
                set_label!(c, "put!(x + 2)")

                b_ret = run!(exec, [b])
                @test length(b_ret) == 1
                @test !iserror(b_ret[1])
                @test unwrap(b_ret[1]) === b

                @test fetch(comm) == 5

                # run remainder of graph
                results = run!(exec, [c], [a])
                @test fetch(comm) == 7
                @test length(results) == 1
                @test !iserror(results[1])
                @test unwrap(results[1]) === c
            end

            @testset "No cycles allowed" begin
                exec = AsyncExecutor()

                a = Op(identity, 3)
                set_label!(a, "3")
                b = Op(identity, a)
                set_label!(b, "a")
                a.args = (b,)

                @test_throws Exception run!(exec, [a])
                @test_throws Exception run!(exec, [b])
            end

            @testset "Functions" begin
                exec = AsyncExecutor()

                function comp(node)
                    x = @op node + 3
                    y = @op node + 1
                    x, y
                end

                a = @op 1 + 2
                b, c = comp(a)
                d = @op b * c

                result = run!(exec, [d])

                @test length(result) == 1
                @test !iserror(result[1])
                @test unwrap(result[1]) === d
                @test fetch(unwrap(result[1])) == 24
            end
        end

        @testset "Parallel - $i process" for i in 1:3
            pnums = i > 1 ? addprocs(i - 1) : ()
            @everywhere using Dispatcher
            comm = i > 1 ? RemoteChannel(()->Channel{Float64}(2)) : Channel{Float64}(2)

            try
                exec = ParallelExecutor()

                a = Op(()->3)
                set_label!(a, "3")
                @test isempty(dependencies(a))

                b = Op((x)->x, 4)
                set_label!(b, "4")
                @test isempty(dependencies(b))

                c = Op(max, a, b)
                deps = dependencies(c)
                @test a in deps
                @test b in deps

                d = Op(sqrt, c)
                @test c in dependencies(d)

                e = Op((x)->(factorial(x), factorial(2x)), c)
                set_label!(e, "factorials")
                @test c in dependencies(e)
                f, g = e

                h = Op((x)->put!(comm, x / 2), g)
                set_label!(h, "put!")
                @test g in dependencies(h)

                result_truth = factorial(2 * (max(3, 4))) / 2

                results = run!(exec, DispatchGraph(h))

                @test isready(comm)
                @test take!(comm) === result_truth
                @test !isready(comm)
                close(comm)
            finally
                rmprocs(pnums)
            end
        end

        @testset "Error Handling" begin
            @testset "Async - Application Errors" begin
                using Dispatcher
                comm = Channel{Float64}(2)

                exec = AsyncExecutor()

                a = Op(()->3)
                set_label!(a, "3")
                @test isempty(dependencies(a))

                b = Op((x)->x, 4)
                set_label!(b, "4")
                @test isempty(dependencies(b))

                c = Op(max, a, b)
                deps = dependencies(c)
                @test a in deps
                @test b in deps

                d = Op(sqrt, c)
                @test c in dependencies(d)

                e = Op(c) do x
                    (factorial(x), throw(ErrorException("Application Error")))
                end

                set_label!(e, "ApplicationError")
                @test c in dependencies(e)
                f, g = e

                h = Op((x)->put!(comm, x / 2), g)
                set_label!(h, "put!")
                @test g in dependencies(h)

                result_truth = factorial(2 * (max(3, 4))) / 2

                # Behaviour of `asyncmap` on exceptions changed
                # between julia 0.5 and 0.6
                if VERSION < v"0.6.0-"
                    @test_throws CompositeException run!(exec, [h])
                else
                    @test_throws DependencyError run!(exec, [h])
                end
                prepare!(exec, DispatchGraph(h))
                @test any(run!(exec, [h]; throw_error=false)) do result
                    iserror(result) && isa(unwrap_error(result), DependencyError)
                end
                @test !isready(comm)
                close(comm)
            end

            @testset "Parallel - Application Errors" begin
                pnums = addprocs(1)
                @everywhere using Dispatcher
                comm = RemoteChannel(()->Channel{Float64}(2))

                try
                    exec = ParallelExecutor()

                    a = Op(()->3)
                    set_label!(a, "3")
                    @test isempty(dependencies(a))

                    b = Op((x)->x, 4)
                    set_label!(b, "4")
                    @test isempty(dependencies(b))

                    c = Op(max, a, b)
                    deps = dependencies(c)
                    @test a in deps
                    @test b in deps

                    d = Op(sqrt, c)
                    @test c in dependencies(d)

                    e = Op(c) do x
                        return (factorial(x), throw(ErrorException("Application Error")))
                    end
                    set_label!(e, "ApplicationError")
                    @test c in dependencies(e)
                    f, g = e

                    h = Op((x)->put!(comm, x / 2), g)
                    set_label!(h, "put!")
                    @test g in dependencies(h)

                    result_truth = factorial(2 * (max(3, 4))) / 2

                    # Behaviour of `asyncmap` on exceptions changed
                    # between julia 0.5 and 0.6
                    if VERSION < v"0.6.0-"
                        @test_throws CompositeException run!(exec, [h])
                    else
                        @test_throws DependencyError run!(exec, [h])
                    end

                    prepare!(exec, DispatchGraph(h))
                    @test any(run!(exec, [h]; throw_error=false)) do result
                        iserror(result) && isa(unwrap_error(result), DependencyError)
                    end
                    @test !isready(comm)
                    close(comm)
                finally
                    rmprocs(pnums)
                end
            end

            @testset "$i procs removed (delay $s)" for i in 1:2, s in 0.1:0.1:0.6
                function rand_sleep()
                    sec = rand(0.1:0.05:0.4)
                    # info(logger, "sleeping for $sec")
                    sleep(sec)
                end

                pnums = addprocs(2)
                @everywhere using Dispatcher
                comm = RemoteChannel(()->Channel{Float64}(2))

                try
                    exec = ParallelExecutor()

                    a = Op() do
                        rand_sleep()
                        return 3
                    end
                    set_label!(a, "3")
                    @test isempty(dependencies(a))

                    b = Op(4) do x
                        rand_sleep()
                        return x
                    end
                    set_label!(b, "4")
                    @test isempty(dependencies(b))

                    c = Op(a, b) do x, y
                        rand_sleep()
                        return max(x, y)
                    end
                    set_label!(c, "max")
                    deps = dependencies(c)
                    @test a in deps
                    @test b in deps

                    d = Op(c) do x
                        rand_sleep()
                        return sqrt(x)
                    end
                    set_label!(d, "sqrt")
                    @test c in dependencies(d)

                    e = Op(c) do x
                        rand_sleep()
                        return (factorial(x), factorial(2x))
                    end
                    set_label!(e, "factorials")
                    @test c in dependencies(e)
                    f, g = e

                    h = Op(g) do x
                        rand_sleep()
                        return put!(comm, x / 2)
                    end
                    set_label!(h, "put!")
                    @test g in dependencies(h)

                    result_truth = factorial(2 * (max(3, 4))) / 2

                    fut = @spawnat 1 run!(exec, [h])
                    sleep(s)

                    rmprocs(pnums[1:i])
                    resp = fetch(fut)
                    @test !isa(resp, RemoteException)
                    @test isready(comm)
                    @test take!(comm) === result_truth
                    @test !isready(comm)
                    close(comm)
                finally
                    rmprocs(pnums)
                end
            end
        end
    end

    @testset "Examples" begin
        @testset "Referencing symbols from other packages" begin
            @testset "Referencing symbols with import" begin
                pnums = addprocs(3)
                @everywhere using Dispatcher
                @everywhere import IterTools

                try
                    a = @op IterTools.imap(+, [1,2,3], [4,5,6])
                    b = @op IterTools.distinct(a)
                    c = @op IterTools.nth(b, 3)

                    exec = ParallelExecutor()
                    (results,) = run!(exec, [c])
                    @test !iserror(results)
                    run_future = unwrap(results)
                    @test isready(run_future)
                    @test fetch(run_future) == 9
                finally
                    rmprocs(pnums)
                end
            end

            @testset "Referencing symbols with using" begin
                pnums = addprocs(3)
                @everywhere using Dispatcher
                @everywhere using IterTools

                try
                    a = @op imap(+, [1,2,3], [4,5,6])
                    b = @op distinct(a)
                    c = @op nth(b, 3)

                    exec = ParallelExecutor()
                    (results,) = run!(exec, [c])
                    @test !iserror(results)
                    run_future = unwrap(results)
                    @test isready(run_future)
                    @test fetch(run_future) == 9
                finally
                    rmprocs(pnums)
                end
            end
        end

        @testset "Dask Do" begin
            function slowadd(x, y)
                return x + y
            end

            function slowinc(x)
                return x + 1
            end

            function slowsum(a...)
                return sum(a)
            end

            data = [1, 2, 3]

            A = map(data) do i
                @op slowinc(i)
            end

            B = map(A) do a
                @op slowadd(a, 10)
            end

            C = map(A) do a
                @op slowadd(a, 100)
            end

            result = @op ((@op slowsum(A...)) + (@op slowsum(B...)) + (@op slowsum(C...)))

            executor = AsyncExecutor()
            (run_result,) = run!(executor, [result])

            @test !iserror(run_result)
            run_future = unwrap(run_result)
            @test isready(run_future)
            @test fetch(run_future) == 357
        end

        @testset "Dask Cluster" begin
            pnums = addprocs(3)
            @everywhere using Dispatcher

            @everywhere function load(address)
                sleep(rand() / 2)

                return 1
            end

            @everywhere function load_from_sql(address)
                sleep(rand() / 2)

                return 1
            end

            @everywhere function process(data, reference)
                sleep(rand() / 2)

                return 1
            end

            @everywhere function roll(a, b, c)
                sleep(rand() / 5)

                return 1
            end

            @everywhere function compare(a, b)
                sleep(rand() / 10)

                return 1
            end

            @everywhere function reduction(seq)
                sleep(rand() / 1)

                return 1
            end

            try
                filenames = ["mydata-$d.dat" for d in 1:100]
                data = [(@op load(filename)) for filename in filenames]

                reference = @op load_from_sql("sql://mytable")
                processed = [(@op process(d, reference)) for d in data]

                rolled = map(1:(length(processed) - 2)) do i
                    a = processed[i]
                    b = processed[i + 1]
                    c = processed[i + 2]
                    roll_result = @op roll(a, b, c)
                    return roll_result
                end

                compared = map(1:200) do i
                    a = rand(rolled)
                    b = rand(rolled)
                    compare_result = @op compare(a, b)
                    return compare_result
                end

                best = @op reduction(CollectNode(compared))

                executor = ParallelExecutor()
                (run_best,) = run!(executor, [best])
            finally
                rmprocs(pnums)
            end
        end
    end

    @testset "Show" begin
        graph = DispatchGraph()
        @test sprint(show, graph) == "DispatchGraph($(graph.graph),NodeSet(DispatchNode[]))"

        @test sprint(show, Dispatcher.NodeSet()) == "NodeSet(DispatchNode[])"

        op = Op(DeferredFutures.DeferredFuture(), print, "op", 1, 1)
        op_str = "Op($(op.result),print,\"op\")"
        @test sprint(show, op) == op_str

        index_node = IndexNode(op, 1)
        index_node_str = "IndexNode($op_str,1,$(index_node.result))"
        @test sprint(show, index_node) == index_node_str

        @test sprint(show, DataNode(op)) == "DataNode($op_str)"

        collect_node = CollectNode([op, index_node])
        @test sprint(show, collect_node) == (
            "CollectNode(DispatchNode[$op_str,$index_node_str]," *
            "$(collect_node.result),\"2 DispatchNodes\")"
        )

        push!(graph, op)
        push!(graph, index_node)

        @test sprint(show, graph) == (
            "DispatchGraph($(graph.graph),NodeSet(DispatchNode[$op_str,$index_node_str]))"
        )
    end
end
