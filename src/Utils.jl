#= MIT License

Copyright (c) 2020 Uwe Fechner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. =#

module Utils

using Rotations, StaticArrays
export demo_state, SEGMENTS

const MyFloat = Float32
const SEGMENTS = 7                    # number of tether segments

struct SysState
    time::Float64                     # time since launch in seconds
    orient::Quat                      # orientation of the kite
    X::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in x
    Y::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in y
    Z::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in z
end 

function demo_state(rel_height=1.0, time=0.0)
    a = 10
    X = range(0, stop=10, length=SEGMENTS+1)
    Y = zeros(length(X))
    Z = (a .* cosh.(X./a) .- a) * rel_height 
    orient = UnitQuaternion(1.0,0,0,0)
    return SysState(time, orient, X, Y, Z)
end

end
