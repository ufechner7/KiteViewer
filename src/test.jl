using StaticArrays, BenchmarkTools, LinearAlgebra

const Vec3     = MVector{3, Float64}

function test_allocation(vec, res)
    my_norm = norm(vec)
    tmp = vec / my_norm
    res .= 2 * tmp
end

@benchmark test_allocation(vec, res) setup=(vec = Vec3(1,2,3); res = Vec3(0,0,0)) 