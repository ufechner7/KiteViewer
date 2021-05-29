using Sundials, GLMakie, StaticArrays, Rotations
using Revise

# TODO:
# 1. implement function SysState()
#    a. for the particle positions - DONE -
#    b. for the orientation
# 2. integrate RTSim in KiteViewer by calling init_sim and next_step
# 3. bind steering and depowering to cursor keys 

if ! @isdefined KPS3
    includet("../src/KPS3.jl")
    using .KPS3
end

if ! @isdefined Utils
    include("Utils.jl")
    using .Utils
end

heights=Float64[]
times=Float64[]

const SEGMENTS = KPS3.SEGMENTS

# create a SysState struct from KPS3.state
function SysState()
    my_state = KPS3.get_state()
    pos = my_state.pos
    X = zeros(MVector{SEGMENTS+1, MyFloat})
    Y = zeros(MVector{SEGMENTS+1, MyFloat})
    Z = zeros(MVector{SEGMENTS+1, MyFloat})
    for i in 1:SEGMENTS+1
        X[i] = pos[i][1]
        Y[i] = pos[i][2]
        Z[i] = pos[i][3]
    end
    r_xyz = RotXYZ(pi/2, -pi/2, 0)
    q = UnitQuaternion(r_xyz)
    orient = MVector{4, Float32}(q.w, q.x, q.y, q.z)
    elevation = calc_elevation([X[end], 0.0, Z[end]])
    return Utils.SysState(my_state.t_0, orient, elevation,0.,0.,0.,0.,0.,0.,X, Y, Z)
end

function init_sim(t_end)
    my_state = KPS3.get_state()
    clear(my_state)
    y0, yd0 = KPS3.find_steady_state(my_state)

    forces = KPS3.get_spring_forces(my_state, my_state.pos)
    println(forces)

    differential_vars =  ones(Bool, 36)
    solver = IDA(linear_solver=:Dense)
    dt = 0.05
    tspan = (0.0, t_end) 

    prob = DAEProblem(residual!, yd0, y0, tspan, differential_vars=differential_vars)
    integrator = init(prob, solver, abstol=0.000001, reltol=0.001)
    return integrator, dt
end

function get_sysstate()
    SysState()
end

function next_step(integrator, dt)
    step!(integrator, dt, true)
    u = integrator.u
    t = integrator.t
    # @show round(u[18],digits=6), round(t,digits=2)
    push!(heights, u[18])
    push!(times, t)
    if iseven(Int64(round(t)))
        v_ro = -1.0
    else
        v_ro = 1.0
    end
    my_state = KPS3.get_state()
    KPS3.set_v_reel_out(my_state, v_ro, t)
    SysState()
end

function rt_sim()
    t_end = 100.0
    integrator, dt = init_sim(t_end)

    @time for i in 1:round(t_end/dt)
        next_step(integrator, dt)
    end
end

function plot_height()
    rt_sim()
    lines(times,heights)
end

# current_figure()