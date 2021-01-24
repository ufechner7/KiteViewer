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

const SCALE = 1.2
const KITE = FileIO.load("data/kite.obj")

function create_coordinate_system(scene, points = 10, length = 10)
    # create origin
    mesh!(scene, Sphere(Point3f0(0, 0, 0), 0.1 * SCALE), color=RGBf0(0.7, 0.7, 0.7))
    
    # create x-axis in red
    points += 2
    for x in range(1, length=points)
        mesh!(scene, Sphere(Point3f0(x * SCALE, 0, 0), 0.1 * SCALE), color=:red)
    end
    mesh!(scene, Cylinder(Point3f0(-SCALE, 0, 0), Point3f0(points * SCALE, 0, 0), Float32(0.05 * SCALE)), color=:red)
    for i in range(0, length=10)
        start = Point3f0((points + 0.07 * (i-0.5)) * SCALE, 0, 0)
        stop = Point3f0((points + 0.07 * (i+0.5)) * SCALE, 0, 0)
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

function drawParticles!(scene, X, Y, Z)
    for i in range(1, length=length(X))
        mesh!(scene, Sphere(Point3f0(X[i], Y[i], Z[i]), 0.07 * SCALE), color=:yellow)
    end
    end_point = Point3f0(0,0,0)
    # loop over the springs of the main tether and render them as cylinders
    for i in range(1, length=length(X) - 1)
        start_point = Point3f0(X[i], Y[i], Z[i])
        end_point  = Point3f0(X[i+1], Y[i+1], Z[i+1])
        mesh!(scene, Cylinder(start_point, end_point, Float32(0.035 * SCALE)), color=:yellow)
    end
    rot = Quaternionf0(1, 0, -1, 0)
    # kite.rot = rot3d(vec3(0, -1, 0), vec3(1, 0, 0), vec3(0, 0, -1), x, y, z)
    meshscatter!(scene, end_point, marker=KITE, markersize = 0.5, rotations = Vec3f0.(0, -1, 0), color=:blue)
end

function show_tether(scene)
    a = 10
    X = range(0, stop=10, length=8)
    Y = zeros(length(X)) 
    Z = (a .* cosh.(X./a) .- a)
    drawParticles!(scene, X, Y, Z)
end

function show_kite(scene)
    kitemesh = FileIO.load("data/kite.obj")
    meshscatter!(scene, Point3f0(8., 0., 8.), marker=kitemesh, color=:blue)
end

function reset_view(scene3D)
    cam = cameracontrols(scene3D.scene)
    cam.lookat[] = [0,0,5]
    cam.eyeposition[] = [-15,-15,5]
    update_cam!(scene3D.scene)
end

function zoom_scene(scene, zoom=1.0f0)
    camera =cameracontrols(scene)
    @extractvalue camera (fov, near, projectiontype, lookat, eyeposition, upvector)
    dir_vector = eyeposition - lookat
    new_eyeposition = lookat + dir_vector * (2.0f0 - zoom)
    update_cam!(scene, new_eyeposition, lookat)
end

function main()
    scene, layout = layoutscene(resolution = (840, 900), backgroundcolor = RGBf0(0.7, 0.8, 1))
    scene3D = LScene(scene, scenekw = (show_axis=false, limits = Rect(-7,-10.0,0, 11,10,11), resolution = (800, 800), camera = cam3d_cad!), raw=false)
    create_coordinate_system(scene3D)
    show_tether(scene3D)
    reset_view(scene3D)

    layout[1, 1] = scene3D
    layout[2, 1] = buttongrid = GridLayout(tellwidth = false)

    btn_RESET = Button(scene, label = "RESET")
    btn_ZOOM_in = Button(scene, label = "Zoom +")
    btn_ZOOM_out = Button(scene, label = "Zoom -")

    buttongrid[1, 1:3] = [btn_RESET, btn_ZOOM_in, btn_ZOOM_out]

    on(btn_RESET.clicks) do c
        reset_view(scene3D)
    end

    on(btn_ZOOM_in.clicks) do c
        zoom_scene(scene3D.scene, 1.2f0)
    end

    on(btn_ZOOM_out.clicks) do c
        zoom_scene(scene3D.scene, 1.0f0/1.2f0)
    end

    return scene
end