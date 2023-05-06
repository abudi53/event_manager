require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
    legislator_names = legislators.map(&:name)
    legislator_names.join(', ')
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

def puts_content(content)
  contents.each do |row|
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)

    puts "#{name} #{zipcode} #{legislators}"
  end
end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

def content_sub(content, template_letter)
  name = content[:first_name]
  zipcode = clean_zipcode(content[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = template_letter.result(binding)
  form_letter
end

contents.each do |row|
  puts content_sub(row, erb_template)
end
