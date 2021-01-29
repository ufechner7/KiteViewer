module Utils

using Rotations, StaticArrays

export test, Pos, SEGMENTS

const MyFloat = Float32
const SEGMENTS = 7

struct Pos
    x::MyFloat
    y::MyFloat
    z::MyFloat
end

struct SysState
    time::Float64                     # time since launch in seconds
    orient::Quat                      # orientation of the kite
    tether::MVector{SEGMENTS+1, Pos}  # vector of the particle positions
end 

# Flight::Vector{SysState}

function test()
    a = 10
    X = range(0, stop=10, length=SEGMENTS+1)
    Y = zeros(length(X)) 
    Z = (a .* cosh.(X./a) .- a) 
    i = 1
    tether = MVector{SEGMENTS+1, Pos}(undef)
    for x in X
        pos = Pos(x, Y[i], Z[i])
        tether[i] = pos
        i += 1
    end
    orient = UnitQuaternion(1.0,0,0,0)
    state = SysState(0.0, orient, tether)
    return state
end

end