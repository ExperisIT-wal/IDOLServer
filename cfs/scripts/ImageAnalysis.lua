-- This script uses Image Server to analyse images and PDF files. Any
-- information discovered by the analysis will be added to the document
-- metadata. Other documents will be filtered by keyview as normal. 

-- These are the KeyView DocumentTypes that should be sent to Image Server for
-- analysis:
local supportedDocumentTypes = {
	["83"] = true, -- tiff
	["5"] = true, -- bmp
	["152"] = true, -- ico
	["153"] = true, -- cur
	["143"] = true, -- jpeg
	["230"] = true, -- pdf
	["238"] = true, -- png
	["333"] = true, ["334"] = true, -- pbm
	["335"] = true, ["336"] = true, -- pgm
	["337"] = true, ["338"] = true, -- ppm
	["26"] = true, ["27"] = true, -- gif
}

function imageServerSupportsTypeInDocument(document)
	local docType = document:getFieldValue("DocumentType");
	return supportedDocumentTypes[docType];
end

function handler(document)
	if imageServerSupportsTypeInDocument(document) then
		-- Send the file to Image Server for analysis.  This will throw
		-- on failure resulting in an error being logged and the
		-- document being filtered by KeyView as normal (provided no
		-- later tasks disable filtering).
		analyze_image_in_document(document, { section="ImageServerSettings" });

		-- If analysis was performed successfully, don't extract
		-- text using KeyView, just get the metadata.
		document:addField("AUTN_FILTER_META_ONLY", "");
	end
	return true;
end
