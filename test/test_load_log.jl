using KiteUtils

logfile=basename(se().log_file)
flight_log=demo_log(7)
try   
    global flight_log
    flight_log = load_log(se().segments+1, logfile)
catch e
    bt = catch_backtrace()
    msg = sprint(showerror, e, bt)
    println(msg)
    raise(e)
    println("Error loading flight_log file: " * logfile)
end 
for i in 1:length(flight_log.syslog)
    dummy=flight_log.syslog[i]
    j=i+1
end