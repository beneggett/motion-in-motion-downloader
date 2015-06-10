require 'feedjira' # rss feed parser
require 'open-uri'
require 'dotenv'

# Load environment variables stored in .env
Dotenv.load
return "You must set your username and password in a .env file" unless ENV['USERNAME'] && ENV['PASSWORD']

# Connection setup
conn = Faraday.new(url: 'https://motioninmotion.tv/paid_feed.rss')
conn.basic_auth( ENV['USERNAME'], ENV['PASSWORD']) # Feed requires basic authentication
rss = conn.get.body # grab the rss
feed = Feedjira::Feed.parse rss # parse the rss into ruby hashes
episodes = feed.entries # grab the relevant episodes from the feed

# Check how many episodes are out there vs how many we have stored locally
Dir.mkdir 'episodes' unless File.exist?('episodes') # Make episodes directory if doesn't exist
my_files = Dir.glob("./episodes/**/*.mp4") # Grab All the mp4 files in the episodes directory
puts "There are #{episodes.count} episodes available, you have #{my_files.count}"
puts "I guess we have about #{episodes.count - my_files.count} episodes to get"

episodes.each do |episode| # Loop through and download each episode if you don't already have it.
  date = episode.published.strftime("%Y-%m-%d") # Find the episode date and put it in YYYY-MM-DD format
  name = "#{date} - #{episode.title.gsub('/', ' ')}.mp4" # Set the filename for the episode
  if existing = File.exist?("episodes/#{name}")   # Check to see if we have the episode
    # If we have it, compare file size to ensure we have a complete download, not a partial download
    file_size = Faraday.new(url: episode.enclosure_url).head.headers['content-length'].to_i
    actual_file = File.size("episodes/#{name}")
    if file_size == actual_file
      puts "#{name} - downloaded entirely already"
    else
      # Redownload the file
      # REPETITIVE
      puts "#{name} - was only partially downloaded. Redownloading."
      open("episodes/#{name}", 'wb') do |file|
        file << open(episode.enclosure_url).read
      end
      puts "#{name} - download completed!"
    end
  else
    # Download the file
    # REPETITIVE
    puts "#{name} - downloading"
    open("episodes/#{name}", 'wb') do |file|
      file << open(episode.enclosure_url).read # download and save the file
    end
    puts "#{name} - download completed!"
  end
end

puts "\n All Done! Go forth and learn some ruby motion!"
