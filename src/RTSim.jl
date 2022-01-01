module RTSim

using Sundials, StaticArrays, Rotations
using KiteUtils, KiteModels, KitePodSimulator

export init_sim, get_height, get_sysstate, next_step

const SEGMENTS = se().segments
const kcu = KCU()

# create a SysState struct from KiteModels.state
function SysState(P)
    my_state = KiteModels.get_state()
    pos = my_state.pos
    X = zeros(MVector{P, MyFloat})
    Y = zeros(MVector{P, MyFloat})
    Z = zeros(MVector{P, MyFloat})
    for i in 1:P
        X[i] = pos[i][1] * se().zoom
        Y[i] = pos[i][2] * se().zoom
        Z[i] = pos[i][3] * se().zoom
    end
    
    pos_kite   = pos[end]
    pos_before = pos[end-1]
    v_app = my_state.v_apparent
    rotation = rot(pos_kite, pos_before, v_app)
    q = QuatRotation(rotation)
    orient = MVector{4, Float32}(Rotations.params(q))

    elevation = calc_elevation(pos_kite)
    azimuth = azimuth_east(pos_kite)
    v_reelout = my_state.v_reel_out
    force = get_force(my_state)
    return KiteUtils.SysState{P}(my_state.t_0, orient, elevation, azimuth, 0., v_reelout, force, 0., 0., X, Y, Z)
end

function get_height()
    my_state = KiteModels.get_state()
    my_state.pos[end][3]
end

function init_sim(t_end)
    init_kcu(kcu, se())
    my_state = KiteModels.get_state()
    clear(my_state)
    y0, yd0 = KiteModels.find_steady_state(my_state)

    # forces = KiteModels.get_spring_forces(my_state, my_state.pos)
    # println(forces)

    differential_vars =  ones(Bool, 36)
    solver = IDA(linear_solver=:Dense)
    dt = 1.0 / se().sample_freq
    tspan = (0.0, t_end) 

    prob = DAEProblem(residual!, yd0, y0, tspan, differential_vars=differential_vars)
    integrator = init(prob, solver, abstol=0.000001, reltol=0.001)
    return integrator
end

function get_sysstate(P)
    SysState(P)
end

function next_step(P, integrator, dt)
    KitePodSimulator.on_timer(kcu)
    KiteModels.set_depower_steering(KiteModels.state, kcu, 0.236, get_steering(kcu))
    step!(integrator, dt, true)
    u = integrator.u
    t = integrator.t
    # if iseven(Int64(round(t)))
    #     v_ro = -1.0
    # else
    #     v_ro = 1.0
    # end
    v_ro = 0.0
    set_v_reel_out(KiteModels.state, v_ro, t)
    SysState(P)
end

precompile(init_sim, (Float64,))  
precompile(next_step, (Int64, Sundials.IDAIntegrator,))
end