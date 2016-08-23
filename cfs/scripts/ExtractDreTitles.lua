
--[[
	General structure:
1. List of possible ways of finding a title, *in order of precedence*.
2. Apply each of them until one of them succeeds.
3. Each individual title-finding function returns true if it found a title and false otherwise to support this.
--]]



--ENTRY-POINT HANDLER

function handler(document)	
	--Intentional orderings:
	--1. TitlesOfParts before Title (powerpoints have both, and Title is usually inaccurate)
	--2. field "Title" before field "Subject" - when we have both (some pdfs, at least) it's likely that Title is more useful.
	--3. DREORIGINALNAME last. All documents *ought* to have one, so it's a great backup, but it's just a filename mostly and the whole point of the more specific options is to do better than the filename.
	--4. Existing DRETITLE first, because (to give just one reason) without that you can't safely set it yourself in another lua script.
	
	local methods =
	{
		use_existing_dretitle,
		parse_from_titlesofparts,
		copy_from_field("Title"),
		copy_from_field("Subject"),
		parse_from_dreoriginalname
	}
	
	local method
	for _,method in ipairs(methods) do
		local title_found = method(document)
		if title_found then break end
	end

	--There's no reason that failing to find a title should inhibit further processing of a document.
	--Only documents that have already failed in some way are likely to lack a DREORIGINALNAME anyway.
	return true;
end





--PARSERS

function copy_from_field(fieldname)
	local copy_from_field_internal = function(document)
		if not document:hasField(fieldname) then return false end
		
		document:copyField(fieldname, "DRETITLE")
		return true
	end
	return copy_from_field_internal
end


function use_existing_dretitle(document)
	return document:hasField("DRETITLE")
end


function parse_from_titlesofparts(document)
	if not document:hasField("TitlesOfParts") or not document:hasField("HeadingPairs") then
		return false
	end

	local titles_of_parts = split(document:getFieldValue("TitlesOfParts"), ';')
	local heading_pairs = split(document:getFieldValue("HeadingPairs"), ';')
	
	local total_before_slide_titles = 0
	local index = 1
	local title_found = false
	while heading_pairs[index] do
		local heading = heading_pairs[index]
		if heading == "Slide Titles" then
			title_found = true
			break
		end
		total_before_slide_titles = total_before_slide_titles + tonumber(heading_pairs[index + 1])
		index = index + 2
	end
	
	if title_found then
		document:setFieldValue("DRETITLE", titles_of_parts[total_before_slide_titles + 1])
		return true
	else
		return false
	end
end


function parse_from_dreoriginalname(document)
	if not document:hasField("DREORIGINALNAME") then return false end

	local path_decomposition_regex = "(.-)([^\\/]-%.?([^%.\\/]*))$"
	local dreoriginalname = document:getFieldValue("DREORIGINALNAME")
	
	local leaf
	_, leaf, _ = dreoriginalname:match(path_decomposition_regex)
	
	
	document:setFieldValue("DRETITLE", leaf)
	return true
end



--LIBRARY FUNCTIONS

function split(data, separator)
	
	data = data .. separator
	local output_table = {}
	local fieldstart = 1
	
	repeat
		local nexti = data:find(separator, fieldstart)
		table.insert(output_table, data:sub(fieldstart, nexti - 1))
		fieldstart = nexti + 1
	until fieldstart > data:len()
	return output_table
end