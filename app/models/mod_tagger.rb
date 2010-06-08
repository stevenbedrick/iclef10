class ModTagger
	
	def self.regExCreate(term)
		r=Regexp.compile("\\b" +"#{term}" +"\\b", Regexp::IGNORECASE)
		return r
	end
	
	def self.modExtractor(caption)
	
		  modality=[]
		  graphic=['graphic', 'plot', 'schematic', 'diagram', 'scatterplot', 'spectra', 'illustration', 'graph', 'drawing', 'graphs', 'drawings', 'scatterplots', 'scattergram', 'chart', 'Kaplan']
		  us=['sonogram', 'US', 'Doppler', 'sonography', 'ultrasound','echogenic']
		  xray=['x-ray', 'radiograph', 'xray', 'barium enema', 'sbft', 'radiography', 'mammogram', 'mammograms', 'mammography', 'fluoroscopic', 'radiographs', 'cystourethrogram ']
		  nuc=['SPECT', 'scintigraphy', 'scintigraph', 'Technetium-99m', 'Technetium', 'bone scan', 'scintigraphies', 'thallium-201', 'Tc-99m', 'lymphangioscintigram' ]
		  photo=['photograph', 'photo', 'pathologic', 'photographs', 'gross pathology', 'pathologies']
      micro=['photomicrograph', 'microscopic', 'photomicrographs', 'micrograph', 'micrographs']
		  endo=['endoscope', 'endoscopic', 'CE', 'endoscopy', 'colonoscopy']
		  mr= ['MR', 'T1', 'T2', 'MRI', 'spin-echo']
		  ct =['CT', 'CTAP', 'CTAH', 'colonography']
		  
      ct.each do |c|  
          cta=regExCreate(c)
          if caption =~cta
              mod='CT'
              modality << mod
          end     
      end
			
		  mr.each do |m|   
        mR=regExCreate(m)	
		  	if caption =~mR
          mod='MRI'
           modality << mod
			   end
		  end  
			 
		  pet=regExCreate('PET')
		  if caption =~pet
			  mod='PET'
			  modality << mod
		  end  
		  
		  us.each do |u|   
        uS=regExCreate(u)
        if caption =~uS
            mod='US'
            modality << mod
        end    
		  end   
			 
			
		   graphic.each do |g|   
          gr=regExCreate(g)
          if caption =~gr
            mod='graphic'
            modality << mod
           end    
		   end   
		   
		   xray.each do |x|   
			  xr=regExCreate(x)
			  if caption =~xr
           mod='X-ray'
           modality << mod
			   end    
		   end   
	
		  nuc.each do |n|   
          nm=regExCreate(n)
          if caption =~nm
              mod='nuc med'
              modality << mod
          end    
		   end   
		   
			
		  photo.each do |p|   
        ph=regExCreate(p)
          if caption =~ph
             mod='photo'
             modality << mod
         end    
		   end   
		   
		   
      micro.each do |m|  
        mic=regExCreate(m)
        if caption =~mic
            mod='micro'
            modality << mod
        end    
      end
		  
		  endo.each do |e|  
		   endsc=regExCreate(e)
			if caption =~endsc
				mod='endoscopy'
				modality << mod
			end       
		end

		  return modality.uniq

	end
	
end
