function [EDFLocalFilename, ETstopNow] = st_etStop(edfFile, EDFFolder, baseName, display)
% Stop recording, close the EDF on the host and copy it to
% EDFFolder/<baseName>_<yyyyddmm_HHMMSS>.edf, the same naming as
% BCBLViennaSoft RetStim.m (timestamp taken when recording stops).
% The EDF -> .mat / gaze conversion is done by st_etConvert, after the
% run data is saved (edfmex can crash MATLAB).
% Adapted from BCBLViennaSoft/measurementlaptop/StopEyetracker.m and
% GetEDFDataFile.m

Eyelink('StopRecording');
% same host image as BCBLViennaSoft StopEyetracker.m
st_etHostImage('Black.bmp', display);
WaitSecs(0.1);

ETstopNow = datestr(now, 'yyyyddmm_HHMMSS');
EDFLocalFilename = fullfile(EDFFolder, [baseName '_' ETstopNow]);

Eyelink('Command', 'set_idle_mode');
WaitSecs(0.5);
Eyelink('CloseFile');

% download data file
try
    fprintf('[%s]: Receiving data file ''%s''\n', mfilename, edfFile);
    status = Eyelink('ReceiveFile', edfFile, [EDFLocalFilename '.edf'], 0);
    if status > 0
        fprintf('[%s]: ReceiveFile status %d, saved %s.edf\n', mfilename, status, EDFLocalFilename);
    end
catch
    fprintf('[%s]: Problem receiving data file ''%s'', it is still on the host PC.\n', mfilename, edfFile);
end

Eyelink('Shutdown');

end
