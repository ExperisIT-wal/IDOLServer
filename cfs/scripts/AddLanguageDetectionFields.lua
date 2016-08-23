-------------------------------------
-- Adds Detected Language metadata fields to documents sent for ingestion 
-- indicating the language of the document detected by IDOL.
-- @param document - LuaDocument representing the document for ingestion.
-------------------------------------
function handler( document )
	--IDOL server setting to be used for language detection
	local idolHost = "localhost"
	local idolACIPort = 9000
	
	--ACI Command Timeout
	local timeout = 30000
	
	--Maximum string length in characters to send to IDOL for language detection,
	-- Values: >= -1
	-- -1 indicates no limit
	local maxLength = 500
	
	--No of prefix characters to ignore from the start of the document content
	-- Values: >= 1
	-- 1 indicates no offset
	local contentOffset= 1
	
	--The names of the metadata fields to be added to the document for ingestion
	local languageMetadataFieldName = "DetectedLanguage"
	local encodingMetadataFieldName = "DetectedLanguageEncoding"
	local unicodeBlockMetadataFieldName = "DetectedLanguageUnicodeBlock"
	
	--Calculate substring from document content to send to IDOL for language detection
	local detectionString = document:getContent():sub(contentOffset, maxLength)
	
	--Return if no content
	if !detectionString then
		return true 
	end
	
	--Send ACI action to IDOL and recieve XML response string
	local response = send_aci_action(idolHost, idolACIPort, "DetectLanguage", { Text=detectionString }, timeout)
	
	--Parse the response string into a LuaXmlDocument
	local luaXmlDoc = parse_xml(response)
	
	--Register response xml namespace with the LuaXmlDocument
	luaXmlDoc:XPathRegisterNs("autn", "http://schemas.autonomy.com/aci/")
	
	--Retrieve the detected language node value from the LuaXmlDocument
	local language = luaXmlDoc:XPathValue("/autnresponse/responsedata/autn:language")
	
	--Retrieve the detected language encoding node value from the LuaXmlDocument
	local encoding = luaXmlDoc:XPathValue("/autnresponse/responsedata/autn:languageencoding")
	
	--Retrieve the detected language unicode block node values from the LuaXmlDocument
	--Unicode blocks represent what character ranges are present in the text
	local languageBlocks = { luaXmlDoc:XPathValues("/autnresponse/responsedata/autn:languagescripts/autn:unicodeblock") }
	
	--Add the Detected Language metadata field to the document for ingestion
	document:setFieldValue( languageMetadataFieldName, language )
	
	--Add the Detected Language metadata field to the document for ingestion
	document:setFieldValue( encodingMetadataFieldName, encoding )
	
	for index, unicodeblock in ipairs(languageBlocks) do
		--Add the Detected Language unicodeblock metadata field to the document for ingestion
		document:addField( unicodeBlockMetadataFieldName, unicodeblock )
	end
	
	return true
end