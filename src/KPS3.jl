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

export State, Vec3, SimFloat, init, calc_cl, calc_rho, calc_wind_factor, calc_drag, calc_res

# Constants
@consts begin
     G_EARTH = 9.81                # gravitational acceleration
     C0 = -0.0032                  # steering offset
     C2_COR =  0.93
     CD_TETHER = se().cd_tether    # tether drag coefficient
     SEGMENTS  = se().segments
     D_TETHER = se().d_tether/1000 # tether diameter [m]
     L_BRIDLE = se().l_bridle      # sum of the lengths of the bridle lines [m]
     L_TOT_0  = 150.0              # initial tether length [m]
     L_0      = L_TOT_0 / SEGMENTS # initial segment length [m]
     MASS = 0.011 * L_0            # initial mass per particle: 1.1 kg per 100m = 0.011 kg/m for 4mm Dyneema
     KITE_MASS = 11.4     # kite including sensor unit
     KCU_MASS  =  8.4
     REL_SIDE_AREA = 0.5
     STEERING_COEFFICIENT = 0.6
     BRIDLE_DRAG = 1.1
     ALPHA = se().alpha
     K_ds = 1.5                    # influence of the depower angle on the steering sensitivity
     MAX_ALPHA_DEPOWER = 31.0

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
    v_wind::T =           [se().v_wind, 0, 0]    # wind vector at the height of the kite
    v_wind_gnd::T =       [se().v_wind, 0, 0]    # wind vector at reference height
    v_wind_tether::T =    [se().v_wind, 0, 0]
    v_apparent::T =       zero(T)
    v_app_perp::T =       zero(T)
    drag_force::T =       zero(T)
    lift_force::T =       zero(T)
    steering_force::T =   zero(T)
    last_force::T =       zero(T)
    spring_force::T =     zero(T)
    total_forces::T =     zero(T)
    force::T =            zero(T)
    unit_vector::T =      zero(T)
    av_vel::T =           zero(T)
    kite_y::T =           zero(T)
    segment::T =          zero(T)
    last_tether_drag::T = zero(T)
    acc::T =              zero(T)           
    seg_area::S =         zero(S)   # area of one tether segment
    c_spring::S =         zero(S)
    length::S =           L_TOT_0
    damping::S =          zero(S)
    area::S =             zero(S)
    last_v_app_norm_tether::S = zero(S)
    param_cl::S =         0.2
    param_cd::S =         1.0
    v_app_norm::S =       zero(S)
    cor_steering::S =     zero(S)
    psi::S =              zero(S)
    beta::S =             1.22      # elevation angle in radian; initial value about 70 degrees
    last_alpha =          0.1
    initial_masses::MVector{SEGMENTS+1, SimFloat} = ones(SEGMENTS+1) * MASS
    masses::MVector{SEGMENTS+1, SimFloat}         = ones(SEGMENTS+1)
end

const state = State{SimFloat, Vec3}()

# Functions

# Calculate the air densisity as function of height
calc_rho(height) = se().rho_0 * exp(-height / 8550.0)

# Calculate the wind speed at a given height and reference height.
# Fast version of: (height / se().h_ref)^ALPHA
calc_wind_factor(height) = exp(ALPHA * log((height / se().h_ref)))

# calculate the drag of one tether segment
function calc_drag(s, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area)
    s.v_apparent .= s.v_wind_tether - v_segment
    v_app_norm = norm(s.v_apparent)
    v_app_perp .= s.v_apparent .- dot(s.v_apparent, unit_vector) .* unit_vector
    last_tether_drag .= -0.5 * CD_TETHER * rho * norm(v_app_perp) * area .* v_app_perp
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
    K                = 0.5 * rho * s.v_app_norm^2 * se().area
    s.lift_force    .= K * s.param_cl .* normalize(cross(s.drag_force, s.kite_y))   
    # some additional drag is created while steering
    s.drag_force    .*= K * s.param_cd * BRIDLE_DRAG * (1.0 + 0.6 * abs(rel_steering)) 
    s.cor_steering    = C2_COR / s.v_app_norm * sin(s.psi) * cos(s.beta)
    s.steering_force .= -K * REL_SIDE_AREA * STEERING_COEFFICIENT * (rel_steering + s.cor_steering) .* s.kite_y
    s.last_force     .= -(s.lift_force + s.drag_force + s.steering_force)
end

# Calculate the vector res1, that depends on the velocity and the acceleration.
# The drag force of each segment is distributed equaly on both particles.
function calc_res(s, pos1, pos2, vel1, vel2, mass, veld, result, i)
    s.segment .= pos1 - pos2
    height = (pos1[3] + pos2[3]) * 0.5
    rho = calc_rho(height)                # calculate the air density
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

    s.area = norm1 * D_TETHER
    s.last_v_app_norm_tether = calc_drag(s, s.av_vel, s.unit_vector, rho, s.last_tether_drag, s.v_app_perp, s.area)

    if i == SEGMENTS
        s.area = L_BRIDLE * D_TETHER
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

# Calculate the vector res0 using a vector expression, and calculate res1 using a loop
# that iterates over all tether segments. 
function loop(s, pos, vel, posd, veld, res0, res1)
    s.masses               .= s.length ./ L_0 .* s.initial_masses
    s.masses[SEGMENTS+1]   += (KITE_MASS + KCU_MASS)
    res0[1] .= pos[1]
    res1[1] .= vel[1]
    for i in 2:SEGMENTS+1
        res0[i] .= vel[i] - posd[i]
    end
    for i in SEGMENTS:-1:2
        calc_res(state, pos[i], pos[i-1], vel[i], vel[i-1], s.masses[i], veld[i],  res1[i], i)
    end
end

end