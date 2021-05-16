#= MIT License

Copyright (c) 2020, 2021 Uwe Fechner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. =#

#= Model of a kite-power system in implicit form: residual = f(y, yd)

This model implements a 3D mass-spring system with reel-out. It uses five tether segments (the number can be
configured in the file data/settings.yaml). The kite is modelled as additional mass at the end of the tether.
The spring constant and the damping decrease with the segment length. The aerodynamic kite forces are
calculated, depending on reel-out speed, depower and steering settings. 

Scientific background: http://arxiv.org/abs/1406.6218 =#

module KPS3

using Dierckx, StaticArrays, LinearAlgebra, Parameters

if ! @isdefined Utils
    include("Utils.jl")
    using .Utils
end

if ! @isdefined KCU_Sim
    include("KCU_Sim.jl")
    using .KCU_Sim
end

export State, Vec3, SimFloat                                                            # types
export calc_cl, calc_rho, calc_wind_factor, calc_drag, calc_set_cl_cd, clear, residual! # functions
export set_v_reel_out, set_depower_steering                                             # setters  

# Constants
@consts begin
    set    = se()                 # settings from settings.yaml
    SEGMENTS = se().segments
    G_EARTH = 9.81                # gravitational acceleration
    PERIOD_TIME = 1.0 / set.sample_freq
    C0 = -0.0032                  # steering offset
    C2_COR =  0.93
    KCU_MASS  =  8.4
    REL_SIDE_AREA = 0.5
    STEERING_COEFFICIENT = 0.6
    BRIDLE_DRAG = 1.1
    ALPHA = set.alpha
    ALPHA_ZERO = 0.0
    K_ds = 1.5                    # influence of the depower angle on the steering sensitivity
    MAX_ALPHA_DEPOWER = 31.0
    V_REEL_OUT = 4.0              # initial reel out speed

    ALPHA_CL = [-180.0, -160.0, -90.0, -20.0, -10.0,  -5.0,  0.0, 20.0, 40.0, 90.0, 160.0, 180.0]
    CL_LIST  = [   0.0,    0.5,   0.0,  0.08, 0.125,  0.15,  0.2,  1.0,  1.0,  0.0,  -0.5,   0.0]
    ALPHA_CD = [-180.0, -170.0, -140.0, -90.0, -20.0, 0.0, 20.0, 90.0, 140.0, 170.0, 180.0]
    CD_LIST  = [   0.5,    0.5,    0.5,   1.0,   0.2, 0.1,  0.2,  1.0,   0.5,   0.5,   0.5]
    calc_cl = Spline1D(ALPHA_CL, CL_LIST)
    calc_cd = Spline1D(ALPHA_CD, CD_LIST)
end

# Type definitions
const SimFloat = Float64
const Vec3     = MVector{3, SimFloat}                   

@with_kw mutable struct State{S, T}
    v_wind::T =           [set.v_wind, 0, 0]    # wind vector at the height of the kite
    v_wind_gnd::T =       [set.v_wind, 0, 0]    # wind vector at reference height
    v_wind_tether::T =    [set.v_wind, 0, 0]
    v_apparent::T =       zeros(3)
    v_app_perp::T =       zeros(3)
    drag_force::T =       zeros(3)
    lift_force::T =       zeros(3)
    steering_force::T =   zeros(3)
    last_force::T =       zeros(3)
    spring_force::T =     zeros(3)
    total_forces::T =     zeros(3)
    force::T =            zeros(3)
    unit_vector::T =      zeros(3)
    av_vel::T =           zeros(3)
    kite_y::T =           zeros(3)
    segment::T =          zeros(3)
    last_tether_drag::T = zeros(3)
    acc::T =              zeros(3)     
    vec_z::T =            zeros(3)
    pos_kite::T =         zeros(3)
    v_kite::T =           zeros(3)        
    res1::SVector{set.segments+1, Vec3} = zeros(SVector{set.segments+1, Vec3})
    res2::SVector{set.segments+1, Vec3} = zeros(SVector{set.segments+1, Vec3})
    seg_area::S =         zero(S)   # area of one tether segment
    c_spring::S =         zero(S)   # depends on lenght of tether segement
    length::S =           set.l_tether
    damping::S =          zero(S)   # depends on lenght of tether segement
    area::S =             zero(S)
    last_v_app_norm_tether::S = zero(S)
    param_cl::S =         0.2
    param_cd::S =         1.0
    v_app_norm::S =       zero(S)
    cor_steering::S =     zero(S)
    psi::S =              zero(S)
    beta::S =             1.22      # elevation angle in radian; initial value about 70 degrees
    last_alpha::S =        0.1
    alpha_depower::S =     0.0
    t_0::S =               0.0      # relative start time of the current time interval
    v_reel_out::S =        0.0
    last_v_reel_out::S =   0.0
    l_tether::S =          0.0
    rho::S =               set.rho_0
    depower::S =           0.0
    steering::S =          0.0
    initial_masses::MVector{set.segments+1, SimFloat} = ones(set.segments+1) * 0.011 * set.l_tether / set.segments # Dyneema: 1.1 kg/ 100m
    masses::MVector{set.segments+1, SimFloat}         = ones(set.segments+1)
end

const state = State{SimFloat, Vec3}()

# Functions
function get_state()
    state
end

# Calculate the air densisity as function of height
calc_rho(height) = set.rho_0 * exp(-height / 8550.0)

# Calculate the wind speed at a given height and reference height.
# Fast version of: (height / set.h_ref)^ALPHA
calc_wind_factor(height) = exp(ALPHA * log((height / set.h_ref)))

# calculate the drag of one tether segment
function calc_drag(s, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area)
    s.v_apparent .= s.v_wind_tether - v_segment
    v_app_norm = norm(s.v_apparent)
    v_app_perp .= s.v_apparent .- dot(s.v_apparent, unit_vector) .* unit_vector
    last_tether_drag .= -0.5 * set.cd_tether * rho * norm(v_app_perp) * area .* v_app_perp
    v_app_norm
end 

#     pos_kite:     position of the kite
#     rho:          air density [kg/m^3]
#     paramCD:      drag coefficient (function of power settings)
#     paramCL:      lift coefficient (function of power settings)
#     rel_steering: value between -1.0 and +1.0
function calc_aero_forces(s, pos_kite, v_kite, rho, rel_steering)
    s.v_apparent    .= s.v_wind - v_kite
    s.v_app_norm     = norm(s.v_apparent)
    s.drag_force    .= s.v_apparent ./ s.v_app_norm
    s.kite_y        .= normalize(cross(pos_kite, s.drag_force))
    K                = 0.5 * rho * s.v_app_norm^2 * set.area
    s.lift_force    .= K * s.param_cl .* normalize(cross(s.drag_force, s.kite_y))   
    # some additional drag is created while steering
    s.drag_force    .*= K * s.param_cd * BRIDLE_DRAG * (1.0 + 0.6 * abs(rel_steering)) 
    s.cor_steering    = C2_COR / s.v_app_norm * sin(s.psi) * cos(s.beta)
    s.steering_force .= -K * REL_SIDE_AREA * STEERING_COEFFICIENT * (rel_steering + s.cor_steering) .* s.kite_y
    s.last_force     .= -(s.lift_force + s.drag_force + s.steering_force) 
    # println(s.last_force) # [ -2.75319859e+02  -3.53069933e-05  -8.72978299e+02]
    nothing
end

# Calculate the vector res1, that depends on the velocity and the acceleration.
# The drag force of each segment is distributed equaly on both particles.
function calc_res(s, pos1, pos2, vel1, vel2, mass, veld, result, i)
    s.segment .= pos1 - pos2
    height = (pos1[3] + pos2[3]) * 0.5
    rho = calc_rho(height)               # calculate the air density
    rel_vel = vel1 - vel2                # calculate the relative velocity
    s.av_vel .= 0.5 * (vel1 + vel2)
    norm1 = norm(s.segment)
    s.unit_vector .= normalize(s.segment) # unit vector in the direction of the tether
    # # look at: http://en.wikipedia.org/wiki/Vector_projection
    # # calculate the relative velocity in the direction of the spring (=segment)
    spring_vel = dot(s.unit_vector, rel_vel)

    k2 = 0.05 * s.c_spring             # compression stiffness tether segments
    if norm1 - s.length > 0.0
        s.spring_force .= (s.c_spring * (norm1 - s.length) + s.damping * spring_vel) .* s.unit_vector
    else
        s.spring_force .= k2 * ((norm1 - s.length) + (s.damping * spring_vel)) .* s.unit_vector
    end

    s.area = norm1 * set.d_tether/1000.0
    s.last_v_app_norm_tether = calc_drag(s, s.av_vel, s.unit_vector, rho, s.last_tether_drag, s.v_app_perp, s.area)
    
    if i == set.segments+1
        s.area =  set.l_bridle * set.d_tether/1000.0
        s.last_v_app_norm_tether = calc_drag(s, s.av_vel, s.unit_vector, rho, s.last_tether_drag, s.v_app_perp, s.area)
        # TODO Check this equation
        s.force .= s.last_tether_drag + s.spring_force + 0.5 * s.last_tether_drag     
    else
        s.force .= s.spring_force + 0.5 * s.last_tether_drag
    end
   
    s.total_forces .= s.force + s.last_force
    s.last_force .= 0.5 * s.last_tether_drag - s.spring_force
    s.acc .= s.total_forces ./ mass # create the vector of the spring acceleration
    result .= veld - (s.acc - SVector(0, 0, G_EARTH))
    nothing
end

# Calculate the vector res1 using a vector expression, and calculate res2 using a loop
# that iterates over all tether segments. 
function loop(s, pos, vel, posd, veld, res1, res2)
    s.masses               .= s.length / (set.l_tether / set.segments) .* s.initial_masses
    s.masses[set.segments+1]   += (set.mass + KCU_MASS)
    res1[1] .= pos[1]
    res2[1] .= vel[1]
    for i in 2:set.segments+1
        res1[i] .= vel[i] - posd[i]
    end
    for i in set.segments+1:-1:2
        calc_res(s, pos[i], pos[i-1], vel[i], vel[i-1], s.masses[i], veld[i],  res2[i], i)
    end
    nothing
end

# Calculate the lift and drag coefficient as a function of the relative depower setting.
function set_cl_cd(s, alpha)   
    angle =  alpha * 180.0 / π + ALPHA_ZERO
    if angle > 180.0
        angle -= 360.0
    end
    if angle < -180.0
        angle += 360.0
    end
    s.param_cl = calc_cl(angle)
    s.param_cd = calc_cd(angle)
    nothing
end

# Calculate the angle of attack alpha from the apparend wind velocity vector
# v_app and the z unit vector of the kite reference frame.
function calc_alpha(v_app, vec_z)
    π/2.0 - acos(-dot(v_app, vec_z) / norm(v_app))
end

# Calculate the lift over drag ratio as a function of the direction vector of the last tether
# segment, the current depower setting and the apparent wind speed.
# Set the calculated CL and CD values. 
function calc_set_cl_cd(s, vec_c, v_app)
    s.vec_z .= normalize(vec_c)
    alpha = calc_alpha(v_app, s.vec_z) - s.alpha_depower
    set_cl_cd(s, alpha)
end

function clear(s)
    s.t_0 = 0.0                     # relative start time of the current time interval
    s.v_reel_out = 0.0
    s.last_v_reel_out = 0.0
    s.area = set.area
    # self.sync_speed = 0.0
    s.v_wind        .= [set.v_wind, 0, 0]    # wind vector at the height of the kite
    s.v_wind_gnd    .= [set.v_wind, 0, 0]    # wind vector at reference height
    s.v_wind_tether .= [set.v_wind, 0, 0]
    s.l_tether = set.l_tether
    s.pos_kite, s.v_kite = zeros(3), zeros(3)
    # TODO: Check 
    s.initial_masses .= ones(set.segments+1) * 0.011 * set.l_tether / set.segments
    s.rho = set.rho_0
end

function unpack(y)
    part = reshape(SVector{6*(set.segments+1)}(y),  Size(3, set.segments+1, 2))
    pos1 = part[:,:,1]
    pos = SVector{set.segments+1}(SVector(pos1[:,i]) for i in 1:set.segments+1)
    return pos
end

# N-point tether model:
# Inputs:
# State vector state_y   = pos1, pos2, ..., posn, vel1, vel2, ..., veln
# Derivative   der_yd    = vel1, vel2, ..., veln, acc1, acc2, ..., accn
# Output:
# Residual     res = res1, res2 = pos1,  ..., vel1, ...
function residual!(res, yd, y, p, time)
    # unpack the vectors y and yd
    part = reshape(SVector{6*(SEGMENTS+1)}(y),  Size(3, SEGMENTS+1, 2))
    partd = reshape(SVector{6*(SEGMENTS+1)}(yd),  Size(3, SEGMENTS+1, 2))
    pos1, vel1 = part[:,:,1], part[:,:,2]
    pos = SVector{SEGMENTS+1}(SVector(pos1[:,i]) for i in 1:SEGMENTS+1)
    vel = SVector{SEGMENTS+1}(SVector(vel1[:,i]) for i in 1:SEGMENTS+1)
    posd1, veld1 = partd[:,:,1], partd[:,:,2]
    posd = SVector{SEGMENTS+1}(SVector(posd1[:,i]) for i in 1:SEGMENTS+1)
    veld = SVector{SEGMENTS+1}(SVector(veld1[:,i]) for i in 1:SEGMENTS+1)

    # update parameters
    s = state
    s.pos_kite .= pos[set.segments+1]
    s.v_kite   .= vel[set.segments+1]
    delta_t = time - s.t_0
    delta_v = s.v_reel_out - s.last_v_reel_out
    s.length = (s.l_tether + s.last_v_reel_out * delta_t + 0.5 * delta_v * delta_t^2) / set.segments
    s.c_spring = set.c_spring / s.length
    s.damping  = set.damping / s.length

    # call core calculation routines
    vec_c = SVector{3, SimFloat}(pos[set.segments] - s.pos_kite)     # convert to SVector to avoid allocations
    v_app = SVector{3, SimFloat}(s.v_wind - s.v_kite)
    calc_set_cl_cd(s, vec_c, v_app)
    calc_aero_forces(s, s.pos_kite, s.v_kite, s.rho, s.steering) # force at the kite
    loop(s, pos, vel, posd, veld, s.res1, s.res2)
   
    # copy and flatten result
    for i in 1:set.segments+1
        for j in 1:3
           @inbounds res[3*(i-1)+j] = s.res1[i][j]
           @inbounds res[3*(set.segments+1)+3*(i-1)+j] = s.res2[i][j]
        end
    end
    nothing
end

# Setter for the reel-out speed. Must be called every 50 ms (before each simulation).
# It also updates the tether length, therefore it must be called even if v_reelout has
# not changed.
function set_v_reel_out(s, v_reel_out, t_0, period_time = PERIOD_TIME)
    s.l_tether += 0.5 * (v_reel_out + s.last_v_reel_out) * period_time
    s.last_v_reel_out = s.v_reel_out
    s.v_reel_out = v_reel_out
    s.t_0 = t_0
end

# Setter depower and the steering model inputs. Valid range for steering: -1.0 .. 1.0.
# Valid range for depower: 0 .. 1.0
function set_depower_steering(s, depower, steering)
    s.steering = steering
    s.depower  = depower
    s.alpha_depower = calc_alpha_depower(depower) * (MAX_ALPHA_DEPOWER / 31.0)
    # print "depower, alpha_depower", form(depower), form(degrees(self.scalars[Alpha_depower]))
    # print "v_app_norm, CL, rho: ", form(self.scalars[V_app_norm]),form(self.scalars[ParamCL]), form(self.rho)
    s.steering = (steering - C0) / (1.0 + K_ds * (s.alpha_depower / deg2rad(MAX_ALPHA_DEPOWER)))
    # println("LoD: ", s.param_cl/ s.param_cd)
    nothing
end

function set_beta_psi(s, beta, psi)
    s.beta = beta
    s.psi  = psi
end

# Setter for the tether reel-out lenght (at zero force).
function set_l_tether(s, l_tether)
    s.l_tether = l_tether
end

# Getter for the tether reel-out lenght (at zero force).
function get_l_tether(s)
    s.l_tether
end

# Return the absolute value of the force at the winch as calculated during the last simulation. 
function get_force(s)
    norm(s.last_force) 
end

# Return an array of the scalar spring forces of all tether segements.
# Input: The vector pos of the positions of the point masses that belong to the tether.
function get_spring_forces(s, pos)
    forces = zeros(set.segments)
    for i in 1:set.segments
        forces[i] =  s.c_spring * (norm(pos[i+1] - pos[i]) - s.length)
    end
    forces
end

function get_lift_drag(s)
    norm(s.lift_force), norm(s.drag_force)
end

# Return the vector of the wind velocity at the height of the kite.
function get_v_wind(s)
    s.v_wind
end

# Set the vector of the wind-velocity at the height of the kite. As parameter the height,
# the ground wind speed and the wind direction are needed.
# Must be called every 50 ms.
function set_v_wind_ground(s, height, v_wind_gnd=set.v_wind, wind_dir=0.0)
    if height < 6.0
        height = 6.0
    end
    s.v_wind .= v_wind_gnd * calc_wind_factor(height) .* [cos(wind_dir), sin(wind_dir), 0]
    s.v_wind_gnd .= [v_wind_gnd * cos(wind_dir), v_wind_gnd * sin(wind_dir), 0.0]
    s.v_wind_tether .= v_wind_gnd * calc_wind_factor(height / 2.0) .* [cos(wind_dir), sin(wind_dir), 0]
    s.rho = calc_rho(height)
    nothing
end

function get_lod(s)
    lift, drag = s.get_lod
    return lift / drag
end

# Calculate the initial conditions y0, yd0 and sw0. Tether with the given elevation angle,
# particle zero fixed at origin. """
function init(s; output=false, pre_tension=1.00293)
    DELTA = 1e-6
    set_cl_cd(s, 10.0/180.0 * π)
    pos, vel, acc = Vec3[], Vec3[], Vec3[]
    state_y = DELTA
    vel_incr = 0
    sin_el, cos_el = sin(set.elevation / 180.0 * π), cos(set.elevation / 180.0 * π)
    for i in 0:set.segments
        radius =  -i * set.l_tether / set.segments*pre_tension
        if i == 0
            push!(pos, Vec3(-cos_el * radius, DELTA, -sin_el * radius))
            push!(vel, Vec3(DELTA, DELTA, DELTA))
        else
            # push!(pos, Vec3(-cos_el * radius*(1.0+0.00002*i/7.0), state_y, -sin_el * radius*(1.0+0.00002*i/7.0)))
            push!(pos, Vec3(-cos_el * radius, state_y, -sin_el * radius))
            if i < set.segments
                push!(vel, Vec3(DELTA, DELTA, -sin_el * vel_incr*i))
            else
            push!(vel, Vec3(DELTA, DELTA, -sin_el * vel_incr*(i-1.0)))
            end
        end
        if pre_tension == 1.0
            push!(acc, Vec3(DELTA, DELTA, -9.81))
        else
            push!(acc, Vec3(DELTA, DELTA, DELTA))
        end
    end
    forces = get_spring_forces(s, pos)
    println("Winch force: $(norm(forces[1])) N")
    state_y0, yd0 = Vec3[], Vec3[]
    for i in 1:set.segments+1
        push!(state_y0,  pos[i]) # Initial state vector
        yd0 = push!(yd0, vel[i]) # Initial state vector derivative
    end
    for i in 1:set.segments+1
        push!(state_y0, vel[i])  # Initial state vector
        push!(yd0, acc[i])       # Initial state vector derivative
    end
    set_v_wind_ground(s, pos[set.segments+1][3])
    set_l_tether(s, set.l_tether)
    set_v_reel_out(s, V_REEL_OUT, 0.0)
    set_v_reel_out(s, V_REEL_OUT, 0.0)
    elements = length(reduce(vcat, state_y0))
    if output
        print("y0: ")
        display(state_y0)
        print("yd0: ")
        display(yd0)
    end
    return MVector{elements, SimFloat}(reduce(vcat, state_y0)), MVector{elements, SimFloat}(reduce(vcat, yd0))
end

end