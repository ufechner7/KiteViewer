using Sundials, GLMakie, StaticArrays
using Revise

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

# create a SysState struct form the state vector u
function SysState(u)
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
    # TODO: return a SysState object
end

function rt_sim()
    t_end = 100.0
    integrator, dt = init_sim(t_end)

    @time for i in 1:round(t_end/dt)
        next_step(integrator, dt)
    end
end



# pos_x = sol[3*5+1, :]
# pos_z = sol[3*5+3, :]
# forces = KPS3.get_spring_forces(my_state, my_state.pos)
# println(forces)
# x=[my_state.pos[i][1] for i in 1:7]
# z=[my_state.pos[i][3] for i in 1:7]
rt_sim()

lines(times,heights)

# current_figure()