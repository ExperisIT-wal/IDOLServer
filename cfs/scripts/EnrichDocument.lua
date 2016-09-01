-------------------------------------
-- EnrichDocument.lua
-- Enrich the document with the prepocessing
-- @param document - LuaDocument representing the document for ingestion.
-------------------------------------
function handler( document )

	local config = get_config("cfs.cfg")
	local log = get_log(config, "ImportLogStream")

	--local ref = document:getField("DREREFERENCE")
	local ref = document:getFieldValues("DREREFERENCE")

	--write_line( log_level_always(), ref)

	log:write_line( log_level_error() , "log message test : " .. ref)

	-- tests the functions above
	local file = 'C:\\HewlettPackardEnterprise\\IDOLServer\\cfs\\scripts\\meta_data_V6_patch.csv'
	local lines = lines_from(file)
	local i = 0
	local parsedLine = ""
	local header
	local writing1
	local writing2
	local writing3
	
	-- read CSV file with header
	for k,v in pairs(lines) do
		parsedLine = ParseCSVLine(v, ';')

		if i == 0 then
			header = parsedLine
			--log:write_line( log_level_error() ,"header = " .. header[1])
		else
			log:write_line( log_level_error() ,' parsedLine[1] = ' .. parsedLine[1] .. ' ref = ' .. ref)
			if parsedLine[1] == ref then
			log:write_line( log_level_error() ,' parsedLine[1] = ' .. parsedLine[1] .. ' ref = ' .. ref)
				for ki,vi in pairs(header) do
					document:addField(vi, parsedLine[ki])
					log:write_line( log_level_error() ,' j = ' .. vi .. ' val = ' .. parsedLine[ki])
					writing1 = "' j = ' .. vi .. ' val = ' .. parsedLine[ki]"
					writing2 = vi
					writing3 = parsedLine[ki]
					--document:setContent("debut content walid")
					--document:setContent(writing1)
					--document:setContent("XXXXXXXX walid")
					document:setContent(writing2 .."=" ..writing3 .. "\n", ki)
					--document:setContent("XXXXXXX2 walid")
					--document:setContent(writing2)
					--document:setContent("XXXXXXXXX3 walid")
					--document:setContent(writing3)
					--document:setContent("end content walid")					
				end
			end
		end

  		i = i+1
	end

	return true

end


function ParseCSVLine (line,sep) 
	local res = {}
	local pos = 1
	sep = sep or ','
	while true do 
		local c = string.sub(line,pos,pos)
		if (c == "") then break end
		if (c == '"') then
			-- quoted value (ignore separator within)
			local txt = ""
			repeat
				local startp,endp = string.find(line,'^%b""',pos)
				txt = txt..string.sub(line,startp+1,endp-1)
				pos = endp + 1
				c = string.sub(line,pos,pos) 
				if (c == '"') then txt = txt..'"' end 
				-- check first char AFTER quoted string, if it is another
				-- quoted string without separator, then append it
				-- this is the way to "escape" the quote char in a quote. example:
				--   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
			until (c ~= '"')
			table.insert(res,txt)
			assert(c == sep or c == "")
			pos = pos + 1
		else	
			-- no quotes used, just look for the first separator
			local startp,endp = string.find(line,sep,pos)
			if (startp) then 
				table.insert(res,string.sub(line,pos,startp-1))
				pos = endp + 1
			else
				-- no separator found -> use rest of string and terminate
				table.insert(res,string.sub(line,pos))
				break
			end 
		end
	end
	return res
end

-- http://lua-users.org/wiki/FileInputOutput

-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
  if not file_exists(file) then return {} end
  lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return lines
end