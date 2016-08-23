

--[[
In essence, all the indextasks catmodule truly contains is a configurable, wrapped call to IDOL Categorize's
CategorySuggestFromText action, followed by a configurable assignment of the return values from
that call into fields within the source document.
This can be replicated fairly easily in lua since you can write the categorysuggestfromtext call
any way you want to (since we already have a send_aci_action function), and then you can also insert
the results into your source document in any way you want.
Therefore, you actually have much more flexibility in setting up exactly the categorize call you want
than you did in catmodule.
There is a convenient glue function (parseCategories) included below which takes the raw xml string as
output from send_aci_action and converts it into a list of category-representing tables, so that the 
main contentsof the category response can be accessed more easily than doing your own xml parsing. 
It is provided purely for convenience, though, and nothing requires that you use it.
]]

--[[
Because this is just a call to CategorySuggestFromText, the user is recommended to the documentation for
that action, and it will not be entirely replicated here.
]]

--[[
Config parameters of the old indextasks catmodule, and how they can be replicated in the script below:


Configuring HOW to send the categorysuggestfromtext action:


Host
Port
	These parameters translate directly into the first two, required, parameters to the send_aci_action
	call, and therefore remain necessary. In the script below, they are statically defined at the top
	of the categorize() function.
	
Timeout
	This parameter specified, in seconds, the length of time for which catmodule would wait for the
	categorysuggestontext action to return. If the timeout was reached without a response, the task
	would fail. This, also, translates directly into a parameter to send_aci_action.
	NOTE: The timeout parameter to send_aci_action is in *milliseconds* rather than in seconds, and it
	defaults to just *three seconds*, which is a lot less than the default for catmodule (60 seconds).
	
SSLConfig
	Again, this config parameter is translated directly into a parameter to the send_aci_action
	call. The SSL parameters are provided to the lua function as a string map rather than by the name
	of a config section, but the names of the parameters and their expected values are the same as they
	would be in any config, including the old catmodule config. This is included in the example below.
	
	

Configuring WHAT to send to the categorysuggestfromtext action:
	

Params
Values
	These two config parameters defined, between them, a set of additional name/value pairs that would
	be passed verbatim to the categorysuggestontext action. They can therefore be replicated easily by
	adding any additional parameters you desire to the main send_aci_action call in the categorize() function.
	
TextFields
TextParse
	These two parameters, between them, defined what the content of the QueryText parameter, which is
	where the actual text that will be used for suggestion is passed, would be. TextFields would pass the
	content of each named field into QueryText, whereas setting TextParse would instead send the entire
	document in idx form. These can be replicated, therefore, by setting QueryText directly, to something
	like "QueryText = document:to_idx()" or "QueryText = document:getFieldValue("MyField1") + " " + 
	document:getFieldValue("DRETITLE"). The first option is therefore clearly the simpler to use, except
	when you are trying to explicitly ignore some field content for the purpose of categorization.
	
Limit
	This config parameter claimed to restrict how many categories were considered when adding the resultant
	category information to the document. I am not currently convinced that it previously worked, but whether
	it did or not the obvious way to replicate this functionality is to pass the NumResults parameter
	to categorysuggestfromtext. 
	Per the documentation for that action, the default for NumResults is 6.

BooleanFields
	This parameter (as well as the rather less-documented NumericRangeFields) was used to build the FieldText
	parameter sent to the categorysuggestfromtext action. They created things like
	"BOOLEANFIELD{MyField1}:MyFieldName AND EQUAL{1000}:MyNumericFieldName. These match expressions are
	strange and convoluted but quite a lot more powerful than was exposed within the catmodule configuration
	interface, and I must therefore once again recommend referring directly to the IDOL documentation for
	the categorysuggestfromtext action.
	


Configuring what to do with the RESPONSE from the categorysuggestfromtext action:


AllowDuplicateFields
Separators
TagField
TagXMLPath
	All of these parameters were used to define which of the category details are inserted into the document
	and into which fields and in what format they were presented. Since now you have direct access to all of
	the information that was returned, all of the functionality available through these parameters (and more)
	is possible by simple uses of the lua document object interface to insert appropriate field data.




IDOLServer
StemAndUnstem
WarpFields
WildcardFallback
	These fields all appear to be years-obsolete compatibility features even in catmodule itself, so unless
	they turn out to be a lot more important than they look I do not propose to attempt to explain how to
	duplicate the functionality here. WarpFields, in particular, I do not think I understand well enough
	to do so.

]]








function parseCategories(categoryOutputString)
	
	local all_categories = {}

	local luaXmlDoc = parse_xml(categoryOutputString)
	luaXmlDoc:XPathRegisterNs("autn", "http://schemas.autonomy.com/aci/")
	local hitNodes = luaXmlDoc:XPathExecute("/autnresponse/responsedata/autn:hit")

	local ii = 0
	while ii < hitNodes:size() do

		--I am not currently sure exactly what this category detail returned can contain, and so I've chosen
		--to read all values into a table rather than only specific ones. The example I am working from,
		--retrieved from a real categorysuggestfromtext call, is below.
		
		local this_category = {}
		
		local hitNode = hitNodes:at(ii)
		local detail = hitNode:firstChild()

		while(detail) do

			if detail:type() ~= "text_node" then
				this_category[detail:name()] = detail:content()
			end
			
			detail = detail:next()
		end
		
		table.insert(all_categories, this_category)
		ii = ii + 1
	end
	
	return all_categories
end

--[[
<?xml version='1.0' encoding='UTF-8' ?>
<autnresponse xmlns:autn='http://schemas.autonomy.com/aci/'>
	<action>CATEGORYSUGGESTFROMTEXT</action>
	<response>SUCCESS</response>
	<responsedata>
		<autn:numhits>1</autn:numhits>
		<autn:hit>
			<autn:reference>732789079453328147</autn:reference>
			<autn:id>732789079453328147</autn:id>
			<autn:weight>99.60</autn:weight>
			<autn:links>CAT</autn:links>
			<autn:title>Cats</autn:title>
		</autn:hit>
	</responsedata>
</autnresponse>
]]




function categorize(document)
	local idolCategorizeHost = "localhost"
	local idolCategorizePort = 9020
	local categorySuggestFromTextParameters =
		{
			QueryText = document:to_idx(),
			TextParse = "true"
		}
	local timeoutMilliseconds = 60000
	local retries = 3
	local sslParameters =
		{
			SSLMethod = "SSLV23",
			--SSLCertificate = "host1.crt",
			--SSLPrivateKey = "host1.key",
			--SSLCACertificate = "trusted.crt"
		}


	local output = send_aci_action(
		idolCategorizeHost,
		idolCategorizePort,
		"categorysuggestfromtext",
		categorySuggestFromTextParameters,
		timeoutMilliseconds,
		retries,
		sslParameters
		)
	if(output) then
		local suggestWasSuccessful = regex_search(output, "<response>SUCCESS</response")

		if(suggestWasSuccessful) then
			local suggestedCategories = parseCategories(output)

			for i, category in ipairs(suggestedCategories) do
				document:addField("category_title", category["title"])
				document:addField("category_reference", category["reference"])
				document:addField("category_id", category["id"])
			end

			document:setFieldValue("result", output)

			return true
		end
	end
	return false
end


function handler(document)
	return categorize(document)
end
		
