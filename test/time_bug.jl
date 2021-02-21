include("../src/Utils.jl")
using TickTock
tick();tock()

tick()
@time Utils.test(true);
tock()


# Output:
# julia> include("test/time_bug.jl")
# 
# [ Info:  started timer at: 2021-02-20T13:58:23.814
#   0.668130 seconds (933.81 k allocations: 55.527 MiB, 1.70% gc time, 98.76% compilation time)
# [ Info:          2.896614005s: 2 seconds, 896 milliseconds

# julia> 2.8966/0.668
# 4.336227544910179

# @time reports 0.67 seconds, while the real execution time incl. compilation is more like 4.3 seconds