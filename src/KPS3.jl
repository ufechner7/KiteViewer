# kitepower system model
using Dierckx, StaticArrays, LinearAlgebra, BenchmarkTools

# settings
const V_WIND = 8.0f0
const AREA   = 20.0f0

# fixed values
const MyFloat = Float32
const Vec3    = MVector{3, MyFloat}

const G_EARTH = 9.81       # gravitational acceleration
const RHO_0 = 1.225f0      # kg / m³
const C_0 = -0.0032        # steering offset
const C_D_TETHER = 0.958f0 # tether drag coefficient
const L_BRIDLE = 33.4      # sum of the lengths of the bridle lines [m]

const K_ds = 1.5 # influence of the depower angle on the steering sensitivity
const MAX_ALPHA_DEPOWER = 31.0 # was: 44
const ALPHA = 1/7

const ALPHA_CL = [-180.0, -160.0, -90.0, -20.0, -10.0,  -5.0,  0.0, 20.0, 40.0, 90.0, 160.0, 180.0]
const CL_LIST  = [   0.0,    0.5,   0.0,  0.08, 0.125,  0.15,  0.2,  1.0,  1.0,  0.0,  -0.5,   0.0]

const ALPHA_CD = [-180.0, -170.0, -140.0, -90.0, -20.0, 0.0, 20.0, 90.0, 140.0, 170.0, 180.0]
const CD_LIST  = [   0.5,    0.5,    0.5,   1.0,   0.2, 0.1,  0.2,  1.0,   0.5,   0.5,   0.5]

const calc_cl = Spline1D(ALPHA_CL, CL_LIST)
const calc_cd = Spline1D(ALPHA_CD, CD_LIST)

# Calculate the air densisity as function of height
function calc_rho(height)
    return RHO_0 * exp(-height / 8550.0)
end

# Calculate the wind speed at a given height and reference height.
function calc_wind_factor(height)
    (height / 6.0)^ALPHA
end

mutable struct State
    v_wind::Vec3
    v_wind_gnd::Vec3
    v_wind_tether::Vec3
    v_apparent::Vec3
    param_cl::MyFloat
    param_cd::MyFloat
end

const state = State(zeros(3), zeros(3), zeros(3), zeros(3), 0.0, 0.0)

function init()
    state.v_wind[1]        = V_WIND # westwind, downwind direction to the east
    state.v_wind_gnd[1]    = V_WIND # westwind, downwind direction to the east
    state.v_wind_tether[1] = V_WIND # wind at half of the height of the kite
    state.v_apparent       = zeros(3)
end

function calc_drag(s, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area)
    s.v_apparent .= s.v_wind_tether - v_segment
    v_app_norm = norm(s.v_apparent)
    v_app_perp .= dot(s.v_apparent, unit_vector) .* unit_vector
    v_app_perp .= s.v_apparent - v_app_perp
    last_tether_drag .= -0.5 * C_D_TETHER * rho * norm(v_app_perp) * area .* v_app_perp
    v_app_norm
end 

#     pos_kite:     position of the kite
#     rho:          air density [kg/m^3]
#     paramCD:      drag coefficient (function of power settings)
#     paramCL:      lift coefficient (function of power settings)
#     rel_steering: value between -1.0 and +1.0
function calcAeroForces(s, pos_kite, v_kite, rho, rel_steering, v_apparent)
    v_apparent .= s.v_wind - v_app_perp
    v_app_norm = norm(s.v_apparent)
#     normalize2(vec3[V_apparent], vec3[Drag_force])
#     cross3(pos_kite, vec3[Drag_force], vec3[Kite_y])
#     normalize1(vec3[Kite_y])
#     K = 0.5 * rho * scalars[V_app_norm]**2 * AREA
#     cross3(vec3[Drag_force], vec3[Kite_y], vec3[Temp])
#     normalize1(vec3[Temp])
#     mul3(K * scalars[ParamCL], vec3[Temp], vec3[Lift_force])
#     # some additional drag is created while steering
#     mul2( K * scalars[ParamCD] * BRIDLE_DRAG * (1.0 + 0.6 * abs(rel_steering)), vec3[Drag_force])
#     scalars[Cor_steering] = C2_COR / scalars[V_app_norm] * math.sin(scalars[Psi]) * math.cos(scalars[Beta])
#     mul3(- K * REL_SIDE_AREA * STEERING_COEFFICIENT * (rel_steering + scalars[Cor_steering]), vec3[Kite_y], \
#          vec3[Steering_force])
#     neg_sum(vec3[Lift_force], vec3[Drag_force], vec3[Steering_force], vec3[Last_force])
end

function test_calc_drag()
    init()
    v_segment = Vec3(1.0, 2, 3)
    unit_vector = Vec3(2.0, 3.0, 4.0)
    rho = MyFloat(calc_rho(10.0))
    last_tether_drag = Vec3(0.0, 0.0, 0.0)
    v_app_perp = Vec3(0, -3.0, -4.0)
    area=AREA    
    println(state.v_apparent)
    println(state.v_wind_tether)
    println(calc_drag(state, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area))
    println(last_tether_drag)
    println(v_app_perp)
end

@benchmark calc_cl(α) setup=(α=(rand()-0.5) * 360.0)
@benchmark calc_cl(calc_drag(state, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area)) setup=(init(); v_segment = Vec3(1.0, 2, 3); unit_vector = Vec3(2.0, 3.0, 4.0); rho = calc_rho(10.0f0); last_tether_drag = Vec3(0.0, 0.0, 0.0); v_app_perp =  Vec3(0, -3.0, -4.0); area=AREA)