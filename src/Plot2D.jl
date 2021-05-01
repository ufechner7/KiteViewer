using Revise,  GLMakie

includet("./Utils.jl")
using .Utils

const objects = []

function plot_height(fig, log)
    if length(objects) > 0
        delete!(objects[end])
    end
    ax=Axis(fig[1, 1], xlabel = "time [s]", ylabel = "height [m]")
    x=log.extlog.time
    y=log.extlog.z
    po=lines!(x,y)
    object=(ax, po)
    push!(objects, ax)   
end

function plot_elevation(fig, log)
    if length(objects) > 0
        delete!(objects[end])
    end
    ax=Axis(fig[1, 1], xlabel = "time [s]", ylabel = "elevation [°]")
    x=log.extlog.time
    y=log.syslog.elevation/pi*180.0
    po=lines!(x,y)   
    push!(objects, ax) 
end

function plot_azimuth(fig, log)
    if length(objects) > 0
        delete!(objects[end])
    end
    ax=Axis(fig[1, 1], xlabel = "time [s]", ylabel = "azimuth [°]")
    x=log.extlog.time
    y=log.syslog.azimuth/pi*180.0
    po=lines!(x,y)   
    push!(objects, ax) 
end

function plot_v_reelout(fig, log)
    if length(objects) > 0
        delete!(objects[end])
    end
    ax=Axis(fig[1, 1], xlabel = "time [s]", ylabel = "v_reelout [m/s]")
    x=log.extlog.time
    y=log.syslog.v_reelout
    po=lines!(x,y)   
    push!(objects, ax) 
end

function plot_force(fig, log)
    if length(objects) > 0
        delete!(objects[end])
    end
    ax=Axis(fig[1, 1], xlabel = "time [s]", ylabel = "force [N]")
    x=log.extlog.time
    y=log.syslog.force
    po=lines!(x,y)   
    push!(objects, ax) 
end

function plot_power(fig, log)
    if length(objects) > 0
        delete!(objects[end])
    end
    ax=Axis(fig[1, 1], xlabel = "time [s]", ylabel = "mechanical power [kW]")
    x=log.extlog.time
    y=log.syslog.force .* log.syslog.v_reelout./1000.0
    po=lines!(x,y)   
    push!(objects, ax) 
end

function main(gl_wait=true)
    fig=Figure()

    fig[2, 1] = buttongrid = GridLayout(tellwidth = false)
    btn_height         = Button(fig, label = "height")
    btn_elevation      = Button(fig, label = "elevation")
    btn_azimuth        = Button(fig, label = "azimuth")
    btn_v_reelout      = Button(fig, label = "v_reelout")
    btn_force          = Button(fig, label = "force")
    btn_power          = Button(fig, label = "power")
    buttongrid[1, 1:6] = [btn_height, btn_elevation, btn_azimuth, btn_v_reelout, btn_force, btn_power]

    if gl_wait
        log=load_log(basename(se().log_file))
    else
        log = demo_log("Launch test!")
    end

    on(btn_height.clicks) do c
        plot_height(fig, log)
    end
    on(btn_elevation.clicks) do c
        plot_elevation(fig, log)
    end
    on(btn_azimuth.clicks) do c
        plot_azimuth(fig, log)
    end
    on(btn_v_reelout.clicks) do c
        plot_v_reelout(fig, log)
    end
    on(btn_force.clicks) do c
        plot_force(fig, log)
    end
    on(btn_power.clicks) do c
        plot_power(fig, log)
    end

    plot_height(fig, log)

    gl_screen = display(fig)
    if gl_wait
        wait(gl_screen)
    end
    return nothing
end
