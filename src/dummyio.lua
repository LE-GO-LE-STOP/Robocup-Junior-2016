io = {}
io.open = function()
	local out = {}
	local dummy = function() return "" end
	out.close = dummy
	out.lines = dummy
	out.read = dummy
	out.write = dummy
	return out
end
io.popen = function()
	return ""
end

lfs = {}
lfs.dir = function()
	return function() return nil end, 1
end

os.execute = function()
	return true
end