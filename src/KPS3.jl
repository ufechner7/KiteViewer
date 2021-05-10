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

using Dierckx, StaticArrays, LinearAlgebra

if ! @isdefined Utils
    include("Utils.jl")
    using .Utils
end

export State, Vec3, MyFloat, init, calc_cl, calc_rho, calc_wind_factor, calc_drag

# Constants
const G_EARTH = 9.81                # gravitational acceleration
const C0 = -0.0032                  # steering offset
const C2_COR =  0.93
const CD_TETHER = se().cd_tether    # tether drag coefficient
const L_BRIDLE = se().l_bridle      # sum of the lengths of the bridle lines [m]
const REL_SIDE_AREA = 0.5
const STEERING_COEFFICIENT = 0.6
const BRIDLE_DRAG = 1.1
const ALPHA = se().alpha
const K_ds = 1.5                    # influence of the depower angle on the steering sensitivity
const MAX_ALPHA_DEPOWER = 31.0

const ALPHA_CL = [-180.0, -160.0, -90.0, -20.0, -10.0,  -5.0,  0.0, 20.0, 40.0, 90.0, 160.0, 180.0]
const CL_LIST  = [   0.0,    0.5,   0.0,  0.08, 0.125,  0.15,  0.2,  1.0,  1.0,  0.0,  -0.5,   0.0]
const ALPHA_CD = [-180.0, -170.0, -140.0, -90.0, -20.0, 0.0, 20.0, 90.0, 140.0, 170.0, 180.0]
const CD_LIST  = [   0.5,    0.5,    0.5,   1.0,   0.2, 0.1,  0.2,  1.0,   0.5,   0.5,   0.5]
const calc_cl = Spline1D(ALPHA_CL, CL_LIST)
const calc_cd = Spline1D(ALPHA_CD, CD_LIST)

# Type definitions
const MyFloat = Float32
const Vec3    = MVector{3, MyFloat}

mutable struct State
    v_wind::Vec3        # wind vector at the height of the kite
    v_wind_gnd::Vec3    # wind vector at reference height
    v_wind_tether::Vec3
    v_apparent::Vec3
    drag_force::Vec3
    lift_force::Vec3
    steering_force::Vec3
    last_force::Vec3
    kite_y::Vec3
    seg_area::MyFloat   # area of one tether segment
    param_cl::MyFloat
    param_cd::MyFloat
    v_app_norm::MyFloat
    cor_steering::MyFloat
    psi::MyFloat
    beta::MyFloat
end

function init()
    state = State(zeros(3), zeros(3), zeros(3), zeros(3), zeros(3), zeros(3), zeros(3), zeros(3), zeros(3), 0.0,  0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    state.v_wind[1]        = se().v_wind # westwind, downwind direction to the east
    state.v_wind_gnd[1]    = se().v_wind # westwind, downwind direction to the east
    state.v_wind_tether[1] = se().v_wind # wind at half of the height of the kite
    state.v_apparent       = zeros(3)
    state.param_cl         = 0.2
    state.param_cd         = 1.0
    state
end
const state = init()

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
    v_app_perp .= dot(s.v_apparent, unit_vector) .* unit_vector
    v_app_perp .= s.v_apparent - v_app_perp
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

end