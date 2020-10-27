-- vector math to get relative yspd/hspd

local function dot(a, b)
    return a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
end

local function cross(a, b)
    return {
        a[2] * b[3] - b[2] * a[3],
        a[3] * b[1] - b[3] * a[1],
        a[1] * b[2] - b[1] * a[2]
    }
end

local function scalar_mult(s, v)
    return {s * v[1], s * v[2], s * v[3]}
end

local function mag(v)
    return math.sqrt(v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
end

-- returns the normalized vector
local function direction(v)
    local m = mag(v)
    if m == 0 then return {0, 0, 0} end
    return {v[1] / m, v[2] / m, v[3] / m}
end

-- projection of a onto b
-- returns with a 4th element, the relative direction to the b vector
local function proj(a, b)
    if (b[1] == 0 and b[2] == 0 and b[3] == 0) then
        return {0, 0, 0, dir = 0}
    end
    local s = dot(a, b) / dot(b, b)
    local dir = 0
    if s > 0 then
        dir = 1
    else
        dir = -1
    end
    return {s * b[1], s * b[2], s * b[3], dir = dir}
end

local function minus(a, b) -- a minus b (a - b)
    return {a[1] - b[1], a[2] - b[2], a[3] - b[3]}
end

local function plus(a, b)
    return {a[1] + b[1], a[2] + b[2], a[3] + b[3]}
end

local function yspd(v, g)
    yvec = proj(v, g)
    return yvec.dir * mag(yvec)
end

local function hspd(v, g)
    return mag(minus(v, proj(v, g)))
end

-- requires |a||b| > 0
-- dot(a, b) = |a||b|sinA
local function angle(a, b)
    if mag(a) * mag(b) == 0 then
        return 0
    end
    return math.acos(dot(a, b) / (mag(a) * mag(b)))
end

-- projection of v onto plane with normal n
local function proj_plane(v, n)
    return minus(v, proj(v, n))
end

local function equal(a, b, epsilon)
    if epsilon <= 0 then return false end
    local delta = {
        math.abs(a[1] - b[1]),
        math.abs(a[2] - b[2]),
        math.abs(a[3] - b[3])
    }
    return delta[1] < epsilon and delta[2] < epsilon and delta[3] < epsilon
end

local vec = {}
vec.zero = {0, 0, 0}
vec.mag = mag
vec.yspd = yspd
vec.hspd = hspd
vec.angle = angle
vec.proj = proj
vec.proj_plane = proj_plane
vec.equal = equal
vec.cross = cross
vec.direction = direction
vec.dot = dot
vec.minus = minus
vec.add = plus
vec.scalar_mult = scalar_mult
return vec
