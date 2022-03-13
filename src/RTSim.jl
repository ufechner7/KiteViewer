module RTSim

using Sundials, StaticArrays, Rotations
using KiteUtils, KiteModels, KitePodSimulator

export init_sim, get_height, get_sysstate, next_step

const SEGMENTS = se().segments
const kcu = KCU()
const kps = KPS3(kcu)

# create a SysState struct from KiteModels.state
function SysState(P)
    pos = kps.pos
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
    v_app = kps.v_apparent
    rotation = rot(pos_kite, pos_before, v_app)
    q = QuatRotation(rotation)
    orient = MVector{4, Float32}(Rotations.params(q))

    elevation = calc_elevation(pos_kite)
    azimuth = azimuth_east(pos_kite)
    v_reelout = kps.v_reel_out
    force = winch_force(kps)
    return KiteUtils.SysState{P}(kps.t_0, orient, elevation, azimuth, 0., v_reelout, force, 0., 0., X, Y, Z)
end

function get_height()
    kps.pos[end][3]
end

function init_sim(t_end)
    init_kcu(kcu, se())
    clear(kps)
    y0, yd0 = KiteModels.find_steady_state(kps)

    # forces = KiteModels.get_spring_forces(my_state, my_state.pos)
    # println(forces)

    differential_vars =  ones(Bool, 36)
    solver = IDA(linear_solver=:Dense)
    tspan = (0.0, t_end) 

    prob = DAEProblem(residual!, yd0, y0, tspan, kps, differential_vars=differential_vars)
    integrator = init(prob, solver, abstol=0.000001, reltol=0.001)
    return integrator
end

function get_sysstate(P)
    SysState(P)
end

function next_step(P, integrator, dt)
    KitePodSimulator.on_timer(kcu)
    KiteModels.set_depower_steering(kps, 0.236, get_steering(kcu))
    step!(integrator, dt, true)
    u = integrator.u
    t = integrator.t
    # if iseven(Int64(round(t)))
    #     v_ro = -1.0
    # else
    #     v_ro = 1.0
    # end
    v_ro = 0.0
    set_v_reel_out(kps, v_ro, t)
    SysState(P)
end

precompile(init_sim, (Float64,))  
precompile(next_step, (Int64, Sundials.IDAIntegrator,))
end