# Implements the class FlightPathController as specified in chapter six of
# the PhD thesis of Uwe Fechner.

# from Components import saturation, Integrator, PERIOD_TIME

# PRINT = False
# PRINT_NDI_GAIN = False
# PRINT_EST_PSI_DOT = False
# PRINT_VA = False

# USE_CHI = True

# RESET_INT1 = True # reset the main integrator to the last estimated turn rate
# RESET_INT2 = False # reset the integrator of the D part at the second time step
# INIT_OPT_TO_ZERO = False # if the root finder should start with zero
# RESET_INT1_TO_ZERO = True
# USE_RADIUS = True

# TAU = 0.95
# TAU_VA = 0.0
# # TAU = 0.0

# # Settings of the flight path controller
# FPC_P    = 20.0 # P gain of the PID controller
# FPC_I    =  1.2 # I gain of the PID controller
# FPC_D    = 10.0  # * 0.1 # D gain of the PID controller
# FPC_GAIN = 0.16 * 0.25# * 2.2 *1.2 # additional factor for P, I and D

# if True:
#     C1 =  0.0612998898221 # was: 0.0786
#     C2 =  1.22597628388   # was: 2.508
#     # increase K_C1, if the radius is too small
#     K_C1 = 1.6 # was: 1.6
#     K_C2 = 6.0     # C2 for the reelout phase was: 7.0
#     K_C2_high = 12.0  # C2 for the reelout phase at high elevation angles was: 14.0
#     K_C2_int = 0.6 # C2 for the intermediate phase LOW_RIGHT, LOW_TURN, LOW_LEFT
# else:
#     K_C1  =  0.3  # correction factor for C1, used by the NDI block  (0.8 < K_C1 < 1.2)
#     C1 = 0.262
#     C2 = 6.27
#     K_C2  =  0.4  # correction factor for C2, used by the NDI block (-1.5 < K_C2 > 1.5)

# def form(number):
#     """ Convert a number to a string with two digits after the decimal point. """
#     return "{:.2f}".format(number)

# def wrapToPi(value):
#     """ Return a value in the range of +- pi. """
#     if value < -pi:
#         result = value + 2 * pi
#     elif value > pi:
#         result = value - 2 * pi
#     else:
#         result = value
#     return result

# def mergeAngles(alpha, beta, factor_beta):
#     """
#     Calculate the weighted average of two angles. The weight of beta,
#     factor_beta must be between 0 and 1.
#     """
#     x1 = sin(alpha)
#     y1 = cos(alpha)
#     x2 = sin(beta)
#     y2 = cos(beta)
#     x = x1 * (1.0 - factor_beta) + x2 * factor_beta
#     y = y1 * (1.0 - factor_beta) + y2 * factor_beta
#     return atan2(x, y)

# class FlightPathController(object):
#     """
#     FlightPathController as specified in chapter six of the PhD thesis of Uwe Fechner.

#     Main inputs are calls to the functions:
#     - onNewControlCommand()
#     - onNewEstSysState()

#     Main output is the set value of the steering u_s, returned by the method:
#     - calcSteering()
#     This method needs the current time step as parameter.

#     Once per time step the method
#     - onTimer
#     must be called.

#     See also:
#     ./01_doc/flight_path_controller_I.png and
#     ./01_doc/flight_path_controller_II.png and
#     ./01_doc/flight_path_controller_III.png
#     """
#     def __init__(self, pro):
#         self.count = 0               # cycle number
#         self.attractor = np.zeros(2) # attractor coordinates, azimuth and elevation in radian
#         self.psi_dot_set = None      # desired turn rate in rad per second or None
#         self.psi_dot_set_final = None
#         self.phi = 0.0               # the azimuth angle of the kite position in radian
#         self.beta = 0.0              # the elevation angle of the kite position in radian
#         self.psi = 0.0               # heading of the kite in radian
#         self.chi = 0.0               # course in radian
#         self.chi_factor = 0.0        # 0.0 use psi only; 1.0 use chi only
#         self.omega = 0.0             # angular velocity of the kite in degrees/s
#         self.est_psi_dot = 0.0       # estimated turn rate
#         self.chi_set = 0.0           # desired flight direction (bearing)
#         # minimal value of the depower setting, needed for the fully powered kite     
#         self.u_d0 = 0.01 * pro._mode.min_depower    
#         # maximal value of the depower setting, needed for the fully depowered kite
#         self.u_d_max = 0.01 * pro._mode.max_depower 
#         self.u_d_prime = 0.2         # normalized depower settings
#         self.u_s_max = 0.99           # maximal value of the steering settings
#         self.psi_dot_max = 3.0       # maximal value of the turn rate in radians per second
#         self.K_d_s = 2.0             # influece of the depower settings on the steering sensitivity
#         self.u_d = self.u_d0         # actual depower setting (0..1)
#         self.k_c2 = pro._course_control.K_C2
#         self.k_c2_int = pro._course_control.K_C2_int
#         self.k_c2_high = pro._course_control.K_C2_high
#         self.c1 = C1 * pro._course_control.K_C1       # identified value for hydra kite from paper [rad/m]
#         self.c2 = C2 * self.k_c2
#         self.intermediate = True
#         self.v_a = 0.0               # apparent wind speed at the kite
#         self.v_a_av = 0.0            # average apparent wind speed
#         self.v_a_min = 8.0           # minimal apparent wind speed for full NDI
#         self.ndi_gain = 1.0          # quotient of the output and the input of the NDI block
#         self.int = Integrator()      # integrator for the I part of the pid controller
#         self.int2 = Integrator()     # integrator for the D part of the pid controller
#         self.P = FPC_P               # P gain of the PID controller
#         self.I = FPC_I               # I gain of the PID controller
#         self.D = FPC_D               # D gain of the PID controller
#         self.gain = FPC_GAIN         # additional factor for P, I and D
#         self.K_u = 5.0               # anti-windup gain for limited steering signal
#         self.K_psi = 10.0            # anti-windup gatin for limited turn rate
#         self.err = 0.0               # error (input of the PID controller)
#         self.res = np.zeros(2)       # residual of the solver
#         self.u_s = 0.0               # steering output of the FPC, caculated by solve()
#         self.period_time = PERIOD_TIME      # period time
#         self.Kpsi_out = 0.0
#         self.Ku_out = 0.0
#         self.k_psi_in = 0.0
#         self.k_u_in = 0.0
#         self.int_in = 0.0
#         self.int2_in = 0.0
#         self.reset_int1 = False
#         self.radius = None
#         self._N = 15
#         self._i = 0                  # number of calls of solve

#     def onNewControlCommand(self, attractor=None, psi_dot_set=None, radius=None, intermediate = True):
#         """
#         Input:
#         Either the attractor point (numpy array of azimuth and elevation in radian),
#         or psi_dot, the set value for the turn rate in degrees per second.
#         """
#         self.intermediate = intermediate
#         if USE_RADIUS and radius is not None:
#              psi_dot_set = degrees(self.omega / radius) # desired turn rate during the turns
#         if psi_dot_set is not None and radius is not None:
#             temp = self.omega / radius
#             if PRINT:
#                 print "--->>--->> temp, psi_dot_set", form(temp), form(psi_dot_set), form(self.omega), form(radius)
#         self.radius = radius
#         if psi_dot_set is None and self.psi_dot_set is not None:
#             # reset integrator
#             self.reset_int1 = True
#         if attractor is not None:
#             self.attractor[:] = attractor
#         if psi_dot_set is not None:
#             self.psi_dot_set_final = radians(psi_dot_set)
#             self.psi_dot_set = self.psi_dot_set_final * 2.0
#         else:
#             self.psi_dot_set = None

#     def onNewEstSysState(self, phi, beta, psi, chi, omega, v_a, u_d=None, u_d_prime=None, \
#                                period_time=PERIOD_TIME):
#         """
#         Parameters:
#         phi:  the azimuth angle of the kite position in radian
#         beta: the elevation angle of the kite position in radian
#         psi:  heading of the kite in radian
#         chi:  course of the kite in radian
#         omega: angular velocity of the kite on the unit sphere in degrees/s ???
#         """
#         self.phi = phi
#         self.chi = chi
#         self.omega = omega
#         self.beta = beta
#         self.period_time = period_time
#         if self._i > 0:
#             delta = psi - self.psi
#             if delta < -pi:
#                 delta += 2 * pi
#             if delta > pi:
#                 delta -= 2 * pi
#             self.est_psi_dot = (delta) / period_time
#         self.psi = psi
#         # Eq. 6.4: calculate the normalized depower setting
#         if u_d_prime is None:
#             self.u_d_prime = (u_d - self.u_d0) / (self.u_d_max - self.u_d0)
#         else:
#             self.u_d_prime = u_d_prime
#         self.u_d = u_d
#         self.v_a = v_a
#         self.v_a_av = TAU_VA * self.v_a_av + (1.0 - TAU_VA) * v_a
#         # print some debug info every second
#         self.count += 1
#         if self.count >= 50:
#             if PRINT_NDI_GAIN:
#                 print "ndi_gain", form(self.ndi_gain)
#             if PRINT_EST_PSI_DOT:
#                 print "est_psi_dot:", degrees(self.est_psi_dot)
#             if PRINT_VA:
#                 print "va, va_av", form(v_a), form(self.v_a_av)
#             self.count = 0

#     def _navigate(self, limit=50.0):
#         """
#         Calculate the desired flight direction chi_set using great circle navigation.
#         Limit delta_beta to the value of the parameter limit (in degrees).
#         """
#         # navigate only if steering towards the attractor point is active
#         if self.psi_dot_set is not None:
#             return
#         phi_set = self.attractor[0]
#         beta_set = self.attractor[1]
#         r_limit = radians(limit)
#         if beta_set - self.beta > r_limit:
#             beta_set = self.beta + r_limit
#         if beta_set - self.beta < -r_limit:
#             beta_set = self.beta - r_limit
#         y = sin(phi_set - self.phi) * cos(beta_set)
#         x = cos(self.beta) * sin(beta_set) - sin(self.beta) * cos(beta_set) * cos(phi_set - self.phi)
#         self.chi_set = atan2(-y, x)

#     def _linearize(self, psi_dot, fix_va=False):
#         """
#         Implement the nonlinear, dynamic inversion block (NDI) according to Eq. 6.4 and Eq. 6.12.
#         psi_dot: desired turn rate in radians per second
#         fix_va: keep v_a fixed for the second term of the turn rate low; was useful in some
#         simulink tests.
#         """
#         # Eq. 6.13: calculate v_a_hat
#         if self.v_a_av >= self.v_a_min:
#             v_a_hat = self.v_a_av
#         else:
#             v_a_hat = self.v_a_min
#         # print "v_a, v_a_hat", self.v_a, v_a_hat
#         # Eq. 6.12: calculate the steering from the desired turn rate
#         if fix_va:
#             va_fix = 20.0
#         else:
#             va_fix = v_a_hat
#         if self.intermediate:
#             k = (va_fix - 22) / 3.8
#             c2 = C2 * (self.k_c2_int + k)
#         else:
#             k = (va_fix - 22) / 3.5 # was: 4
#             if self.beta < radians(30):
#                 c2 = C2 * (self.k_c2 + k)
#             else:
#                 c2 = C2 * (self.k_c2_high + k)
#         u_s = (1.0 + self.K_d_s * self.u_d_prime) / (self.c1 * v_a_hat) \
#               * (psi_dot - c2 / va_fix * sin(self.psi) * cos(self.beta))
#         if abs(psi_dot) < 1e-6:
#             psi_dot = 1e-6
#         self.ndi_gain = saturation(u_s / psi_dot, -20.0, 20.0)
#         if abs(self.ndi_gain) < 1e-6:
#             self.ndi_gain = 1e-6
#         # print "ndi_gain", self.ndi_gain
#         return u_s

#     def _calcSat1In_Sat1Out_SatIn_Sat2Out(self, x):
#         """
#         see: ./01_doc/flight_path_controller_II.png
#         x: vector of k_u_in, k_psi_in and int2_in
#         """
#         k_u_in   = x[0]
#         k_psi_in = x[1]

#         # calculate I part
#         int_in = self.I * self.err + self.K_u * k_u_in + self.K_psi * k_psi_in
#         int_out = self.int.calcOutput(int_in)

#         # calculate D part
#         int2_in = self._N * (self.err * self.D - self.int2.getLastOutput()) / (1.0 + self._N * self.period_time)
#         self.int2.calcOutput(int2_in)

#         # calculate P, I, D output
#         sat1_in = (self.P * self.err + int_out + int2_in) * self.gain

#         # calcuate saturated set value of the turn rate psi_dot
#         sat1_out = saturation(sat1_in, -self.psi_dot_max, self.psi_dot_max)
#         # nonlinar inversion
#         sat2_in = self._linearize(sat1_out)
#         # calculate the saturated set value of the steering
#         sat2_out = saturation(sat2_in, -self.u_s_max, self.u_s_max)
#         return sat1_in, sat1_out, sat2_in, sat2_out, int_in

#     def _calcResidual(self, x):
#         """
#         see: ./01_doc/flight_path_controller_II.png
#         x: vector of k_u_in, k_psi_in and int2_in
#         """
#         sat1_in, sat1_out, sat2_in, sat2_out, int_in = self._calcSat1In_Sat1Out_SatIn_Sat2Out(x)
#         k_u_in = (sat2_out - sat2_in) / self.ndi_gain
#         k_psi_in = sat1_out - sat1_in
#         self.res[0] = k_u_in - x[0]
#         self.res[1] = k_psi_in - x[1]
#         return self.res

#     def _solve(self, parking):
#         """
#         Calculate the steering output u_s and the turn rate error err,
#         but also the signals Kpsi_out, Ku_out and int_in.

#         Implements the simulink block diagram, shown in:
#         01_doc/flight_path_controller_I.png

#         If the parameter parking is True, only the heading is controlled, not the course.
#         """
#         self._navigate()
#         # control the heading of the kite
#         chi_factor = 0.0
#         if self.omega > 0.8:
#              chi_factor = (self.omega - 0.8) / 1.2
#         if chi_factor > 0.85:
#             chi_factor = 0.85
#         self.chi_factor = chi_factor
#         if USE_CHI and not parking:
#             control_var = mergeAngles(self.psi, self.chi, chi_factor)
#         else:
#             self.chi_factor = 0.0
#             control_var = self.psi
#         self.err = wrapToPi(self.chi_set - control_var)
#         if RESET_INT1 and self._i == 0 or self.reset_int1:
#             if RESET_INT1_TO_ZERO:
#                 if PRINT:
#                     print "===>>> Reset integrator to zero!"
#                 self.int.reset(0.0)
#             else:
#                 if PRINT:
#                     print "est_psi_dot: ", self.est_psi_dot
#                     print "initial integrator output: ", (self.est_psi_dot / self.gain - self.err * self.P)
#                 self.int.reset(self.est_psi_dot / self.gain - self.err * self.P)
#             self.reset_int1 = False
#         if RESET_INT2 and self._i == 1:
#             if PRINT:
#                 print "initial output of integrator two: ", self.err * self.D
#             self.int2.reset((self.err * self.D))
#         # begin interate
#         # print "------------------"
#         if INIT_OPT_TO_ZERO:
#             x = scipy.optimize.broyden1(self._calcResidual, [0.0, 0.0], f_tol=1e-14)
#         else:
#             x = scipy.optimize.broyden1(self._calcResidual, [self.k_u_in, self.k_psi_in], f_tol=1e-14)
#         sat1_in, sat1_out, sat2_in, sat2_out, int_in = self._calcSat1In_Sat1Out_SatIn_Sat2Out(x)
#         self.k_u_in = (sat2_out - sat2_in) / self.ndi_gain
#         self.k_psi_in = sat1_out - sat1_in
#         self.Kpsi_out = (sat1_out - sat1_in) * self.K_psi
#         self.Ku_out = (sat2_out - sat2_in) * self.K_u
#         # print "sat1_in, sat1_out, sat2_in, sat2_out", sat1_in, sat1_out, sat2_in, sat2_out
#         # end first iteration loop
#         self.int_in = int_in
#         if self.psi_dot_set is not None:
#             if USE_RADIUS and self.radius is not None:
#                 self.psi_dot_set_final = self.omega / self.radius # desired turn rate during the turns
#             self.psi_dot_set = self.psi_dot_set * TAU + self.psi_dot_set_final * (1-TAU)

#             self.u_s = saturation(self._linearize(self.psi_dot_set), -1.0, 1.0)
#             # self.err = 0.0
#         else:
#             self.u_s = sat2_out

#         self._i += 1
#         return self.u_s

#     def getErr(self):
#         """ Return the heading/ course error of the controller. """
#         return self.err

#     def getKpsi_out(self):
#         return self.Kpsi_out

#     def getKu_out(self):
#         return self.Ku_out

#     def getIntIn(self):
#         return self.int_in

#     def getIntOut(self):
#         return self.int.getOutput()

#     def getChiFactor(self):
#         return self.chi_factor

#     def onTimer(self):
#         self.int.onTimer()
#         self.int2.onTimer()

#     def calcSteering(self, parking, period_time):
#         self.period_time = period_time
#         self._solve(parking)
#         return self.u_s

#     def getSteering(self):
#         return self.u_s

#     def getState(self):
#         if self.psi_dot_set is not None:
#             turning = True
#             value = self.psi_dot_set
#         else:
#             turning = False
#             value = self.attractor
#         return turning, value

# if __name__ == "__main__":
#     fpc = FlightPathController()
#     u_s = fpc.calcSteering(False, 0.02)
#     print "u_s:", form(u_s)
#     u_d = 0.24
#     v_a = 24.0
#     beta = radians(70.0)
#     psi = radians(90.0)
#     chi = psi
#     phi = 0.0
#     omega = 5.0
#     fpc.onNewEstSysState(phi, beta, psi, chi, omega, v_a, u_d=u_d)
#     fpc.onTimer()
#     u_s = fpc.calcSteering(False, 0.02)
#     print "u_s:", form(u_s)