# Simulator tests

You can find the following test scripts and modules in the folder "test":

## Settings

All tests work with a combination of global and local settings. Global settings are defined in the file
"data/settings.yaml". Local settings for example in the following function: 
```Julia
function init_392()
    my_state = KPS3.get_state()
    KPS3.set.l_tether = 392.0
    KPS3.set.elevation = 70.7
    KPS3.set.area = 10.18
    KPS3.set.v_wind = 9.51 # wind speed at 6 m height
    KPS3.set.mass = 6.2
    KPS3.clear(my_state)
end
```

## TestWindProfile
It provides the functions

1. test_wind_profile(height = 10.0, profile_law=EXP)
2. test_force()

The following profile laws are implemented:
`@enum ProfileLaw EXP=1 LOG=2 EXPLOG=3`

EXPLOG is a linar combination of the exponential and the logarithmic law which allows to fit wind profiles when the speed is measured at three different heights.

The function test_force() calculates the tether force at the winch for the conditions descripted in the paper xxx.
According to the paper the one point tether model shall give a value of 727 N, the new simulator calculates 740 N
which is close enough (the new code uses more accurate routines to calculate the lift and the drag which might
explain the difference).

To execute any of these functions type:
```Julia
./runjulia.sh
using TestWindProfile
test_force() # or test_wind_profile(100.0) or whatever
```
The following global settings are used:
```Yaml
environment:
    v_wind: 9.51     # wind speed at reference height       [m/s]
    h_ref:  6.0      # reference height for the wind speed    [m]
    rho_0:  1.225    # air density at the ground          [kg/m³]
    alpha:  0.08163  # exponent of the wind profile law
    z0: 0.0002       # surface roughness                      [m]
    profile_law: 3   # 1=EXP, 2=LOG, 3=EXPLOG
```

## Execute all tests
With the following command all available tests can be executed:
```Julia
./runjulia.sh
include("test/runtests.jl")
```


