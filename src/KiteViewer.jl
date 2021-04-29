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

using GeometryBasics, Rotations, GLMakie, FileIO, LinearAlgebra
AbstractPlotting.__init__()

using Revise
includet("./Utils.jl")
using .Utils

const SCALE = 1.2 
const TIME_LAPSE = 2       # time lapse factor
const INITIAL_HEIGHT = 2.0 # meter, for demo
const MAX_HEIGHT     = 6.0 # meter, for demo
const KITE = FileIO.load("data/kite.obj")
const FLYING    = [false]
const PLAYING    = [false]
const GUI_ACTIVE = [false]

const points      = Vector{Point3f0}(undef, se().segments+1)
const quat        = Node(Quaternionf0(0,0,0,1))                        # orientation of the kite
const kite_pos    = Node(Point3f0(1,0,0))                              # position of the kite
const positions   = Node([Point3f0(x,0,0) for x in 1:se().segments])        # positions of the tether segments
const part_positions   = Node([Point3f0(x,0,0) for x in 1:se().segments+1]) # positions of the tether particles
const markersizes = Node([Point3f0(1,1,1) for x in 1:se().segments])        # includes the segment length
const rotations   = Node([Point3f0(1,0,0) for x in 1:se().segments])        # unit vectors corresponding with
                                                                       #   the orientation of the segments 

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

# draw the kite power system, consisting of the tether and the kite
function init_system(scene)
    sphere = Sphere(Point3f0(0, 0, 0), Float32(0.07 * SCALE))
    meshscatter!(scene, part_positions, marker=sphere, markersize=1.0, color=:yellow)
    cyl = Cylinder(Point3f0(0,0,-0.5), Point3f0(0,0,0.5), Float32(0.035 * SCALE))        
    meshscatter!(scene, positions, marker=cyl, rotations=rotations, markersize=markersizes, color=:yellow)
    meshscatter!(scene, kite_pos, marker=KITE, markersize = 0.25, rotations=quat, color=:blue)
end

# update the kite power system, consisting of the tether and the kite
function update_system(scene, state)

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
end

function reset_view(cam, scene3D)
    update_cam!(scene3D.scene, [-15,-15,5], [0,0,5])
    zoom_scene(cam, scene3D.scene, 1.4f0)
end

function zoom_scene(camera, scene, zoom=1.0f0)
    @extractvalue camera (fov, near, projectiontype, lookat, eyeposition, upvector)
    dir_vector = eyeposition - lookat
    new_eyeposition = lookat + dir_vector * (2.0f0 - zoom)
    update_cam!(scene, new_eyeposition, lookat)
end

function main(gl_wait=true)
    scene, layout = layoutscene(resolution = (840, 900), backgroundcolor = RGBf0(0.7, 0.8, 1))
    scene3D = LScene(scene, scenekw = (show_axis=false, limits = Rect(-7,-10.0,0, 11,10,11), resolution = (800, 800)), raw=false)
    create_coordinate_system(scene3D)
    cam = cameracontrols(scene3D.scene)
    init[1] = false
    FLYING[1] = false
    PLAYING[1] = false
    GUI_ACTIVE[1] = true

    reset_view(cam, scene3D)

    text!(scene3D, "z", position = Point3f0(0, 0, 14.6), textsize = 30, align = (:center, :center), show_axis = false)
    text!(scene3D, "x", position = Point3f0(17, 0,0), textsize = 30, align = (:center, :center), show_axis = false)
    text!(scene3D, "y", position = Point3f0( 0, 14.5, 0), textsize = 30, align = (:center, :center), show_axis = false)

    layout[1, 1] = scene3D
    layout[2, 1] = buttongrid = GridLayout(tellwidth = false)
    layout[3, 1] = slidergrid = GridLayout(tellwidth = false)

    btn_RESET    = Button(scene, label = "RESET")
    btn_ZOOM_in  = Button(scene, label = "Zoom +")
    btn_ZOOM_out = Button(scene, label = "Zoom -")
    btn_LAUNCH   = Button(scene, label = "LAUNCH")
    btn_PLAY     = Button(scene, label = "PLAY")
    btn_STOP     = Button(scene, label = "STOP")

    buttongrid[1, 1:6] = [btn_PLAY, btn_LAUNCH, btn_ZOOM_in, btn_ZOOM_out, btn_RESET, btn_STOP]

    sl_height = Slider(scene, range = 0:0.01:MAX_HEIGHT, startvalue = INITIAL_HEIGHT)
    sl_label = Label(scene, "set_height", textsize = 18)
    slidergrid[1, 1:2] = [sl_label, sl_height]
    
    init_system(scene3D)
    update_system(scene3D, demo_state(INITIAL_HEIGHT, 0))
    on(sl_height.value) do val
        update_system(scene3D, demo_state(val, 0))
    end

    gl_screen = display(scene)

    camera = cameracontrols(scene3D.scene)
    update_cam!(scene3D.scene,  Float32[-17.505877, -21.005878, 5.5000005], Float32[-1.5, -5.0000005, 5.5000005])
    zoom_scene(camera, scene3D.scene, 1.13f0)

    on(btn_LAUNCH.clicks) do c
        FLYING[1] = true
        PLAYING[1] = false
        GC.enable(false)
    end

    on(btn_PLAY.clicks) do c
        FLYING[1] = true
        PLAYING[1] = true
        GC.enable(false)
    end

    on(btn_RESET.clicks) do c
        camera = cameracontrols(scene3D.scene)
        update_cam!(scene3D.scene,  Float32[-17.505877, -21.005878, 5.5000005], Float32[-1.5, -5.0000005, 5.5000005])
        zoom_scene(camera, scene3D.scene, 1.13f0)
    end

    on(btn_STOP.clicks) do c
        camera = cameracontrols(scene3D.scene)
        update_cam!(scene3D.scene,  Float32[-17.505877, -21.005878, 5.5000005], Float32[-1.5, -5.0000005, 5.5000005])
        zoom_scene(camera, scene3D.scene, 1.13f0)
        FLYING[1] = false
        PLAYING[1] = false
        GC.enable(true)
    end

    on(btn_ZOOM_in.clicks) do c    
        camera = cameracontrols(scene3D.scene)
        zoom_scene(camera, scene3D.scene, 1.2f0)
    end

    on(btn_ZOOM_out.clicks) do c
        camera = cameracontrols(scene3D.scene)
        zoom_scene(camera, scene3D.scene, 0.75f0)
    end

    # launch the kite on button click
    delta_t = 1.0 / se().sample_freq
    active = false
    GC.enable(false)
    simulation = @async begin
        while GUI_ACTIVE[1]
            # wait for launch command
            while ! FLYING[1] && GUI_ACTIVE[1]
                active = false
                sleep(0.10)
            end
            if ! active && GUI_ACTIVE[1]
                if PLAYING[1]
                    log = (load_log(basename(se().log_file))).syslog 
                else
                    log = demo_syslog("Launch test!")
                end
                steps = length(log)            
                println("Steps: $steps")
                active = true
            end
            i=0
            # fly...
            while FLYING[1]
                state = log[i+1]
                update_system(scene3D, state)
                sleep(delta_t / TIME_LAPSE)
                i += 1
                if i >= steps
                    FLYING[1] = false
                    PLAYING[1] = false
                    GC.enable(true)
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
    return nothing
end