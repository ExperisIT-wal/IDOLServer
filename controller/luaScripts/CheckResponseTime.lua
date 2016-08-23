function TaskMain(service)
	local t = os.clock()
	
	local response = send_aci_action(
		"localhost", --host name
		service:getPortNumber(), --port 
		"query", --action
		{text = "*", print = "all"}, --parameters
		5000, --timeout (ms)
		1 --retries
	)
	if (response == nil) then --didn't get response
		return 2
	elseif (string.find(response, "SUCCESS") == nil) then --got error in response
		return 2
	end
	
	t = os.clock() - t
	if (t >= 1) then --add warning if response took at least 1s
		service:addServiceStatus("Warning", "Query response time is "..string.format("%.2f", t).." seconds")
	end
	return 0
end