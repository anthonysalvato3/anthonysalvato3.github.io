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

  rss_doc = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
    xml.rss(:version => "2.0") do
      xml.channel do
        xml.title atom_doc.at_xpath('//atom:feed/atom:title', atom_namespace)&.content
        xml.link atom_doc.at_xpath('//atom:feed/atom:link[@rel="alternate"]/@href', atom_namespace)&.value
        xml.description atom_doc.at_xpath('//atom:feed/atom:subtitle', atom_namespace)&.content || "Generated RSS Feed"
        xml.pubDate Time.parse(atom_doc.at_xpath('//atom:feed/atom:updated', atom_namespace)&.content).rfc2822 rescue nil

        # Add the test item at the top
          # xml.item do
          #   xml.title "Test Item Title"
          #   xml.link "https://example.com/test-item"
          #   xml.description "This is a test item added to the RSS feed."
          #   xml.pubDate Time.now.rfc2822
          #   xml.guid "https://example.com/test-item"
          # end

        # Process each Atom entry
        atom_doc.xpath('//atom:feed/atom:entry', atom_namespace).each do |entry|
          # Extract the permalink for the current entry
          post_permalink = entry.at_xpath('atom:link[@rel="alternate"]/@href', atom_namespace)&.value
          puts "Processing entry with permalink: #{post_permalink}"
          
          teaser_url = nil

          if post_permalink
            # Match the permalink against the front matter of posts
            post_file_path = Dir.glob("#{posts_dir}/*.markdown").find do |path|
              begin
                puts "Processing file: #{path}"
                file_content = File.read(path, encoding: 'utf-8')
                front_matter, _ = file_content.split(/^---$/, 3)[1, 2]
                puts "Front matter: #{front_matter}"
                post_metadata = YAML.safe_load(front_matter)

                # For test only
                # url = "http://localhost:4000"

                generated_permalink = File.join(url, baseurl, post_metadata['permalink'] || "/#{File.basename(path, '.markdown')}/")
                if generated_permalink == post_permalink
                  puts "Match found! #{generated_permalink} == #{post_permalink}"
                  true
                else
                  false
                end

              rescue StandardError => e
                puts "Error processing file #{path}: #{e.message}"
                next
              end
            end

            # Extract the teaser URL from the matched post
            puts "Post file path: #{post_file_path}"
            if post_file_path
              front_matter, _ = File.read(post_file_path).split(/^---$/, 3)[1, 2]
              post_metadata = YAML.safe_load(front_matter)
              teaser_relative_path = post_metadata.dig('header', 'teaser') || ''
              teaser_url = File.join(url, baseurl, teaser_relative_path) unless teaser_relative_path.empty?
            end
          end

          # Add the item to the RSS feed
          xml.item do
            xml.title entry.at_xpath('atom:title', atom_namespace)&.content
            xml.link post_permalink
            xml.description entry.at_xpath('atom:summary', atom_namespace)&.content || entry.at_xpath('atom:content', atom_namespace)&.content
            xml.pubDate Time.parse(entry.at_xpath('atom:published', atom_namespace)&.content).rfc2822 rescue nil
            xml.guid entry.at_xpath('atom:id', atom_namespace)&.content

            # Add the teaser tag if available
            xml.teaser teaser_url if teaser_url
          end
        end
      end
    end
  end

  File.write(rss_file, rss_doc.to_xml)
  puts "RSS feed generated at #{rss_file}"
end

# File paths
atom_file = ARGV[0] || '_site/feed.xml'  # Default Atom feed file
rss_file = ARGV[1] || '_site/rss-feed.xml'  # Output RSS file
posts_dir = ARGV[2] || 'raw_posts'  # Directory containing post files
config_file = ARGV[3] || '_config.yml'  # Jekyll configuration file

# Run the script
convert_atom_to_rss(atom_file, rss_file, posts_dir, config_file)
