using GeometryBasics, GLMakie

const SCALE = 1.2
const SEGMENTS = 7                    # number of tether segments

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

function main()
    scene, layout = layoutscene(resolution = (840, 900), backgroundcolor = RGBf0(0.7, 0.8, 1))

    scene3D = LScene(scene, scenekw = (show_axis=false, limits = Rect(-7,-10.0,0, 11,10,11), resolution = (800, 800)), raw=false)
    create_coordinate_system(scene3D)
    cam = cameracontrols(scene3D.scene)
    cam.lookat[] = [0,0,5]
    cam.eyeposition[] = [-15,-15,5]
    update_cam!(scene3D.scene)

    layout[1, 1] = scene3D
    layout[2, 1] = buttongrid = GridLayout(tellwidth = false)

    buttongrid[1, 1:1] = [Button(scene, label = "RESET")]

    for i = 0:4
        # calculate a vector of 3D coordinates
        X = range(0, stop=10, length=SEGMENTS+1)
        Y = zeros(length(X)) 
        Z = (10 .* cosh.(X./10) .- 10) * i/5.0 

        # loop over the particles of the main tether and render them as spheres
        for i in range(1, length=length(X))
            mesh!(scene3D, Sphere(Point3f0(X[i], Y[i], Z[i]), 0.07 * SCALE), color=:yellow)
        end
        display(scene)

        sleep(0.2)
    end
    
    return nothing
end