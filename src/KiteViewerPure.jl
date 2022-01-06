#= MIT License

Copyright (c) 2020, 2021 Uwe Fechner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. =#

# Stripped down version of KiteViewer, no simulation, no 2D diagrams

using GeometryBasics, Rotations, GLMakie, FileIO, LinearAlgebra, Printf, Parameters

using KiteUtils

@consts begin
    SCALE = 1.2 
    INITIAL_HEIGHT =  80.0*se().zoom # meter, for demo
    MAX_HEIGHT     = 200.0*se().zoom # meter, for demo
    KITE = FileIO.load(se().model)
    FLYING     = [false]
    PLAYING    = [false]
    GUI_ACTIVE = [false]
    AXIS_LABEL_SIZE = 30
    TEXT_SIZE = 16
    running   = Node(false)
    starting  = [0]
    zoom      = [1.0]
    steering  = [0.0]
    textnode  = Node("")
    textsize  = Node(TEXT_SIZE)
    textsize2 = Node(AXIS_LABEL_SIZE)
    status = Node("")
    p1 = Node(Vector{Point2f0}(undef, 6000)) # 5 min
    p2 = Node(Vector{Point2f0}(undef, 6000)) # 5 min
    pos_x = Node(0.0f0)

    points          = Vector{Point3f0}(undef, se().segments+1)
    quat            = Node(Quaternionf0(0,0,0,1))                        # orientation of the kite
    kite_pos        = Node(Point3f0(1,0,0))                              # position of the kite
    positions       = Node([Point3f0(x,0,0) for x in 1:se().segments])   # positions of the tether segments
    part_positions  = Node([Point3f0(x,0,0) for x in 1:se().segments+1]) # positions of the tether particles
    markersizes     = Node([Point3f0(1,1,1) for x in 1:se().segments])   # includes the segment length
    rotations       = Node([Point3f0(1,0,0) for x in 1:se().segments])   # unit vectors corresponding with
                                                                           #   the orientation of the segments 
    energy = [0.0]
end                                                                           

include("common.jl")

function reset_view(cam, scene3D)
    update_cam!(scene3D.scene, [-15.425113, -18.925116, 5.5], [-1.5, -5.0, 5.5])
end

function zoom_scene(camera, scene, zoom=1.0f0)
    @extractvalue camera (fov, near, lookat, eyeposition, upvector)
    dir_vector = eyeposition - lookat
    new_eyeposition = lookat + dir_vector * (2.0f0 - zoom)
    update_cam!(scene, new_eyeposition, lookat)
end

function reset_and_zoom(camera, scene3D, zoom)
    reset_view(camera, scene3D)
    if ! (zoom ≈ 1.0) 
        zoom_scene(camera, scene3D.scene, zoom)  
    end
end

function main(gl_wait=true)
    scene, layout = layoutscene(resolution = (840, 900), backgroundcolor = RGBf0(0.7, 0.8, 1))
    scene3D = LScene(scene, scenekw = (show_axis=false, limits = Rect(-7,-10.0,0, 11,10,11), resolution = (800, 800)), raw=false)
    create_coordinate_system(scene3D)
    cam = cameracontrols(scene3D.scene)
    FLYING[1] = false
    PLAYING[1] = false
    GUI_ACTIVE[1] = true

    reset_view(cam, scene3D)

    textsize[]  = TEXT_SIZE
    textsize2[] = AXIS_LABEL_SIZE
    text!(scene3D, "z", position = Point3f0(0, 0, 14.6), textsize = textsize2, align = (:center, :center), show_axis = false)
    text!(scene3D, "x", position = Point3f0(17, 0,0), textsize = textsize2, align = (:center, :center), show_axis = false)
    text!(scene3D, "y", position = Point3f0( 0, 14.5, 0), textsize = textsize2, align = (:center, :center), show_axis = false)

    text!(scene, status, position = Point2f0( 20, 0), textsize = TEXT_SIZE, align = (:left, :bottom), show_axis = false)
    status[]="Stopped"

    layout[1, 1] = scene3D
    layout[2, 1] = buttongrid = GridLayout(tellwidth = false)

    l_sublayout = GridLayout()
    layout[1:3, 1] = l_sublayout
    l_sublayout[:v] = [scene3D, buttongrid]

    log = demo_log(7, "Launch test!")

    btn_RESET       = Button(scene, label = "RESET")
    btn_ZOOM_in     = Button(scene, label = "Zoom +")
    btn_ZOOM_out    = Button(scene, label = "Zoom -")
    btn_PLAY_PAUSE  = Button(scene, label = @lift($running ? "PAUSE" : " PLAY  "))
    btn_STOP        = Button(scene, label = "STOP")
    sw = Toggle(scene, active = false)
    label = Label(scene, "repeat")
    
    buttongrid[1, 1:7] = [btn_PLAY_PAUSE, btn_ZOOM_in, btn_ZOOM_out, btn_RESET, btn_STOP, sw, label]

    gl_screen = display(scene)
    
    init_system(scene3D)
    update_system(scene3D, demo_state(7, INITIAL_HEIGHT, 0))

    camera = cameracontrols(scene3D.scene)
    reset_view(camera, scene3D)

    reset() = reset_and_zoom(camera, scene3D, zoom[1]) 
    status[] = "Stopped"

    @async begin
        logfile=se().log_file * ".arrow"  
        if ! isfile(logfile)
            status[] = "The logfile $logfile is missing! Importing..."; sleep(0.1)
            try
                include("src/Importer.jl"); sleep(0.1)
            catch e
                bt = catch_backtrace()
                msg = sprint(showerror, e, bt)
                println(msg)
                raise(e)
            end 
            if isfile(logfile)
                status[] = "Success!"
            end
        else
            sleep(0.1)
        end
    end

    on(btn_PLAY_PAUSE.clicks) do c     
        if status[] != "Simulating..."
            if ! running[]
                logfile=se().log_file * ".arrow"                
                if isfile(logfile)
                    running[] = true
                    status[] = "Running"
                    FLYING[1] = true
                    PLAYING[1] = true
                else
                    status[] = "Failed to import $logfile !"
                end
            else
                running[] = false
                status[] = "Paused"
            end
            reset_and_zoom(camera, scene3D, zoom[1])    
        end
    end

    on(btn_RESET.clicks) do c
        reset_view(camera, scene3D)
        zoom[1] = 1.0
    end

    on(btn_STOP.clicks) do c
        # if status[] != "Stopped"
            FLYING[1] = false
            PLAYING[1] = false
            running[] = false
            status[] = "Stopped"
            reset_and_zoom(camera, scene3D, zoom[1])
        # end
    end

    on(scene.px_area) do x
        textsize[] = round(x.widths[2]/900.0 * TEXT_SIZE)
        textsize2[] = round(x.widths[2]/900.0 * AXIS_LABEL_SIZE)
        reset_view(camera, scene3D)
        zoom[1] = 1.0
    end

    on(btn_ZOOM_in.clicks) do c    
        zoom[1] *= 1.2
        reset_and_zoom(camera, scene3D, zoom[1])
    end

    on(btn_ZOOM_out.clicks) do c
        zoom[1] /= 1.2
        reset_and_zoom(camera, scene3D, zoom[1])
    end

    # launch the kite on button click
    delta_t = 1.0 / se().sample_freq
    active = false
    log = demo_log(7, "Launch test!")
    reset_view(camera, scene3D)
    
    simulation = @async begin
        while GUI_ACTIVE[1]
            # wait for launch command
            while ! FLYING[1] && GUI_ACTIVE[1]
                active = false
                sleep(0.05)
            end
            # load log file
            if ! active && GUI_ACTIVE[1]
                if PLAYING[1]
                    logfile=basename(se().log_file)
                    if log.name != logfile
                        old =  status[]
                        status[] = "Loading log file..."
                        reset_and_zoom(camera, scene3D, zoom[1])
                        try 
                            log = load_log(7, logfile)
                            dummy=log.syslog[1]
                            status[] = old 
                        catch e
                            bt = catch_backtrace()
                            msg = sprint(showerror, e, bt)
                            println(msg)
                            raise(e)
                            status[] = "Error loading log file: " * logfile
                        end 
                    end
                    steps = length(log.syslog)  
                end  
                starting[1] = 1
                active = true
            end
            i = 0; energy[1] = 0.0
            while FLYING[1]
                if PLAYING[1]
                    state = nothing
                    # println("===> i: ", i)
                    try
                        @assert i >= 0
                        @assert i < length(log.syslog)
                        state = log.syslog[i+1]
                    catch e
                        bt = catch_backtrace()
                        msg = sprint(showerror, e, bt)
                        println(msg)
                        raise(e)
                    end
                else
                    try
                        state = next_step(se().segments+1, integrator, delta_t)
                        @assert ! isnan(state.orient[1])
                    catch e
                        bt = catch_backtrace()
                        msg = sprint(showerror, e, bt)
                        println(msg)
                        raise(e)
                    end                   
                end
                if running[] || ! PLAYING[1]
                    if ! isnothing(state)
                        @sync update_system(scene3D, state, i)
                    else
                        println("Warning! isnothing(state)")
                    end
                    pos_x[] = i*delta_t
                    i += 1
                end
                sleep(delta_t / se().time_lapse)
                if i >= steps || (! PLAYING[1] && get_height() < 0.0)
                    if ! sw.active[]
                        FLYING[1] = false
                        PLAYING[1] = false
                        running[] = false
                        status[] = "Stopped"
                        reset_and_zoom(camera, scene3D, zoom[1])
                    else
                        i = 0
                    end
                end
            end
        end
    end

    if gl_wait
        wait(gl_screen)
    end

    # terminate the simulation
    FLYING[1] = false
    GUI_ACTIVE[1] = false
    running[] = false
    energy[1] = 0.0
    return nothing
end