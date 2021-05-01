# Import the compressed log file of a simulation (.csv.xz) and convert it to an arrow file that can be re-played
# by the KiteViewer. 
#
# Available fields in the input (some of them contain arrays):
# time,azimuth,course,depower,elevation,force,heading,height,kite_distance,l_tether,position,prediction,set_force,steering,
#      sync_speed,system_state,time,time_rel,turn_rate,v_app,v_app_norm,v_reelout,vel_kite,yaw_angle

using CodecXz, CSV, DataFrames, StaticArrays, StructArrays, Rotations, LinearAlgebra
include("./Utils.jl")
using .Utils

# Constants
const CSV_FILE = se().log_file * ".csv"

# Functions
function decompress(in, out)
    stream = open(in)
    output = open(out,"w")
    for line in eachline(XzDecompressorStream(stream))
        println(output, line)
    end
    close(stream)
    close(output)
end

function parse_array(pos)
    res = replace(pos, ['\n', ']', '['] => "")
    arr = parse.(MyFloat, split(res))
    arr = reshape(arr, (3, length(arr) ÷ 3))
end

function parse_vector(pos)
    res = replace(pos, [')', '('] => "")
    res = replace(res, ',' => " ")
    arr = parse.(MyFloat, split(res))
end

function getX(pos); return parse_array(pos)[1,:]; end
function getY(pos); return parse_array(pos)[2,:]; end
function getZ(pos); return parse_array(pos)[3,:]; end

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

function df2syslog(df)
    orient = MVector(1.0f0, 0, 0, 0)
    steps = size(df)[1]
    orient_vec = Vector{MVector{4, Float32}}(undef, steps)
    elevation=Vector{Float32}(undef, steps)
    azimuth=Vector{Float32}(undef, steps)
    v_reelout=Vector{Float32}(undef, steps)
    force=Vector{Float32}(undef, steps)
    myzeros = zeros(MyFloat, steps)
    V_app = df.v_app
    for i in range(1, length=steps)
        pos_kite = [df.X[i][end], df.Y[i][end], df.Z[i][end]]
        pos_before = [df.X[i][end-1], df.Y[i][end-1], df.Z[i][end-1]]
        v_app = V_app[i]
        rotation = rot(pos_kite, pos_before, v_app)
        q = UnitQuaternion(rotation)
        orient_vec[i] = MVector{4, Float32}(q.w, q.x, q.y, q.z)
        elevation[i] = df.elevation[i]
        azimuth[i] = df.azimuth[i]
        force[i] = df.force[i]
        v_reelout[i] = df.v_reelout[i]
    end
    return StructArray{SysState}((df.time_rel, orient_vec, elevation, azimuth, myzeros, v_reelout, force, myzeros, myzeros, df.X*se().zoom, df.Y*se().zoom, df.Z*se().zoom))
end

# Main program
decompress(se().log_file * ".csv.xz", CSV_FILE)

# convert to DataFrame, cleanup, transform
data = DataFrame(CSV.File(CSV_FILE))
df = select(data, :time_rel, :position, :v_app => :v_app_str, :azimuth, :elevation, :force, :v_reelout)
df[!, :X] = getX.(df.position)
df[!, :Y] = getY.(df.position)
df[!, :Z] = getZ.(df.position)
df[!, :v_app] = parse_vector.(df.v_app_str)
select!(df, Not(:position))
select!(df, Not(:v_app_str))

# convert to arrow format and save
syslog = df2syslog(df)
name = basename(CSV_FILE)[1:end-4]
save_log(SysLog(name, syslog, syslog2extlog(syslog)))

