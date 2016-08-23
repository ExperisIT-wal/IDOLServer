-------------------------------------
-- EnrichDocument.lua
-- Enrich the document with the prepocessing
-- @param document - LuaDocument representing the document for ingestion.
-------------------------------------
function handler( document )

	local fieldname = 'WALIDMETADATA'
	local fieldvalue = 'test'
	document:addField(fieldname, fieldvalue)
	return true
end


