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

using GeometryBasics, GLMakie, FileIO

using Revise
includet("./Utils.jl")
using .Utils

const SCALE = 1.2

function create_coordinate_system(scene, points = 10, length = 10)
    # create origin
    mesh!(scene, Sphere(Point3f0(0, 0, 0), 0.1 * SCALE), color=RGBf0(0.7, 0.7, 0.7))
      
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
end

# draw the kite power system, consisting of the tether and the kite
function draw_system(scene, state)
    # loop over the particles of the main tether and render them as spheres
    for i in range(1, length=length(state.X))
        mesh!(scene, Sphere(Point3f0(state.X[i], state.Y[i], state.Z[i]), 0.07 * SCALE), color=:yellow)
    end
    return nothing
end

function reset_view(scene3D)
    cam = cameracontrols(scene3D.scene)
    cam.lookat[] = [0,0,5]
    cam.eyeposition[] = [-15,-15,5]
    update_cam!(scene3D.scene)
    zoom_scene(scene3D.scene, 1.2f0)
end

function zoom_scene(scene, zoom=1.0f0)
    camera =cameracontrols(scene)
    @extractvalue camera (fov, near, projectiontype, lookat, eyeposition, upvector)
    dir_vector = eyeposition - lookat
    new_eyeposition = lookat + dir_vector * (2.0f0 - zoom)
    update_cam!(scene, new_eyeposition, lookat)
end

function main(gl_wait=false)
    scene, layout = layoutscene(resolution = (840, 900), backgroundcolor = RGBf0(0.7, 0.8, 1))
    scene3D = LScene(scene, scenekw = (show_axis=false, limits = Rect(-7,-10.0,0, 11,10,11), resolution = (800, 800), camera = cam3d_cad!), raw=false)
    create_coordinate_system(scene3D)

    layout[1, 1] = scene3D
    layout[2, 1] = buttongrid = GridLayout(tellwidth = false)

    btn_RESET = Button(scene, label = "RESET")
    btn_ZOOM_in = Button(scene, label = "Zoom +")
    btn_ZOOM_out = Button(scene, label = "Zoom -")

    buttongrid[1, 1:3] = [btn_RESET, btn_ZOOM_in, btn_ZOOM_out]
    for i = 0:4
        draw_system(scene3D, demo_state(i/5.0))
        display(scene)
        reset_view(scene3D)
        sleep(0.2)
    end
    
    return nothing
end