# Import the compressed log file of a simulation (.csv.xz) and convert it to an arrow file that can be re-played
# by the KiteViewer. 
#
# Available fields (some of them contain arrays):
# time,azimuth,course,depower,elevation,force,heading,height,kite_distance,l_tether,position,prediction,set_force,steering,
#      sync_speed,system_state,time,time_rel,turn_rate,v_app,v_app_norm,v_reelout,vel_kite,yaw_angle

# TODO: calculate the orientation based on v_app and the last tether segment
# TODO: write arrow file

using CodecXz, CSV, DataFrames

const FILENAME = "data/log_8700W_8ms.csv.xz"
const CSV_FILE = FILENAME[1:end-3]

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
    arr = parse.(Float64, split(res))
    arr = reshape(arr, (3, length(arr) ÷ 3))
end

function getX(pos); return parse_array(pos)[1,:]; end
function getY(pos); return parse_array(pos)[2,:]; end
function getZ(pos); return parse_array(pos)[3,:]; end

decompress(FILENAME, CSV_FILE)

data = DataFrame(CSV.File(CSV_FILE))
df = select(data, :time_rel, :position)
df[!, :X] = getX.(df.position)
df[!, :Y] = getY.(df.position)
df[!, :Z] = getZ.(df.position)
select!(df, Not(:position))
