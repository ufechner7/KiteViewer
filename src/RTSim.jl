module RTSim

using Sundials, StaticArrays, Rotations
using Utils, KPS3, KCU_Sim

export init_sim, get_height, get_sysstate, next_step

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
    v_reelout = my_state.v_reel_out
    force = get_force(my_state)
    return Utils.SysState(my_state.t_0, orient, elevation, azimuth, 0., v_reelout, force, 0., 0., X, Y, Z)
end

function get_height()
    my_state = KPS3.get_state()
    my_state.pos[end][3]
end

function init_sim(t_end)
    init_kcu()
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
    KCU_Sim.on_timer()
    # KPS3.set_depower_steering(KPS3.state, KPS3.state.depower, get_steering())
    # KPS3.set_depower_steering(KPS3.state, 0.0, 0.0)
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

precompile(init_sim, (Float64,))  
precompile(next_step, (Sundials.IDAIntegrator,))
end