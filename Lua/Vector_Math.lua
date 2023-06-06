local Vec = {}

Vec = {
    EPSILON = 0.000001, -- used for equality comparison

    mt = {},

    New = function(obj)
        local v = setmetatable(obj or {}, Vec.mt)
        return v
    end,

    ToString = function(v, format)
        if format == nil then
            format = "%.3f"
        end
        return string.format(
            "{"..format..", "..format..", "..format.."}",
            v[1], v[2], v[3]
        )
    end,

    Magnitude = function(v)
        v = Vec.New(v)
        return #v
    end,

    Dot = function(u, v)
        u = Vec.New(u)
        v = Vec.New(v)
        return u[1]*v[1] + u[2]*v[2] + u[3]*v[3]
    end,

    Cross = function(u, v)
        u = Vec.New(u)
        v = Vec.New(v)
        return Vec.New({
            u[2]*v[3] - v[2]*u[3],
            u[3]*v[1] - v[3]*u[1],
            u[1]*v[2] - v[1]*u[2]
        })
    end,

    Direction = function(v) -- returns the normalized vector
        v = Vec.New(v)
        local m = #v
        if m == 0 then
            return Vec.New({0, 0, 0})
        end
        return Vec.New({v[1]/m, v[2]/m, v[3]/m})
    end,

    Normalize = function(v)
        return Vec.Direction(v)
    end,

    Angle = function(u, v) -- requires |a||b| > 0
        u = Vec.New(u)
        v = Vec.New(v)
        if #u * #v == 0 then
            return 0
        end
        -- dot(a, b) = |a||b|cosA
        local rad = math.acos(Vec.Dot(u, v) / (#u * #v))
        return rad
    end,

    -- projection of a onto b
    -- returns v, dir (relative direction to the b vector)
    Project = function(u, v)
        u = Vec.New(u)
        v = Vec.New(v)
        if v == Vec.New({0, 0, 0}) then
            return Vec.New({0, 0, 0}), 0
        end
        local s = Vec.Dot(u, v) / Vec.Dot(v, v)
        local dir = 1
        if s < 0 then
            dir = -1
        end
        return s*v, dir
    end,

    YSpd = function(velocity, gravity)
        local yvec, dir = Vec.Project(
            Vec.New(velocity),
            Vec.New(gravity)
        )
        return dir * #yvec
    end,

    HSpd = function(velocity, gravity)
        local v = Vec.New(velocity)
        return #(v - Vec.Project(v, gravity)) -- 2nd return value ignored?
    end,
    
    -- projection of v onto plane with normal n
    ProjectPlane = function(v, n)
        return v - Vec.Project(v, n)
    end
}

Vec.mt = {
    __add = function(u, v)
        u = Vec.New(u)
        v = Vec.New(v)
        return Vec.New({
            u[1] + v[1],
            u[2] + v[2],
            u[3] + v[3]
        })
    end,

    __sub = function(u, v)
        u = Vec.New(u)
        v = Vec.New(v)
        return Vec.New({
            u[1] - v[1],
            u[2] - v[2],
            u[3] - v[3]
        })
    end,

    __mul = function(a, b)
        if type(a) == "table" and type(b) == "table" then
            return Vec.Dot(a, b) -- default option
        elseif type(a) == "table" then
            return Vec.New({b*a[1], b*a[2], b*a[3]})
        elseif type(b) == "table" then
            return Vec.New({a*b[1], a*b[2], a*b[3]})
        end
    end,

    __unm = function(v)
        return Vec.New({
            -v[1],
            -v[2],
            -v[3]
        })
    end,

    __concat = function(a, b)
        if type(a) == "table" and type(b) == "table" then
            return Vec.ToString(a) .. Vec.ToString(b)
        elseif type(a) == "table" then
            return Vec.ToString(a) .. b
        elseif type(b) == "table" then
            return a .. Vec.ToString(b)
        end
    end,

    __len = function(v) -- magnitude
        return math.sqrt(v[1]*v[1] + v[2]*v[2] + v[3]*v[3])
    end,

    __eq = function(u, v)
        return (
            (math.abs(u[1] - v[1]) < Vec.EPSILON) and
            (math.abs(u[2] - v[2]) < Vec.EPSILON) and
            (math.abs(u[3] - v[3]) < Vec.EPSILON)
        )
    end,

    __tostring = function(v)
        return Vec.ToString(v)
    end,

    __index = function(self, key)
        -- if checking an index fails, try checking xyz or XYZ
        -- default to a value of 0
        if key == 1 then
            return rawget(self, "x") or rawget(self, "X") or 0
        elseif key == 2 then
            return rawget(self, "y") or rawget(self, "Y") or 0
        elseif key == 3 then
            return rawget(self, "Z") or rawget(self, "Z") or 0
        end

        -- if checking xyz or XYZ fails, try checking an index (uses above behaviour)
        if string.find("xyz", key) or string.find("XYZ", key) then
            return self[string.find("xyz", key) or string.find("XYZ", key)]
        end
    end
}

return Vec
