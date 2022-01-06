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
        lin_font="/usr/share/fonts/truetype/ttf-bitstream-vera/VeraMono.ttf"
        if isfile(lin_font)
            font=lin_font
        else
            font="/usr/share/fonts/truetype/freefont/FreeMono.ttf"
        end
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
    q0 = state.orient                                     # SVector in the order w,x,y,z
    quat[]     = Quaternionf0(q0[2], q0[3], q0[4], q0[1]) # the constructor expects the order x,y,z,w
    kite_pos[] = points[end]

    # print state values
    power = state.force * state.v_reelout
    energy[1] += (power / se().sample_freq)
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