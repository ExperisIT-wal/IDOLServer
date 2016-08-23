-------------------------------------
-- EnrichDocument.lua
-- Enrich the document with the prepocessing
-- @param document - LuaDocument representing the document for ingestion.
-------------------------------------
function handler( document )

	local config = get_config("cfs.cfg")
	local log = get_log(config, "ImportLogStream")
	
	local fieldname = 'AUTN_IDENTIFIER'
	local subfieldname = 'EDK_DATE_VALUE'

	local dates
	local datevalues
	local names
	
	local count_dates = 0
	local count_fields = 0
	local count_fields2 = 0
	local counte = 0
	local countesubfield = 0
	local count_names = 0
	local count_fields = 0
	local count_fieldvaleurs = 0
	
	local saveunefois = 0
	local filename = 'filename.xml'

		
	 dates = document:getField(fieldname) --version --1 qui marche qui récupère le premier champ
	--dates = { document:getFields( fieldname ) }
	datevalues = document:getField(subfieldname)

	--fields = { document:getFields( fieldname ) }
	--subfields = { document:getFields(subfieldname) }

	
	counte = document:countField(fieldname)
	countesubfield = document:countField(subfieldname)
	
	log:write_line( log_level_always() , "counte : " .. counte)
	log:write_line( log_level_always() , "countesubfield : " .. countesubfield)
		
	log:write_line( log_level_always() , "document:type dates : " .. type(dates))
	log:write_line( log_level_always() , "document:type datevalues : " .. type(datevalues))
	log:write_line( log_level_always() , "document:type length diese dates : " .. #dates)
	log:write_line( log_level_always() , "document:type lenght diese datevalues : " .. #datevalues)

	
	for i,v in pairs(dates) do 
	count_dates = count_dates + 1 
	log:write_line( log_level_always() , "document:dates[count_dates] : " .. count_dates)
	log:write_line( log_level_always() , "document:dates[table length] : " .. tablelength(dates))
	log:write_line( log_level_error() ,' i = ' .. i .. ' v = ' .. tostring(v))
	log:write_line( log_level_always() , "i: " .. i)
	log:write_line( log_level_always() , "i type: " .. type(i))

	log:write_line( log_level_always() , "v: " .. type(v))
	log:write_line( log_level_always() , "v value tostring: " .. tostring(v))

	
	end
	
	-- log:write_line( log_level_always() , "document:type fields: " .. type(fields))
	-- for _ in pairs(fields) do 
	-- count_fields = count_fields + 1 
	-- log:write_line( log_level_always() , "document:fields[count_fields]: " .. count_fields)
	-- log:write_line( log_level_always() , "document:fields[table length]: " .. tablelength(fields))
	-- end
	
	-- log:write_line( log_level_always() , "document:type subfields: " .. type(subfields))
	-- for _ in pairs(subfields) do 
	-- count_fields2 = count_fields2 + 1 
	-- log:write_line( log_level_always() , "document:subfields[subfields]: " .. count_fields2)
	-- log:write_line( log_level_always() , "document:fields[table length]: " .. tablelength(subfields))
	-- end
	
	
	names = {dates:getFieldNames()}
	
	log:write_line( log_level_always() , "dates:getFieldNames : " .. type(names))
	for i,v in pairs(names) do 
	count_names = count_names + 1
	local fieldnom = names[count_names]
	log:write_line( log_level_always() , "dates:[count_names] : " .. names[count_names])
	log:write_line( log_level_error() ,' dates:[count_names] : i = ' .. i .. ' v = ' .. tostring(v))
	log:write_line( log_level_always() , "dates:[count_names] : i: " .. i)
	log:write_line( log_level_always() , " dates:[count_names] : i type: " .. type(i))

	log:write_line( log_level_always() , "dates:[count_names] : v: " .. type(v))
	log:write_line( log_level_always() , "dates:[count_names] : v value tostring: " .. tostring(v))
	
	fieldvaleurs = { dates:getFieldValues( fieldnom ) }
	log:write_line( log_level_always() , "fieldvaleurs : " .. type(fieldvaleurs))
	log:write_line( log_level_always() , "fieldvaleurs [table length] : " .. tablelength(fieldvaleurs))
	
	for index,value in pairs(fieldvaleurs) do
		count_fieldvaleurs = count_fieldvaleurs+1
		--if (fieldvaleurs == "") then break end
		--log:write_line( log_level_always() , " getFieldValues val: " .. fieldvaleurs[count_fieldvaleurs])
		--log:write_line( log_level_always() , " getFieldValues wal: " .. fieldvaleurs[1])
		log:write_line( log_level_always() , " getFieldValues count: " .. count_fieldvaleurs)
		log:write_line( log_level_always() , " getFieldValues type: " .. type(fieldvaleurs))
		log:write_line( log_level_error() ,' getFieldValues : index = ' .. index .. ' value = ' .. tostring(value))

			-- -- if(names[count_names] == 'EDK_DATE_VALUE') then
				
				
				-- -- fieldvaleurselements = {fields[1]:getFieldNames()}
				-- -- log:write_line( log_level_always() , "document:[count_names] fieldvaleurselements val: " .. fieldvaleurselements)
				-- -- log:write_line( log_level_always() , "document:[count_names] fieldvaleurselements wal: " .. fieldvaleurselements[1])
				-- -- log:write_line( log_level_always() , "document:[count_names] fieldvaleurselements type: " .. type(fieldvaleurselements))
			-- -- end
			
		end
		--count_fieldvaleurs = 0

	end
	
	return true
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end


