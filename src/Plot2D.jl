module Plot2D

using GLMakie
export plot2d, buttons

LOG=nothing
const P1= [Node(Vector{Point2f0}(undef, 6000))]

function autoscale(ax, x, y)
    xlims!(ax, x[1], x[end])
    range = maximum(y) - minimum(y)
    ylims!(ax, minimum(y)-0.05*range, maximum(y)+0.05*range)
end

function plot2d(se, ax, label, log, p1, field)
    global LOG, P1
    LOG=log
    P1[1]=p1
    unit = ""
    factor = 1.0
    y = [1f0]
    if field == :height
        unit = "[m]"
        y    = log.extlog.z ./ se().zoom * factor
    elseif field == :elevation
        unit = "[°]"
        y    = log.syslog.elevation/pi*180.0
        factor = 180.0/pi
    elseif field == :azimuth
        unit = "[°]"
        y    = log.syslog.azimuth/pi*180.0
        factor = 180.0/pi
    elseif field == :v_reelout
        unit = "[m/s]"
        y    = log.syslog.v_reelout
    elseif field == :force
        unit = "[N]"
        y    = log.syslog.force
    end
    x       = log.extlog.time
    label[] = string(field) * " " * unit
    p1[]    =  Point2f0.(x, y)
    autoscale(ax, x, y)
end

function buttons(fig, bg, se, ax, label, reset)
    textsize=14
    btn_height         = Button(fig, label = "height", textsize=textsize)
    btn_elevation      = Button(fig, label = "elevation", textsize=textsize)
    btn_azimuth        = Button(fig, label = "azimuth", textsize=textsize)
    btn_v_reelout      = Button(fig, label = "v_reelout", textsize=textsize)
    btn_force          = Button(fig, label = "force", textsize=textsize)
    btn_depower        = Button(fig, label = "depower", textsize=textsize)
    btn_v_app          = Button(fig, label = "v_app", textsize=textsize)
    btn_l_tether       = Button(fig, label = "l_tether", textsize=textsize)
    btn_power          = Button(fig, label = "power", textsize=textsize)
    bg[1, 1:9] = [btn_height, btn_elevation, btn_azimuth, btn_v_reelout, btn_force, btn_depower, btn_v_app, btn_l_tether, btn_power]

    on(btn_height.clicks) do c
        plot2d(se, ax, label, LOG, P1[1], :height)
        reset()
    end
    on(btn_elevation.clicks) do c
        plot2d(se, ax, label, LOG, P1[1], :elevation)
        reset()
    end
    on(btn_azimuth.clicks) do c
        plot2d(se, ax, label, LOG, P1[1], :azimuth)
        reset()
    end
    on(btn_v_reelout.clicks) do c
        plot2d(se, ax, label, LOG, P1[1], :v_reelout)
        reset()
    end
    on(btn_force.clicks) do c
        plot2d(se, ax, label, LOG, P1[1], :force)
        reset()
    end
end

# function plot_power(fig, log)
#     if length(objects) > 0
#         delete!(objects[end])
#     end
#     ax=Axis(fig[1, 1], xlabel = "time [s]", ylabel = "mechanical power [kW]")
#     x=log.extlog.time
#     y=log.syslog.force .* log.syslog.v_reelout./1000.0
#     po=lines!(x,y)   
#     push!(objects, ax) 
# end

# function plot_depower(fig, log)
#     if length(objects) > 0
#         delete!(objects[end])
#     end
#     ax=Axis(fig[1, 1], xlabel = "time [s]", ylabel = "depower [%]")
#     x=log.extlog.time
#     y=log.syslog.depower .* 100.0
#     po=lines!(x,y)   
#     push!(objects, ax) 
# end

# function plot_v_app(fig, log)
#     if length(objects) > 0
#         delete!(objects[end])
#     end
#     ax=Axis(fig[1, 1], xlabel = "time [s]", ylabel = "v_app [m/s]")
#     x=log.extlog.time
#     y=log.syslog.v_app
#     po=lines!(x,y)   
#     push!(objects, ax) 
# end

# function plot_l_tether(fig, log)
#     if length(objects) > 0
#         delete!(objects[end])
#     end
#     ax=Axis(fig[1, 1], xlabel = "time [s]", ylabel = "tether length [m]")
#     x=log.extlog.time
#     y=log.syslog.l_tether
#     po=lines!(x,y)   
#     push!(objects, ax) 
# end

# function main(gl_wait=true)
#     fig=Figure()

#     fig[2, 1] = buttongrid = GridLayout(tellwidth = false, default_colgap=10)
#     textsize=14
#     btn_height         = Button(fig, label = "height", textsize=textsize)
#     btn_elevation      = Button(fig, label = "elevation", textsize=textsize)
#     btn_azimuth        = Button(fig, label = "azimuth", textsize=textsize)
#     btn_v_reelout      = Button(fig, label = "v_reelout", textsize=textsize)
#     btn_force          = Button(fig, label = "force", textsize=textsize)
#     btn_depower        = Button(fig, label = "depower", textsize=textsize)
#     btn_v_app          = Button(fig, label = "v_app", textsize=textsize)
#     btn_l_tether        = Button(fig, label = "l_tether", textsize=textsize)
#     btn_power          = Button(fig, label = "power", textsize=textsize)
#     buttongrid[1, 1:9] = [btn_height, btn_elevation, btn_azimuth, btn_v_reelout, btn_force, btn_depower, btn_v_app, btn_l_tether, btn_power]

#     if gl_wait
#         log=load_log(basename(se().log_file))
#     else
#         log = demo_log("Launch test!")
#     end

#     on(btn_height.clicks) do c
#         plot_height(fig, log)
#     end
#     on(btn_elevation.clicks) do c
#         plot_elevation(fig, log)
#     end
#     on(btn_azimuth.clicks) do c
#         plot_azimuth(fig, log)
#     end
#     on(btn_v_reelout.clicks) do c
#         plot_v_reelout(fig, log)
#     end
#     on(btn_force.clicks) do c
#         plot_force(fig, log)
#     end
#     on(btn_depower.clicks) do c
#         plot_depower(fig, log)
#     end
#     on(btn_v_app.clicks) do c
#         plot_v_app(fig, log)
#     end
#     on(btn_l_tether.clicks) do c
#         plot_l_tether(fig, log)
#     end
#     on(btn_power.clicks) do c
#         plot_power(fig, log)
#     end

#     plot_height(fig, log)

#     gl_screen = display(fig)
#     if gl_wait
#         wait(gl_screen)
#     end
#     return nothing
# end

end