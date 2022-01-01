module Test

using Dierckx, StaticArrays, LinearAlgebra, Parameters, NLsolve
using KiteUtils, KitePodSimulator

# Constants
@consts begin
    set    = se()                 # settings from settings.yaml
    SEGMENTS = set.segments
    G_EARTH = 9.81                # gravitational acceleration
    BRIDLE_DRAG = 1.1             # should probably be removed
    X0 = zeros(2 * SEGMENTS)
    calc_cl = Spline1D(set.alpha_cl, set.cl_list)
    calc_cd = Spline1D(set.alpha_cd, set.cd_list)
end

# Type definitions
const SimFloat = Float64
const KVec3    = MVector{3, SimFloat}
const SVec3    = SVector{3, SimFloat}                   

@with_kw mutable struct State{S, T}
    v_wind::T =           [set.v_wind, 0, 0]    # wind vector at the height of the kite
    v_wind_gnd::T =       [set.v_wind, 0, 0]    # wind vector at reference height
    v_wind_tether::T =    [set.v_wind, 0, 0]
    v_apparent::T =       [set.v_wind, 0, 0]
    v_app_perp::T =       zeros(S, 3)
    drag_force::T =       zeros(S, 3)
    lift_force::T =       zeros(S, 3)
    steering_force::T =   zeros(S, 3)
    last_force::T =       zeros(S, 3)
    spring_force::T =     zeros(S, 3)
    total_forces::T =     zeros(S, 3)
    force::T =            zeros(S, 3)
    unit_vector::T =      zeros(S, 3)
    av_vel::T =           zeros(S, 3)
    kite_y::T =           zeros(S, 3)
    segment::T =          zeros(S, 3)
    last_tether_drag::T = zeros(S, 3)
    acc::T =              zeros(S, 3)     
    vec_z::T =            zeros(S, 3)
    pos_kite::T =         zeros(S, 3)
    v_kite::T =           zeros(S, 3)        
    res1::SVector{set.segments+1, KVec3} = zeros(SVector{set.segments+1, KVec3})
    res2::SVector{set.segments+1, KVec3} = zeros(SVector{set.segments+1, KVec3})
    pos::SVector{set.segments+1, KVec3} = zeros(SVector{set.segments+1, KVec3})
    seg_area::S =         zero(S)   # area of one tether segment
    bridle_area::S =      zero(S)
    c_spring::S =         zero(S)   # depends on lenght of tether segement
    length::S =           set.l_tether / set.segments
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

end