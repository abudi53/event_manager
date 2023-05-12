# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

# def puts_content(content)
#   contents.each do |row|
#     name = row[:first_name]
#     zipcode = clean_zipcode(row[:zipcode])
#     legislators = legislators_by_zipcode(zipcode)

#     puts "#{name} #{zipcode} #{legislators}"
#   end
# end

def content_sub(row, template_letter)
  # Substitutes the content of the csv file into the template letter
  # the row is the selected row from the csv file

  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = template_letter.result(binding)

  save_thank_you_letters(id, form_letter)
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  # If the phone number is less than 10 digits, assume that it is a bad number
  # If the phone number is 10 digits, assume that it is good
  # If the phone number is 11 digits and the first number is 1, trim the 1 and use the remaining 10 digits
  # If the phone number is 11 digits and the first number is not 1, then it is a bad number
  # If the phone number is more than 11 digits, assume that it is a bad number

  phone_number = phone_number.to_s.gsub(/\D/, '')
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == '1'
    phone_number[1..]
  else
    'Bad number'
  end
end

def puts_phone_number(contents)
  contents.each do |row|
    name = row[:first_name]
    phone_number = clean_phone_number(row[:homephone])

    puts "#{name} #{phone_number}"
  end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
    legislator_names = legislators.map(&:name)
    legislator_names.join(', ')
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

puts 'EventManager initialized.'

def save_thank_you_letters(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts(form_letter)
  end
end

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

# contents.each do |row|
#   puts content_sub(row, erb_template)
# end

puts_phone_number(contents)
