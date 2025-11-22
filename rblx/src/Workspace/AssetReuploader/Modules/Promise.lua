--[[ promise
	tyridge77
	(Not a real promise, but borrowed some of the same functionality)
]]

local RESOLVED,FAILED,CANCELLED = 1,2,3

local Promise = {}
Promise.__index = Promise
function Promise.new(fn)
	local self = setmetatable({
		callbacks = {{},{},{},{}}
	},Promise)
	self.statusString = "Started"
	self.thread = task.spawn(function()
		fn(function(...) self:resolve(...) end,function(...) self:reject(...) end)
	end)
	return self
end
function Promise:andThen(fn)
	table.insert(self.callbacks[1],fn)
	return self
end
function Promise:catch(fn)
	table.insert(self.callbacks[2],fn)
	return self
end
function Promise:cancelled(fn)
	table.insert(self.callbacks[3],fn)
	return self
end
function Promise:finally(fn)
	table.insert(self.callbacks[4],fn)
	return self
end

function Promise:finish(status,...)
	if self._resolved then
		return
	end
	self._resolved = true
	
	local args = table.pack(...)

	task.defer(function()
		
		task.cancel(self.thread)

		local callbacks = self.callbacks[status]
		for _,fn in pairs(callbacks) do
			fn(unpack(args,1,args.n))
		end

		--[[ "Finally" callbacks ]]
		for _,fn in pairs(self.callbacks[4]) do
			fn(unpack(args,1,args.n))
		end
		--
		
		
		if status == RESOLVED then
			self.statusString = "Resolved"
		elseif status == FAILED then
			self.statusString = "Failed"
		elseif status == CANCELLED then
			self.statusString = "Cancelled"
		end
	end)
end
function Promise:getStatus()
	return self.statusString
end
function Promise:resolve(...)
	self:finish(RESOLVED,...)
end
function Promise:reject(...)
	self:finish(FAILED,...)
end
function Promise:cancel(...)
	self:finish(CANCELLED,...)
end
function Promise:Timeout(n)
	if self._timeout then
		return
	end
	self._timeout = true
	task.delay(n,function()
		self:reject()
	end)
end

return Promise