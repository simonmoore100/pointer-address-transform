require 'rubygems'
require 'fileutils'
require 'csv'
require 'pathname'
require 'time'

# Various default file names and paths

input_file_name = ENV["ALLNI_20161006_F_2.csv"] || "ALLNI_20161006_F_2.csv"
output_file_name = ENV["ni_postcode_to_authority_data.json"] || "ni_postcode_to_authority_data.json"
template_postcode_to_authority = ENV["templatePostcodeToAuthority.txt"] || "templatePostcodeToAuthority.txt"
input_file_path = Pathname.new("./input_file")
output_file_path = Pathname.new("./output_file")
template_file_path = Pathname.new("./templates")

# NI specific json variables for template substitution

niGSSCode = ENV["N07000001"] || "N07000001"
niCountry = ENV["Northern Ireland"] || "Northern Ireland"
lat = ENV["1.1"] || "1.1"
long = ENV["0"] || "0"
easting = ENV["1.1"] || "1.1"
northing = ENV["0"] || "0"
nhsHealthAuthority = ENV["nhsHealthAuthority"] || "nhsHealthAuthority"
ward = ENV["ward"] || "ward"

# json template locations for mongo import

templatePostcodeToAuthority = File.open(template_file_path + template_postcode_to_authority, "rb")
templatePostcodeToAuthorityContents = templatePostcodeToAuthority.read

# Arrays to transport data into the final file

postcode= Array.new

# open the output file

output_file = File.open(output_file_path + output_file_name, "wb")


begin
	start = Time.now
	puts "Begin"
	puts "Checking if input file exists"

	if File.exists?(input_file_path + input_file_name.to_s)

		puts "Input file exists"
		puts "Begin processing"

		counter2 = 0

				CSV.foreach(input_file_path + input_file_name.to_s, :headers=>true, :encoding=>"ISO8859-1") do |row|
					postcode << row[0]
					counter2 = counter2 + 1
					puts counter2
				end

			puts "Array processing complete from input file"
			puts "Beginning json creation"

			# Insert the first row into the output file to be used as a test address
			output_file.puts 	templatePostcodeToAuthorityContents % {postcode1:"bt12ab", 
																	country:niCountry,
																	gssCode:niGSSCode,
																	name:niCountry,
																	easting:easting,
																	northing:northing,
																	lat:lat,
																	long:long,
																	nhsHealthAuthority:"E99999999",
																	ward:"E99999999"} 
			

			# Continue inserting the rest of the rows
			
			counter3 = 0

			postcode.each do |postcode|
				

				postcode1 = postcode.delete(' ').downcase
					
					counter3 = counter3 + 1
					puts counter3

					output_file.puts 	templatePostcodeToAuthorityContents % {postcode1:postcode1, 
																	country:niCountry,
																	gssCode:niGSSCode,
																	name:niCountry,
																	easting:easting,
																	northing:northing,
																	lat:lat,
																	long:long,
																	nhsHealthAuthority:niGSSCode,
																	ward:niGSSCode} 


		end
	end
ensure

	# Close and delete the files as a final clean up task

	templatePostcodeToAuthority.close
	output_file.close
	puts "Json creation finished"
	finish = Time.now
	diff = finish - start
	puts "Processing complete in " + diff.to_s + " seconds"
end