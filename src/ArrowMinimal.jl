using Rotations, StaticArrays, StructArrays, Arrow

const MyFloat = Float32
const SEGMENTS = 7                    # number of tether segments
const SAMPLE_FREQ = 20                # sample frequency in Hz
const DATA_PATH = "."                 # path for log files and other data

struct SysState
    time::Float64                     # time since launch in seconds
    orient::Quat                      # orientation of the kite
end 

struct FlightLog
    name::String
    log_2d::Vector{SysState}          # structs of vectors
    log_3d::Vector{SysState}          # vector of structs
end

# create a demo state with a given height and time
function demo_state(height=6.0, time=0.0)
    a = 10
    orient = UnitQuaternion(1.0,0,0,0)
    return SysState(time, orient)
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
    for i in range(1, length=steps)
        state=log[i]
        time_vec[i] = state.time
        orient_vec[i] = state.orient
    end
    return StructArray{SysState}((time_vec, orient_vec))
end

function demo_log(name="Test_flight"; duration=10)
    log_3d = demo_log3d(name, duration=duration)
    log_2d = vos2sov(log_3d)
    return FlightLog(name, log_2d, log_3d)
end

function save_log(log::FlightLog)
    filename=joinpath(DATA_PATH, log.name) * ".arrow"
    println(filename)
    Arrow.write(filename, log.log_2d)
    println(filename)
end

flight_log=demo_log()
save_log(flight_log)
