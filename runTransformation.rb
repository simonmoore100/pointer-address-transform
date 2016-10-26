require 'rubygems'
require 'fileutils'
require 'csv'
require 'pathname'
require 'time'

# Various default file names and paths

input_file_name = ENV["ALLNI_20161006_F.csv"] || "ALLNI_20161006_F.csv"
temp_file_1 = ENV["temp_file_1.csv"] || "temp_file_1.csv"
temp_file_2 = ENV["temp_file_2.csv"] || "temp_file_2.csv"
output_file_name = ENV["ni_address_data.json"] || "ni_address_data.json"
template_with_property_file_name = ENV["templateWithPropertyField.txt"] || "templateWithPropertyField.txt"
template_without_property_file_name = ENV["templateWithoutPropertyField.txt"] || "templateWithoutPropertyField.txt"
input_file_path = Pathname.new("./input_file")
output_file_path = Pathname.new("./output_file")
template_file_path = Pathname.new("./templates")

# NI specific json variables for template substitution

niGSSCode = ENV["N07000001"] || "N07000001"
niCountry = ENV["Northern Ireland"] || "Northern Ireland"
niUPRN = ENV["0"] || "0"
lat = ENV["1.1"] || "1.1"
long = ENV["0"] || "0"
buildingClassification = ENV["RD"] || "RD"
buildingStatus = ENV["inUse"] || "inUse"
buildingState = ENV["approved"] || "approved"
primaryClassification = ENV["Residential"] || "Residential"
secondaryClassification = ENV["Dwelling"] || "Dwelling"

# json template locations for mongo import

templateWithPropertyField = File.open(template_file_path + template_with_property_file_name, "rb")
templateWithPropertyFieldContents = templateWithPropertyField.read
templateWithoutPropertyField = File.open(template_file_path + template_without_property_file_name, "rb")
templateWithoutPropertyFieldContents = templateWithoutPropertyField.read

# Arrays to transport data into the final file

subBuildingName= Array.new
buildingName= Array.new
buildingNumber= Array.new
primaryThorfare= Array.new
locality= Array.new
town= Array.new
county= Array.new
postcode= Array.new
uprn = Array.new
classification= Array.new
usrn= Array.new

# open the output file

output_file = File.open(output_file_path + output_file_name, "wb")


begin
	start = Time.now
	puts "Begin"
	puts "Checking if input file exists"

	if File.exists?(input_file_path + input_file_name.to_s)

		puts "Input file exists"
		puts "Creating temp file 1"

		# We are only interested in certain columns from the input file.
		# These are then inserted into a new csv to manipulate further.

		COLUMNS = ['SUB_BUILDING_NAME','BUILDING_NAME','BUILDING_NUMBER','PRIMARY_THORFARE','LOCALITY','TOWN','COUNTY','POSTCODE','UPRN','CLASSIFICATION', 'USRN']
		
		counter= 0

		CSV.open(temp_file_1, "wb") do |csv|
  			CSV.foreach(input_file_path + input_file_name, :headers=>true, :encoding=>"ISO8859-1") do |row|
    			csv << COLUMNS.map { |col| row[col] }
				counter = counter + 1
				puts counter
  			end
		end

		puts "Temp file 1 created and populated"

		# Now that we have have the correct columns in a specific order
		# we can process the data a bit more.

		puts "Creating arrays of data to send to temp file 2"
		
		counter2 = 0

		if File.exists?(temp_file_1.to_s)

			CSV.open(temp_file_2, "wb") do |csv|
				CSV.foreach(temp_file_1, :headers=>true, :encoding=>"ISO8859-1") do |row|
					subBuildingName << row[0]
					buildingName << row[1]
					buildingNumber << row[2]
					primaryThorfare << row[3]
					locality << row[4]
					town << row[5]
					county << row[6]
					postcode << row[7]
					uprn << row[8]
					classification << row[9]
					usrn << row[10]
					
					counter2 = counter2 + 1
					puts counter2
				end
			end

			puts "Temp file 2 created"
			puts "Array processing complete"
			puts "Beginning json creation"

			# Insert the first row into the output file to be used as a test address
			output_file.puts 	templateWithPropertyFieldContents % {postcode1:"bt12ab", 
																	gssCode:niGSSCode,
																	country:niCountry,
																	uprn:"%011d" % niUPRN,
																	createdAt:"ISODate()",
																	property:"niproperty",
																	street:"nistreet",
																	locality:"nilocality",
																	town:"nitown",
																	area:"niarea",
																	postcode2:"BT1 2AB",
																	lat:lat,
																	long:long,
																	blpuCreatedAt:"ISODate()",
																	blpuUpdatedAt:"ISODate()",
																	classification:buildingClassification,
																	status:buildingStatus,
																	state:buildingState,
																	isPostalAddress:true,
																	isCommercial:false,
																	isResidential:true,
																	isHigherEducational:false,
																	isElectoral:true,
																	usrn:"1234",
																	file:input_file_name,
																	primaryClassification:primaryClassification,
																	secondaryClassification:secondaryClassification,
																	saoText:"property"} 

			# Continue inserting the rest of the rows
			
			counter3 = 0

			subBuildingName.zip(buildingName, buildingNumber, primaryThorfare, locality, town, county, postcode, uprn, classification, usrn).each do |subBuildingName, buildingName, buildingNumber, primaryThorfare, locality, town, county, postcode, uprn, classification, usrn|
				
				# We only want residential classifications (DO_) and addresses 
				# with a postcode so we can filter the rest out here. After that 
				# we write the mongo json to file

				if classification.to_s.start_with?("DO_") && postcode.to_s != ''
					property = subBuildingName.to_s + " " + buildingName.to_s
					street = buildingNumber.to_s + " " + primaryThorfare.to_s
					postcode1 = postcode.delete(' ').downcase
					postcode2 = postcode
					
					if property.to_s != ''
						property = property.split.map(&:capitalize).join(' ')
					end
					
					if street.to_s != ''
						street = street.split.map(&:capitalize).join(' ')
					end
					
					if locality.to_s != ''
						locality = locality.split.map(&:capitalize).join(' ')
					end
					
					if town.to_s != ''
						town = town.split.map(&:capitalize).join(' ')
					end
					
					if county.to_s != ''
						county = county.split.map(&:capitalize).join(' ')
					end
					
					counter3 = counter3 + 1
					puts counter3

					if property != " "
					
						output_file.puts 	templateWithPropertyFieldContents % {postcode1:postcode1, 
																				gssCode:niGSSCode,
																				country:niCountry,
																				uprn:uprn,
																				createdAt:"ISODate()",
																				property:property,
																				street:street,
																				locality:locality,
																				town:town,
																				area:county,
																				postcode2:postcode2,
																				lat:lat,
																				long:long,
																				blpuCreatedAt:"ISODate()",
																				blpuUpdatedAt:"ISODate()",
																				classification:buildingClassification,
																				status:buildingStatus,
																				state:buildingState,
																				isPostalAddress:true,
																				isCommercial:false,
																				isResidential:true,
																				isHigherEducational:false,
																				isElectoral:true,
																				usrn:usrn,
																				file:input_file_name,
																				primaryClassification:primaryClassification,
																				secondaryClassification:secondaryClassification,
																				saoText:"property"} 

					else

						output_file.puts 	templateWithoutPropertyFieldContents % 	{postcode1:postcode1,
																					gssCode:niGSSCode,
																					country:niCountry,
																					uprn:uprn,
																					createdAt:"ISODate()",
																					street:street,
																					locality:locality,
																					town:town,
																					area:county,
																					postcode2:postcode2,
																					lat:lat,
																					long:long,
																					blpuCreatedAt:"ISODate()",
																					blpuUpdatedAt:"ISODate()",
																					classification:buildingClassification,
																					status:buildingStatus,
																					state:buildingState,
																					isPostalAddress:true,
																					isCommercial:false,
																					isResidential:true,
																					isHigherEducational:false,
																					isElectoral:true,
																					usrn:usrn,
																					file:input_file_name,
																					primaryClassification:primaryClassification,
																					secondaryClassification:secondaryClassification,
																					saoText:"property"} 

					end
				end

			end
		end
	end
ensure

	# Close and delete the files as a final clean up task

	templateWithPropertyField.close
	templateWithoutPropertyField.close
	output_file.close
	puts "Json creation finished"
	File.delete(temp_file_1)
	puts "Temp file 1 deleted"
	File.delete(temp_file_2)
	puts "Temp file 2 deleted"
	finish = Time.now
	diff = finish - start
	puts "Processing complete in " + diff.to_s + " seconds"
end