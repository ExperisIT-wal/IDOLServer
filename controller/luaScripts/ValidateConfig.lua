function countNodeValues(xml, xpath, value)
	local nodes = xml:XPathExecute(xpath)
	local matchedNodes = 0
	for i=0,nodes:size()-1 do
		if nodes:at(i):content():find(value) then
			matchedNodes = matchedNodes+1
		end
	end
	return matchedNodes
end

function TaskMain(service)
	-- TODO: Lua monitor should have service:getServicePortNumber and service:getIndexPortNumber functions
	local response = send_aci_action("localhost", service:getPortNumber(), "getstatus", {}, 1000, 1)
	if (response == nil) then
		return 2
	end
	local xml = parse_xml(response)

	local servicePort = xml:XPathValue( "/autnresponse/responsedata/serviceport" )
	if (not servicePort) then
		service:addServiceStatus("Warning", servicePort)
		return 2
	end
	
	response = send_aci_action("localhost", servicePort, "validateconfig", {}, 1000, 1)
	if (response == nil) then
		return 2
	end
	xml = parse_xml(response)
	
	local keysNotUsed = countNodeValues(xml, "/autnresponse/responsedata/autn:validator/autn:section/autn:key/autn:comment", "//Key not used")
	if keysNotUsed > 0 then
		service:addServiceStatus("Warning", keysNotUsed.." configuration keys not used")
	end
	
	local sectionsUnreferenced = countNodeValues(xml, "/autnresponse/responsedata/autn:validator/autn:section/autn:comment", "//Section unreferenced")
	if sectionsUnreferenced > 0 then
		service:addServiceStatus("Warning", sectionsUnreferenced.." configuration sections not referenced")
	end
	return 0
end