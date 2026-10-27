function st_etHostImage(imgfile, display)
% Show an image on the EyeLink host screen, centered on the stimulus
% window, as BCBLViennaSoft StartEyetracker.m / StopEyetracker.m do.
% imgfile is looked up on the path (BCBLViennaSoft/measurementlaptop).
% A failed transfer only prints a message, it does not stop the run.

width  = display.rect(3) - display.rect(1);
height = display.rect(4) - display.rect(2);
try
    info = imfinfo(imgfile);
    % ImageTransfer only accepts whole numbers
    transferStatus = Eyelink('ImageTransfer', info.Filename, 0, 0, info.Width, info.Height, ...
        round(width/2 - info.Width/2), round(height/2 - info.Height/2), 1);
    if transferStatus ~= 0
        fprintf('[%s]: *****Image transfer of %s failed*****\n', mfilename, imgfile);
    end
catch ME
    fprintf('[%s]: could not show %s on the host: %s\n', mfilename, imgfile, ME.message);
end

end
