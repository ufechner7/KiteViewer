using KiteUtils

logfile=basename(se().log_file)
flight_log=demo_log(7)
try   
    flight_log = load_log(se().segments+1, logfile)
catch e
    bt = catch_backtrace()
    msg = sprint(showerror, e, bt)
    println(msg)
    raise(e)
    println("Error loading flight_log file: " * logfile)
end 
flight_log