include("../src/Utils.jl")
using TickTock
tick();tock()

tick()
etime = @elapsed Utils.test(true);
println(etime)
tock()


# Output:
# julia> include("test/time2_bug.jl")
# 
# [ Info:  started timer at: 2021-02-20T13:58:23.814
#   0.670841 
# [ Info:          2.92531268s: 2 seconds, 925 milliseconds

# julia> 2.9253/0.6708
# 4.360912343470483

# @time reports 0.67 seconds, while the real execution time incl. compilation is more like 2.9 seconds