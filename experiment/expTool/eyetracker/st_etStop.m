function EDFLocalFilename = st_etStop(edfFile, EDFFolder, baseName)
% Stop recording, close the EDF on the host and copy it to
% EDFFolder/<baseName>_<yyyyddmm_HHMMSS>.edf, the same naming as
% BCBLViennaSoft RetStim.m (timestamp taken when recording stops).
% If edfmex is on the path also save the EDFStruct to a .mat.
% Adapted from BCBLViennaSoft/measurementlaptop/StopEyetracker.m and
% GetEDFDataFile.m

Eyelink('StopRecording');
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

% Convert data file
if exist([EDFLocalFilename '.edf'], 'file') == 2 && exist('edfmex', 'file')
    try
        EDFStruct = edfmex([EDFLocalFilename '.edf']);
        save([EDFLocalFilename '.mat'], 'EDFStruct');
    catch
        fprintf('[%s]: edfmex could not convert %s.edf\n', mfilename, EDFLocalFilename);
    end
end

end
