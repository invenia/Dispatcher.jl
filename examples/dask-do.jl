# inspired by https://github.com/dask/dask-examples/blob/master/do-and-profiler.ipynb
using Dispatcher

function slowadd(x, y)
    sleep(1)
    return x + y
end

function slowinc(x)
    sleep(1)
    return x + 1
end

function slowsum(a...)
    sleep(0.5)
    return sum(a)
end

function main()
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

    return run_result
end

main()
@time main()
