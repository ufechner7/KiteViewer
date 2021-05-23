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
# function se() for reading the settings
# in addition helper functions for working with rotations

using Rotations, StaticArrays, StructArrays, RecursiveArrayTools, Arrow, YAML
export SysState, ExtSysState, SysLog, MyFloat

export demo_state, demo_syslog, demo_log, load_log, syslog2extlog, save_log, rot3d, se

const MyFloat = Float32               # type to use for postions
const DATA_PATH = "./data"            # path for log files and other data

mutable struct Settings
    log_file::String
    model::String
    segments::Int64          # number of tether segments
    sample_freq::Int64
    time_lapse::Float64
    zoom::Float64
    fixed_font::String
    v_reel_out::Float64
    c0::Float64
    c_s::Float64
    c2_cor::Float64
    k_ds::Float64
    area::Float64            # projected kite area            [m^2]
    mass::Float64            # kite mass incl. sensor unit     [kg]
    alpha_cl::Vector{Float64}
    cl_list::Vector{Float64}
    alpha_cd::Vector{Float64}
    cd_list::Vector{Float64}
    rel_side_area::Float64   # relative side area               [%]
    alpha_d_max::Float64     # max depower angle              [deg]
    kcu_mass::Float64        # mass of the kite control unit   [kg]
    v_wind::Float64
    h_ref::Float64
    rho_0::Float64
    z0::Float64
    profile_law::Int64
    alpha::Float64
    cd_tether::Float64
    d_tether::Float64
    d_line::Float64
    l_bridle::Float64
    l_tether::Float64
    damping::Float64
    c_spring::Float64
    elevation::Float64
end
const SETTINGS = [Settings("","",0,0,0,0,"",0,0,0,0,0,0,0,[],[],[],[],0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)]

# getter function for the Settings struct
function se(project="settings.yaml")
    if SETTINGS[1].segments == 0
        # load settings from YAML
        dict = YAML.load_file(joinpath(DATA_PATH, project))
        SETTINGS[1].log_file    = dict["system"]["log_file"]
        SETTINGS[1].segments    = dict["system"]["segments"]
        SETTINGS[1].sample_freq = dict["system"]["sample_freq"]
        SETTINGS[1].time_lapse  = dict["system"]["time_lapse"]
        SETTINGS[1].zoom        = dict["system"]["zoom"]
        SETTINGS[1].fixed_font  = dict["system"]["fixed_font"]

        SETTINGS[1].l_tether    = dict["initial"]["l_tether"]
        SETTINGS[1].v_reel_out   = dict["initial"]["v_reel_out"]
        SETTINGS[1].elevation   = dict["initial"]["elevation"]

        SETTINGS[1].c0          = dict["steering"]["c0"]
        SETTINGS[1].c_s         = dict["steering"]["c_s"]
        SETTINGS[1].c2_cor      = dict["steering"]["c2_cor"]
        SETTINGS[1].k_ds        = dict["steering"]["k_ds"]

        SETTINGS[1].alpha_d_max = dict["depower"]["alpha_d_max"]

        SETTINGS[1].model       = dict["kite"]["model"]
        SETTINGS[1].area        = dict["kite"]["area"]
        SETTINGS[1].rel_side_area = dict["kite"]["rel_side_area"]
        SETTINGS[1].mass        = dict["kite"]["mass"]
        SETTINGS[1].alpha_cl    = dict["kite"]["alpha_cl"]
        SETTINGS[1].cl_list     = dict["kite"]["cl_list"]
        SETTINGS[1].alpha_cd    = dict["kite"]["alpha_cd"]
        SETTINGS[1].cd_list     = dict["kite"]["cd_list"]

        SETTINGS[1].l_bridle    = dict["bridle"]["l_bridle"]
        SETTINGS[1].d_line      = dict["bridle"]["d_line"]

        SETTINGS[1].kcu_mass    = dict["kcu"]["mass"]

        SETTINGS[1].cd_tether   = dict["tether"]["cd_tether"]
        SETTINGS[1].d_tether    = dict["tether"]["d_tether"]
        SETTINGS[1].damping     = dict["tether"]["damping"]
        SETTINGS[1].c_spring    = dict["tether"]["c_spring"]

        SETTINGS[1].v_wind      = dict["environment"]["v_wind"]
        SETTINGS[1].h_ref       = dict["environment"]["h_ref"]
        SETTINGS[1].rho_0       = dict["environment"]["rho_0"]
        SETTINGS[1].z0          = dict["environment"]["z0"]
        SETTINGS[1].alpha       = dict["environment"]["alpha"]
        SETTINGS[1].profile_law = dict["environment"]["profile_law"]
    end
    return SETTINGS[1]
end

# basic system state; one of these will be saved per time step
struct SysState
    time::Float64                          # time since start of simulation in seconds
    orient::MVector{4, Float32}            # orientation of the kite (quaternion)
    elevation::MyFloat                     # elevation angle in radians
    azimuth::MyFloat                       # azimuth angle in radians
    l_tether::MyFloat                      # tether length [m]
    v_reelout::MyFloat                     # reel out velocity [m/s]
    force::MyFloat                         # tether force [N]
    depower::MyFloat                       # depower settings 
    v_app::MyFloat                         # apparent wind speed [m/s]
    X::MVector{se().segments+1, MyFloat}   # vector of particle positions in x
    Y::MVector{se().segments+1, MyFloat}   # vector of particle positions in y
    Z::MVector{se().segments+1, MyFloat}   # vector of particle positions in z
end 

# extended SysState containing derived values for plotting
struct ExtSysState
    time::Float64                          # time since launch in seconds
    orient::UnitQuaternion{Float32}        # orientation of the kite
    X::MVector{se().segments+1, MyFloat}   # vector of particle positions in x
    Y::MVector{se().segments+1, MyFloat}   # vector of particle positions in y
    Z::MVector{se().segments+1, MyFloat}   # vector of particle positions in z
    x::MyFloat                             # kite position in x
    y::MyFloat                             # kite position in y
    z::MyFloat                             # kite position in z
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
    X = range(0, stop=10, length=(se().segments)+1)
    Y = zeros(length(X))
    Z = (a .* cosh.(X./a) .- a) * height/ 5.430806 
    r_xyz = RotXYZ(pi/2, -pi/2, 0)
    q = UnitQuaternion(r_xyz)
    orient = MVector{4, Float32}(q.w, q.x, q.y, q.z)
    elevation = asin(Z[end]/X[end])
    return SysState(time, orient, elevation,0.,0.,0.,0.,0.,0.,X, Y, Z)
end

# create a demo flight log with given name [String] and duration [s]
function demo_syslog(name="Test flight"; duration=10)
    max_height = 6.03
    steps   = Int(duration * se().sample_freq) + 1
    time_vec = Vector{Float64}(undef, steps)
    myzeros = zeros(MyFloat, steps)
    elevation = Vector{Float64}(undef, steps)
    orient_vec = Vector{MVector{4, Float32}}(undef, steps)
    X_vec = Vector{MVector{se().segments+1, MyFloat}}(undef, steps)
    Y_vec = Vector{MVector{se().segments+1, MyFloat}}(undef, steps)
    Z_vec = Vector{MVector{se().segments+1, MyFloat}}(undef, steps)
    for i in range(0, length=steps)
        state = demo_state(max_height * i/steps, i/se().sample_freq)
        time_vec[i+1] = state.time
        orient_vec[i+1] = state.orient
        elevation[i+1] = asin(state.Z[end]/state.X[end])
        X_vec[i+1] = state.X
        Y_vec[i+1] = state.Y
        Z_vec[i+1] = state.Z
    end
    return StructArray{SysState}((time_vec, orient_vec, elevation, myzeros,myzeros,myzeros,myzeros,myzeros,myzeros, X_vec, Y_vec, Z_vec))
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
    myzeros = zeros(MyFloat, length(table.time))
    syslog = StructArray{SysState}((table.time, table.orient, table.elevation, table.azimuth, table.l_tether, table.v_reelout, table.force, table.depower, table.v_app, table.X, table.Y, table.Z))
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
