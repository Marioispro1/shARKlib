--!strict

local PREFIX = "[shARKlib]"

local Log = {}

local function formatMessage(scope: string?, action: string?, text: string): string
	local parts = { PREFIX }
	if scope ~= nil and scope ~= "" then
		table.insert(parts, scope)
	end
	if action ~= nil and action ~= "" then
		table.insert(parts, action)
	end
	table.insert(parts, text)
	return table.concat(parts, ": ")
end

function Log.braced(value: any): string
	return ("{%s}"):format(tostring(value))
end

function Log.message(scope: string?, action: string?, text: string): string
	return formatMessage(scope, action, text)
end

function Log.info(scope: string?, action: string?, text: string)
	print(formatMessage(scope, action, text))
end

function Log.warn(scope: string?, action: string?, text: string)
	warn(formatMessage(scope, action, text))
end

return Log
