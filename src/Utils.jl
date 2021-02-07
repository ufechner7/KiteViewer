#= MIT License

Copyright (c) 2020, 2021 Uwe Fechner

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
export demo_state, demo_log, SEGMENTS, SAMPLE_FREQ
export SysState, SysLog

const MyFloat = Float32
const SEGMENTS = 7                    # number of tether segments
const SAMPLE_FREQ = 20                # sample frequency in Hz

struct SysState
    time::Float64                     # time since launch in seconds
    orient::Quat                      # orientation of the kite
    X::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in x
    Y::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in y
    Z::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in z
end 

# recording of a flight
struct SysLog
    name::String
    log::Vector{SysState}
end

# create a demo state with a given height and time
function demo_state(height=6.0, time=0.0)
    a = 10
    X = range(0, stop=10, length=SEGMENTS+1)
    Y = zeros(length(X))
    Z = (a .* cosh.(X./a) .- a) * height/ 5.430806 
    orient = UnitQuaternion(1.0,0,0,0)
    return SysState(time, orient, X, Y, Z)
end

# create a demo flight log with given name [String] and duration [s]
function demo_log(name, duration=10)
    delta_t = 1.0 / SAMPLE_FREQ
    t_max   = 10.0
    max_height = 6.0
    steps   = Int(t_max * SAMPLE_FREQ) + 1
    log = Vector{SysState}(undef, steps)
    for i in range(0, length=steps)
        log[i+1] = demo_state(max_height * i/steps, i*delta_t)
    end
    return SysLog(name, log)
end

end
