require 'umls'

class UmlsUtilities
  
  SEMANTIC_TYPE_WHITELIST = ['Disease or Syndrome', 'Neoplastic Process', 'Neoplasms', 'Neoplastic Process',
                              'Pathologic Function', 'Congenital Abnormality', 'Anatomical Abnormality', 
                              'Body Part, Organ, or Organ Component', 'Body Location or Region','Acquired Abnormality', 
                              'Diagnostic Procedure', 'Cell', 'Injury or Poisoning']


  
	def self.extractSemanticType(term)
		results=UMLSClient.find_semantic_types_by_query(term)
		if results.nil? or results.empty?
		  return nil
	  else
		  semanticType=results[0][:semantic_type]		  
		  return semanticType
	  end
	
	end

	def self.extractSemanticTypePhrase(phrase)
		#terms=phrase.split
		semanticType=[]
		#terms.each do |t|
			results=UMLSClient.find_semantic_types_by_query(t)
			semanticType << results[0][:semantic_type]
			return semanticType.uniq
		
		#end
	end
	
	def self.findSynonyms(phrase)
		
		terms=phrase.split
    synonyms=[]
		terms.each do |t|
        
        #conditions=['Disease or Syndrome', 'Neoplastic Process', 'Neoplasms', 'Pathologic Function', 'Congenital Abnormality', 'Anatomical Abnormality', 'Body Part, Organ, or Organ Component', 'Diagnostic Procedure']
        semType=extractSemanticType(t)
        if (not semType.nil?) and  (SEMANTIC_TYPE_WHITELIST.include? semType)
                  syn=UMLSClient.find_synonyms(t)[0][:preferred_term][:str].downcase
                  synonyms << syn
        end
    end         
    if synonyms.empty?
      return nil
    else
      return synonyms.uniq
    end  
  end
=begin

  def self.findSynonymsSdb(phrase)
    
    synonyms = []
    semType = extractSemanticType(phrase)
        
    if SEMANTIC_TYPE_WHITELIST.include? semType
      
      # will eventually gather all of the synonyms... for now, just finds the pref term.
      syn = UMLSClient.find_synonyms(phrase)[0]
      
      pref_term = syn[:preferred_term][:str].downcase
      
      synonyms << pref_term
      
    end
    
    return synonyms
    
  end
=end


def self.findSynonymsExtended(phrase)
		bestNgram=UmlsUtilities.findBestNgram(phrase) 
    synonyms=[]
   # r=/\(.*\)/
   syn=nil
    if not bestNgram.nil?
        
        syn=UMLSClient.find_synonyms(bestNgram)[0][:preferred_term][:str]
        
        #syn.each do |s|
          #  synonyms << s[:str].gsub(r,'').strip.downcase
          #end
          
     end 
      return syn
end


    def self.findSynonymsPhrase(p)
                 # conditions=['Disease or Syndrome', 'Neoplastic Process', 'Neoplasms', 'Pathologic Function', 'Congenital Abnormality', 'Anatomical Abnormality', 'Body Part, Organ, or Organ Component', 'Diagnostic Procedure']
                  semType=extractSemanticType(p)
                  synonyms=[]
                  if (not semType.nil?) and  (SEMANTIC_TYPE_WHITELIST.include? semType)
                      syn=UMLSClient.find_synonyms(p)[0][:preferred_term][:str].downcase
                      synonyms << syn
                  end
            
                if synonyms.empty?
                  return nil
                else
                  return synonyms.uniq
                end  
    end
              
    def self.findBestNgram(phrase) 
        terms=phrase.split
        arraySize=terms.size

        terms.each_with_index do |a,i|
          for j in 0..i
             newArray=terms[j..j+arraySize-i-1]
             bestNgram=newArray.join(' ')
             inUmls=UMLSClient.find_semantic_types_by_query(bestNgram)
             if not inUmls.empty?
                return bestNgram
            end
          end
          
        end
       
        return nil
      
    end  
    
    

end
