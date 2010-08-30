class TempIdx < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX record_caption_title_idx ON records USING gin(to_tsvector('english', caption || ' ' || title));"
    ["caption || ' ' || pubmed_mh",
    "caption || ' ' ||  pubmed_mh_major",
    "caption || ' ' ||  metamap_mh",
    "caption || ' ' ||  pubmed_mh || ' ' ||  metamap_mh",
    "caption || ' ' ||  pubmed_mh_major || ' ' || metamap_mh",
    "caption || ' ' ||  title || ' ' ||  pubmed_mh",
    "caption || ' ' ||  title || ' ' ||  pubmed_mh_major",
    "caption || ' ' ||  title || ' ' ||  metamap_mh",
    "caption || ' ' ||  title || ' ' ||  pubmed_mh || ' ' ||  metamap_mh",
    "caption || ' ' ||  title || ' ' ||  pubmed_mh_major || ' ' ||  metamap_mh"].each do |c|
      puts "working on: #{c}"
      execute "CREATE INDEX record_#{c.split("|| ' ' ||").map(&:strip).join('_')}_idx ON records USING gin(to_tsvector('english', #{c}));"
    end    
    
  end

  def self.down
  end
end
