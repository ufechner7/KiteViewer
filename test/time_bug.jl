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

# On Julia 1.5.3:
# julia> include("test/time_bug.jl")
# [ Info:  started timer at: 2021-02-21T10:59:55.463
#   0.811249 seconds (1.94 M allocations: 103.003 MiB, 2.59% gc time)
# [ Info:          2.161581335s: 2 seconds, 161 milliseconds

# julia> 2.161/0.811
# 2.664611590628853

# @time reports 0.81 seconds, while the real execution time incl. compilation is more like 2.16 seconds