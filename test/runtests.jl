using Dispatcher
using Base.Test

import LightGraphs


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
                    @dispatch_context begin
                        @op sum(4)
                    end
                end

                expanded_ex = macroexpand(ex)

                ctx = eval(expanded_ex)

                @test isa(ctx, DispatchContext)

                ctx_nodes = collect(nodes(ctx.graph))
                @test length(ctx_nodes) == 1
                @test isa(ctx_nodes[1], Op)
                @test ctx_nodes[1].func == sum
                @test collect(ctx_nodes[1].args) == [4]
                @test isempty(ctx_nodes[1].kwargs)
            end

            @testset "Generic (Op)" begin
                ex = quote
                    @dispatch_context begin
                        @node Op(sum, 4)
                    end
                end

                expanded_ex = macroexpand(ex)

                ctx = eval(expanded_ex)

                @test isa(ctx, DispatchContext)

                ctx_nodes = collect(nodes(ctx.graph))
                @test length(ctx_nodes) == 1
                @test isa(ctx_nodes[1], Op)
                @test ctx_nodes[1].func == sum
                @test collect(ctx_nodes[1].args) == [4]
                @test isempty(ctx_nodes[1].kwargs)
            end
        end

        @testset "Complex" begin
            @testset "Components" begin
                ex = quote
                    @component function comp(node)
                        x = @op node + 3
                        y = @op node + 1
                        x, y
                    end

                    @dispatch_context begin
                        a = @op 1 + 2
                        b, c = @include comp(a)
                        d = @op b * c
                    end
                end

                expanded_ex = macroexpand(ex)

                ctx = eval(expanded_ex)

                @test isa(ctx, DispatchContext)

                ctx_nodes = collect(nodes(ctx.graph))
                @test length(ctx_nodes) == 4
                @test all(n->isa(n, Op), ctx_nodes)

                op_ctx = let
                    @dispatch_context begin
                        a = @op 1 + 2
                        x = @op a + 3
                        y = @op a + 1
                        d = @op x * y
                    end
                end

                @test ctx.graph.graph == op_ctx.graph.graph
            end
        end
    end

    @testset "Executors" begin
        @testset "Async" begin
            @testset "Example" begin
                ctx = DispatchContext()
                exec = AsyncExecutor()
                comm = Channel{Float64}(2)

                op = Op(()->3)
                @test isempty(dependencies(op))
                a = add!(ctx, op)

                op = Op((x)->x, 4)
                @test isempty(dependencies(op))
                b = add!(ctx, op)

                op = Op(max, a, b)
                deps = dependencies(op)
                @test a in deps
                @test b in deps
                c = add!(ctx, op)

                op = Op(sqrt, c)
                @test c in dependencies(op)
                d = add!(ctx, op)

                op = Op((x)->(factorial(x), factorial(2x)), c)
                @test c in dependencies(op)
                e, f = add!(ctx, op)

                op = Op((x)->put!(comm, x / 2), f)
                @test f in dependencies(op)
                g = add!(ctx, op)

                result_truth = factorial(2 * (max(3, 4))) / 2

                run!(exec, ctx)

                @test isready(comm)
                @test take!(comm) === result_truth
                @test !isready(comm)
                close(comm)
            end

            @testset "Partial (dict input)" begin
                # this sort of stateful behaviour outside of the node graph is not recommended
                # but we're using it here because it makes testing easy

                ctx = DispatchContext()
                exec = AsyncExecutor()
                comm = Channel{Float64}(3)

                op = Op(()->(put!(comm, 4); comm))
                a = add!(ctx, op)

                op = Op(a) do ch
                    x = take!(ch)
                    put!(ch, x + 1)
                end
                b = add!(ctx, op)

                op = Op(a) do ch
                    x = take!(ch)
                    put!(ch, x + 2)
                end
                c = add!(ctx, op)

                ret = run!(exec, ctx, [b])
                @test b === ret[1]

                @test fetch(comm) == 5

                # run remainder of graph
                run!(exec, ctx, [c]; input_map=Dict(a=>fetch(a)))
                @test fetch(comm) == 7
            end

            @testset "Partial (array input)" begin
                info("Partial array")
                # this sort of stateful behaviour outside of the node graph is not recommended
                # but we're using it here because it makes testing easy

                ctx = DispatchContext()
                exec = AsyncExecutor()
                comm = Channel{Float64}(3)

                op = Op(()->(put!(comm, 4); comm))
                a = add!(ctx, op)

                op = Op(a) do ch
                    x = take!(ch)
                    put!(ch, x + 1)
                end
                b = add!(ctx, op)

                op = Op(a) do ch
                    x = take!(ch)
                    put!(ch, x + 2)
                end
                c = add!(ctx, op)

                b_ret, = run!(exec, ctx, [b])
                @test b === b_ret

                @test fetch(comm) == 5

                # run remainder of graph
                run!(exec, ctx, [c], [a])
                @test fetch(comm) == 7
            end

            @testset "No cycles allowed" begin
                ctx = DispatchContext()
                exec = AsyncExecutor()

                a = Op(identity, 3)
                b = Op(identity, a)
                a.args = (b,)

                @test_throws Exception begin
                    add!(ctx, a)
                    add!(ctx, b)
                    run!(exec, ctx)
                end
            end

            @testset "Components" begin
                exec = AsyncExecutor()

                @component function comp(node)
                    x = @op node + 3
                    y = @op node + 1
                    x, y
                end

                ctx = @dispatch_context begin
                    a = @op 1 + 2
                    b, c = @include comp(a)
                    d = @op b * c
                end

                result = run!(exec, ctx, [d])

                @test fetch(result[1]) == 24
            end
        end

        @testset "Parallel - $i process" for i in 1:3
            pnums = i > 1 ? addprocs(i - 1) : ()
            @everywhere using Dispatcher
            comm = i > 1 ? RemoteChannel(()->Channel{Float64}(2)) : Channel{Float64}(2)

            try
                ctx = DispatchContext()
                exec = ParallelExecutor()

                op = Op(()->3)
                @test isempty(dependencies(op))
                a = add!(ctx, op)

                op = Op((x)->x, 4)
                @test isempty(dependencies(op))
                b = add!(ctx, op)

                op = Op(max, a, b)
                deps = dependencies(op)
                @test a in deps
                @test b in deps
                c = add!(ctx, op)

                op = Op(sqrt, c)
                @test c in dependencies(op)
                d = add!(ctx, op)

                op = Op((x)->(factorial(x), factorial(2x)), c)
                @test c in dependencies(op)
                e, f = add!(ctx, op)

                op = Op((x)->put!(comm, x / 2), f)
                @test f in dependencies(op)
                g = add!(ctx, op)

                result_truth = factorial(2 * (max(3, 4))) / 2

                results = run!(exec, ctx)

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

                ctx = DispatchContext()
                exec = AsyncExecutor()

                op = Op(()->3)
                @test isempty(dependencies(op))
                a = add!(ctx, op)

                op = Op((x)->x, 4)
                @test isempty(dependencies(op))
                b = add!(ctx, op)

                op = Op(max, a, b)
                deps = dependencies(op)
                @test a in deps
                @test b in deps
                c = add!(ctx, op)

                op = Op(sqrt, c)
                @test c in dependencies(op)
                d = add!(ctx, op)

                op = Op(
                    (x)-> (
                        factorial(x),
                        throw(ErrorException("Application Error"))
                    ), c
                )

                @test c in dependencies(op)
                e, f = add!(ctx, op)

                op = Op((x)->put!(comm, x / 2), f)
                @test f in dependencies(op)
                g = add!(ctx, op)

                result_truth = factorial(2 * (max(3, 4))) / 2

                # Behaviour of `asyncmap` on exceptions changed
                # between julia 0.5 and 0.6
                if VERSION < v"0.6.0-"
                    @test_throws CompositeException run!(exec, ctx)
                else
                    @test_throws DependencyError run!(exec, ctx)
                end
                prepare!(exec, ctx)
                @test any(x -> isa(x, DependencyError), run!(exec, ctx; throw_error=false))
                @test !isready(comm)
                close(comm)
            end

            @testset "Parallel - Application Errors" begin
                pnums = addprocs(1)
                @everywhere using Dispatcher
                comm = RemoteChannel(()->Channel{Float64}(2))

                try
                    ctx = DispatchContext()
                    exec = ParallelExecutor()

                    op = Op(()->3)
                    @test isempty(dependencies(op))
                    a = add!(ctx, op)

                    op = Op((x)->x, 4)
                    @test isempty(dependencies(op))
                    b = add!(ctx, op)

                    op = Op(max, a, b)
                    deps = dependencies(op)
                    @test a in deps
                    @test b in deps
                    c = add!(ctx, op)

                    op = Op(sqrt, c)
                    @test c in dependencies(op)
                    d = add!(ctx, op)

                    op = Op(
                        (x)-> (
                            factorial(x),
                            throw(ErrorException("Application Error"))
                        ), c
                    )

                    @test c in dependencies(op)
                    e, f = add!(ctx, op)

                    op = Op((x)->put!(comm, x / 2), f)
                    @test f in dependencies(op)
                    g = add!(ctx, op)

                    result_truth = factorial(2 * (max(3, 4))) / 2

                    # Behaviour of `asyncmap` on exceptions changed
                    # between julia 0.5 and 0.6
                    if VERSION < v"0.6.0-"
                        @test_throws CompositeException run!(exec, ctx)
                    else
                        @test_throws DependencyError run!(exec, ctx)
                    end

                    prepare!(exec, ctx)
                    @test any(x -> isa(x, DependencyError), run!(exec, ctx; throw_error=false))
                    @test !isready(comm)
                    close(comm)
                finally
                    rmprocs(pnums)
                end
            end

            @testset "$i procs removed (delay $s)" for i in 1:2, s in 0.1:0.1:0.6
                function rand_sleep()
                    sec = rand(0.1:0.05:0.4)
                    # info("sleeping for $sec")
                    sleep(sec)
                end

                pnums = addprocs(2)
                @everywhere using Dispatcher
                comm = RemoteChannel(()->Channel{Float64}(2))

                try
                    ctx = DispatchContext()
                    exec = ParallelExecutor()

                    op = Op(
                        ()-> begin
                            rand_sleep()
                            return 3
                        end
                    )
                    @test isempty(dependencies(op))
                    a = add!(ctx, op)

                    op = Op(
                        (x)-> begin
                            rand_sleep()
                            return x
                        end, 4
                    )
                    @test isempty(dependencies(op))
                    b = add!(ctx, op)

                    op = Op(
                        (x, y) -> begin
                            rand_sleep()
                            max(x, y)
                        end, a, b
                    )
                    deps = dependencies(op)
                    @test a in deps
                    @test b in deps
                    c = add!(ctx, op)

                    op = Op(
                        (x) -> begin
                            rand_sleep()
                            return sqrt(x)
                        end, c
                    )
                    @test c in dependencies(op)
                    d = add!(ctx, op)

                    op = Op(
                        (x)-> begin
                            rand_sleep()
                            return (factorial(x), factorial(2x))
                        end, c
                    )
                    @test c in dependencies(op)
                    e, f = add!(ctx, op)

                    op = Op(
                        (x) -> begin
                            rand_sleep()
                            return put!(comm, x / 2)
                        end, f
                    )
                    @test f in dependencies(op)
                    g = add!(ctx, op)

                    result_truth = factorial(2 * (max(3, 4))) / 2

                    f = @spawnat 1 run!(exec, ctx)
                    sleep(s)

                    rmprocs(pnums[1:i])
                    resp = fetch(f)
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
end
