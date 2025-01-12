require 'nokogiri'
require 'time'
require 'yaml'

def convert_atom_to_rss(atom_file, rss_file, posts_dir, config_file)
  # Load _config.yml
  config = YAML.safe_load(File.read(config_file))
  baseurl = config['baseurl'] || ''
  url = config['url'] || ''

  # Parse the Atom feed
  atom_doc = Nokogiri::XML(File.read(atom_file))
  atom_namespace = { "atom" => "http://www.w3.org/2005/Atom" }

  # Create the RSS feed
  rss_doc = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
    xml.rss(:version => "2.0") do
      xml.channel do
        xml.title atom_doc.at_xpath('//atom:feed/atom:title', atom_namespace)&.content
        xml.link atom_doc.at_xpath('//atom:feed/atom:link[@rel="alternate"]/@href', atom_namespace)&.value
        xml.description atom_doc.at_xpath('//atom:feed/atom:subtitle', atom_namespace)&.content || "Generated RSS Feed"
        xml.pubDate Time.parse(atom_doc.at_xpath('//atom:feed/atom:updated', atom_namespace)&.content).rfc2822 rescue nil

        # Process each post
        Dir.glob("#{posts_dir}/*.md").each do |post_file|
          front_matter, _ = File.read(post_file).split(/^---$/, 3)[1, 2]
          post_metadata = YAML.safe_load(front_matter)

          teaser_relative_path = post_metadata.dig('header', 'teaser') || ''
          teaser_url = File.join(url, baseurl, teaser_relative_path) if !teaser_relative_path.empty?

          xml.item do
            xml.title post_metadata['title']
            xml.link "#{url}#{post_metadata['permalink']}"
            xml.description post_metadata['description'] || "No description available."
            xml.pubDate Time.parse(post_metadata['date']).rfc2822 rescue nil
            xml.guid "#{url}#{post_metadata['permalink']}"

            # Add the teaser tag
            if teaser_url
              xml.teaser teaser_url
            end
          end
        end
      end
    end
  end

  File.write(rss_file, rss_doc.to_xml)
  puts "RSS feed generated at #{rss_file}"
end

# Input and output file paths
atom_file = ARGV[0] || '_site/feed.xml'
rss_file = ARGV[1] || '_site/rss-feed.xml'
posts_dir = ARGV[2] || '_posts'
config_file = ARGV[3] || '_config.yml'

# Run the conversion
convert_atom_to_rss(atom_file, rss_file, posts_dir, config_file)
