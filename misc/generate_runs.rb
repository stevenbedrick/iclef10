###- high recall: mm, pm (all), expansion (all)
###- mm, pm (major), modality (jaykc), expansion (all)
###- mm, pm (major), modality (all), expansion (all)
###- mm, pm (major), modality (all), reordered, expansion (all) <--- should be same as high recall, but with higher MAP
###- mm, pm (major), modality (jaykc), reordered, expansion (all)
###- mm mh, modality (all), expansion (all)
###- pm mh (all), modality (all), expansion (all)
###- pm mh (major), modality (all), expansion (all)
###- mm mh, pm mh (major), modality (all), expansion (all)
###


runs = [
  {
    'parseMode' => 'custom',
    'outOp' => 'trec',
    'uploadFile' => 'uplF',
    'uf_format' => 'xml',
    'umlsSynonym' => 'umSy',
    'mm_mh' => 't',
    'pm_mh' => 't',
    'pm_major' => 'f',
    'topicSetName' => 'OHSU_high_recall'
  },
  {
    'parseMode' => 'custom',
    'outOp' => 'trec',
    'uploadFile' => 'uplF',
    'uf_format' => 'xml',
    'umlsSynonym' => 'umSy',
    'mm_mh' => 't',
    'pm_mh' => 't',
    'pm_major' => 't',
    'limitModality' => 'lm',
    'modColumn' => 'jaykc',
    'topicSetName' => 'OHSU_all_mh_major_jaykc_mod'
  },
  {
    'parseMode' => 'custom',
    'outOp' => 'trec',
    'uploadFile' => 'uplF',
    'uf_format' => 'xml',
    'umlsSynonym' => 'umSy',
    'mm_mh' => 't',
    'pm_mh' => 't',
    'pm_major' => 't',
    'limitModality' => 'lm',
    'modColumn' => 'all',
    'topicSetName' => 'OHSU_all_mh_major_all_mod'
  },
  {
    'parseMode' => 'custom',
    'outOp' => 'trec',
    'uploadFile' => 'uplF',
    'uf_format' => 'xml',
    'umlsSynonym' => 'umSy',
    'mm_mh' => 't',
    'pm_mh' => 't',
    'pm_major' => 't',
    'limitModality' => 'lm',
    'modColumn' => 'all',
    'reorder' => 't',
    'topicSetName' => 'OHSU_all_mh_major_all_mod_reorder'
  },
  {
    'parseMode' => 'custom',
    'outOp' => 'trec',
    'uploadFile' => 'uplF',
    'uf_format' => 'xml',
    'umlsSynonym' => 'umSy',
    'mm_mh' => 't',
    'pm_mh' => 't',
    'pm_major' => 't',
    'limitModality' => 'lm',
    'modColumn' => 'jaykc',
    'reorder' => 't',
    'topicSetName' => 'OHSU_all_mh_major_jaykc_mod_reorder'
  },
  {
    'parseMode' => 'custom',
    'outOp' => 'trec',
    'uploadFile' => 'uplF',
    'uf_format' => 'xml',
    'umlsSynonym' => 'umSy',
    'mm_mh' => 't',
    'limitModality' => 'lm',
    'modColumn' => 'all',
    'topicSetName' => 'OHSU_mm_all_mod'
  },  
  {
    'parseMode' => 'custom',
    'outOp' => 'trec',
    'uploadFile' => 'uplF',
    'uf_format' => 'xml',
    'umlsSynonym' => 'umSy',
    'pm_mh' => 't',
    'limitModality' => 'lm',
    'modColumn' => 'all',
    'topicSetName' => 'OHSU_pm_all_all_mod'
  },
  {
    'parseMode' => 'custom',
    'outOp' => 'trec',
    'uploadFile' => 'uplF',
    'uf_format' => 'xml',
    'umlsSynonym' => 'umSy',
    'pm_mh' => 't',
    'pm_major' => 't',
    'limitModality' => 'lm',
    'modColumn' => 'all',
    'topicSetName' => 'OHSU_pm_major_all_mod'
  },
]

runs = [
  {
    'parseMode' => 'custom',
    'outOp' => 'trec',
    'uploadFile' => 'uplF',
    'uf_format' => 'xml',
    'umlsSynonym' => 'umSy',
    'pm_mh' => 't',
    'pm_major' => 'f',
    'titleOp' => 't',
    'topicSetName' => 'OHSU_high_recall_with_titles'
  },
  {
    'parseMode' => 'custom',
    'outOp' => 'trec',
    'uploadFile' => 'uplF',
    'uf_format' => 'xml',
    'umlsSynonym' => 'umSy',
    'pm_mh' => 't',
    'pm_major' => 'f',
    'limitModality' => 'lm',
    'modColumn' => 'all',
    'reorder' => 't',
    'titleOp' => 't',
    'topicSetName' => 'OHSU_high_recall_with_titles_modality_reorder'
  }

]


puts "there are #{runs.size} runs to make:"

runs.each do |post_opts|
  puts "\t#{post_opts['topicSetName']}"
  flags = post_opts.map { |k,v| "-F #{k}=#{v}"}
  flags << "-F file=@../ad_hoc_topics.xml"

  url = 'http://localhost:3000/search/search'

  cmd = "curl " + flags.join(' ') + ' -o ' + post_opts['topicSetName'] + '.txt ' + url

  puts cmd
  res = `#{cmd}`
end


=begin

@limitModality=(params['limitModality']) # do we try and guess the modality from the query?
@modColumn = params[:mod_column] # which modality column to use? allowed vals: :title, :caption, :caption_title, :jaykc, :all
@umlsSynonym=(params['umlsSynonym']) # use UMLS query expansion?
@columnOp=(params['columnOp']) # which caption column to use?
@titleOp=(params['titleOp']) # include titles, or just captions?
@umls = params[:umlsSynonym]
@stem_and_star = params[:stem_and_star] # stem and wildcard query terms?
@unique = params[:unique_term] # only include unique terms after stemming/expansion?
@parse_mode = params[:parseMode]

# include mesh?
@inc_mm_mh = params[:mm_mh]
@inc_pm_mh = params[:pm_mh]
@pm_major = params[:pm_major]

=end