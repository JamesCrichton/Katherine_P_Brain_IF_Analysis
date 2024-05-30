//James Crichton

//Program to enable tracing of brain regions and quantification of signal intensities within nucleus
//Running in Fiji with CBS-Deep, Stradist, and IJPB-plugins installed

//Program takes individual 2-channel stacks with the first channel being DAPI, and te second being the signal to quantify
//Users are prompted to set brain ROI is manually. Nuclei are segmented automatically. Masks and ROIs are saved
//Quantified signal is saved for each cell before and after background subtraction


//1. Open image
run("Fresh Start");//clear anything which is open and set to defaults

background_sigma=50; //set the sigma value for background subtraction

#@ File (label="Select image file", style="file") img_path

open(img_path);
dir1=File.getDirectory(img_path);
dir2=replace(img_path, ".tif", "");//make a new directory path using the image's name, in the same starting location

img=getTitle();
img_temp=File.nameWithoutExtension;

all_files=getFileList(dir1);

for (i=0; i<all_files.length; i++){
	
	if (endsWith(all_files[i], "/")){
		temp_dir_name=replace(all_files[i], "/", "");
		if (temp_dir_name==img_temp){
			Dialog.create("Error");		
			Dialog.addMessage("An image of this name has already been analysed.\nDo you want to continue?");
			Dialog.addRadioButtonGroup("", newArray("Continue", "Exit"), 1, 2, "Exit");
			Dialog.show();
			
			if (Dialog.getRadioButton()=="Exit"){
				exit;
				close("*");
			}
		}
	}
}


//2. Choose region
setSlice(1);run("Grays");//Make channel LUT grey, so it can be more accurately segmented by user
setTool("freehand");//select freehand drwaing tool

selection=0;

while (selection!=3){
run("Colors...", "foreground=green background=black selection=green");

Dialog.createNonBlocking("Draw ROI");
Dialog.addMessage("Using the freehand tool (selected), draw the region\nof the image you wish to analyse");
Dialog.addCheckbox("Run in background (faster but don't see output)", true);
Dialog.show();

background_processing=Dialog.getCheckbox();

selection=selectionType();
}

//Run in background from here on if selected
if (background_processing){
	setBatchMode("hide");	
} else {
	setBatchMode("show");
}

start_time=getTime();

roiManager("Add");
roiManager("select", 0);
roiManager("rename", "manual_selection");


//3. Make a directory for the image's metadata
File.makeDirectory(dir2);
roi_path=dir2+File.separator+"Selection_Roi.zip";
roiManager("save", roi_path);


//4. Isolate region to analyse and measure 
run("Select All");
selectImage(img);run("Duplicate...", "title=DAPI duplicate channels=1");
selectImage(img);run("Duplicate...", "title=C2 duplicate channels=2");

//Clear the image outside of the selection
selectImage("DAPI");
roiManager("select", 0);
run("Clear Outside");
run("Select All");
roiManager("reset");//clear manager for nuclear rois

//Segment cells using Stardist fluorescence defaults
run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'DAPI', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'Both', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");

//Set measurements to record
run("Set Measurements...", "area mean standard min centroid perimeter shape display redirect=C2 decimal=3");

//Select all ROIs
n_ROIs=roiManager("count");
all_ROI_array=Array.getSequence(n_ROIs);//make array of a ROI index IDs
roiManager("select", all_ROI_array);//select them all
//Measure morphological attributes and raw brightess from channle 2 
roiManager("Measure");
//Assign the columns to individual array for later use
label_ID=Table.getColumn("Label");
area=Table.getColumn("Area");
mean_raw=Table.getColumn("Mean");
stdev_raw=Table.getColumn("StdDev");
min_raw=Table.getColumn("Min");
max_raw=Table.getColumn("Max");
X_centroid=Table.getColumn("X");
Y_centroid=Table.getColumn("Y");
perimeter=Table.getColumn("Perim.");
circularity=Table.getColumn("Circ.");
aspect_ratio=Table.getColumn("AR");
roundness=Table.getColumn("Round");
solidity=Table.getColumn("Solidity");

//Create background subbtracted version of the C2 image using the sigma value specified at the start
selectImage("C2");
run("Subtract Background...", "rolling="+background_sigma);//background subtract
rename("C2_bg_sub");

run("Set Measurements...", "mean standard min redirect=C2_bg_sub decimal=3");
roiManager("select", all_ROI_array);//select them all
run("Clear Results");//remove existing results

roiManager("Measure");
mean_bg_sub=Table.getColumn("Mean");
stdev_bg_sub=Table.getColumn("StdDev");
min_bg_sub=Table.getColumn("Min");
max_bg_sub=Table.getColumn("Max");

close("Results");

//make an array for each label number
label_no=Array.getSequence(roiManager("count")+1);
label_no=Array.deleteIndex(label_no, 0);

////make array with the bg subtracted value
//bg_sub_sigma=newArray(0);
//
//for (i=0; i<n_ROIs; i++){
//	bg_sub_sigma=Array.concat(bg_sub_sigma,background_sigma);
//}



//Make an array of all the useful data
Array.show("Results", label_no, label_ID, area, perimeter, circularity, roundness, aspect_ratio, solidity, X_centroid, Y_centroid, mean_raw, stdev_raw, min_raw, max_raw, mean_bg_sub, stdev_bg_sub, min_bg_sub, max_bg_sub);

//Save data
//Save results
selectWindow("Results");
saveAs("results", dir2+File.separator+"Results_BgSub_"+background_sigma+".csv");
close("Results");

//Save label image
selectImage("Label Image");
saveAs("tiff", dir2+File.separator+"Nuclear_Label_Img.tif");
close();

//Save nuclear ROIs
roiManager("save", dir2+File.separator+"Nuclear_ROIs.zip");
close("ROI Manager");


close("*"); //close remaining images

end_time=getTime();
total_time=(end_time-start_time)/1000;

waitForUser("Image '"+img+"' fully processed.\n"+total_time+" seconds. \n:)");







