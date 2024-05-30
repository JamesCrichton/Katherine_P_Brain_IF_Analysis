//IJ Macro Script - Running in Fiji, using BioFormats
//James Crichton - University of Exeter

//Script will open .lif project file of images and convert to separate .tif stacks 
//with channel_1 in Blue, and channel_2 in Green. 
//Images ordered into eight separate folders reflecting the mouse ID recorded in the image name ("9612m1" - "9612m4", and "9613m1" - "9613m4")


//1. User sets input file and output destination
#@ File (label="lif project file to process", style="file") file_path
#@ File (label="Output directory", style="directory") dir

setBatchMode("hide"); //don't show the images being  processed

//Make new folders for each mouse ID specified here:
mouse_name_array=newArray("9612m1","9612m2", "9612m3", "9612m4", "9613m1", "9613m2", "9613m3", "9613m4");
for (i=0; i<mouse_name_array.length; i++){
	
	new_dir_path=dir+File.separator+mouse_name_array[i];
	File.makeDirectory(new_dir_path);
}

//2. Loop through images in the .lif file
run("Bio-Formats Macro Extensions");
Ext.setId(file_path);//initialise the image in bioformats

Ext.getSeriesCount(seriesCount);//how many images are in this .lif project file? 

time_a=getTime();//start timer
time_from_start=0//time since last run

for (i = 0; i < seriesCount; i++) {
	
	series_no=i;
	run("Bio-Formats Importer", "open=["+file_path+"] color_mode=Default view=Hyperstack stack_order=XYCZT series_"+series_no);//open image

	//Set colours
	setSlice(1);
	run("Blue");
	setSlice(2);
	run("Green");
	
	//get image name
	title=getTitle();
	
	print("Processing "+title);
	
	//extract mouse ID and make/check for a folder for this mouse
	title_2=replace(title, ".lif - ", "#");//using #  to set the delimiter to split the image name. Longer strings were splitting with instances of every letter contained in the delimiter, rather than the full phrase

	names=split(title_2, "#");
	proj_name=names[0];
	img_name=names[1];
	
	dir_array_match=newArray();//record which folder names a file matches to. 
	match_count=0; 
	for (j=0;j<mouse_name_array.length;j++){//loop though the different mouse IDs specified at the start (also used for folders to save to)
		match_test=startsWith(img_name, mouse_name_array[j]);//does the file name start with the ID specified for the mouse?
		dir_array_match=Array.concat(dir_array_match,match_test);
		match_count=match_count+match_test;
	}
	if (match_count==1){
		for (j=0;j<mouse_name_array.length;j++){//loop though the different mouse IDs specified at the start (also used for folders to save to)
			if (startsWith(img_name, mouse_name_array[j])){//does the file name start with the ID specified for the mouse?
				file_save_path=dir+File.separator+mouse_name_array[j]+File.separator+img_name;
				selectImage(title);
				saveAs("tiff", file_save_path);
				close("*"); 
			}}}
			else {
				print("Image "+ img_name + " has an error in it's name and is not matching to a single mouse ID directory for saving. Check it's name"
			}
	
	time_b=getTime();
	time_for_file=time_b-time_from_start-time_a;
	time_from_start=time_b-time_a;
	
	seconds_total=time_from_start/1000;
	seconds_single_file=time_for_file/1000;
	print(title+ " processing complete! "+seconds_single_file+ "s, "+seconds_total+"s total");

}


time_b=getTime();
time_c=(time_b-time_a)/1000;
print(time_c+ " seconds");

