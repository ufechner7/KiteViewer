using LinearAlgebra

# functions
function pprint(mat::Matrix)
    show(stdout, "text/plain", mat)
    println("\n")
end

function pprint(vec::Vector)
    println(vec)
    println("\n")
end

# http://cgkit.sourceforge.net/doc2/mat3.html
function mat3(x, y, z)
    hcat(x, y, z)
end

"""
Calculate the rotation of reference frame (ax, ay, az) so that it matches the reference frame 
(bx, by, bz).
All parameters must be 3-element vectors. Both refrence frames must be orthogonal,
all vectors must already be normalized.
Source: http://en.wikipedia.org/wiki/User:Snietfeld/TRIAD_Algorithm
"""
function rot3d(ax, ay, az, bx, by, bz)
    R_ai = mat3(ax, az, ay)
    R_bi = mat3(bx, bz, by)
    return R_bi * R_ai'
end

# main
ax, ay, az = [1,0,0], [ 0,1,0], [0,0,1]
bx, by, bz = [0,1,0], [-1,0,0], [0,0,1]
vec = [1,0,0]

pprint(vec)

pprint(rot3d(ax, ay, az, bx, by, bz))
pprint(rot3d(ax, ay, az, bx, by, bz) * vec)
pprint(mat3(bx, by, bz))
