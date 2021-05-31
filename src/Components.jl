#=
A collection of control functions and control components for discrete control

Functions:

- calc_v_ro
- saturation

Components:

- Integrator
- UnitDelay
- RateLimiter
- Mixer_2CH    two channel mixer
- Mixer_3CH    three channel mixer
- CalcVSetIn   calculate the set speed of the speed controller, using soft switching
- Winch        model of 20 kW winch, 4000 N max force, 8 m/s max speed
- SpeedController
- LowerForceController
- UpperForceController

Implemented as described in the PhD thesis of Uwe Fechner.

see also: 

.. image:: 01_doc/classes_Components.png
=#

# FAC = 0.25

# PERIOD_TIME = 1/50.0
# TEST_COMPONENTS = False
# EPSILON = 1e-6

# T_BLEND = 0.25 # blending time of the mixers in seconds
# V_SAT_ERR = 1.0 # limitation of the reel-out speed error, used by the input saturation block of the speed controller
# # V_SAT = 8.0    # limitation of the reel-out speed , used by the output saturation block of the speed controller
# V_SAT = 12.0
# # V_RI_MAX = 8.0
# V_RI_MAX = 12.0

# # speed controller
# P_SPEED = 0.125 #-0.025  # P value of the speed controller
# I_SPEED = 4.0   # I value of the speed controller
# K_b_SPEED = 4.0 # back calculation constant for the anti-windup loop of the speed controller
# K_t_SPEED = 5.0 # tracking constant of the speed controller
# V_F_MAX = 2.75   # reel-out velocity where the set force should reach it's maximum
# # lower force controller
# P_F_LOW = 1.44e-4 * FAC
# I_F_LOW = 7.5e-3 * 1.5 * FAC
# K_b_F_LOW = 1.0
# K_t_F_LOW = 8.0
# # F_LOW = 300.0
# # upper force controller
# if TEST_COMPONENTS:
#     P_F_HIGH = 1.44e-4
#     I_F_HIGH = 7.5e-3
#     D_F_HIGH = 2e-5
#     N_F_HIGH = 15.0
# else:
#     P_F_HIGH = 0.007 * 0.33
#     I_F_HIGH = 0.003 * 0.33
#     D_F_HIGH = 2e-5 * 2.0 * 0.0
#     N_F_HIGH = 15.0

# K_b_F_HIGH = 1.0
# K_t_F_HIGH = 10.0
# # F_HIGH = 3750.0*2.0
# # Winch
# WINCH_ITER = 10

# MAX_ACC = 8.0 # maximal acceleration of the winch (derivative of the set value of the reel-out speed)
# K_v = 0.06  #

# V_ri_max = V_RI_MAX

# def setVRiMax(v_ri_max):
#     global V_ri_max
#     V_ri_max = v_ri_max

# def form(number):
#     """ Convert a number to a string with two digits after the decimal point. """
#     return "{:.2f}".format(number)

# def calcV_ro(force, f_high, f_low):
#     """ Calculate the optimal reel-out speed for a given force. """
#     if TEST_COMPONENTS:
#         return sqrt(force) * K_v
#     else:
#         if force >= f_low:
#             return V_F_MAX * sqrt((force - f_low) / float(f_high - f_low))
#         else:
#             return -V_F_MAX * sqrt((f_low - force) / float(f_high - f_low))

# def saturation(value, min_, max_):
#     """ Calculate a saturated value, that stays within the given limits. """
#     result = value
#     if result > max_:
#         result = max_
#     if result < min_:
#         result = min_
#     return result

# def wrapToPi(value):
#     num2pi = np.floor(value / (2 * pi) + 0.5)
#     return value - num2pi * 2 * pi

# #class Wrap2Pi(object):
# #    def __init__(self):
# #        self.last_value = 0.0
# #        self.last_raw_value = 0.0
# #        self.turns = 0
# #
# #    def wrap2pi(self, value):
# #        self.last_raw_value = value
# #        if value < 0.0:
# #            temp_result = value + 2 * pi
# #        else:
# #            temp_result = value
# #        if self.last_raw_value < 0.0 and value >= 0.0:
# #            self.turns +=1
# #        if self.last_raw_value >= 0.0 and value < 0.0:
# #            self.turns -= 1
# #        return temp_result + self.turns * 2 * pi

# class Integrator(object):
#     """ Discrete integrator with external reset. """
#     def __init__(self, I=1.0, x_0=0.0):
#         """
#         Constructor. Parameters:
#         I:   integration constant
#         x_0: initial ouput
#         """
#         self._output = x_0
#         self._last_output = x_0
#         self._I = I

#     def reset(self, x_0):
#         self._output = x_0
#         self._last_output = x_0

#     # TODO: pass period time to calcOutput    
#     def calcOutput(self, input_):
#         self._output = self._last_output + input_ * self._I * PERIOD_TIME
#         return self._output
        
#     def getOutput(self):
#         return self._output
        
#     def getLastOutput(self):
#         return self._last_output
        
#     def onTimer(self):
#         self._last_output = self._output

# class UnitDelay(object):
#     """ Delay the input signal by one time step. """
#     def __init__(self):
#         self._last_output = 0.0
#         self._last_input = 0.0

#     def calcOutput(self, input_):
#         self._last_input = input_
#         return self._last_output

#     def onTimer(self):
#         self._last_output = self._last_input

# class RateLimiter(object):
#     """ Limit the rate of the output signal (return value of calcOutput) to -+ MAX_ACC. """
#     def __init__(self, x0=0.0):
#         self._output = x0
#         self._last_output = x0

#     def reset(self, x0=0.0):
#         self.__init__(x0)

#     def calcOutput(self, input_):
#         if input_ - self._last_output > MAX_ACC * PERIOD_TIME:
#             self._output = self._last_output + MAX_ACC * PERIOD_TIME
#             # print "acc too high:", (input_ - self._last_output) / PERIOD_TIME
#         elif input_ - self._output < -MAX_ACC * PERIOD_TIME:
#             self._output = self._last_output - MAX_ACC * PERIOD_TIME
#             # print "acc too low:", (input_ - self._last_output) / PERIOD_TIME
#         else:
#             self._output = input_
#         return self._output

#     def onTimer(self):
#         self._last_output = self._output

# class Mixer_2CH(object):
#     """
#     Mix two analog inputs. Implements the simulink block diagram, shown in
#     ./01_doc/mixer_2ch.png
#     """
#     def __init__(self, t_blend = T_BLEND):
#         self._input_a = 0.0
#         self._input_b = 0.0
#         self._factor_b = 0.0
#         self._select_b = False
#         self._t_blend = t_blend

#     def onTimer(self):
#         """ Must be called every period time. """
#         if self._select_b:
#             integrator_in = 1.0 / self._t_blend
#         else:
#             integrator_in = -1.0 / self._t_blend
#         self._factor_b += integrator_in * PERIOD_TIME
#         if self._factor_b > 1.0:
#             self._factor_b = 1.0
#         if self._factor_b < 0.0:
#             self._factor_b = 0.0

#     def setInputA(self, input_a):
#         self._input_a = input_a

#     def setInputB(self, input_b):
#         self._input_b = input_b

#     def selectB(self, select_b):
#         assert type(select_b) == bool
#         self._select_b = select_b

#     def getOutput(self):
#         result = self._input_b * self._factor_b + self._input_a * (1.0 - self._factor_b)
#         return result

# class CalcVSetIn(object):
#     """ Class for calculation v_set_in, using soft switching. """
#     def __init__(self, f_high, f_low):
#         self._mixer2 = Mixer_2CH()
#         self._f_high = f_high
#         self._f_low = f_low

#     def setVSetPc_Force(self, v_set_pc, force):
#         """
#         Parameters:

#         force: measured tether force [N]
#         v_set: only used during manual operation or park-at-length. If it is none,
#         v_set_in is calculated as function of the force.
#         """
#         if v_set_pc is None:
#             v_set_in = calcV_ro(force, self._f_high, self._f_low)
#             self._mixer2.setInputA(v_set_in)
#             self._mixer2.selectB(False)
#         else:
#             v_set_in = v_set_pc
#             self._mixer2.setInputB(v_set_in)
#             self._mixer2.selectB(True)

#     def getVSetIn(self):
#         """
#         Returns:

#         v_set_in: Either v_set, or a value, proportional to the sqare root of the force.
#         """
#         return self._mixer2.getOutput()

#     def onTimer(self):
#         self._mixer2.onTimer()

# class Mixer_3CH(object):
#     """
#     Mix thre analog inputs. Implements the simulink block diagram, shown in
#     ./01_doc/mixer_3ch.png
#     """
#     def __init__(self):
#         self._input_a = 0.0
#         self._input_b = 0.0
#         self._input_c = 0.0
#         self._factor_b = 0.0
#         self._factor_c = 0.0
#         self._select_b = False
#         self._select_c = False

#     def onTimer(self):
#         """ Must be called every period time. """
#         # calc output of integrator b
#         if self._select_b:
#             integrator_b_in = 1.0 / T_BLEND
#         else:
#             integrator_b_in = -1.0 / T_BLEND
#         self._factor_b += integrator_b_in * PERIOD_TIME
#         if self._factor_b > 1.0:
#             self._factor_b = 1.0
#         if self._factor_b < 0.0:
#             self._factor_b = 0.0
#         # calc output of integrator c
#         if self._select_c:
#             integrator_c_in = 1.0 / T_BLEND
#         else:
#             integrator_c_in = -1.0 / T_BLEND
#         self._factor_c += integrator_c_in * PERIOD_TIME
#         if self._factor_c > 1.0:
#             self._factor_c = 1.0
#         if self._factor_c < 0.0:
#             self._factor_c = 0.0

#     def setInputA(self, input_a):
#         self._input_a = input_a

#     def setInputB(self, input_b):
#         self._input_b = input_b

#     def setInputC(self, input_c):
#         self._input_c = input_c

#     def selectB(self, select_b):
#         assert type(select_b) == bool
#         self._select_b = select_b
#         if select_b:
#             self.selectC(False)

#     def selectC(self, select_c):
#         assert type(select_c) == bool
#         self._select_c = select_c
#         if select_c:
#             self.selectB(False)

#     def getOutput(self):
#         result = self._input_b * self._factor_b + self._input_c * self._factor_c \
#                  + self._input_a * (1.0 - self._factor_b - self._factor_c)
#         return result

#     def getDirectOutput(self):
#         result = self._input_b * self._select_b + self._input_c * self._select_c \
#                  + self._input_a * (1.0 - self._select_b - self._select_c)
#         return result

#     def getControllerState(self):
#         """
#         Return the controller state as integer.
#         wcsLowerForceControl = 0
#         wcsSpeedControl = 1
#         wcsUpperForceControl = 2
#         """
#         return (not self._select_b) and (not self._select_c) + 2 * self._select_c

# class Winch(object):
#     """ Class, that calculates the acceleration of the tether based on the tether force
#     and the set speed (= synchronous speed). Asynchronous motor model and drum inertia
#     are taken into account. """
#     def __init__(self):
#         self._v_set = 0.0 # input
#         self._force = 0.0 # input
#         self._acc = 0.0   # output
#         self._speed = 0.0 # output; reel-out speed; only state of this model

#     def setVSet(self, v_set):
#         self._v_set = v_set

#     def setForce(self, force):
#         self._force = force

#     def getSpeed(self):
#         # self._acc = calcAcceleration(self._v_set, self._speed, self._force)
#         return self._speed

#     def getAcc(self):
#         return self._acc

#     def onTimer(self):
#         if False:
#             self._acc = calcAcceleration(self._v_set, self._speed, self._force)
#             self._speed += self._acc * PERIOD_TIME
#         else:
#             acc = 0.0
#             for i in range(WINCH_ITER):
#                 self._acc = calcAcceleration(self._v_set, self._speed, self._force)
#                 acc += self._acc
#                 self._speed += self._acc * PERIOD_TIME / WINCH_ITER
#             self._acc = acc / WINCH_ITER

# class KiteModel(object):
#     r""" Class, that calculates the position of the kite (elevation angle beta and azimuth angle phi) and the
#     orientation of the kite (psi and psi_dot) as function of:
#     u_s: the relative steering, output of the KCU model (KCU: kite control unit)
#     u_d_prime: the normalized depower settings
#     v_a: the apparent wind speed
#     omega: the angular velocity of the kite
#     implements the simulink diagram ./01_doc/kite_model.png
#     """
#     def __init__(self, beta_0=33.0, psi_0=90.0, phi_0=0.0, K_d_s=1.5, c1=0.262, c2=6.27, omega=0.08):
#         self.int_beta = Integrator(x_0=radians(beta_0)) # integrator output: the elevation angle beta
#         self.int_psi =  Integrator(x_0=radians(psi_0))  # integrator output: heading angle psi, not normalized
#         self.int_phi =  Integrator(x_0=radians(phi_0))  # integrator output: azimuth angle phi
#         self.u_s = 0.0
#         self.v_a = 0.0
#         self.u_d_prime = 0.2
#         self.k_d_s = K_d_s
#         self.omega = omega
#         self.c0 = 0.0
#         self.c1 = c1
#         self.c2 = c2
#         self.psi_dot = 0.0
#         self.a = 0.0
#         self.m1 = self.c2 / 20.0
#         self.res = np.zeros(2)
#         self.psi = radians(psi_0)
#         self.psi_dot = 0.0
#         self.beta = radians(beta_0)
#         self.phi = radians(phi_0)
#         self.x0 = 0.0

#     def setUS(self, u_s):
#         self.u_s = u_s

#     def setUD_prime(self, u_d_prime):
#         self.u_d_prime = u_d_prime

#     def setVA(self, v_a):
#         self.v_a = v_a

#     def setOmega(self, omega):
#         self.omega = omega

#     def getPsiDot(self):
#         return self.psi_dot

#     def getPsi(self):
#         return self.psi
        
#     def getBeta(self):
#         return self.beta
        
#     def getPhi(self):
#         return self.phi
        
#     def getX0(self):
#         return self.x0
        
#     def calcX0_X1_psi_dot(self, x):
#         x0, x1 = x[0], x[1]
#         psi_dot = self.a + self.m1 * sin(x0) * cos(x1)
#         x0 = self.int_psi.calcOutput(psi_dot)
#         x1 = self.int_beta.calcOutput(self.omega * cos(x0))
#         return x0, x1, psi_dot

#     def calcResidual(self, x):
#         x0, x1, psi_dot = self.calcX0_X1_psi_dot(x)
#         self.res[0] = (x0 - x[0]) * 0.5
#         self.res[1] = (x1 - x[1]) 
#         return self.res

#     def solve(self):
#         divisor = self.u_d_prime * self.k_d_s + 1.0
#         assert abs(divisor) > EPSILON
#         self.a = (self.u_s - self.c0) * self.v_a * self.c1 / divisor
#         self.m1 = self.c2 / 20.0
#         x = scipy.optimize.broyden1(self.calcResidual, [self.x0, self.beta], f_tol=1e-14)
#         x0, x1, psi_dot = self.calcX0_X1_psi_dot(x)
#         self.psi_dot = psi_dot
#         self.psi = wrapToPi(x0)
#         self.x0 = x0
#         self.beta = x1
#         self.phi = self.int_phi.calcOutput(-(sin(x0) * self.omega))

#     def onTimer(self):
#         self.int_beta.onTimer()
#         self.int_psi.onTimer()
#         self.int_phi.onTimer()

# class SpeedController(object):
#     """
#     PI controller for the reel-out speed of the winch in speed control mode.
#     While inactive, it tracks the value from the tracking input.
#     Back-calculation is used as anti-windup method and for tracking. The constant for
#     anti-windup is K_b, the constant for tracking K_t
#     Implements the simulink block diagram, shown in ./01_doc/speed_controller.png.
#     """
#     def __init__(self, P=P_SPEED, I=I_SPEED, K_b=K_b_SPEED, K_t=K_t_SPEED):
#         self._P = P
#         self.integrator = Integrator()
#         self._I = I
#         self._K_b = K_b
#         self._K_t = K_t
#         self._v_act = 0.0
#         self._v_set_in = 0.0
#         self._inactive = False
#         self._tracking = 0.0
#         self._v_err = 0.0      # output, calculated by solve
#         self._v_set_out = 0.0  # output, calculated by solve
#         self.limiter = RateLimiter()
#         self.delay = UnitDelay()
#         self.res = np.zeros(2)

#     def setInactive(self, inactive):
#         assert type(inactive) == bool
#         # if it gets activated
#         if self._inactive and not inactive:
#             # print "SC: Reset. v_set: ", self._tracking
#             self.integrator.reset(self._tracking)
#             self.limiter.reset(self._tracking)
#             self._v_set_out = self._tracking
#         self._inactive = inactive

#     def setVAct(self, v_act):
#         self._v_act = v_act

#     def setVSetIn(self, v_set_in):
#         self._v_set_in = v_set_in

#     def setTracking(self, tracking):
#         self._tracking = tracking

#     def calcSat2In_Sat2Out_rateOut(self, x):
#         kb_in = x[0]
#         kt_in = x[1]
#         int_in = self._I * self.sat_out + self._K_b * kb_in + self._K_t * kt_in * (self._inactive)
#         int_out = self.integrator.calcOutput(int_in)
#         if True:
#             sat2_in = int_out + self._P * self.delay.calcOutput(self.sat_out)
#         else:
#             sat2_in = int_out + self._P * self.sat_out
#         sat2_out = saturation(sat2_in, -V_ri_max, V_SAT)
#         rate_out = self.limiter.calcOutput(sat2_out)
#         return sat2_in, sat2_out, rate_out, int_in

#     def calcResidual(self, x):
#         """
#         Function, that calculates the residual for the given kb_in and kt_in estimates
#         of the feed-back loop of the integrator.
#         """
#         # TODO: calculate kt_in correctly
#         # kt_in = x[1]
#         sat2_in, sat2_out, rate_out, int_in = self.calcSat2In_Sat2Out_rateOut(x)
#         kt_in = self._tracking - sat2_out
#         kb_in = sat2_out - sat2_in
#         self.res[0] = kb_in - x[0]
#         self.res[1] = kt_in - x[1]
#         # print self.res[0], kb_in
#         return self.res

#     def solve(self):
#         err = self._v_set_in - self._v_act
#         if self._inactive:
#             self._v_err = 0.0
#         else:
#             self._v_err = err
#         self.sat_out = saturation(err, -V_SAT_ERR, V_SAT_ERR)
#         # begin interate
#         # print "------------------"
#         x = scipy.optimize.broyden2(self.calcResidual, [0.0, 0.0], f_tol=1e-14)
#         sat2_in, sat2_out, rate_out, int_in = self.calcSat2In_Sat2Out_rateOut(x)
#         # print "int_in, sat2_in", int_in, sat2_in
#         # end first iteration loop
#         self._v_set_out = rate_out

#     def onTimer(self):
#         self.limiter.onTimer()
#         self.integrator.onTimer()
#         self.delay.onTimer()

#     def getVSetOut(self):
#         self.solve()
#         return self._v_set_out

#     def getVErr(self):
#         if self._inactive:
#             return 0.0
#         else:
#             return self._v_err

# class LowerForceController(object):
#     """
#     PI controller for the lower force of the tether.
#     While inactive, it tracks the value from the tracking input.
#     Back-calculation is used as anti-windup method and for tracking. The constant for
#     anti-windup is K_b, the constant for tracking K_t
#     Implements the simulink block diagram, shown in ./01_doc/lower_force_controller.png.
#     """
#     def __init__(self, P, I, K_b, K_t):
#         self._P = P
#         self.integrator = Integrator()
#         self._I = I
#         self._K_b = K_b
#         self._K_t = K_t
#         self._v_act = 0.0
#         self._force = 0.0
#         self._reset = False
#         self._active = False
#         self._f_set = 0.0
#         self._v_sw = 0.0
#         self._tracking = 0.0
#         self._f_err = 0.0      # output, calculated by solve
#         self._v_set_out = 0.0  # output, calculated by solve
#         self.limiter = RateLimiter()
#         self.delay = UnitDelay()
#         self.res = np.zeros(2)

#     def _set(self):
#         """ internal method to set the SR flip-flop and activate the force controller """
#                 # if it gets activated
#         if self._reset:
#             return
#         if not self._active:
#             # print "Reset. Tracking: ", self._tracking
#             self.integrator.reset(self._tracking)
#             self.limiter.reset(self._tracking)
#             self._v_set_out = self._tracking
#         self._active = True

#     def _updateReset(self):
#         if (self._v_act - self._v_sw) >= 0.0 or self._reset:
#             if (self._force - self._f_set) > 0.0 or self._reset:
#                 self._active = False

#     def setVAct(self, v_act):
#         self._v_act = v_act

#     def setForce(self, force):
#         self._force = force

#     def setReset(self, reset):
#         self._reset = reset
#         self._updateReset()

#     def setFSet(self, f_set):
#         self._f_set = f_set

#     def setV_SW(self, v_sw):
#         self._v_sw = v_sw
#         # print "--->>>", self._v_sw, self._v_act
# #        if self._active and (self._v_act - self._v_sw) >= 0.0:
# #            print "-->", self._v_act

#     def setTracking(self, tracking):
#         self._tracking = tracking

#     def calcSat2In_Sat2Out_rateOut(self, x):
#         kb_in = x[0]
#         kt_in = x[1]
#         int_in = self._I * self._f_err + self._K_b * kb_in + self._K_t * kt_in * (not self._active)
#         int_out = self.integrator.calcOutput(int_in)
#         sat2_in = int_out + self._P * self.delay.calcOutput(self._f_err)
#         sat2_out = saturation(sat2_in, -V_ri_max, V_SAT)
#         rate_out = self.limiter.calcOutput(sat2_out)
#         return sat2_in, sat2_out, rate_out, int_in

#     def solve(self):
#         self._updateReset()
#         err = self._force - self._f_set

#         if not self._active:
#             # activate the force controller if the force drops below the set force
#             if err < 0.0:
#                 self._set()
#                 # print "err: ", err
#             self._f_err = 0.0
#         else:
#             self._f_err = err

#         # begin interate
#         # print "------------------"
#         x = scipy.optimize.broyden2(self.calcResidual, [0.0, 0.0], f_tol=1e-14)
#         sat2_in, sat2_out, rate_out, int_in = self.calcSat2In_Sat2Out_rateOut(x)
#         # print "int_in, sat2_in", int_in, sat2_in
#         # end first iteration loop
#         self._v_set_out = rate_out

#     def calcResidual(self, x):
#         """
#         Function, that calculates the residual for the given kb_in and kt_in estimates
#         of the feed-back loop of the integrator.
#         """
#         sat2_in, sat2_out, rate_out, int_in = self.calcSat2In_Sat2Out_rateOut(x)
#         kt_in = self._tracking - sat2_out
#         kb_in = rate_out - sat2_in
#         self.res[0] = kb_in - x[0]
#         self.res[1] = kt_in - x[1]
#         # print self.res[0], kb_in
#         return self.res

#     def getVSetOut(self):
#         self.solve()
#         return self._v_set_out

#     def getFErr(self):
#         return self._f_err

#     def getFSetLow(self):
#         return self._active * self._f_set

#     def onTimer(self):
#         self.limiter.onTimer()
#         self.integrator.onTimer()
#         self.delay.onTimer()

# class UpperForceController(object):
#     """
#     PI controller for the lower force of the tether.
#     While inactive, it tracks the value from the tracking input.
#     Back-calculation is used as anti-windup method and for tracking. The constant for
#     anti-windup is K_b, the constant for tracking K_t
#     Implements the simulink block diagram, shown in ./01_doc/lower_force_controller.png.
#     """
#     def __init__(self, P, I, D, N, K_b, K_t):
#         self._P = P
#         self.integrator = Integrator()
#         self.int2 = Integrator() # integrater of the D part
#         self._I = I
#         self._D = D
#         self._N = N
#         self._K_b = K_b
#         self._K_t = K_t
#         self._v_act = 0.0
#         self._force = 0.0
#         self._reset = False
#         self._active = False
#         self._f_set = 0.0
#         self._v_sw = 0.0
#         self._tracking = 0.0
#         self._f_err = 0.0      # output, calculated by solve
#         self._v_set_out = 0.0  # output, calculated by solve
#         self.limiter = RateLimiter()
#         self.delay = UnitDelay()
#         self.res = np.zeros(3)

#     def _set(self):
#         """ internal method to set the SR flip-flop and activate the force controller """
#                 # if it gets activated
#         if self._reset:
#             return
#         if not self._active:
#             # print "Reset. Tracking: ", self._tracking
#             self.integrator.reset(self._tracking)
#             self.int2.reset(0.0)
#             self.limiter.reset(self._tracking)
#             self._v_set_out = self._tracking
#         self._active = True

#     def _updateReset(self):
#         if (self._v_act - self._v_sw) <= 0.0 or self._reset:
#             if (self._force - self._f_set) < 0.0 or self._reset:
#                 self._active = False

#     def setVAct(self, v_act):
#         self._v_act = v_act

#     def setForce(self, force):
#         self._force = force

#     def setReset(self, reset):
#         self._reset = reset

#     def setFSet(self, f_set):
#         self._f_set = f_set

#     def setV_SW(self, v_sw):
#         self._v_sw = v_sw
#         # print "--->>>", self._v_sw, self._v_act
# #        if self._active and (self._v_act - self._v_sw) >= 0.0:
# #            print "-->", self._v_act

#     def setTracking(self, tracking):
#         self._tracking = tracking

#     def calcSat2In_Sat2Out_rateOut(self, x):
#         kb_in = x[0]
#         kt_in = x[1]
#         int2_in = x[2]
#         int_in = self._I * self._f_err + self._K_b * kb_in + self._K_t * kt_in * (not self._active)
#         int_out = self.integrator.calcOutput(int_in)
#         int2_out = self.int2.calcOutput(int2_in)
#         sat2_in = int_out + self._P * self.delay.calcOutput(self._f_err) + self._N * (self._f_err * self._D - int2_out)

#         sat2_out = saturation(sat2_in, -V_ri_max, V_SAT)
#         rate_out = self.limiter.calcOutput(sat2_out)
#         return sat2_in, sat2_out, rate_out, int_in, int2_in

#     def solve(self):
#         self._updateReset()
#         err = self._force - self._f_set

#         if not self._active:
#             # activate the force controller if the force rises above the set force
#             if err >= 0.0:
#                 self._set()
#                 # print "err: ", err
#             self._f_err = 0.0
#         else:
#             self._f_err = err
#         # begin interate
#         # print "------------------"
#         x = scipy.optimize.broyden1(self.calcResidual, [0.0, 0.0, 0.0], f_tol=1e-14)
#         sat2_in, sat2_out, rate_out, int_in, int2_in = self.calcSat2In_Sat2Out_rateOut(x)
#         # print "int_in, sat2_in", int_in, sat2_in
#         # end first iteration loop
#         self._v_set_out = rate_out

#     def calcResidual(self, x):
#         """
#         Function, that calculates the residual for the given kb_in and kt_in estimates
#         of the feed-back loop of the integrator.
#         """
#         sat2_in, sat2_out, rate_out, int_in, int2_in = self.calcSat2In_Sat2Out_rateOut(x)
#         kt_in = self._tracking - sat2_out
#         kb_in = rate_out - sat2_in
#         self.res[0] = kb_in - x[0]
#         self.res[1] = kt_in - x[1]
#         self.res[2] = int2_in - x[2]
#         # print self.res[0], kb_in
#         return self.res

#     def getVSetOut(self):
#         self.solve()
#         return self._v_set_out

#     def getFErr(self):
#         return self._f_err

#     def getFSetUpper(self):
#         return self._active * self._f_set

#     def onTimer(self):
#         self.limiter.onTimer()
#         self.integrator.onTimer()
#         self.int2.onTimer()
#         self.delay.onTimer()

# if __name__ == "__main__":
#     limiter = RateLimiter()
#     mix2 = Mixer_2CH()
#     mix3 = Mixer_3CH()
#     pid1 = SpeedController()
#     pid2 = LowerForceController(P_F_LOW, I_F_LOW, K_b_F_LOW, K_t_F_LOW)
#     pid3 = UpperForceController(P_F_HIGH, I_F_HIGH, D_F_HIGH, N_F_HIGH, K_b_F_HIGH, K_t_F_HIGH)
#     winch = Winch()
#     kite = KiteModel()

