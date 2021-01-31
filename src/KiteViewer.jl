#= MIT License

Copyright (c) 2020 Uwe Fechner

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

using GeometryBasics, Rotations, GLMakie, FileIO

using Revise
includet("./Utils.jl")
using .Utils

const SCALE = 1.2 
const INITIAL_HEIGHT = 0.3 # relative value
const KITE = FileIO.load("data/kite.obj")
const PARTICLES = Vector{AbstractPlotting.Mesh}(undef, SEGMENTS+1)
const SEGS      = Vector{AbstractPlotting.Mesh}(undef, SEGMENTS)
const KITE_MESH = Vector{MeshScatter{Tuple{Vector{Point{3, Float32}}}}}(undef, 1)
const init      = [false]
const FLYING    = [false]
const GUI_ACTIVE = [false]

function create_coordinate_system(scene, points = 10, max_x = 15.0)
    # create origin
    mesh!(scene, Sphere(Point3f0(0, 0, 0), 0.1 * SCALE), color=RGBf0(0.7, 0.7, 0.7))
    
    # create x-axis in red
    points += 2
    for x in range(1, length=points)
        mesh!(scene, Sphere(Point3f0(x * max_x/points, 0, 0), 0.1 * SCALE), color=:red)
        # println(x * max_x/points)
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
function draw_system(scene, state)
    # loop over the particles of the main tether and render them as spheres
    for i in range(1, length=length(state.X))
        if init[1] 
            delete!(scene.scene, PARTICLES[i])
        end
        particle = mesh!(scene, Sphere(Point3f0(state.X[i], state.Y[i], state.Z[i]), 0.07 * SCALE), color=:yellow)
        PARTICLES[i] = particle
    end

    end_point = Point3f0(0,0,0)
    # loop over the springs of the main tether and render them as cylinders
    for i in range(1, length=length(state.X) - 1)
        if init[1] 
            delete!(scene.scene, SEGS[i])
        end
        start_point = Point3f0(state.X[i], state.Y[i], state.Z[i])
        end_point  = Point3f0(state.X[i+1], state.Y[i+1], state.Z[i+1])
        segment = mesh!(scene, Cylinder(start_point, end_point, Float32(0.035 * SCALE)), color=:yellow)
        SEGS[i] = segment
    end

    r_xyz = RotXYZ(pi/2, -pi/2, 0)
    q0 = UnitQuaternion(r_xyz) * state.orient
    q  = Quaternionf0(q0.x, q0.y, q0.z, q0.w)

    # render the kite
    if init[1]
        delete!(scene.scene,  KITE_MESH[1])
    end
    KITE_MESH[1] = meshscatter!(scene, end_point, marker=KITE, markersize = 0.5, rotations=q, color=:blue)
    init[1] = true
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
    GUI_ACTIVE[1] = true

    reset_view(cam, scene3D)

    text!(scene, "z", position = Point2f0(322, 815), textsize = 30, align = (:left, :bottom), show_axis = false)
    text!(scene, "x", position = Point2f0(642, 352), textsize = 30, align = (:left, :bottom), show_axis = false)
    text!(scene, "y", position = Point2f0( 90, 346), textsize = 30, align = (:left, :bottom), show_axis = false)

    layout[1, 1] = scene3D
    layout[2, 1] = buttongrid = GridLayout(tellwidth = false)
    layout[3, 1] = slidergrid = GridLayout(tellwidth = false)

    btn_RESET    = Button(scene, label = "RESET")
    btn_ZOOM_in  = Button(scene, label = "Zoom +")
    btn_ZOOM_out = Button(scene, label = "Zoom -")
    btn_LAUNCH   = Button(scene, label = "LAUNCH")

    buttongrid[1, 1:4] = [btn_LAUNCH, btn_ZOOM_in, btn_ZOOM_out, btn_RESET]

    sl_height = Slider(scene, range = 0:0.01:10, startvalue = INITIAL_HEIGHT*10)
    sl_label = Label(scene, "set_height", textsize = 18)
    slidergrid[1, 1:2] = [sl_label, sl_height]

    draw_system(scene3D, demo_state(INITIAL_HEIGHT, 0))
    on(sl_height.value) do val
        draw_system(scene3D, demo_state(val/10.0, 0))
    end

    gl_screen = display(scene)

    camera = cameracontrols(scene3D.scene)
    update_cam!(scene3D.scene,  Float32[-17.505877, -21.005878, 5.5000005], Float32[-1.5, -5.0000005, 5.5000005])
    zoom_scene(camera, scene3D.scene, 1.13f0)

    on(btn_LAUNCH.clicks) do c
        FLYING[1] = true
    end

    on(btn_RESET.clicks) do c
        camera = cameracontrols(scene3D.scene)
        update_cam!(scene3D.scene,  Float32[-17.505877, -21.005878, 5.5000005], Float32[-1.5, -5.0000005, 5.5000005])
        zoom_scene(camera, scene3D.scene, 1.13f0)
        FLYING[1] = false
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
    delta_t = 0.05
    t_max   = 10.0
    steps   = t_max/delta_t-1.0
    simulation = @async begin
        while GUI_ACTIVE[1]
            # wait for launch command
            while ! FLYING[1] && GUI_ACTIVE[1]
                sleep(0.10)
            end
            i=0
            # fly...
            while FLYING[1]
                state = demo_state(i/steps, i*delta_t)
                draw_system(scene3D, state)
                sleep(delta_t)
                i+=1
                if i>=steps
                    FLYING[1] = false
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