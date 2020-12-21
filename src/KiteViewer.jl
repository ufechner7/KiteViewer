using GeometryBasics, Makie, GLMakie

const SCALE = 1.2

function demo1()
    x = [2 .* (i/3) .* cos(i) for i in range(0, stop = 4pi, length = 30)]
    y = [2 .* (i/3) .* sin(i) for i in range(0, stop = 4pi, length = 30)]
    z = range(0, stop = 5, length = 30)
    meshscatter(x, y, z, markersize = 0.5, color = to_colormap(:blues, 30))
end

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

function show_tether(scene)
    a = 10
    X = range(0, stop=10, length=8)
    Y = zeros(length(X)) 
    Z = (a .* cosh.(X./a) .- a)
    lines!(scene, X, Y, Z, color = :yellow, linewidth = 3)
end

function main()
    scene=Scene(show_axis=false, limits = Rect(-7,-10.0,0, 11,10,11), resolution = (800, 800), backgroundcolor = RGBf0(0.7, 0.8, 1), camera=cam3d_cad!)
    create_coordinate_system(scene)
    show_tether(scene)

    cam = cameracontrols(scene)
    cam.lookat[] = [0,0,5]
    cam.eyeposition[] = [-15,-15,5]
    update_cam!(scene)
    return scene
end