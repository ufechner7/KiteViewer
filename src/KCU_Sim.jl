# Module for simulating the kite control unit (KCU).

module KCU_Sim

export calc_alpha_depower

const HEIGHT_K = 2.0                         # height of the kite
const HEIGHT_B = 6.93                        # height of the bridle
const POWER2STEER_DIST = 1.3                 
const DEPOWER_DRUM_DIAMETER = 69.0e-3 * 0.97 # outer diameter of the depower drum at depower = DEPOWER_OFFSET [m]
const DEPOWER_OFFSET = 23.8
const STEERING_LINE_SAG = 0.0                # sag of the steering lines in percent
const TAPE_THICKNESS = 6e-4           # thickness of the depower tape [m]

# Calculate the length increase of the depower line [m] as function of the relative depower
# setting [0..1].
function calc_delta_l(rel_depower)
    u = DEPOWER_DRUM_DIAMETER * (100.0 + STEERING_LINE_SAG) / 100.0
    l_ro = 0.0
    rotations = (rel_depower - 0.01 * DEPOWER_OFFSET) * 10.0 * 11./3. * (3918.8 - 230.8) / 4096.
    while rotations > 0.0
         l_ro += u * π    
         rotations -= 1.0
         u -= TAPE_THICKNESS
    end
    if rotations < 0.0
         l_ro += (-(u + TAPE_THICKNESS) * rotations + u * (rotations + 1.0)) * π * rotations
    end
    return l_ro
end

# calculate the change of the angle between the kite and the last tether segment [rad] as function of the
# length increase of the depower line delta_l [m].
function calc_alpha_depower(rel_depower)
    a   = POWER2STEER_DIST
    b_0 = HEIGHT_B + 0.5 * Height_K
    b = b_0 + 0.5 * calc_delta_l(rel_depower) # factor 0.5 due to the pulleys

    c = sqrt(a * a + b_0 * b_0)
    # print 'a, b, c:', a, b, c, rel_depower
    if c >= a + b
         return nothing
    else
        tmp = 1/(2*a*b)*(a*a+b*b-c*c)
        if tmp > 1.0:
            println("-->>> WARNING: tmp > 1.0: ", tmp)
            tmp = 1.0
        elseif tmp < -1.0
            println("-->>> WARNING: tmp < 1.0: ", tmp)
            tmp = -1.0
        end            
        return pi/2.0 - acos(tmp)
    end
end

end