-------------------------------------
-- EnrichDocument.lua
-- Enrich the document with the prepocessing
-- @param document - LuaDocument representing the document for ingestion.
-------------------------------------
function handler( document )

	local config = get_config("cfs.cfg")
	local log = get_log(config, "ImportLogStream")
	
	local fieldname = 'EDK_DATE_VALUE'
	local dates
	local names
	
	local count_dates = 0
	local count_names = 0
	local count_fields = 0
	local count_fieldvaleurs = 0
	
	local saveunefois = 0
	local filename = 'filename.xml'
	

		
	dates = document:getField(fieldname)
	names = {document:getFieldNames()}
	fields = { document:getFields( fieldname ) }
	
	
	log:write_line( log_level_always() , "document:getField : " .. type(dates))
	for _ in pairs(dates) do 
	count_dates = count_dates + 1 
	log:write_line( log_level_always() , "document:dates[count_dates] : " .. count_dates)
	end
	
	log:write_line( log_level_always() , "document:getFieldNames : " .. type(names))
	for _ in pairs(names) do 
	count_names = count_names + 1
	local fieldnom = names[count_names]
	log:write_line( log_level_always() , "document:[count_names] : " .. names[count_names])
--	local fieldnom = names[count_names]
	log:write_line( log_level_always() , "document:[count_names] getFieldValue : " .. document:getFieldValue(fieldnom))
	
	fieldvaleurs = { document:getFieldValues( fieldnom ) }
		for _ in pairs(fieldvaleurs) do
		count_fieldvaleurs = count_fieldvaleurs+1
		--if (fieldvaleurs == "") then break end
		log:write_line( log_level_always() , "document:[count_names] getFieldValues val: " .. fieldvaleurs[count_fieldvaleurs])
		log:write_line( log_level_always() , "document:[count_names] getFieldValues wal: " .. fieldvaleurs[1])
		log:write_line( log_level_always() , "document:[count_names] getFieldValues count: " .. count_fieldvaleurs)
		log:write_line( log_level_always() , "document:[count_names] getFieldValues type: " .. type(fieldvaleurs))
		
			-- if(names[count_names] == 'EDK_DATE_VALUE') then
				
				
				-- fieldvaleurselements = {fields[1]:getFieldNames()}
				-- log:write_line( log_level_always() , "document:[count_names] fieldvaleurselements val: " .. fieldvaleurselements)
				-- log:write_line( log_level_always() , "document:[count_names] fieldvaleurselements wal: " .. fieldvaleurselements[1])
				-- log:write_line( log_level_always() , "document:[count_names] fieldvaleurselements type: " .. type(fieldvaleurselements))
			-- end
			
		end
		count_fieldvaleurs = 0

	end
	
	log:write_line( log_level_always() , "document:getFields walid aoudi: " .. type(fields))
	for _ in pairs(fields) do 
	count_fields = count_fields + 1 
	log:write_line( log_level_always() , "document:getFields walid aoudi: " .. count_fields)
	end
	count_fields = 0
	
	-- if (saveunefois ==0) then 
		-- --document:writeStubXml('C:\\HewlettPackardEnterprise\\IDOLServer\\cfs\\logs')
		-- document:writeStubXml(filename)
		-- saveunefois = saveunefois + 1 
	-- end
	
	return true
end


-- function tablelength(T)
  -- local count = 0
  -- for _ in pairs(T) do count = count + 1 end
  -- return count
-- end

