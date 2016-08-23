-------------------------------------
-- Adds sub file indices to the AUTN_IDENTIFIER field
-- enabling sub file extraction for the connectors
-- @param document - LuaDocument representing the document for ingestion.
-------------------------------------
function handler( document )
	--If we have an AUTN_IDENTIFIER and a SubFileIndexCSV
    identifier = document:getFieldValue( "AUTN_IDENTIFIER" )
    if identifier then
        indices = document:getFieldValue( "SubFileIndexCSV" )
        if indices then
			--Append on the subfile indices in the right format
            indices = string.gsub(indices, ",", ".")
            document:setFieldValue( "AUTN_IDENTIFIER", identifier .. "|" .. indices )
        end
    end
    return true
end