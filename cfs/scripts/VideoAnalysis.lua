-- This script uses Video Server to analyse audio and video files. Any
-- information discovered by the analysis will be added to the document
-- metadata. Other documents will be filtered by keyview as normal. 

-- These are the KeyView DocumentClasses that should be sent to Video Server for
-- analysis:
local supportedDocumentClasses = {
	["9"] = true, -- adSOUND
	["20"] = true -- adMOVIE
}

local supportedExtensions = {
	[".ts"] = true, -- MPEG transport stream
	[".m2ts"] = true -- MPEG-2 transport stream
}

function GetFileExtension(filename)
  return filename:match("%.[^./]+$")
end

function videoServerSupportsTypeInDocument(document)
	if(document:hasField("DocumentClass")) then
		-- Keyview recognized the file type, check the document
		-- class to see if the filetype is supported
		local docType = document:getFieldValue("DocumentClass");
		return supportedDocumentClasses[docType];
	else
		-- If keyview does not recognize the file type, check
		-- the extension to see if the filetype is supported.
		local filename = get_filename(document);

		if(filename ~= nil and filename ~= '') then
			local extension = GetFileExtension(filename);
			return supportedExtensions[extension];
		end
	end
end

function handler(document)
	if videoServerSupportsTypeInDocument(document) then
		-- Send the file to Video Server for analysis.  This will throw
		-- on failure resulting in an error being logged and the
		-- document being filtered by KeyView as normal (provided no
		-- later tasks disable filtering).
		analyze_video_in_document(document, { section="VideoServerSettings" });

		-- If analysis was performed successfully, don't extract
		-- text using KeyView, just get the metadata.
		document:addField("AUTN_FILTER_META_ONLY", "");
	end
	return true;
end
