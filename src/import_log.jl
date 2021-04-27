# Import the compressed log file of a simulation (.csv.xz) and convert it to an arrow file that can be re-played
# by the KiteViewer. 
#
# Available fields (some of them contain arrays):
# time,azimuth,course,depower,elevation,force,heading,height,kite_distance,l_tether,position,prediction,set_force,steering,
#      sync_speed,system_state,time,time_rel,turn_rate,v_app,v_app_norm,v_reelout,vel_kite,yaw_angle

# TODO: calculate the orientation based on v_app and the last tether segment
# TODO: convert v_app in the data frame into a julia vector

using CodecXz, CSV, DataFrames, StaticArrays, StructArrays
include("./Utils.jl")
using .Utils

# Constants
const FILENAME = "data/log_8700W_8ms.csv.xz"
const CSV_FILE = FILENAME[1:end-3]

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

function getX(pos); return parse_array(pos)[1,:]; end
function getY(pos); return parse_array(pos)[2,:]; end
function getZ(pos); return parse_array(pos)[3,:]; end

function df2syslog(df)
    orient = MVector(1.0f0, 0, 0, 0)
    steps = size(df)[1]
    orient_vec = Vector{MVector{4, Float32}}(undef, steps)
    for i in range(1, length=steps)
        orient_vec[i] = orient
    end
    return StructArray{SysState}((df.time_rel, orient_vec, df.X, df.Y, df.Z))
end

# calculate the rotation matrix of the kite based on the position of the
# last two tether particles and the apparent wind speed vector
function rot(pos_kite, pos_before, v_app)
    delta = pos_kite - pos_before
    c = -delta
    z = normalize(c)
    y = normalize(cross(v_app, c))
    x = normalize(cross(y, c))
    rot = rot3d([0,-1.0,0], [1.0,0,0], [0,0,-1.0], x, y, z)
end

# Main program
decompress(FILENAME, CSV_FILE)

# convert to DataFrame, cleanup, transform
data = DataFrame(CSV.File(CSV_FILE))
df = select(data, :time_rel, :position, :v_app)
df[!, :X] = getX.(df.position)
df[!, :Y] = getY.(df.position)
df[!, :Z] = getZ.(df.position)
select!(df, Not(:position))

# convert to arrow format and save
syslog = df2syslog(df)
name = basename(CSV_FILE)[1:end-4]
save_log(SysLog(name, syslog, syslog2extlog(syslog)))
