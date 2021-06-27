local file = {}

function file.Write(path, data)
	local f = love.filesystem.newFile(path)
	f:open("w")
	f:write(data)
	f:close()
end

function file.Exists(path)
	return (love.filesystem.getInfo(path)) and true or false
end

function file.Read(path)
	return love.filesystem.read(path)
end

return file