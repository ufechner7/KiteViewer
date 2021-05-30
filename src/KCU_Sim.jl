# Module for simulating the kite control unit (KCU).

module KCU_Sim

using Utils, Parameters

export calc_alpha_depower, init_kcu, set_depower_steering, get_depower, get_steering, on_timer

const HEIGHT_K = 2.23                        # height of the kite
const HEIGHT_B = 4.9                         # height of the bridle
const POWER2STEER_DIST = 1.3                 
const DEPOWER_DRUM_DIAMETER = 69.0e-3 * 0.97 # outer diameter of the depower drum at depower = DEPOWER_OFFSET [m]
const DEPOWER_OFFSET = 23.6
const STEERING_LINE_SAG = 0.0                # sag of the steering lines in percent
const TAPE_THICKNESS = 6e-4           # thickness of the depower tape [m]
const V_DEPOWER  = 0.075            # max velocity of depowering in units per second (full range: 1 unit)
const V_STEERING = 0.2              # max velocity of steering in units per second   (full range: 2 units)
const DEPOWER_GAIN  = 3.0           # 3.0 means: more than 33% error -> full speed
const STEERING_GAIN = 3.0

@with_kw mutable struct KCUState{S}
    set_depower::S =         DEPOWER_OFFSET * 0.01
    set_steering::S =        0.0
    depower::S =             DEPOWER_OFFSET * 0.01   #    0 .. 1.0
    steering::S =            0.0                     # -1.0 .. 1.0
end

const kcu_state = KCUState{Float64}()

# Calculate the length increase of the depower line [m] as function of the relative depower
# setting [0..1].
function calc_delta_l(rel_depower)
    u = DEPOWER_DRUM_DIAMETER * (100.0 + STEERING_LINE_SAG) / 100.0
    l_ro = 0.0
    rotations = (rel_depower - 0.01 * DEPOWER_OFFSET) * 10.0 * 11.0 / 3.0 * (3918.8 - 230.8) / 4096.
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
    b_0 = HEIGHT_B + 0.5 * HEIGHT_K
    b = b_0 + 0.5 * calc_delta_l(rel_depower) # factor 0.5 due to the pulleys

    c = sqrt(a * a + b_0 * b_0)
    # print 'a, b, c:', a, b, c, rel_depower
    if c >= a + b
         return nothing
    else
        tmp = 1/(2*a*b)*(a*a+b*b-c*c)
        if tmp > 1.0
            println("-->>> WARNING: tmp > 1.0: $tmp")
            tmp = 1.0
        elseif tmp < -1.0
            println("-->>> WARNING: tmp < 1.0: $tmp")
            tmp = -1.0
        end            
        return pi/2.0 - acos(tmp)
    end
end

function init_kcu()
    kcu_state.set_depower =         DEPOWER_OFFSET * 0.01
    kcu_state.set_steering =        0.0
    kcu_state.depower =             DEPOWER_OFFSET * 0.01   #    0 .. 1.0
    kcu_state.steering =            0.0                     # -1.0 .. 1.0
end

function set_depower_steering(depower, steering)
    kcu_state.set_depower  = depower
    kcu_state.set_steering = steering
end

function get_depower();  return kcu_state.depower;  end
function get_steering(); return kcu_state.steering; end

function on_timer(dt = 1.0 / se().sample_freq)
    # calculate the depower motor velocity
    vel_depower = (kcu_state.set_depower - kcu_state.depower) * DEPOWER_GAIN
    # println("vel_depower: $(vel_depower)")
    if vel_depower > V_DEPOWER
        vel_depower = V_DEPOWER
    elseif vel_depower < -V_DEPOWER
        vel_depower = -V_DEPOWER
    end
    # update the position
    kcu_state.depower += vel_depower * dt
    # calculate the steering motor velocity
    vel_steering = (kcu_state.set_steering - kcu_state.steering) * STEERING_GAIN
    if vel_steering > V_STEERING
        vel_steering = V_STEERING
    elseif vel_steering < -V_STEERING
        vel_steering = -V_STEERING
    end
    kcu_state.steering += vel_steering * dt
end

end