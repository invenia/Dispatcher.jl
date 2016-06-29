using Dispatcher
using Base.Test

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
