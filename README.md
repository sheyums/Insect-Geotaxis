# Insect-Geotaxis
The repository contains Matlab functions for (1) controlling instruments during geotaxis experiment, (2) tracking flies in the acquired videos, and (3) analyzing their movements. 


1: RecordVideos(numVideos,userFrameRate,duration,waitTime,filename)

-Function: 
          to record multiple videos in succession directly using MATLAB. This function does include the connection to the fly slamming mechanism.
          
-Input:

	        numVideos = the # of videos to record in succession 
         
            userFrameRate = the frame rate (Hz: frames per second) for each video (could be limited by the camera)
          
	        duration = duration of each recording (in seconds)
         
	        waitTime = the time between each video (in seconds)
         
            filename = name to label videos (the number of the recording will be appended)
		      For example: ‘exp_1’ for a numVideos=3 will output:
			        ‘exp1_1.mp4’ ‘exp1_2.mat’ ‘exp1_3.mp4’
           
-Output:

        ‘.mp4’ video files saved to the open folder in the MATLAB path. 
	
-Notes:
***The function can overwrite videos with the same name but will check with the user prior to execution. 
***This code works with XXXXXX camera specified in line 25. User should change this if using a different type of camera. 
***This code connects directly to the motor for the fly slamming mechanism. If the user is not connecting to the same motor (or to any motor) comment out lines 34-36, 60-62, 87. 

+++++++++++++++++++++++++++++++++++++

2: VideoProcessor(prev_roi,n_ROI,startFrame,saveROI,videoName)

-Function:
          Uses an input video from a D. melanogaster geotaxis experiment.
          Removes the initial frames containing the movement of the slamming (in short specifying a start frame)
          Cuts the video into regions of interest (ROI)
          Waits for the user to be satisfied with the ROI (using button/mouse click)
          Saves the separated ROI into new vial videos for tracking.
          
-Inputs:  

          prev_roi = previous ROI matrix from the MATLAB workspace 
      	  
          n_ROI = number of ROI’s desired
          
          startFrame = number of frames removed from the beginning
        
          saveROI = specify if you would like to save the ROI information into a .mat file. 1 = save, 0 = do not save.
          
          videoName = user already has the FULL PATH to the desired video file	
          
-Outputs:

      ‘.mp4’ video files corresponding with the original video and then the ROI number. 
			For example, if input file is ‘exp1_3.mp4’ and n_ROI=2				the output would be: ‘exp1_3_1.mp4’, ‘exp1_3_2.mp4’
   
-Notes:
***If using the prev_roi you must load it into the workspace.
***For the first video in each experiment, saveROI is recommended. Due to the nature of negative geotaxis experiments any following ROI should be identical barring any human error. For future videos in the same experiment, use the prev_roi to make sure you are using the same cropping.

+++++++++++++++++++++++++++++++++++

2.5: VideoProcessIterative(prev_roi,n_ROI,startFrame,saveROI)

-Function:
		NOT REQURIED: Created for convenience. Identical to VideoProcessor but iteratively cuts multiple videos in succession.
  
-Inputs:
		prev_roi = previous ROI matrix from the MATLAB workspace
		n_ROI = number of ROI’s desired
		startFrame = number of frames removed from the beginning
    saveROI = specify if you would like to save the ROI information into a .mat file. 1 = save, 0 = do not save.
    *vidoeName = dialog box will pop up and ask the user to input one or more video files
    
-Outputs:

    ‘.mp4’ video files corresponding with the original video and then the ROI number. For example, if input file is ‘exp1_3.mp4’ and n_ROI=2, the output would be: ‘exp1_3_1.mp4’, ‘exp1_3_2.mp4’
   
-Notes:
***If using the prev_roi you must load it into the workspace.
***Recommended use of this function is after using VideoProcessor and utilizing prev_roi for the remainder of the experiment videos. 
***Watch to make sure the videos are framed correctly for each video regardless of the iteration. Some videos can occasionally be cropped incorrectly and can only be rectified manually. 
***All inputs will be identical for each iteration. If parameters need to be changed for one of the videos, it is best to use the VideoProcessor.  

++++++++++++++++++++++++++++++++++++

3: Calibrate(sameFile,saveInfo)

-Function: Creates a background for each input video file. Loads frame from every 0.5 second of each recording. Subtracts background from frame and detects blobs. Asks the user to categorize all blobs into 3 possible groups: One fly, Multiple flies, Noise. Saves area information in 3 separate excel files
			Axis lengths
			Single area
			Multi area

-Inputs:

     sameFile: specifies if user desires to save to existing excel files. Must be all three of them. 
	   1 = yes
	   0 = no
	    default = 0
    
    saveInfo: specifies if user desires to save the calibrated information.
	   1 = yes
	   0 = no
	    default = 1
     
    ***If saveInfo=1 and sameFile=0, user will need to define the name of the new calibration files in a pop-up window. For example, “Straight_wing_”.
    ***If saveInfo=1 and sameFile=1, user will need to identify the desired file they wish to append to. 
    ***Recommendation is to first create the new file with a single ROI video. Then append subsequent ROI videos in groups of 3. The task is tedious, and it will help break up the workload. 
    
-Outputs: 
		3 separate excel files=
			Axis lengths: 
first column = single fly maximum axis length
second column = single fly minimum axis length
third column = multiple flies maximum axis length
fourth column = multiple flies minimum axis length

named: user_defined_name”_axisLengths.xls”
	example: Straight_Wing_axisLengths.xls
			Single area:
first column = single fly pixel area 

named: user_defined_name”_pixelarea.xls”
example: Straight_Wing_pixelarea.xls
			Multi area:
first column = multiple flies pixel area 

named: user_defined_name”_multiarea.xls”
example: Straight_Wing_multiarea.xls
***This could be changed to one excel file output if necessary. I like to keep things separate. However, if you change this to a single excel output, keep in mind you have to edit the FlyTracking() function to be able to read it properly. 
-	Notes: 
***Highly recommend calibrating the tracking to the metrics of your experimental set up. The camera quality, distance of camera to vials, size of flies, and sharpness of image all influence these parameters. Despite having identical equipment, small variations in fly size can strongly influence the accuracy of tracking.  





