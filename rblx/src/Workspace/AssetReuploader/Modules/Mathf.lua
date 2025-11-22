local Mathf = {}

--

function Mathf.FrameDelta(mult, delta)
	return 1 - (1 - mult) ^ (delta * 60)
end

--

local WeightRandom = Random.new()
local RNG = Random.new()


local function GetWeighedRandom(tab)
	local total = 0

	for index, weight in pairs(tab) do
		total = total + weight
	end

	local random = WeightRandom:NextNumber(0,total)

	for index, weight in pairs(tab) do
		random = random - weight
		if random <= 0 then
			return index
		end
	end

	return (next(tab))
end


function Mathf.RandomizeVector(basisVector: Vector3, radianSpreadX: number, radianSpreadY: number): Vector3
	local zVector = basisVector.Unit
	local xVector = zVector:Cross(Vector3.yAxis).Unit
	local yVector = zVector:Cross(xVector).Unit
	local deviatedRot = CFrame.fromMatrix(Vector3.one, xVector, yVector, zVector)
		* CFrame.Angles(RNG:NextNumber(-radianSpreadX, radianSpreadX), RNG:NextNumber(-radianSpreadY, radianSpreadY), 0)
	return deviatedRot.ZVector * basisVector.Magnitude
end

function Mathf.GetWeighedRandom(tab)
	return GetWeighedRandom(tab)
end

function Mathf.SafeLerp(a, b, t)
	if a == nil or t >= 1 then
		return b
	elseif b == nil or t <= 0 then
		return a
	end

	if typeof(a) == "Color3" then
		local it = 1 - t

		return Color3.new(
			(a.R ^ 2 * it + b.R ^ 2 * t) ^ 0.5,
			(a.G ^ 2 * it + b.G ^ 2 * t) ^ 0.5,
			(a.B ^ 2 * it + b.B ^ 2 * t) ^ 0.5
		)
	end

	return a * (1 - t) + b * t
end

-- Numbers

function Mathf.PercentBetween(num, min, max)
	return (max - min) == 0 and 1 or math.clamp((num - min) / (max - min), 0, 1)
end

function Mathf.Round(num, grid, offset)
	return math.floor(num / grid + (offset or 0.5)) * grid
end

function Mathf.RoundNumber(x)
	return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

function Mathf.Lerp(a, b, t)
	return a * (1 - t) + b * t
end

function Mathf.SmoothLerp(a, b, t)
	return t < 0.001 and a or t > 0.999 and b or Mathf.Lerp(a, b, (1 - math.cos(t * math.pi)) / 2)
end

function Mathf.LerpTowards(n,g,t)
	if n < g then
		return math.clamp(n + t, n, g)
	else
		return math.clamp(n - t, g, n)
	end
end

function Mathf.Wrap(num, min, max)
	return min + (num - min) % (max - min)
end
function Mathf.WrapIndex(num,length)
	return Mathf.Wrap(num,1,length+1)
end


function Mathf.Cubic_Interpolate(v0, v1, v2, v3,x)
	local P = (v3 - v2) - (v0 - v1)
	local Q = (v0 - v1) - P
	local R = v2 - v0
	local S = v1

	return P*x^3 + Q*x^2 + R*x + S
end

-- Vectors

function Mathf.SlerpVector(a, b, t)
	return (CFrame.new(Vector3.new(), a):Lerp(CFrame.new(Vector3.new(), b), t)).LookVector
end

-- Color3

function Mathf.LerpColor3(a, b, t)
	local it = 1 - t

	return Color3.new(
		(a.R ^ 2 * it + b.R ^ 2 * t) ^ 0.5,
		(a.G ^ 2 * it + b.G ^ 2 * t) ^ 0.5,
		(a.B ^ 2 * it + b.B ^ 2 * t) ^ 0.5
	)
end

-- Other

function Mathf.InPart(part, pos,sizemult)
	local rel = part.CFrame:PointToObjectSpace(pos)
	local size = part.Size * (sizemult or 1)

	if math.abs(rel.x) <= size.x/2 and math.abs(rel.y) <= size.y/2 and math.abs(rel.z) <= size.z/2 then
		return true
	end

	return false
end

function Mathf.ReflectVector(vector,normal)
	-- Calculate the projection of the incoming vector onto the normal vector
	local projection = (vector:Dot(normal) / normal.Magnitude^2) * normal

	-- Calculate the reflection vector using the formula: R = V - 2 * Proj_N(V)
	local reflection = vector - 2 * projection

	-- Return the reflection vector
	return reflection
end

function Mathf.IK(a, b, l1, l2) --joint pivot, end point, length 1, length 2
	if (a-b).magnitude >= l1+l2 then
		return CFrame.new(a,b),0,0
	end

	if (a-b).magnitude < (math.max(l1,l2)-math.min(l1,l2)) then
		return CFrame.new(a,b),0,math.pi
	end

	local cf=CFrame.new(a,b)
	local b=cf:pointToObjectSpace(b)
	local x=(b.z^2-l2^2+l1^2)/(2*b.z)
	local y=math.sqrt(1-(x/l1)^2)*l1	
	local a1=-math.asin(y/((x^2+y^2)^0.5))
	local a2=(x < b.z) and -math.pi+math.asin(-y/(((b.z-x)^2+y^2)^0.5)) or -math.asin(-y/(((b.z-x)^2+y^2)^0.5))

	return cf,a1,a2-a1
end


function Mathf.Vector3ToPixel(Position,Camera,Reference)
	local screen_width=Reference.AbsoluteSize.X
	local screen_height=Reference.AbsoluteSize.Y
	local point = (Camera.CoordinateFrame*CFrame.Angles(0,0,-Camera:GetRoll())):inverse() * (Position)
	local fovMult = 1 / math.tan(math.rad(Camera.FieldOfView)/2)
	local x = screen_width / 2 * (1 + point.x / -point.z * fovMult * screen_height / screen_width)
	local y = screen_height / 2 * (1 + point.y / -point.z * fovMult)
	if point.z > 0 then
		x=20000
		y=20000
	end

	return x,screen_height-y-36
end

function Mathf.LerpAngle(a, b, t) --prevents lerping the "long-way" around for angular lerps in degrees
	local ret

	if a - b < 180 then
		ret = a + (b - a)*t
	else
		ret = a + (360 + b - a)*t
	end

	return (ret - 180)%360 - 180
end

function Mathf.LerpRadAngle(A1,A2,Percent)
	A1 = math.deg(A1)
	A2 = math.deg(A2)
	difference = math.abs(A2 - A1);
	if (difference > 180) then
		-- We need to add on to one of the values.
		if (A2 > A1) then
			-- We'll add it on to start...
			A1 =A1+360
		else
			-- Add it on to end.
			A2 =A2+360
		end
	end
	A1 = math.rad(A1)
	A2 = math.rad(A2)
	return Mathf.Wrap(Mathf.Lerp(A1,A2,Percent),0,math.pi*2)
end


function Mathf.LerpTowardsAngle(a1,a2,t)
	local dist=math.abs(a2-a1)
	if dist > 180 then
		if a1 > a2 then
			a1=a1+360
		else
			a2=a2+360
		end
	end
	return Mathf.LerpTowards(a1,a2,t)
end

function Mathf.LerpAngle2(A1,A2,Percent)
	A1=(A1+180)
	A2=(A2+180)
	difference = math.abs(A2 - A1)
	if (difference > 180) then
		-- We need to add on to one of the values.
		if (A2 > A1) then
			-- We'll add it on to start...
			A2 = A2-360
		else
			-- Add it on to end.
			A1 = A1-360
		end
	end
	A1=(A1-180)
	A2=(A2-180)
	--print(math.floor(A1).."vs"..math.floor(A2))
	return Mathf.Wrap(Mathf.Lerp(A1,A2,Percent),-180,180)
end

function Mathf.AngleDistance(A1,A2)
	A1=math.deg(A1)
	A2=math.deg(A2)
	difference = math.abs(A2 - A1)
	if (difference > 180) then
		-- We need to add on to one of the values.
		if (A1 > A2) then
			-- We'll add it on to start...
			A2 = A2+360
		else
			-- Add it on to end.
			A1 = A1+360
		end
	end
	return math.rad(A1-A2)
end

function Mathf.InterpolateCFrame(CF1,CF2,Percent)
	--[[x1,y1,z1=CF1:toEulerAnglesXYZ()
	x2,y2,z2=CF2:toEulerAnglesXYZ()
	Angle=Vector3.new(math.rad(Mathf.LerpAngle(math.deg(x1),math.deg(x2),Percent)),math.rad(Mathf.LerpAngle2(math.deg(y1),math.deg(y2),Percent)),math.rad(Mathf.LerpAngle2(math.deg(z1),math.deg(z2),Percent)))
	return CFrame.new(CF1.p:Lerp(CF2.p,Percent))*CFrame.Angles(Angle.x,Angle.y,Angle.z)]]
	return Percent < 0.001 and CF1 or Percent > 0.999 and CF2 or CF1:lerp(CF2,Percent)
end

return Mathf