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


using Rotations, StaticArrays, StructArrays, Arrow

const MyFloat = Float32
const SEGMENTS = 7                    # number of tether segments
const SAMPLE_FREQ = 20                # sample frequency in Hz
const DATA_PATH = "."            # path for log files and other data

struct SysState
    time::Float64                     # time since launch in seconds
    orient::Quat                      # orientation of the kite
    X::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in x
    Y::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in y
    Z::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in z
end 

# extended SysState containing derived values for plotting
struct ExtSysState
    time::Float64                     # time since launch in seconds
    orient::Quat                      # orientation of the kite
    X::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in x
    Y::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in y
    Z::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in z
    x::MyFloat                        # kite position in x
    y::MyFloat                        # kite position in y
    z::MyFloat                        # kite position in z
end 

struct FlightLog
    name::String
    log_3d::Vector{SysState}          # vector of structs
    log_2d::StructArray{ExtSysState}  # struct of vectors, derived from log_3d
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

# create a demo flight log for 3d replay with given name [String] and duration [s]
function demo_log3d(name="Test flight"; duration=10)
    max_height = 6.0
    steps   = Int(duration * SAMPLE_FREQ) + 1
    log_3d = Vector{SysState}(undef, steps)
    for i in range(0, length=steps)
        log_3d[i+1] = demo_state(max_height * i/steps, i/SAMPLE_FREQ)
    end
    return log_3d
end

# convert vector of structs to struct of vectors for easy plotting in 2d
function vos2sov(log::Vector)
    steps=length(log)
    time_vec = Vector{Float64}(undef, steps)
    orient_vec = Vector{Quat}(undef, steps)
    X_vec = Vector{MVector{SEGMENTS+1, MyFloat}}(undef, steps)
    Y_vec = Vector{MVector{SEGMENTS+1, MyFloat}}(undef, steps)
    Z_vec = Vector{MVector{SEGMENTS+1, MyFloat}}(undef, steps)
    x = Vector{MyFloat}(undef, steps)
    y = Vector{MyFloat}(undef, steps)
    z = Vector{MyFloat}(undef, steps)
    for i in range(1, length=steps)
        state=log[i]
        time_vec[i] = state.time
        orient_vec[i] = state.orient
        X_vec[i] = state.X
        Y_vec[i] = state.Y
        Z_vec[i] = state.Z
        x[i] = state.X[end]
        y[i] = state.Y[end]
        z[i] = state.Z[end]
    end
    return StructArray{ExtSysState}((time_vec, orient_vec, X_vec, Y_vec, Z_vec, x, y, z))
end

function demo_log(name="Test_flight"; duration=10)
    log_3d = demo_log3d(name, duration=duration)
    log_2d = vos2sov(log_3d)
    return FlightLog(name, log_3d, log_2d)
end

function save_log(log::FlightLog)
    filename=joinpath(DATA_PATH, log.name) * ".arrow"
    println(filename)
    Arrow.write(filename, log.log_2d)
    println(filename)
end

flight_log=demo_log()
save_log(flight_log)
