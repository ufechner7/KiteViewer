# kitepower system model
using Dierckx, StaticArrays, LinearAlgebra, BenchmarkTools

# settings
const V_WIND = 8.0f0
const AREA = 20.0f0

# fixed values
const MyFloat = Float32

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
    v_wind::MVector{3, MyFloat}
    v_wind_gnd::MVector{3, MyFloat}
    v_wind_tether::MVector{3, MyFloat}
    v_apparent::MVector{3, MyFloat}
    v_app_norm::MyFloat
end

const state = State(zeros(3), zeros(3), zeros(3), zeros(3), 0.0)

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
    last_tether_drag .= -0.5f0 * C_D_TETHER * rho * norm(v_app_perp) * area .* v_app_perp
    v_app_norm
end 

function test_calc_drag()
    init()
    v_segment = MVector{3, MyFloat}(1.0, 2, 3)
    unit_vector = MVector{3, MyFloat}(2.0, 3.0, 4.0)
    rho = MyFloat(calc_rho(10.0))
    last_tether_drag = MVector{3, MyFloat}(0.0, 0.0, 0.0)
    v_app_perp = MVector{3, MyFloat}(0, -3.0, -4.0)
    area=AREA    
    println(state.v_apparent)
    println(state.v_wind_tether)
    println(calc_drag(state, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area))
    println(last_tether_drag)
    println(v_app_perp)
end

@benchmark calc_cl(calc_drag(state, v_segment, unit_vector, rho, last_tether_drag, v_app_perp, area)) setup=(init(); v_segment = MVector{3, MyFloat}(1.0, 2, 3); unit_vector = MVector{3, MyFloat}(2.0, 3.0, 4.0); rho = calc_rho(10.0f0); last_tether_drag = MVector{3, MyFloat}(0.0, 0.0, 0.0); v_app_perp =  MVector{3, MyFloat}(0, -3.0, -4.0); area=AREA)