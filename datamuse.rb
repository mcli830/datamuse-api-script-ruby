require 'rest-client'
require 'json'
require 'yaml'

OUTPUT_FILE = begin
  YAML.load_file('config.yml').fetch('output_file')
rescue Errno::ENOENT, KeyError
  '.'
end

def program_error
  puts "Please provide a chain of arguments: <command> <keyword> etc..."
  puts "> Commands: related, synonym, antonym, sound, describe, describe_by, rhyme, max, prefix, suffix, spelling, follow, precede, general, specific, comprise, part, topic, trigger, homophone"
  abort
end

program_error unless ARGV.length > 1

# data validation
args = ARGV
args.pop if args.length % 2 != 0

# setting up api endpoint
parameters = args.select.with_index do |val, index|
  index % 2 == 0
end
values = args.select.with_index do |val, index|
  index % 2 != 0
end

URL = 'https://api.datamuse.com/words'

queries = []

def build_query(command, keyword)
  case command
  when 'related'
    return "ml=#{keyword}"
  when 'synonym', 'syn'
    return "rel_syn=#{keyword}"
  when 'antonym', 'ant'
    return "rel_ant=#{keyword}"
  when 'sound'
    return "sl=#{keyword}"
  when 'describe'
    return "rel_jjb=#{keyword}"
  when 'describe_by'
    return "rel_jja=#{keyword}"
  when 'rhyme'
    return "rel_rhy=#{keyword}"
  when 'max'
    return "max=#{keyword}"
  when 'prefix'
    return "sp=#{keyword}*"
  when 'suffix'
    return "sp=*#{keyword}"
  when 'spelling'
    return "sp=#{keyword}"
  when 'follow'
    return "rel_bga=#{keyword}"
  when 'precede'
    return "rel_bgb=#{keyword}"
  when 'general', 'parent'
    return "rel_gen=#{keyword}"
  when 'specific', 'kind', 'kind_of'
    return "rel_spc=#{keyword}"
  when 'comprise'
    return "rel_com=#{keyword}"
  when 'part_of', 'part'
    return "rel_par=#{keyword}"
  when 'sort', 'topic'
    return "topics=#{keyword}"
  when 'trigger', 'associated'
    return "rel_trg=#{keyword}"
  when 'homophone'
    return "rel_hom=#{keyword}"
  else
    return ""
  end
end

parameters.each_with_index do |param, index|
  queries.push build_query(param, values[index])
end

endpoint = "#{URL}?#{queries.join('&')}"

# API call
print "Fetching #{endpoint}..."
response = RestClient.get endpoint
json = JSON.parse(response.body)
puts "Done"

data = json.map { |entry| entry["word"] }

# write data
print "Writing data to datamuse_output.json..."
File.open(OUTPUT_FILE, 'w') do |file|
  file.puts "[\n"
  data.each do |word|
    file.puts "  \"#{word}\",\n"
  end
  file.puts "]"
end
puts "Done"
