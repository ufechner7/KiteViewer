module Plot2D

using GLMakie
export plot2d, buttons

LOG=nothing
const P1= [Node(Vector{Point2f0}(undef, 6000))]
const P2= [Node(Vector{Point2f0}(undef, 6000))]

function autoscale(ax, x, y)
    xlims!(ax, x[1], x[end])
    range = maximum(y) - minimum(y)
    ylims!(ax, minimum(y)-0.05*range, maximum(y)+0.05*range)
end

function plot2d(se, ax, label, log, p1, field, lower=false)
    global LOG, P1, P2
    LOG=log
    if lower
        P2[1]=p1
    else
        P1[1]=p1
    end
    unit = ""
    y = [1f0]
    if field == :height
        unit = "[m]"
        y    = log.extlog.z ./ se().zoom
    elseif field == :elevation
        unit = "[°]"
        y    = log.syslog.elevation/pi*180.0
    elseif field == :azimuth
        unit = "[°]"
        y    = log.syslog.azimuth/pi*180.0
    elseif field == :v_reelout
        unit = "[m/s]"
        y    = log.syslog.v_reelout
    elseif field == :force
        unit = "[N]"
        y    = log.syslog.force
    elseif field == :depower
        unit = "[%]"
        y    = log.syslog.depower * 100.0f0
    elseif field == :v_app
        unit = "[m/s]"
        y    = log.syslog.v_app
    elseif field == :l_tether
        unit = "[m]"
        y    = log.syslog.l_tether
    elseif field == :power
        unit = "[kW]"
        y    = log.syslog.v_reelout .* log.syslog.force * 0.001f0
    end
    x       = log.extlog.time
    if field == :power
        label[] = "mechanical " * string(field) * " " * unit
    else
        label[] = string(field) * " " * unit
    end
    p1[]    =  Point2f0.(x, y)
    autoscale(ax, x, y)
end

function buttons(fig, bg, se, ax, ax2, label, label2, reset)
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
    sw = Toggle(fig, vertical=true, active = false) # active means plot in the upper area
    bg[1, 1:10] = [btn_height, btn_elevation, btn_azimuth, btn_v_reelout, btn_force, btn_depower, btn_v_app, btn_l_tether, btn_power, sw]

    on(btn_height.clicks) do c
        if sw.active[]
            plot2d(se, ax, label, LOG, P1[1], :height)
        else
            plot2d(se, ax2, label2, LOG, P2[1], :height, true)
        end
        reset()
    end
    on(btn_elevation.clicks) do c
        if sw.active[]
            plot2d(se, ax, label, LOG, P1[1], :elevation)
        else
            plot2d(se, ax2, label2, LOG, P2[1], :elevation, true)
        end
        reset()
    end
    on(btn_azimuth.clicks) do c
        if sw.active[]
            plot2d(se, ax, label, LOG, P1[1], :azimuth)
        else
            plot2d(se, ax2, label2, LOG, P2[1], :azimuth, true)
        end
        sleep(0.05)
        reset()
    end
    on(btn_v_reelout.clicks) do c
        if sw.active[]
            plot2d(se, ax, label, LOG, P1[1], :v_reelout)
        else
            plot2d(se, ax2, label2, LOG, P2[1], :v_reelout, true)
        end
        reset()
    end
    on(btn_force.clicks) do c
        if sw.active[]
            plot2d(se, ax, label, LOG, P1[1], :force)
        else
            plot2d(se, ax2, label2, LOG, P2[1], :force, true)
        end
        reset()
    end
    on(btn_depower.clicks) do c
        if sw.active[]
            plot2d(se, ax, label, LOG, P1[1], :depower)
        else
            plot2d(se, ax2, label2, LOG, P2[1], :depower, true)
        end
        reset()
    end
    on(btn_v_app.clicks) do c
        if sw.active[]
            plot2d(se, ax, label, LOG, P1[1], :v_app)
        else
            plot2d(se, ax2, label2, LOG, P2[1], :v_app, true)
        end
        reset()
    end
    on(btn_l_tether.clicks) do c
        if sw.active[]
            plot2d(se, ax, label, LOG, P1[1], :l_tether)
        else
            plot2d(se, ax2, label2, LOG, P2[1], :l_tether, true)
        end
        reset()
    end
    on(btn_power.clicks) do c
        if sw.active[]
            plot2d(se, ax, label, LOG, P1[1], :power)
        else
            plot2d(se, ax2, label2, LOG, P2[1], :power)
        end
        reset()
    end
end

end