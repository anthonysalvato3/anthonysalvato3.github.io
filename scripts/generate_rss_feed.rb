# scripts/generate_rss_feed.rb

require 'nokogiri'
require 'time'

def convert_atom_to_rss(atom_file, rss_file)
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
        xml.item do
          xml.title "Test Item Title"
          xml.link "https://example.com/test-item"
          xml.description "This is a test item added to the RSS feed."
          xml.pubDate Time.now.rfc2822
          xml.guid "https://example.com/test-item"
        end

        atom_doc.xpath('//atom:feed/atom:entry', atom_namespace).each do |entry|
          xml.item do
            xml.title entry.at_xpath('atom:title', atom_namespace)&.content
            xml.link entry.at_xpath('atom:link[@rel="alternate"]/@href', atom_namespace)&.value
            xml.description entry.at_xpath('atom:summary', atom_namespace)&.content || entry.at_xpath('atom:content', atom_namespace)&.content
            xml.pubDate Time.parse(entry.at_xpath('atom:published', atom_namespace)&.content).rfc2822 rescue nil
            xml.guid entry.at_xpath('atom:id', atom_namespace)&.content
          end
        end
      end
    end
  end

  File.write(rss_file, rss_doc.to_xml)
  puts "RSS feed generated at #{rss_file}"
end

atom_file = ARGV[0] || '_site/feed.xml'  # Default input
rss_file = ARGV[1] || '_site/rss-feed.xml'  # Default output
convert_atom_to_rss(atom_file, rss_file)
