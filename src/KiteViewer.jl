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

using GeometryBasics, Rotations, GLMakie, FileIO, LinearAlgebra, Printf
AbstractPlotting.__init__()

using Revise
includet("./Utils.jl")
using .Utils

const SCALE = 1.2 
const INITIAL_HEIGHT =  80.0*se().zoom # meter, for demo
const MAX_HEIGHT     = 200.0*se().zoom # meter, for demo
const KITE = FileIO.load(se().model)
const PLOT_CMD = `./plot2d.sh`
const FLYING    = [false]
const PLAYING    = [false]
const GUI_ACTIVE = [false]
const AXIS_LABEL_SIZE = 30
const TEXT_SIZE = 16
const running = Node(false)
const starting = [0]
const zoom = [1.0]
const textnode = Node("")
const textsize = Node(TEXT_SIZE)
const textsize2 = Node(AXIS_LABEL_SIZE)
const status = Node("")

const points          = Vector{Point3f0}(undef, se().segments+1)
const quat            = Node(Quaternionf0(0,0,0,1))                        # orientation of the kite
const kite_pos        = Node(Point3f0(1,0,0))                              # position of the kite
const positions       = Node([Point3f0(x,0,0) for x in 1:se().segments])   # positions of the tether segments
const part_positions  = Node([Point3f0(x,0,0) for x in 1:se().segments+1]) # positions of the tether particles
const markersizes     = Node([Point3f0(1,1,1) for x in 1:se().segments])   # includes the segment length
const rotations       = Node([Point3f0(1,0,0) for x in 1:se().segments])   # unit vectors corresponding with
                                                                           #   the orientation of the segments 
const energy = [0.0]                                                                           

function create_coordinate_system(scene, points = 10, max_x = 15.0)
    # create origin
    mesh!(scene, Sphere(Point3f0(0, 0, 0), 0.1 * SCALE), color=RGBf0(0.7, 0.7, 0.7))
    
    # create x-axis in red
    points += 2
    for x in range(1, length=points)
        mesh!(scene, Sphere(Point3f0(x * max_x/points, 0, 0), 0.1 * SCALE), color=:red)
    end
    mesh!(scene, Cylinder(Point3f0(-max_x/points, 0, 0), Point3f0(points * max_x/points, 0, 0), Float32(0.05 * SCALE)), color=:red)
    for i in range(0, length=points)
        start = Point3f0((points + 0.07 * (i-0.5)) * max_x/points, 0, 0)
        stop = Point3f0((points + 0.07 * (i+0.5)) * max_x/points, 0, 0)
        mesh!(scene, Cylinder(start, stop, Float32(0.018 * (10 - i) * SCALE)), color=:red)
    end
    
    # create y-axis in green
    points -= 3
    for y in range(0, length = 2points + 1)
        if y - points != 0
            mesh!(scene, Sphere(Point3f0(0, (y - points) * SCALE, 0), 0.1 * SCALE), color=:green)
        end
    end
    mesh!(scene, Cylinder(Point3f0(0, -(points+1) * SCALE, 0), Point3f0(0, (points+1) * SCALE , 0), Float32(0.05 * SCALE)), color=:green)
    for i in range(0, length=10)
        start = Point3f0(0, (points+1 + 0.07 * (i-0.5)) * SCALE, 0)
        stop = Point3f0(0, (points+1 + 0.07 * (i+0.5)) * SCALE, 0)
        mesh!(scene, Cylinder(start, stop, Float32(0.018 * (10 - i) * SCALE)), color=:green)
    end

    # create z-axis in blue
    points += 1
    for z in range(2, length=points)
        mesh!(scene, Sphere(Point3f0(0, 0, (z - 1) * SCALE), 0.1 * SCALE), color=:mediumblue)
    end
    mesh!(scene, Cylinder(Point3f0(0, 0, -SCALE), Point3f0(0, 0, (points+1) * SCALE), Float32(0.05 * SCALE)), color=:mediumblue)
    for i in range(0, length=10)
        start = Point3f0(0, 0, (points+1 + 0.07 * (i-0.5)) * SCALE)
        stop = Point3f0(0, 0, (points+1 + 0.07 * (i+0.5)) * SCALE)
        mesh!(scene, Cylinder(start, stop, Float32(0.018 * (10 - i) * SCALE)), color=:dodgerblue3)
    end 
end

# draw the kite power system, consisting of the tether, the kite and the state (text and numbers)
function init_system(scene)
    sphere = Sphere(Point3f0(0, 0, 0), Float32(0.07 * SCALE))
    meshscatter!(scene, part_positions, marker=sphere, markersize=1.0, color=:yellow)
    cyl = Cylinder(Point3f0(0,0,-0.5), Point3f0(0,0,0.5), Float32(0.035 * SCALE))        
    meshscatter!(scene, positions, marker=cyl, rotations=rotations, markersize=markersizes, color=:yellow)
    meshscatter!(scene, kite_pos, marker=KITE, markersize = 0.25, rotations=quat, color=:blue)
    if Sys.islinux()
        font="/usr/share/fonts/truetype/ttf-bitstream-vera/VeraMono.ttf"
    else
        font="Courier New"
    end
    if se().fixed_font != ""
        font=se().fixed_font
    end
    text!(scene, textnode, position = Point3f0(-5.2, 3.5, -1), textsize = textsize, font=font, align = (:left, :top))
end

# update the kite power system, consisting of the tether, the kite and the state (text and numbers)
function update_system(scene, state, step=0)

    # move the particles to the correct position
    for i in range(1, length=se().segments+1)
        points[i] = Point3f0(state.X[i], state.Y[i], state.Z[i])
    end
    part_positions[] = [(points[k]) for k in 1:se().segments+1]

    # move, scale and turn the cylinder correctly
    positions[] = [(points[k] + points[k+1])/2 for k in 1:se().segments]
    markersizes[] = [Point3f0(1, 1, norm(points[k+1] - points[k])) for k in 1:se().segments]
    rotations[] = [normalize(points[k+1] - points[k]) for k in 1:se().segments]

    # move and turn the kite to the new position
    q0 = UnitQuaternion(state.orient)
    quat[]     = Quaternionf0(q0.x, q0.y, q0.z, q0.w)
    kite_pos[] = points[end]

    # print state values
    power = state.force * state.v_reelout
    energy[1] += (power / se().sample_freq * 2)
    if mod(step, 2) == 0
        height = points[end][3]/se().zoom
        msg = "time:      $(@sprintf("%7.2f", state.time)) s\n" *
            "height:    $(@sprintf("%7.2f", height)) m\n" *
            "elevation: $(@sprintf("%7.2f", state.elevation/pi*180.0)) °\n" *
            "azimuth:   $(@sprintf("%7.2f", state.azimuth/pi*180.0)) °\n" *
            "v_reelout: $(@sprintf("%7.2f", state.v_reelout)) m/s   " * "p_mech:  $(@sprintf("%8.2f", state.force*state.v_reelout)) W\n" *
            "force:     $(@sprintf("%7.2f", state.force    )) N     " * "energy:  $(@sprintf("%8.2f", energy[1]/3600)) Wh\n"
        textnode[] = msg   
    end
end

function reset_view(cam, scene3D)
    update_cam!(scene3D.scene, [-15.425113, -18.925116, 5.5], [-1.5, -5.0, 5.5])
end

function zoom_scene(camera, scene, zoom=1.0f0)
    @extractvalue camera (fov, near, projectiontype, lookat, eyeposition, upvector)
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

    btn_RESET       = Button(scene, label = "RESET")
    btn_ZOOM_in     = Button(scene, label = "Zoom +")
    btn_ZOOM_out    = Button(scene, label = "Zoom -")
    btn_LAUNCH      = Button(scene, label = "LAUNCH")
    btn_PLAY_PAUSE  = Button(scene, label = @lift($running ? "PAUSE" : " PLAY  "))
    btn_STOP        = Button(scene, label = "STOP")
    btn_PLOT        = Button(scene, label = "PLOT2D")
    
    buttongrid[1, 1:7] = [btn_PLAY_PAUSE, btn_LAUNCH, btn_PLOT, btn_ZOOM_in, btn_ZOOM_out, btn_RESET, btn_STOP]

    gl_screen = display(scene)
    
    init_system(scene3D)
    update_system(scene3D, demo_state(INITIAL_HEIGHT, 0))

    camera = cameracontrols(scene3D.scene)
    reset_view(camera, scene3D)

    on(btn_LAUNCH.clicks) do c
        if ! PLAYING[1]
            FLYING[1] = true
            PLAYING[1] = false
            status[] = "Launching..."
            @sync reset_and_zoom(camera, scene3D, zoom[1])   
        end
    end

    on(btn_PLOT.clicks) do c
        starting[1] = 1
        run(PLOT_CMD, wait=false)
    end

    @async begin
        while true
            if starting[1] == 1
                old=status[]
                status[] = "Starting plot2d.."
                starting[1] = 0
                sleep(8)
                status[] = old
            else
                sleep(0.1)
            end
        end
    end

    @async begin
        logfile=se().log_file * ".arrow"  
        if ! isfile(logfile)
            status[] = "The logfile $logfile is missing! Importing..."; sleep(0.1)
            include("src/Importer.jl"); sleep(0.1)
            if isfile(logfile)
                status[] = "Success!"
            end
        else
            sleep(0.1)
        end
    end

    on(btn_PLAY_PAUSE.clicks) do c     
        if status[] != "Launching..."
            if ! running[]
                logfile=se().log_file * ".arrow"                
                if isfile(logfile)
                    running[] = true
                    status[]="Running"
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
        if status[] != "Stopped"
            FLYING[1] = false
            PLAYING[1] = false
            running[] = false
            status[] = "Stopped"
            reset_and_zoom(camera, scene3D, zoom[1])
        end
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
    log = demo_log("Launch test!")
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
                        println("Loading log file...")
                        log = load_log(logfile) 
                    end
                else
                    log = demo_log("Launch test!")
                end
                steps = length(log.syslog)        
                println("Steps: $steps")
                active = true
            end
            i=0
            energy[1] = 0.0
            # fly...
            while FLYING[1]
                state = log.syslog[i+1]
                if running[] || ! PLAYING[1]
                    @sync update_system(scene3D, state, i)
                    i += 1
                end
                sleep(delta_t / se().time_lapse)
                if i >= steps
                    FLYING[1] = false
                    PLAYING[1] = false
                    running[] = false
                    status[] = "Stopped"
                    reset_and_zoom(camera, scene3D, zoom[1])
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