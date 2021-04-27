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

# data structures for the flight state and the flight log
# functions for creating a demo flight state, demo flight log, loading and saving flight logs
# in addition helper functions for working with rotations

using Rotations, StaticArrays, StructArrays, RecursiveArrayTools, Arrow
export SysState, ExtSysState, SysLog, MyFloat

export demo_state, demo_syslog, demo_log, load_log, syslog2extlog, save_log, rot3d, SEGMENTS, SAMPLE_FREQ

const MyFloat = Float32               # type to use for postions
const SEGMENTS = 6                    # number of tether segments
const SAMPLE_FREQ = 20                # sample frequency in Hz
const DATA_PATH = "./data"            # path for log files and other data

# basic system state; one of these will be saved per time step
struct SysState
    time::Float64                     # time since launch in seconds
    orient::MVector{4, Float32}       # orientation of the kite (quaternion)
    X::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in x
    Y::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in y
    Z::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in z
end 

# extended SysState containing derived values for plotting
struct ExtSysState
    time::Float64                     # time since launch in seconds
    orient::UnitQuaternion{Float32}   # orientation of the kite
    X::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in x
    Y::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in y
    Z::MVector{SEGMENTS+1, MyFloat}   # vector of particle positions in z
    x::MyFloat                        # kite position in x
    y::MyFloat                        # kite position in y
    z::MyFloat                        # kite position in z
end

# flight log, containing the basic data as struct of arrays 
# and in addition an extended view on the data that includes derived/ calculated values for plotting
# finally meta data like the file name of the log file is included
struct SysLog
    name::String
    syslog::StructArray{SysState}    # struct of vectors
    extlog::StructArray{ExtSysState} # struct of vectors, containing derived values
end

# functions
"""
Calculate the rotation of reference frame (ax, ay, az) so that it matches the reference frame (bx, by, bz).
All parameters must be 3-element vectors. Both refrence frames must be orthogonal,
all vectors must already be normalized.
Source: http://en.wikipedia.org/wiki/User:Snietfeld/TRIAD_Algorithm
"""
function rot3d(ax, ay, az, bx, by, bz)
    R_ai = hcat(ax, az, ay)
    R_bi = hcat(bx, bz, by)
    return R_bi * R_ai'
end

# create a demo state with a given height and time
function demo_state(height=6.0, time=0.0)
    a = 10
    X = range(0, stop=10, length=SEGMENTS+1)
    Y = zeros(length(X))
    Z = (a .* cosh.(X./a) .- a) * height/ 5.430806 
    r_xyz = RotXYZ(pi/2, -pi/2, 0)
    q = UnitQuaternion(r_xyz)
    orient = MVector{4, Float32}(q.w, q.x, q.y, q.z)
    return SysState(time, orient, X, Y, Z)
end

# create a demo flight log with given name [String] and duration [s]
function demo_syslog(name="Test flight"; duration=10)
    max_height = 6.0
    steps   = Int(duration * SAMPLE_FREQ) + 1
    time_vec = Vector{Float64}(undef, steps)
    orient_vec = Vector{MVector{4, Float32}}(undef, steps)
    X_vec = Vector{MVector{SEGMENTS+1, MyFloat}}(undef, steps)
    Y_vec = Vector{MVector{SEGMENTS+1, MyFloat}}(undef, steps)
    Z_vec = Vector{MVector{SEGMENTS+1, MyFloat}}(undef, steps)
    for i in range(0, length=steps)
        state = demo_state(max_height * i/steps, i/SAMPLE_FREQ)
        time_vec[i+1] = state.time
        orient_vec[i+1] = state.orient
        X_vec[i+1] = state.X
        Y_vec[i+1] = state.Y
        Z_vec[i+1] = state.Z
    end
    return StructArray{SysState}((time_vec, orient_vec, X_vec, Y_vec, Z_vec))
end

# extend a flight systom log with the fieds x, y, and z (kite positions) and convert the orientation to the type UnitQuaternion
function syslog2extlog(syslog)
    x_vec = @view VectorOfArray(syslog.X)[end,:]
    y_vec = @view VectorOfArray(syslog.Y)[end,:]
    z_vec = @view VectorOfArray(syslog.Z)[end,:]
    orient_vec = Vector{UnitQuaternion{Float32}}(undef, length(syslog.time))
    for i in range(1, length=length(syslog.time))
        orient_vec[i] = UnitQuaternion(syslog.orient[i])
    end
    return StructArray{ExtSysState}((syslog.time, orient_vec, syslog.X, syslog.Y, syslog.Z, x_vec, y_vec, z_vec))    
end

# create an artifical log file for demonstration purposes
function demo_log(name="Test_flight"; duration=10)
    syslog = demo_syslog(name, duration=duration)
    return SysLog(name, syslog, syslog2extlog(syslog))
end

function save_log(flight_log::SysLog)
    Arrow.ArrowTypes.registertype!(SysState, SysState)
    filename=joinpath(DATA_PATH, flight_log.name) * ".arrow"
    Arrow.write(filename, flight_log.syslog, compress=:lz4)
end

function load_log(filename::String)
    Arrow.ArrowTypes.registertype!(SysState, SysState)
    Arrow.ArrowTypes.registertype!(MVector{4, Float32}, MVector{4, Float32})
    if isnothing(findlast(isequal('.'), filename))
        fullname = joinpath(DATA_PATH, filename) * ".arrow"
    else
        fullname = joinpath(DATA_PATH, filename) 
    end
    table = Arrow.Table(fullname)
    syslog = StructArray{SysState}((table.time, table.orient, table.X, table.Y, table.Z))
    return SysLog(basename(fullname[1:end-6]), syslog, syslog2extlog(syslog))
end

function test(save=false)
    if save
        log_to_save=demo_log()
        save_log(log_to_save)
    end
    return(load_log("Test_flight.arrow"))
end

end
