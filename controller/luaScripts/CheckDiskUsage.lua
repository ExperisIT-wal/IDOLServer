function TaskMain(service)
	local response = send_aci_action("localhost", service:getPortNumber(), "diskreport", {}, 1000, 1)
	if (response == nil) then
		return 2
	end
	local xml = parse_xml(response)
	if (xml:XPathValue( "/autnresponse/response" ) ~= "SUCCESS") then
		return 2
	end
	
	-- For each component, add warning if it is using more than 1GB
	local components = xml:XPathExecute( "/autnresponse/responsedata/component" )
	for i=0,components:size()-1 do
		local comp = components:at(i)
		local diskUsage = comp:attr("size"):value()/1024/1024
		if diskUsage > 1024 then
			service:addServiceStatus("Warning", comp:attr("name"):value().." uses "..string.format("%.0f", diskUsage).."MB of disk")
		end
	end
	return 0
end