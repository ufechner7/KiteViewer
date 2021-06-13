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

using Rotations, StaticArrays, StructArrays, RecursiveArrayTools, Arrow, YAML, LinearAlgebra
export SysState, ExtSysState, SysLog, MyFloat

export demo_state, demo_syslog, demo_log, load_log, syslog2extlog, save_log, rot, rot3d, ground_dist, calc_elevation, azimuth_east, se

const MyFloat = Float32               # type to use for postions
const DATA_PATH = "./data"            # path for log files and other data

mutable struct Settings
    project::String
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
    sim_time::Float64
end
const SETTINGS = Settings("","","",0,0,0,0,"",0,0,0,0,0,0,0,[],[],[],[],0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

# getter function for the Settings struct
function se()
    if SETTINGS.segments == 0
        # determine which project to load
        dict = YAML.load_file(joinpath(DATA_PATH, "system.yaml"))
        SETTINGS.project = dict["system"]["project"]
        # load project from YAML
        dict = YAML.load_file(joinpath(DATA_PATH, SETTINGS.project))
        SETTINGS.log_file    = dict["system"]["log_file"]
        SETTINGS.segments    = dict["system"]["segments"]
        SETTINGS.sample_freq = dict["system"]["sample_freq"]
        SETTINGS.time_lapse  = dict["system"]["time_lapse"]
        SETTINGS.sim_time    = dict["system"]["sim_time"]
        SETTINGS.zoom        = dict["system"]["zoom"]
        SETTINGS.fixed_font  = dict["system"]["fixed_font"]

        SETTINGS.l_tether    = dict["initial"]["l_tether"]
        SETTINGS.v_reel_out   = dict["initial"]["v_reel_out"]
        SETTINGS.elevation   = dict["initial"]["elevation"]

        SETTINGS.c0          = dict["steering"]["c0"]
        SETTINGS.c_s         = dict["steering"]["c_s"]
        SETTINGS.c2_cor      = dict["steering"]["c2_cor"]
        SETTINGS.k_ds        = dict["steering"]["k_ds"]

        SETTINGS.alpha_d_max = dict["depower"]["alpha_d_max"]

        SETTINGS.model       = dict["kite"]["model"]
        SETTINGS.area        = dict["kite"]["area"]
        SETTINGS.rel_side_area = dict["kite"]["rel_side_area"]
        SETTINGS.mass        = dict["kite"]["mass"]
        SETTINGS.alpha_cl    = dict["kite"]["alpha_cl"]
        SETTINGS.cl_list     = dict["kite"]["cl_list"]
        SETTINGS.alpha_cd    = dict["kite"]["alpha_cd"]
        SETTINGS.cd_list     = dict["kite"]["cd_list"]

        SETTINGS.l_bridle    = dict["bridle"]["l_bridle"]
        SETTINGS.d_line      = dict["bridle"]["d_line"]

        SETTINGS.kcu_mass    = dict["kcu"]["mass"]

        SETTINGS.cd_tether   = dict["tether"]["cd_tether"]
        SETTINGS.d_tether    = dict["tether"]["d_tether"]
        SETTINGS.damping     = dict["tether"]["damping"]
        SETTINGS.c_spring    = dict["tether"]["c_spring"]

        SETTINGS.v_wind      = dict["environment"]["v_wind"]
        SETTINGS.h_ref       = dict["environment"]["h_ref"]
        SETTINGS.rho_0       = dict["environment"]["rho_0"]
        SETTINGS.z0          = dict["environment"]["z0"]
        SETTINGS.alpha       = dict["environment"]["alpha"]
        SETTINGS.profile_law = dict["environment"]["profile_law"]
    end
    return SETTINGS
end

# basic system state; one of these will be saved per time step
struct SysState{P}
    time::Float64                          # time since start of simulation in seconds
    orient::MVector{4, Float32}            # orientation of the kite (quaternion)
    elevation::MyFloat                     # elevation angle in radians
    azimuth::MyFloat                       # azimuth angle in radians
    l_tether::MyFloat                      # tether length [m]
    v_reelout::MyFloat                     # reel out velocity [m/s]
    force::MyFloat                         # tether force [N]
    depower::MyFloat                       # depower settings 
    v_app::MyFloat                         # apparent wind speed [m/s]
    X::MVector{P, MyFloat}   # vector of particle positions in x
    Y::MVector{P, MyFloat}   # vector of particle positions in y
    Z::MVector{P, MyFloat}   # vector of particle positions in z
end 


# extended SysState containing derived values for plotting
struct ExtSysState{P}
    time::Float64                          # time since launch in seconds
    orient::UnitQuaternion{Float32}        # orientation of the kite
    X::MVector{P, MyFloat}   # vector of particle positions in x
    Y::MVector{P, MyFloat}   # vector of particle positions in y
    Z::MVector{P, MyFloat}   # vector of particle positions in z
    x::MyFloat                             # kite position in x
    y::MyFloat                             # kite position in y
    z::MyFloat                             # kite position in z
end

# flight log, containing the basic data as struct of arrays 
# and in addition an extended view on the data that includes derived/ calculated values for plotting
# finally meta data like the file name of the log file is included
struct SysLog{P}
    name::String
    syslog::StructArray{SysState{P}}    # struct of vectors
    extlog::StructArray{ExtSysState{P}} # struct of vectors, containing derived values
end

# functions
function __init__()
    SETTINGS.segments=0 # force loading of settings.yaml
end

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

# calculate the rotation matrix of the kite based on the position of the
# last two tether particles and the apparent wind speed vector
function rot(pos_kite, pos_before, v_app)
    delta = pos_kite - pos_before
    c = -delta
    z = normalize(c)
    y = normalize(cross(-v_app, c))
    x = normalize(cross(y, c))
    rot = rot3d([0,-1.0,0], [1.0,0,0], [0,0,-1.0], z, y, x)
end

# Calculate the ground distance from the kite position (x,y,z, z up).
function ground_dist(vec)
    sqrt(vec[1]^2 + vec[2]^2)
end 

# Calculate the elevation angle in radian from the kite position 
function calc_elevation(vec)
    atan(vec[3] / ground_dist(vec))
end

# Calculate the azimuth angle in radian from the kite position in ENU reference frame.
# Zero east. Positive direction clockwise seen from above.
# Valid range: -pi .. pi.
function azimuth_east(vec)
    return -atan(vec[2], vec[1])
end

# create a demo state with a given height and time
function demo_state(P, height=6.0, time=0.0)
    a = 10
    X = range(0, stop=10, length=(P+1)
    Y = zeros(length(X))
    Z = (a .* cosh.(X./a) .- a) * height/ 5.430806 
    r_xyz = RotXYZ(pi/2, -pi/2, 0)
    q = UnitQuaternion(r_xyz)
    orient = MVector{4, Float32}(q.w, q.x, q.y, q.z)
    elevation = calc_elevation([X[end], 0.0, Z[end]])
    return SysState{P}(time, orient, elevation,0.,0.,0.,0.,0.,0.,X, Y, Z)
end

# create a demo flight log with given name [String] and duration [s]
function demo_syslog(P, name="Test flight"; duration=10)
    max_height = 6.03
    steps   = Int(duration * se().sample_freq) + 1
    time_vec = Vector{Float64}(undef, steps)
    myzeros = zeros(MyFloat, steps)
    elevation = Vector{Float64}(undef, steps)
    orient_vec = Vector{MVector{4, Float32}}(undef, steps)
    X_vec = Vector{MVector{P, MyFloat}}(undef, steps)
    Y_vec = Vector{MVector{P, MyFloat}}(undef, steps)
    Z_vec = Vector{MVector{P, MyFloat}}(undef, steps)
    for i in range(0, length=steps)
        state = demo_state(P, max_height * i/steps, i/se().sample_freq)
        time_vec[i+1] = state.time
        orient_vec[i+1] = state.orient
        elevation[i+1] = asin(state.Z[end]/state.X[end])
        X_vec[i+1] = state.X
        Y_vec[i+1] = state.Y
        Z_vec[i+1] = state.Z
    end
    return StructArray{SysState{P}}((time_vec, orient_vec, elevation, myzeros,myzeros,myzeros,myzeros,myzeros,myzeros, X_vec, Y_vec, Z_vec))
end

# extend a flight systom log with the fieds x, y, and z (kite positions) and convert the orientation to the type UnitQuaternion
function syslog2extlog(P, syslog)
    x_vec = @view VectorOfArray(syslog.X)[end,:]
    y_vec = @view VectorOfArray(syslog.Y)[end,:]
    z_vec = @view VectorOfArray(syslog.Z)[end,:]
    orient_vec = Vector{UnitQuaternion{Float32}}(undef, length(syslog.time))
    for i in range(1, length=length(syslog.time))
        orient_vec[i] = UnitQuaternion(syslog.orient[i])
    end
    return StructArray{ExtSysState{P}}((syslog.time, orient_vec, syslog.X, syslog.Y, syslog.Z, x_vec, y_vec, z_vec))    
end

# create an artifical log file for demonstration purposes
function demo_log(P, name="Test_flight"; duration=10)
    syslog = demo_syslog(P, name, duration=duration)
    return SysLog{P}(name, syslog, syslog2extlog(P, syslog))
end

function save_log(P, flight_log)
    Arrow.ArrowTypes.registertype!(SysState{P}, SysState)
    filename=joinpath(DATA_PATH, flight_log.name) * ".arrow"
    Arrow.write(filename, flight_log.syslog, compress=:lz4)
end

function load_log(P, filename::String)
    Arrow.ArrowTypes.registertype!(SysState{P}, SysState)
    Arrow.ArrowTypes.registertype!(MVector{4, Float32}, MVector{4, Float32})
    if isnothing(findlast(isequal('.'), filename))
        fullname = joinpath(DATA_PATH, filename) * ".arrow"
    else
        fullname = joinpath(DATA_PATH, filename) 
    end
    table = Arrow.Table(fullname)
    myzeros = zeros(MyFloat, length(table.time))
    syslog = StructArray{SysState{P}}((table.time, table.orient, table.elevation, table.azimuth, table.l_tether, table.v_reelout, table.force, table.depower, table.v_app, table.X, table.Y, table.Z))
    return SysLog{P}(basename(fullname[1:end-6]), syslog, syslog2extlog(P, syslog))
end

function test(save=false)
    if save
        log_to_save=demo_log(7)
        save_log(7, log_to_save)
    end
    return(load_log(7, "Test_flight.arrow"))
end

precompile(load_log, (Int64, String,))     

end
