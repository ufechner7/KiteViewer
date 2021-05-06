using GLMakie

const p1 = Node(Vector{Point2f0}(undef, 6000)) # 5 min
const y_label = Node("")

function plot_sin(x)
    y_label[]="sin"
    y = sin.(x)
    p1[] =  Point2f0.(x, y)
end

function plot_cos(x)
    y_label[]="cos"
    y = cos.(x)
    p1[] =  Point2f0.(x, y)
end

function main(gl_wait=true)
    fig=Figure()
    ax=Axis(fig[1, 1], xlabel = "time [s]", ylabel = y_label)
    x_1 = 0f0:0.1f0:10f0*pi
    x_2 = 0:0.1:5*pi
    plot_sin(x_1)
    po = lines!(p1)   

    @async begin
        for i in 0:2
            plot_sin(x_1)
            autolimits!(ax)
            sleep(2)
            plot_cos(x_2)
            autolimits!(ax)
            sleep(2)
        end
    end

    gl_screen = display(fig)
    if gl_wait
        wait(gl_screen)
    end
    return nothing
end

main()
