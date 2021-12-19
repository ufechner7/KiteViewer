using Sundials, GLMakie, StaticArrays
# Tutorial example showing how to use an implicit solver 
# It simulates a falling mass.

if ! @isdefined G_EARTH
    const G_EARTH  = [0.0, 0.0, -9.81]
end

# Type definitions
const SimFloat = Float64
const Vec3     = MVector{3, SimFloat}

# Falling mass.
# State vector y   = mass.pos, mass.vel
# Derivative   yd  = mass.vel, mass.acc
# Residual     res = (y.vel - yd.vel), (yd.acc - G_EARTH)     
function res1(res, yd, y::MVector{S, SimFloat}, p, t) where S
    res[1:3] .= y[4:6] - yd[1:3]
    res[4:6] .= yd[4:6] - G_EARTH
end

vel_0 = Vec3(0.0, 0.0, 50.0)    # Initial velocity
pos_0 = Vec3(0.0, 0.0,  0.0)    # Initial position
acc_0 = Vec3(0.0, 0.0, -9.81)   # Initial acceleration
y0  = vcat(pos_0, vel_0)    # Initial pos, vel
yd0 = vcat(vel_0, acc_0)    # Initial vel, acc

tspan = (0.0, 10.2)         # time span

differential_vars = ones(Bool, 6)
prob = DAEProblem(res1, yd0, y0, tspan, differential_vars=differential_vars)

sol = solve(prob, IDA(), saveat=0.1)

time = sol.t
y = sol.u

pos_z = sol[3, :]
vel_z = sol[6, :]

# plot the result
f = Figure()
ax1 = Axis(f[1, 1], yticklabelcolor = :blue, xlabel="time [s]", ylabel = "pos_z [m]")
ax2 = Axis(f[1, 1], yticklabelcolor = :red, yaxisposition = :right, ylabel = "vel_z [m/s]")
lines!(ax1, time, pos_z, color=:green)
lines!(ax2, time, vel_z, color=:red)
current_figure()
