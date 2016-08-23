function TaskMain(service)
	local response = send_aci_action("localhost", service:getPortNumber(), "memoryreport", {}, 1000, 1)
	if (response == nil) then
		return 2
	end
	local xml = parse_xml(response)
	if (xml:XPathValue( "/autnresponse/response" ) ~= "SUCCESS") then
		return 2
	end
	
	-- Adding warnings if more than 90% of memory is used
	local totalMemory = xml:XPathValue( "/autnresponse/responsedata/systemmemoryinfo/total_physical_mem_mb" )
	local freeMemory = xml:XPathValue( "/autnresponse/responsedata/systemmemoryinfo/free_physical_mem_mb" )
	local freeMemoryPercent = freeMemory/totalMemory*100
	if (freeMemoryPercent < 10) then
		service:addServiceStatus("Warning", string.format("Only %.1f%% of memory is free", freeMemoryPercent))
	end
	local totalPagingFileMb = xml:XPathValue( "/autnresponse/responsedata/systemmemoryinfo/total_paging_file_mb" )
	local freePagingFileMb = xml:XPathValue( "/autnresponse/responsedata/systemmemoryinfo/free_paging_file_mb" )
	local freePagingFilePercent = freePagingFileMb/totalPagingFileMb*100
	if (freePagingFilePercent < 10) then
		service:addServiceStatus("Warning", string.format("Only %.1f%% of paging file is free", freePagingFilePercent))
	end
	
	-- Adding warnings if this service is using more than 30% of memory
	local processWorkingSet = xml:XPathValue( "/autnresponse/responsedata/processmemoryinfo/workingset_kb" )/1024
	local processVirtualMem = xml:XPathValue( "/autnresponse/responsedata/processmemoryinfo/virtualmem_kb" )/1024
	local processWorkingSetPeak = xml:XPathValue( "/autnresponse/responsedata/processmemoryinfo/peakworkingset_kb" )/1024
	local processVirtualMemPeak = xml:XPathValue( "/autnresponse/responsedata/processmemoryinfo/peakvirtualmem_kb" )/1024
	if (processWorkingSet > totalMemory*0.3) then
		service:addServiceStatus("Warning", string.format("Process is using %.1f MB (%.1f%%) of physical memory", processWorkingSet, processWorkingSet/totalMemory*100))
	end
	if (processVirtualMem > (totalMemory+totalPagingFileMb)*0.3) then
		service:addServiceStatus("Warning", string.format("Process is using %.1f MB (%.1f%%) of virtual memory", processVirtualMem, processVirtualMem/(totalMemory+totalPagingFileMb)*100))
	end
	
	-- Reporting memory usage peaks
	if (processWorkingSet == processWorkingSetPeak) then
		service:addServiceStatus("Info", string.format("Process working set is currently at the peak (%.1fMB)", processWorkingSet))
	end
	if (processVirtualMem == processVirtualMemPeak) then
		service:addServiceStatus("Info", string.format("Process virtual memory is currently at the peak (%.1fMB)", processVirtualMem))
	end
	
	return 0
end