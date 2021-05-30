using Sundials, StaticArrays, Rotations

# TODO:
# 1. implement function SysState() - DONE -
# 2. integrate RTSim in KiteViewer by calling init_sim and next_step
# 3. bind steering and depowering to cursor keys 

if ! @isdefined KPS3
    include("../src/KPS3.jl")
    using .KPS3
end

if ! @isdefined Utils
    include("Utils.jl")
    using .Utils
end

const SEGMENTS = KPS3.SEGMENTS

# create a SysState struct from KPS3.state
function SysState()
    my_state = KPS3.get_state()
    pos = my_state.pos
    X = zeros(MVector{SEGMENTS+1, MyFloat})
    Y = zeros(MVector{SEGMENTS+1, MyFloat})
    Z = zeros(MVector{SEGMENTS+1, MyFloat})
    for i in 1:SEGMENTS+1
        X[i] = pos[i][1] * se().zoom
        Y[i] = pos[i][2] * se().zoom
        Z[i] = pos[i][3] * se().zoom
    end
    
    pos_kite   = pos[end]
    pos_before = pos[end-1]
    v_app = my_state.v_apparent
    rotation = rot(pos_kite, pos_before, v_app)
    q = UnitQuaternion(rotation)
    orient = MVector{4, Float32}(q.w, q.x, q.y, q.z)

    elevation = calc_elevation(pos_kite)
    azimuth = azimuth_east(pos_kite)
    return Utils.SysState(my_state.t_0, orient, elevation, azimuth,0.,0.,0.,0.,0.,X, Y, Z)
end

function get_height()
    my_state = KPS3.get_state()
    my_state.pos[end][3]
end

function init_sim(t_end)
    my_state = KPS3.get_state()
    clear(my_state)
    y0, yd0 = KPS3.find_steady_state(my_state)

    # forces = KPS3.get_spring_forces(my_state, my_state.pos)
    # println(forces)

    differential_vars =  ones(Bool, 36)
    solver = IDA(linear_solver=:Dense)
    dt = 1.0 / se().sample_freq
    tspan = (0.0, t_end) 

    prob = DAEProblem(residual!, yd0, y0, tspan, differential_vars=differential_vars)
    integrator = init(prob, solver, abstol=0.000001, reltol=0.001)
    return integrator
end

function get_sysstate()
    SysState()
end

function next_step(integrator, dt)
    step!(integrator, dt, true)
    u = integrator.u
    t = integrator.t
    if iseven(Int64(round(t)))
        v_ro = -1.0
    else
        v_ro = 1.0
    end
    set_v_reel_out(KPS3.state, v_ro, t)
    SysState()
end

# @async begin
#     println("Start...")
#     init_sim(10.0)
#     println("Stop...")
# end

# function rt_sim()
#     t_end = se().sim_time
#     integrator = init_sim(t_end)
#     dt = 1.0 / se().sample_freq

#     @time for i in 1:round(t_end/dt)
#         next_step(integrator, dt)
#     end
# end
