using Revise,  GLMakie

includet("./Utils.jl")
using .Utils

function main(gl_wait=true)
    fig=Figure()
    ax=Axis(fig[1, 1], xlabel = "time [s]", ylabel = "height [m]")
    if gl_wait
        log=load_log(basename(se().log_file))
    else
        log = demo_log("Launch test!")
    end
    x=log.extlog.time
    y=log.extlog.z
    po=lines!(x,y)
    gl_screen = display(fig)
    if gl_wait
        wait(gl_screen)
    end
    return nothing
end
