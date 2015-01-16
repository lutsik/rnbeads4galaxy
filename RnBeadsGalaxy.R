#msg.file<-file("RnBeads.messages.out", open="w")
#sink(file=msg.file)


## add the RnBeads dependencies if we are on a cloud share-instance
if("Rsitelibrary" %in% list.files("/mnt")){
	.libPaths("/mnt/galaxy/Rsitelibrary")
}

if(!'wordcloud' %in% rownames(installed.packages())){
	install.packages('wordcloud',repos='http://cran.us.r-project.org')	
}

suppressWarnings(suppressPackageStartupMessages(library(RnBeads)))
suppressWarnings(suppressPackageStartupMessages(library(getopt)))


fname <- system.file(file.path("extdata", "options.txt"), package = "RnBeads")
table.options <- read.delim(fname, quote = "", stringsAsFactors = FALSE)
rownames(table.options) <- table.options[, "Name"]

all.opts<-table.options$Name
#all.opts<-names(rnb.options())
#opt.class<-RnBeads:::OPTION.TYPES[-28]
opt.class<-table.options$Type
names(opt.class)<-all.opts
#all.opts<-names(opt.class)
#all.opts<-paste("--", all.opts, sep="")
#all.opts<-gsub("\\.([a-z])", "\\U\\1", all.opts, perl=TRUE)
all.opts<-gsub("\\.","-", all.opts)
#opt.class<-sapply(rnb.options(), class)

rnb.opt.spec<-data.frame(
		Long=all.opts, 
		Short=as.character(1:length(all.opts)), 
		Mask=c(1,2)[as.integer((opt.class=="logical"))+1], 
		Type=opt.class)

### automated xml file preparation
#xml.strings<-apply(rnb.opt.spec,1, function(row){
#			
#			opt.lab<-gsub("-", ".", row[1])
#			opt.def.val<-rnb.getOption(opt.lab)
#			#print(opt.def.val)
#			opt.name<-gsub("-([0-9a-z])", "\\U\\1", row[1], perl=TRUE)
#			tf.opt<-"\t\t\t<option value=\"True\">True</option>\n\t\t\t<option value=\"False\">False</option>"
#			opt.lab<-paste(opt.lab, gsub("\\."," ", row[4]), sep=", ")
#			if(row[4]=="logical"){
#				opt.type<-'select'
#				if(!is.null(opt.def.val) && opt.def.val)
#					opt.def.val<-"1" else
#					opt.def.val<-"0"
#				string<-sprintf("\t\t<param name=\"%s\" type=\"%s\" label=\"%s\" value=\"%s\">\n%s\n\t\t</param>\n", opt.name, opt.type, opt.lab, opt.def.val, tf.opt)
#			}else{
#				opt.type<-'text'
#				if(length(opt.def.val)<1L){
#					opt.def.val<-""
#				}else{
#					if(!is.null(opt.def.val) && opt.def.val!="")
#						opt.def.val<-paste(opt.def.val, collapse=",") else
#						opt.def.val<-""
#				}
#				string<-sprintf("\t\t<param name=\"%s\" type=\"%s\"  label=\"%s\" value=\"%s\"/>\n", opt.name, opt.type, opt.lab, opt.def.val)
#			}
#			string
#		})
##cat(xml.strings, sep="", file="automated.settings.xml.txt")
#
#opt.def.strings<-apply(rnb.opt.spec,1, function(row){
#			
#			opt.name<-gsub("-([0-9a-z])", "\\U\\1", row[1], perl=TRUE)
#			opt.long<-row[1]
#			opt.short<-row[2]
#			
#			if(row[4]=="logical"){
#				def.string<-sprintf("#if str( $options.%s ) == \"True\"\n\t--%s\n#end if\n", opt.name, opt.long)		
#			}else{
#				def.string<-sprintf("#if str( $options.%s ) != \"\"\n\t--%s=\"$options.%s\" \n#end if\n", opt.name, opt.long, opt.name)
#			}
#			def.string
#			
#		})
#cat(opt.def.strings, sep="", file="automated.option.assignments.txt")


rnb.opt.spec$Type<-gsub("\\.vector", "", rnb.opt.spec$Type)
rnb.opt.spec$Type<-gsub("numeric", "double", rnb.opt.spec$Type)
rnb.opt.spec<-rbind(data.frame(
				Long=c("data-type", "pheno", "idat-dir","idat-files","bed-files", "gs-report", "geo-series", "betas", "pvals","output-file", "report-dir"),
				Short=c("d","s","a","i","f","g","e","b","p","r","o"),
				Mask=c(1,2,2,2,2,2,2,2,2,1,1),
				Type=c("character","character","character","character","character","character","character","character","character","character", "character")),
				rnb.opt.spec)
		
opts<-getopt(as.matrix(rnb.opt.spec))
#opts<-getopt(as.matrix(rnb.opt.spec), opt=list("--data-type=idats","--report-dir=dir", "--idats=file1\tfile2"))
print(opts)

if(opts[["data-type"]]=="idatDir"){
   
	data.source<-list()
	data.type<-"idat.dir"
	data.source[["idat.dir"]]<-opts[["idat-dir"]]
	data.source[["sample.sheet"]]<-opts[["pheno"]]
   
}else if(opts[["data-type"]]=="idatFiles"){
	
	data.type<-"idat.dir"
	file.string<-gsub(" ","", opts[["idat-files"]])
	files<-strsplit(file.string, ",")[[1]]
	files<-files[files!=""]
	bed.dir<-sprintf("%s_beds",opts[["report-dir"]])
	dir.create(bed.dir)
	file.copy(files, bed.dir)
	for(dat.file in list.files(bed.dir, full.names = TRUE)){
		file.rename(dat.file, gsub("\\.dat", ".bed", dat.file))
	}
	data.source<-list()
	data.source[["bed.dir"]]<-bed.dir
	data.source[["sample.sheet"]]<-opts[["pheno"]]
	
	
}else if(opts[["data-type"]]=="GS.report"){

	data.type<-"GS.report"
	data.source<-opts[["gs-report"]]
	
}else if(opts[["data-type"]]=="GEO"){
	
	data.type<-"GEO"
	data.source<-opts[["geo-series"]]
	
}else if(opts[["data-type"]]=="data.files"){
	
	data.type<-"GEO"
	data.source<-opts[["geo-series"]]
	
}else if(opts[["data-type"]]=="data.files"){
	
	data.type<-"data.files"
	data.source<-c(opts[["pheno"]], opts[["betas"]])
	if(!is.null(opts[["pvals"]]))
		data.source<-c(data.source, opts[["pvals"]])
		
}else if(opts[["data-type"]]=="bed.dir"){

	data.type<-"bed.dir"
	file.string<-gsub(" ","", opts[["bed-files"]])
	files<-strsplit(file.string, ",")[[1]]
	files<-files[files!=""]
	bed.dir<-sprintf("%s_beds",opts[["report-dir"]])
	dir.create(bed.dir)
	file.copy(files, bed.dir)
	for(dat.file in list.files(bed.dir, full.names = TRUE)){
		file.rename(dat.file, gsub("\\.dat", ".bed", dat.file))
	}
	data.source<-list()
	data.source[["bed.dir"]]<-bed.dir
	
	logger.start(fname="NA")
	sample.sheet<-read.sample.annotation(opts[["pheno"]])
	logger.close()
	if(length(files) < nrow(sample.sheet))
		stop("Not all bed files are present")
	
	cn<-colnames(sample.sheet)
	dat.files<-sapply(strsplit(files, "\\/"), function(el) el[length(el)])
	sample.sheet<-cbind(sample.sheet, gsub("\\.dat", ".bed", dat.files))
	colnames(sample.sheet)<-c(cn, "BED_files")
	data.source[["sample.sheet"]]<-sample.sheet
}

if("logging" %in% names(opts)){ # TODO create a cleaner way of checking whether the full options set was supplied
	
	dump<-sapply(names(opt.class), function(on){
		getoptname<-gsub("-", "\\.","-",on)
		if(getoptname %in% names(opts)){
			if(opt.class[on]=="logical"){
				ov<-TRUE
			}else if(opt.class %in% c("character","character.vector")){
				ov<-opts[[getoptname]]
				ov<-gsub("\"", "", ov)
				if(opt.class=="character.vector"){
					ov<-as.character(strsplit(ov,","))
				}
				
			}else if(opt.class %in% c("integer","numeric","integer.vector","numeric.vector")){
				ov<-opts[[getoptname]]
				ov<-gsub("\"", "", ov)
				if(opt.class %in% c("integer.vector","numeric.vector")){
					ov<-as.character(strsplit(ov,","))
				}
			}
			eval(parse(text=sprintf("rnb.options(%s=ov)",on)))
		}
	})
	
	logical.opts<-names(opt.class[opt.class=="logical"])
	logical.opts.false<-logical.opts[!logical.opts %in% gsub("-",".",names(opts))]
	
	
	dump<-sapply(logical.opts.false, function(on){
				eval(parse(text=sprintf("rnb.options(%s=FALSE)",on)))	
			})
}

print(rnb.options())

#report.out.dir<-sprintf("%s_rnbReport", tempdir())
report.out.dir<-opts[["report-dir"]]
print("Starting RnBeads with the following inputs:")
print(data.source)
print(report.out.dir)
print(data.type)
rnb.run.analysis(data.source=data.source, dir.report=report.out.dir, data.type=data.type)


#sink(file=NULL)
#flush(msg.file)
#close(msg.file)