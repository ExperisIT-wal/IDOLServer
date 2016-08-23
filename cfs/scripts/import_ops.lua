-- Lua script to process import operations from old style import configuration
-- ===========================================================================
-- Call import_ops(document, configFilename, section) to perform all supported ops from config
-- ===========================================================================================

-- Read string config parameter.
function readString(config, section, param, def)
	local value = config:getValue(section, param, "")
	if value == "" then
		return def
	end
	local inner = string.match(value, '^"(.*)"$')
	if inner ~= nil then
		value = string.gsub(inner, "\\(.)", "%1")
	end
	return value
end

-- Read boolean config parameter.
function readBool(config, section, param, def)
	local value = string.upper(config:getValue(section, param, ""))
	if value == "" then
		return def
	end
	if value == "TRUE" or value == "ON" or value == "1" or value == "YES" then
		return true
	else
		return false
	end
end

-- This is an attempt to handle CSV strings allowing for quoted values with quote escaping,
-- or unquoted values with comma escaping.  It does not cover every possible case but should
-- support a sufficiently large set.
function split(str, delim)
    local result = {}
    local num = 1
    local lastPos = 1
    local quotepat = '^"(.-[^\\])"'..delim..'()'
    local quotepat2 = '^"(.-[^\\]\\\\)"'..delim..'()'
    local quotefpat = '^"(.-[^\\])"$'
    local quotefpat2 = '^"(.-[^\\]\\\\)"$'
    local commapat = '^(.-[^\\])'..delim..'()'
    local quotef = false
    local s, e, value, pos = string.find(str, quotepat, 1)
    if s == nil then
    	s, e, value, pos = string.find(str, quotepat2, 1)
    end	
    if s == nil then
    	s, e, value = string.find(str, quotefpat, 1)
    	quotef = true
    end	
    if s == nil then
    	s, e, value = string.find(str, quotefpat2, 1)
    	quotef = true
    end	
    if s == nil then
    	quotef = false
    	s, e, value, pos = string.find(str, commapat, 1)
    end	
    while s do
		result[num] = string.gsub(value, "\\(.)", "%1")
		if quotef == true then
			return result
		end
		num = num + 1
		lastPos = pos
		s, e, value, pos = string.find(str, quotepat, lastPos)
		if s == nil then
			s, e, value, pos = string.find(str, quotepat2, lastPos)
		end	
		if s == nil then
			s, e, value = string.find(str, quotefpat, lastPos)
	    	quotef = true
		end	
		if s == nil then
			s, e, value = string.find(str, quotefpat2, lastPos)
	    	quotef = true
		end	
		if s == nil then
	    	quotef = false
			s, e, value, pos = string.find(str, commapat, lastPos)
		end	
    end
	result[num] = string.gsub(string.sub(str, lastPos), "\\(.)", "%1")
    return result
end

-- Escape all characters to pass as pattern to lua string functions.
function makePlain(str)
	local result = string.gsub(str, "(%W)", "%%%1")
	return result
end

-- Return true if string matches wildcard string (using * and ?).
function matchWild(str, wild)
	local pat = makePlain(wild)
	local pat = string.gsub(pat, "%%%*", ".*")
	pat = string.gsub(pat, "%%%?", ".")
	pat = "^"..pat.."$"
	if nil ~= string.match(str, pat) then
		return true
	end
	return false
end

-- Return true if string matches one of a list of wildcard strings (using * and ?).
function matchMultiWild(str, wildCSV, delim)
	local wildList = split(wildCSV, delim)
	for n,wild in pairs(wildList) do
		if matchWild(str, wild) then
			return true
		end
	end
	return false
end

-- Convert Fname parameter to field value or return original string.
function getValueWithFname( document, str )
	local fieldName = string.match(str, "^[fF][nN][aA][mM][eE](.*)$")
	if nil ~= fieldName then
		local value = document:getFieldValue(fieldName)
		if value == nil then
			return ""
		else
			return value
		end
	else
		return str
	end
end

-- Set Fixed fields using FixedFieldName<N> and FixedFieldValue<N>.
function opFixedFields( config, section, document )
	local index = 0
	local fieldName = config:getValue(section, "FixedFieldName"..index, "")
	while fieldName ~= "" do
		local fieldValue = readString(config, section, "FixedFieldValue"..index, "")
		local overwrite = readBool(config, section, "FixedFieldOverwriteExistingValue"..index, 1)
		if overwrite or document:getFieldValue(fieldName) == nil then
			document:setFieldValue(fieldName, fieldValue);
		end
		index = index + 1
		fieldName = config:getValue(section, "FixedFieldName"..index, "")
	end
end

-- Remap fields using ImportRemapFieldsCSVsFrom<N> and ImportRemapFieldsCSVsTo<N>.
function opRemapFieldCSVs( config, section, document )
	local index = 0
	local fieldFromCSV = config:getValue(section, "ImportRemapFieldsCSVsFrom"..index, "")
	while fieldFromCSV ~= "" do
		local fieldFromList = split(fieldFromCSV, ",")
		for n,fieldFrom in pairs(fieldFromList) do
			local fieldFromValue = document:getFieldValue(fieldFrom)
			if fieldFromValue ~= nil then
				local fieldTo = config:getValue(section, "ImportRemapFieldsCSVsTo"..index, "")
				document:setFieldValue(fieldTo, fieldFromValue)
				break
			end
		end
		index = index + 1
		fieldFromCSV = config:getValue(section, "ImportRemapFieldsCSVsFrom"..index, "")
	end
end

-- Remap fields using ImportRemapField<N> and ImportRemapFieldTo<N>.
function opRemapFields( config, section, document )
	local index = 0
	local fieldFrom = config:getValue(section, "ImportRemapField"..index, "")
	while fieldFrom ~= "" do
		local fieldFromValue = document:getFieldValue(fieldFrom)
		if fieldFromValue ~= nil then
			local fieldTo = config:getValue(section, "ImportRemapFieldTo"..index, "")
			document:setFieldValue(fieldTo, fieldFromValue)
		end
		index = index + 1
		fieldFrom = config:getValue(section, "ImportRemapField"..index, "")
	end
end

-- Extract Date with ImportExtractDate* settings (Incomplete).
-- Only works with ImportExtractDateFrom<N>=16 and only if field is exactly in a specified format.
-- See also FieldOp CONVERTDATE.
function opExtractDate( config, section, document )
	local index = 0
	local extractDateFormatCSV = config:getValue(section, "ImportExtractDateFormatCSVs"..index, "")
	local extractDateToFormat = config:getValue(section, "ImportExtractDateToFormat"..index, "")
	local extractDateFrom = config:getValue(section, "ImportExtractDateFrom"..index, "")
	local extractDateFromField = config:getValue(section, "ImportExtractDateFromField"..index, "")
	local extractDateToField = config:getValue(section, "ImportExtractDateToField"..index, "")
	while extractDateFormatCSV ~= "" 
		and extractDateToFormat ~= "" 
		and extractDateFrom == "16"
		and extractDateFromField ~= "" 
		and extractDateToField ~= ""
	do
		local extractDateFormatList = split(extractDateFormatCSV, ",")
		local extractDateFromFieldValue = document:getFieldValue(extractDateFromField)
		local result = ""
		if extractDateFromFieldValue ~= nil and extractDateFromFieldValue ~= "" then
		   for n,format in pairs(extractDateFormatList) do
			result = convert_date_time(extractDateFromFieldValue, format, extractDateToFormat)
			if result ~= "" then
				break
			end
		   end
		   document:setFieldValue(extractDateToField, result)
		end
		index = index + 1
		extractDateFormatCSV = config:getValue(section, "ImportExtractDateFormatCSVs"..index, "")
		extractDateToFormat = config:getValue(section, "ImportExtractDateToFormat"..index, "")
		extractDateFrom = config:getValue(section, "ImportExtractDateFrom"..index, "")
		extractDateFromField = config:getValue(section, "ImportExtractDateFromField"..index, "")
		extractDateToField = config:getValue(section, "ImportExtractDateToField"..index, "")
	end
end

-- ##### Begin Field Operations #####

function opFieldOpREPLACESTRING( document, field, params )
	local paramList = split(params, ";")
	local value = document:getFieldValue(field)
	if value == nil then return end
	local fs, fe = string.find(value, paramList[1], 1, true)
	if fs == nil then return end
	document:setFieldValue(field, string.sub(value, 1, fs - 1)..paramList[2]..string.sub(value, fe + 1))
end

function opFieldOpREPLACEMULTIPLE( document, field, params )
	local paramList = split(params, ";")
	local value = document:getFieldValue(field)
	if value == nil then return end
	value = string.gsub(value, makePlain(paramList[1]), paramList[2]);
	document:setFieldValue(field, value)
end

function opFieldOpFIELDGLUE( document, field, params )
	local value = ""
	local paramList = split(params, ",")
	for n,param in pairs(paramList) do
		value = value..getValueWithFname(document, param)
	end
	document:setFieldValue(field, value)
end

function opFieldOpSTRINGMATCH( document, field, params )
	local paramList = split(params, ";")
	local value = document:getFieldValue(field)
	if value == nil then return end
	local check = getValueWithFname(document, paramList[1])
	local valueiftrue = getValueWithFname(document, paramList[2])
	local valueiffalse = getValueWithFname(document, paramList[3])
	if value == check then
		document:setFieldValue(field, valueiftrue)
	else
		document:setFieldValue(field, valueiffalse)
	end
end

function opFieldOpCONVERTDATE( document, field, params )
	local paramList = split(params, ";")
	local value = document:getFieldValue(field)
	if value == nil then return end
	result = convert_date_time(value, paramList[1], paramList[2])
	if result == "" then
		result = convert_date_time("1970/01/01", "YYYY/MM/DD", paramList[2])
	end
	document:setFieldValue(field, result)
end

function opFieldOpENCRYPTSECURITYFIELD( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	document:setFieldValue(field, encrypt_security_field(value))
end

function opFieldOpCHECKSUM( document, field, params )
	local algorithm, fieldcsv = string.match(params, "^(.-)|(.*)$")
	if algorithm == nil then
		algorithm = "MD5"
		fieldcsv = params
	end
	local fields = split(fieldcsv, ",")
	local input = ""
	
	for n,f in pairs(fields) do
		local value = document:getFieldValue(f)
		if value ~= nil then
			input = input..value
		end
	end
	
	local checksum = hash_string(input, algorithm)
	document:setFieldValue(field, checksum)
end

function opFieldOpEXPAND( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	local separator, outputfield = string.match(params, "^(.);(.*)$")
	if separator == nil then
		separator = string.sub(params, 1, 1)
		outputfield = field.."_"
	end
	local values = split(value, separator)
	for n,v in pairs(values) do
		document:addField(outputfield, v)
	end
end

function opFieldOpEXPANDTONUMBERED( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	local separator, outputfield = string.match(params, "^(.);(.*)$")
	if separator == nil then
		separator = string.sub(params, 1, 1)
		outputfield = field
	end
	local values = split(value, separator)
	for n,v in pairs(values) do
		document:addField(outputfield.."_"..n, v)
	end
end

function opFieldOpESCAPE( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	local index = 1
	local len = string.len(value)
	local result = ""
	while index <= len do
		local b = string.byte(value, index)
		if (b >= 48 and b <= 57) or (b >= 65 and b <= 90) or (b >= 97 and b <= 122) then
			result = result..string.sub(value, index, index)
		else
			result = result..string.format("%%%X%X", math.floor(b/16), b%16)
		end
		index = index + 1
	end
	document:setFieldValue(field, result)
end

function opFieldOpUNESCAPE( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	-- this line is added to be consistent with strUnescape used by field op
	value = string.gsub(value, "%+", " ");
	local index = 1
	local len = string.len(value)
	local result = ""
	while index <= len do
		local s, e = string.find(value, "%%[0-9a-fA-F][0-9a-fA-F]", index)
		if s == nil then
			result = result..string.sub(value, index, len)
			index = string.len(value) + 1
		else
			if s > index then
				result = result..string.sub(value, index, s - 1)
			end
			local ch = 0
			local b = string.byte(value, s + 1)
			if (b >= 48 and b <= 57) then
				ch = 16 * (b - 48)
			elseif (b >= 65 and b <= 70) then
				ch = 16 * (b - 55)
			elseif (b >= 97 and b <= 102) then
				ch = 16 * (b - 87)
			end
			b = string.byte(value, s + 2)
			if (b >= 48 and b <= 57) then
				ch = ch + (b - 48)
			elseif (b >= 65 and b <= 70) then
				ch = ch + (b - 55)
			elseif (b >= 97 and b <= 102) then
				ch = ch + (b - 87)
			end
			result = result..string.char(ch)
			index = s + 3
		end
	end
	document:setFieldValue(field, result)
end

function opFieldOpSTRIPCHARS( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	local pat = "["..makePlain(params).."]"
	value = string.gsub(value, pat, "")
	document:setFieldValue(field, value)
end

function opFieldOpGOBBLEWHITESPACE( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	document:setFieldValue(field, gobble_whitespace(value))
end

function opFieldOpTOUPPER( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	document:setFieldValue(field, string.upper(value))
end

function opFieldOpTOLOWER( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	document:setFieldValue(field, string.lower(value))
end

function opFieldOpTOPNTAILWHITESPACE( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	value = string.match(value, "^%s*(.-)%s*$")
	if value ~= nil then
		document:setFieldValue(field, value)
	end
end

function opFieldOpTAILWHITESPACE( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	value = string.match(value, "^(.-)%s*$")
	if value ~= nil then
		document:setFieldValue(field, value)
	end
end

function opFieldOpBLANKFIELD( document, field, params )
	document:setFieldValue(field, "")
end

function opFieldOpCOPYFIELD( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	document:setFieldValue(params, value)
end

function opFieldOpDELETEFIELD( document, field, params )
	document:deleteField(field)
end

function startAtChars( document, value, params )
	local paramList = split(params, ",")
	local pat = "["..makePlain(paramList[1]).."]"
	if paramList[2] == "0" then
		local s, e = string.find(value, pat, 1)
		if s ~= nil then
			value = string.sub(value, s)
		else
			value = ""
		end
	elseif paramList[2] == "1" then
		local rev = value:reverse()
		local s, e = string.find(rev, pat, 1)
		if s ~= nil then
			value = string.sub(value, value:len() - s + 1)
		else
			value = ""
		end
	elseif paramList[2] == "2" then
		local s, e = string.find(value, pat, 1)
		if s ~= nil then
			value = string.sub(value, s + 1)
		else
			value = ""
		end
	elseif paramList[2] == "3" then
		local rev = value:reverse()
		local s, e = string.find(rev, pat, 1)
		if s ~= nil then
			value = string.sub(value, value:len() - s + 2)
		else
			value = ""
		end
	end
	return value
end

function opFieldOpSTARTATCHARS( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	document:setFieldValue(field, startAtChars(document, value, params))
end

function opFieldOpSTARTATCHARSCSVS( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	local valueList = split(value, ",")
	local result = ""
	for n,v in pairs(valueList) do
		if result == "" then
			result = startAtChars(document, v, params)
		else
			result = result..","..startAtChars(document, v, params)
		end
	end
	document:setFieldValue(field, result)
end

function opFieldOpENDATCHARS( document, field, params )
	local value = document:getFieldValue(field)
	if value == nil then return end
	local paramList = split(params, ",")
	local pat = "["..makePlain(paramList[1]).."]"
	if paramList[2] == "0" then
		local s, e = string.find(value, pat, 1)
		if s ~= nil then
			value = string.sub(value, 1, s)
		else
			value = ""
		end
	elseif paramList[2] == "1" then
		local rev = value:reverse()
		local s, e = string.find(rev, pat, 1)
		if s ~= nil then
			value = string.sub(value, 1, value:len() - s + 1)
		else
			value = ""
		end
	elseif paramList[2] == "2" then
		local s, e = string.find(value, pat, 1)
		if s ~= nil then
			value = string.sub(value, 1, s - 1)
		else
			value = ""
		end
	elseif paramList[2] == "3" then
		local rev = value:reverse()
		local s, e = string.find(rev, pat, 1)
		if s ~= nil then
			value = string.sub(value, 1, value:len() - s)
		else
			value = ""
		end
	end
	document:setFieldValue(field, value)
end

-- ##### End Field Operations #####

-- Perform Field operations ImportFieldOp*
-- Field op implementations are all above in functions "opFieldOp<NAME>"
-- See import documentation for description of individual field operations
function opFieldOp( config, section, document )
	local index = 0
	local fieldOp = string.upper(config:getValue(section, "ImportFieldOp"..index, ""))
	local fieldOpApplyToCSV = config:getValue(section, "ImportFieldOpApplyTo"..index, "")
	local fieldOpParam = readString(config, section, "ImportFieldOpParam"..index, "")
	local fieldOpCheckField = config:getValue(section, "ImportFieldOpCheckField"..index, "")
	local fieldOpCheckValue = readString(config, section, "ImportFieldOpCheckValue"..index, "")
	local fieldOpCreateField = readBool(config, section, "ImportFieldOpCreateField"..index, "")
	while fieldOp ~= "" and fieldOpApplyToCSV ~= "" do
		if fieldOpCheckField == "" or matchMultiWild(document:getFieldValue(fieldOpCheckField), fieldOpCheckValue, ",") then
			local fieldOpApplyToList = split(fieldOpApplyToCSV, ",")
			for n,field in pairs(fieldOpApplyToList) do
				if fieldOpCreateField or nil ~= document:getFieldValue(field) then
					if fieldOp == "REPLACESTRING" then
						opFieldOpREPLACESTRING(document, field, fieldOpParam)
					elseif fieldOp == "REPLACEMULTIPLE" then
						opFieldOpREPLACEMULTIPLE(document, field, fieldOpParam)
					elseif fieldOp == "FIELDGLUE" then
						opFieldOpFIELDGLUE(document, field, fieldOpParam)
					elseif fieldOp == "STRINGMATCH" then
						opFieldOpSTRINGMATCH(document, field, fieldOpParam)
					elseif fieldOp == "CONVERTDATE" then
						opFieldOpCONVERTDATE(document, field, fieldOpParam)
					elseif fieldOp == "ENCRYPTSECURITYFIELD" then
						opFieldOpENCRYPTSECURITYFIELD(document, field, fieldOpParam)
					elseif fieldOp == "CHECKSUM" then
						opFieldOpCHECKSUM(document, field, fieldOpParam)
					elseif fieldOp == "EXPAND" then
						opFieldOpEXPAND(document, field, fieldOpParam)
					elseif fieldOp == "EXPANDTONUMBERED" then
						opFieldOpEXPANDTONUMBERED(document, field, fieldOpParam)
					elseif fieldOp == "ESCAPE" then
						opFieldOpESCAPE(document, field, fieldOpParam)
					elseif fieldOp == "UNESCAPE" then
						opFieldOpUNESCAPE(document, field, fieldOpParam)
					elseif fieldOp == "STRIPCHARS" then
						opFieldOpSTRIPCHARS(document, field, fieldOpParam)
					elseif fieldOp == "GOBBLEWHITESPACE" then
						opFieldOpGOBBLEWHITESPACE(document, field, fieldOpParam)
					elseif fieldOp == "TOUPPER" then
						opFieldOpTOUPPER(document, field, fieldOpParam)
					elseif fieldOp == "TOLOWER" then
						opFieldOpTOLOWER(document, field, fieldOpParam)
					elseif fieldOp == "TOPNTAILWHITESPACE" then
						opFieldOpTOPNTAILWHITESPACE(document, field, fieldOpParam)
					elseif fieldOp == "TAILWHITESPACE" then
						opFieldOpTAILWHITESPACE(document, field, fieldOpParam)
					elseif fieldOp == "BLANKFIELD" then
						opFieldOpBLANKFIELD(document, field, fieldOpParam)
					elseif fieldOp == "COPYFIELD" then
						opFieldOpCOPYFIELD(document, field, fieldOpParam)
					elseif fieldOp == "DELETEFIELD" then
						opFieldOpDELETEFIELD(document, field, fieldOpParam)
					elseif fieldOp == "STARTATCHARS" then
						opFieldOpSTARTATCHARS(document, field, fieldOpParam)
					elseif fieldOp == "STARTATCHARSCSVS" then
						opFieldOpSTARTATCHARSCSVS(document, field, fieldOpParam)
					elseif fieldOp == "ENDATCHARS" then
						opFieldOpENDATCHARS(document, field, fieldOpParam)
					end
				end
			end
		end
		index = index + 1
		fieldOp = string.upper(config:getValue(section, "ImportFieldOp"..index, ""))
		fieldOpApplyToCSV = config:getValue(section, "ImportFieldOpApplyTo"..index, "")
		fieldOpParam = readString(config, section, "ImportFieldOpParam"..index, "")
		fieldOpCheckField = config:getValue(section, "ImportFieldOpCheckField"..index, "")
		fieldOpCheckValue = readString(config, section, "ImportFieldOpCheckValue"..index, "")
		fieldOpCreateField = config:getValue(section, "ImportFieldOpCreateField"..index, "")
	end
end

-- Perform Field Glue operations using ImportFieldGlueSourceCSVs and ImportFieldGlueDestination
-- Similar to FieldOp FIELDGLUE
function opImportFieldGlue( config, section, document )
	local index = 0
	local sourcecsv = readString(config, section, "ImportFieldGlueSourceCSVs"..index, "")
	local destination = config:getValue(section, "ImportFieldGlueDestination"..index, "")
	while sourcecsv ~= "" and destination ~= "" do
		opFieldOpFIELDGLUE(document, destination, sourcecsv)
		index = index + 1
		sourcecsv = readString(config, section, "ImportFieldGlueSourceCSVs"..index, "")
		destination = config:getValue(section, "ImportFieldGlueDestination"..index, "")
	end
end



function import_ops( document, configFilename, section )

	-- Read config from specified file
	local config = get_config(configFilename)
	
	-- Rename a few fields to match those generated by old import module
	opFieldOpCOPYFIELD(document, "Content-Type", "CONTENT-TYPE")
	opFieldOpCOPYFIELD(document, "DREFILENAME", "DREFULLFILENAME")
	opFieldOpCOPYFIELD(document, "VersionNumber", "KV_DOCINFO_Version")
	
	opFixedFields(config, section, document)
	
	opRemapFieldCSVs(config, section, document)
	
	opRemapFields(config, section, document)
	
	opExtractDate(config, section, document)
	
	opFieldOp(config, section, document)
	
	opImportFieldGlue(config, section, document)

end
