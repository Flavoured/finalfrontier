local ROOM_UPDATE_FREQ = 1

local _mt = {}
_mt.__index = _mt
_mt._lastUpdate = 0

_mt._ship = nil
_mt._doorlist = nil
_mt._bounds = nil
_mt._system = nil
_mt._convexPolys = nil

_mt._nwdata = nil

function _mt:GetName()
	return self._nwdata.name
end

function _mt:GetIndex()
	return self._nwdata.index or 0
end

function _mt:GetShip()
	return self._ship
end

function _mt:_UpdateBounds()
	local bounds = Bounds()
	for _, v in ipairs(self:GetCorners()) do
		bounds:AddPoint(v.x, v.y)
	end
	self._bounds = bounds
end

function _mt:GetBounds()
	return self._bounds
end

function _mt:GetSystemName()
	return self._nwdata.systemname
end

function _mt:_UpdateSystem()
	self._system = sys.Create(self:GetSystemName(), self)
end

function _mt:HasSystem()
	return self._system ~= nil
end

function _mt:GetSystem()
	return self._system
end

function _mt:GetVolume()
	return self._nwdata.volume or 0
end

function _mt:GetSurfaceArea()
	return self._nwdata.surfacearea or 0
end

function _mt:AddDoor(door)
	if table.HasValue(self._doorlist, door) then return end

	table.insert(self._doorlist, door)
end

function _mt:GetDoors()
	return self._doorlist
end

function _mt:GetCorners()
	return self._nwdata.corners
end

function _mt:_UpdateConvexPolys()
	self._convexPolys = FindConvexPolygons(self:GetCorners())
end

function _mt:GetConvexPolys()
	return self._convexPolys
end

function _mt:GetStatusLerp()
	return math.Clamp((CurTime() - self._lastUpdate) / ROOM_UPDATE_FREQ, 0, 1)
end

function _mt:GetTemperature()
	return (self._nwdata.temperature or 0) * self:GetAtmosphere()
end

function _mt:GetAirVolume()
	return self._nwdata.airvolume or 0
end

function _mt:GetAtmosphere()
	return self:GetAirVolume() / self:GetVolume()
end

function _mt:GetShields()
	return self._nwdata.shields or 0
end

function _mt:GetPermissionsName()
	return "p_" .. self:GetShip():GetName() .. "_" .. self:GetIndex()
end

local ply_mt = FindMetaTable("Player")
function ply_mt:GetPermission(room)
	return self:GetNWInt(room:GetPermissionsName(), 0)
end

function ply_mt:HasPermission(room, perm)
	return self:GetPermission(room) >= perm
end

function ply_mt:HasDoorPermission(door)
	return self:HasPermission(door:GetRooms()[1], permission.ACCESS)
		or self:HasPermission(door:GetRooms()[2], permission.ACCESS)
end

function ply_mt:GetRoom()
	if not self:GetNWInt("room") then return nil end
	if not self:GetNWString("ship") then return nil end
	return self:GetShip():GetRoomByIndex(self:GetNWInt("room"))
end

function ply_mt:IsInRoom(room)
	if self:GetNWString("ship") == room:GetShip():GetName()
		and self:GetNWInt("room") == room:GetIndex() then
		return true
	end
end

function _mt:Think()
	if self:GetSystemName() and not self:GetSystem() then
		self:_UpdateSystem()
	end

	if not self:GetBounds() and self:GetCorners() then
		self:_UpdateBounds()
	end

	if not self:GetConvexPolys() and self:GetCorners() then
		self:_UpdateConvexPolys()
	end
end

function Room(name, ship, index)
	local room = {}

	room._nwdata = GetGlobalTable(name)
	room._nwdata.name = name
	room._nwdata.index = index

	room._ship = ship
	room._doorlist = {}

	return setmetatable(room, _mt)
end
