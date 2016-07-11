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
        for (parent, child) in reverse(f_edges)
            add_edge!(g2, parent, child)
        end

        @test g1 == g2
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

        @test Dispatcher.ancestor_subgraph(g, [f_nodes[9], f_nodes[10]]) == g_sliced_truth
        @test Dispatcher.ancestor_subgraph(g, [9, 10]) == g_sliced_truth
        @test Dispatcher.ancestor_subgraph(g, [f_nodes[10]]) == g_sliced_truth
        @test Dispatcher.ancestor_subgraph(g, [10]) == g_sliced_truth

        g_sliced_truth = DispatchGraph()
        for node in f_nodes[1:7]
            push!(g_sliced_truth, node)
        end
        for (parent, child) in f_edges[1:7]
            add_edge!(g_sliced_truth, parent, child)
        end

        @test Dispatcher.ancestor_subgraph(g, [f_nodes[1], f_nodes[7]]) == g_sliced_truth
        @test Dispatcher.ancestor_subgraph(g, [f_nodes[7]]) != g_sliced_truth
    end
end

@testset "Dispatcher" begin
    @testset "Single process" begin
        @testset "Example" begin
            ctx = DispatchContext()
            exec = AsyncExecutor()

            op = Op(()->3)
            @test isempty(dependencies(op))
            a = push!(ctx, op)

            op = Op((x)->x, 4)
            @test isempty(dependencies(op))
            b = push!(ctx, op)

            op = Op(max, a, b)
            deps = dependencies(op)
            @test a in deps
            @test b in deps
            c = push!(ctx, op)

            op = Op(sqrt, c)
            @test c in dependencies(op)
            d = push!(ctx, op)

            op = Op((x)->(rand(Int, x), rand(UInt, x)), c)
            @test c in dependencies(op)
            e, f = push!(ctx, op)

            op = Op((x)->mean(x), f)
            @test f in dependencies(op)
            g = push!(ctx, op)

            run(exec, ctx)
        end
    end

    @testset "Parallel" begin
        @testset "1 process" begin
            @testset "Example" begin
                ctx = DispatchContext()
                exec = ParallelExecutor()

                op = Op(()->3)
                @test isempty(dependencies(op))
                a = push!(ctx, op)

                op = Op((x)->x, 4)
                @test isempty(dependencies(op))
                b = push!(ctx, op)

                op = Op(max, a, b)
                deps = dependencies(op)
                @test a in deps
                @test b in deps
                c = push!(ctx, op)

                op = Op(sqrt, c)
                @test c in dependencies(op)
                d = push!(ctx, op)

                op = Op((x)->(rand(Int, x), rand(UInt, x)), c)
                @test c in dependencies(op)
                e, f = push!(ctx, op)

                op = Op((x)->mean(x), f)
                @test f in dependencies(op)
                g = push!(ctx, op)

                run(exec, ctx)
            end
        end

        @testset "2 process" begin
            @testset "Example" begin
                pnums = addprocs(1)
                @everywhere using Dispatcher

                try
                    ctx = DispatchContext()
                    exec = ParallelExecutor()

                    op = Op(()->3)
                    @test isempty(dependencies(op))
                    a = push!(ctx, op)

                    op = Op((x)->x, 4)
                    @test isempty(dependencies(op))
                    b = push!(ctx, op)

                    op = Op(max, a, b)
                    deps = dependencies(op)
                    @test a in deps
                    @test b in deps
                    c = push!(ctx, op)

                    op = Op(sqrt, c)
                    @test c in dependencies(op)
                    d = push!(ctx, op)

                    op = Op((x)->(rand(Int, x), rand(UInt, x)), c)
                    @test c in dependencies(op)
                    e, f = push!(ctx, op)

                    op = Op((x)->mean(x), f)
                    @test f in dependencies(op)
                    g = push!(ctx, op)

                    run(exec, ctx)
                finally
                    rmprocs(pnums)
                end
            end
        end

        @testset "3 process" begin
            @testset "Example" begin
                pnums = addprocs(2)
                @everywhere using Dispatcher

                try
                    ctx = DispatchContext()
                    exec = ParallelExecutor()

                    op = Op(()->3)
                    @test isempty(dependencies(op))
                    a = push!(ctx, op)

                    op = Op((x)->x, 4)
                    @test isempty(dependencies(op))
                    b = push!(ctx, op)

                    op = Op(max, a, b)
                    deps = dependencies(op)
                    @test a in deps
                    @test b in deps
                    c = push!(ctx, op)

                    op = Op(sqrt, c)
                    @test c in dependencies(op)
                    d = push!(ctx, op)

                    op = Op((x)->(rand(Int, x), rand(UInt, x)), c)
                    @test c in dependencies(op)
                    e, f = push!(ctx, op)

                    op = Op((x)->mean(x), f)
                    @test f in dependencies(op)
                    g = push!(ctx, op)

                    run(exec, ctx)
                finally
                    rmprocs(pnums)
                end
            end
        end
    end
end
