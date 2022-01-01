module KiteModels

using Dierckx, StaticArrays, LinearAlgebra, Parameters, NLsolve
using KiteUtils, KitePodSimulator

export KPS3

# Constants
const G_EARTH = 9.81                # gravitational acceleration
const BRIDLE_DRAG = 1.1             # should probably be removed

# Type definitions
const SimFloat = Float64
const KVec3    = MVector{3, SimFloat}
const SVec3    = SVector{3, SimFloat}                   

@with_kw mutable struct KPS3{S, T}
    set::Settings = se()
    calc_cl = Spline1D(se().alpha_cl, se().cl_list)
    calc_cd = Spline1D(se().alpha_cd, se().cd_list)    
    v_wind::T =           zeros(S, 3)    # wind vector at the height of the kite
    v_wind_gnd::T =       zeros(S, 3)    # wind vector at reference height
    v_app_perp::T =       zeros(S, 3)
    drag_force::T =       zeros(S, 3)
end

function KPS3(set::Settings, kcu::KCUState)
    s = KPS3{SimFloat, KVec3}()
    s.set = set
    s.v_wind =            [set.v_wind, 0, 0]    # wind vector at the height of the kite
    s.v_wind_gnd =        [set.v_wind, 0, 0]    # wind vector at reference height
    return s
end

end