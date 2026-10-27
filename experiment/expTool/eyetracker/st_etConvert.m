function st_etConvert(EDFLocalFilename, ETstopNow)
% Convert the run's EDF to <EDFLocalFilename>.mat (EDFStruct) and save the
% gaze during the experiment to <EDFLocalFilename>_<ETstopNow>_gaze.mat,
% as BCBLViennaSoft GetEDFDataFile.m and RetStim.m do.
% Call it after the run data is saved: edfmex can crash MATLAB, and a
% crash cannot be caught. The .edf is kept either way.

if exist([EDFLocalFilename '.edf'], 'file') ~= 2
    fprintf('[%s]: %s.edf not found, nothing to convert.\n', mfilename, EDFLocalFilename);
    return
end

if exist('edfmex', 'file')
    try
        EDFStruct = edfmex([EDFLocalFilename '.edf']);
        save([EDFLocalFilename '.mat'], 'EDFStruct');
    catch
        fprintf('[%s]: edfmex could not convert %s.edf\n', mfilename, EDFLocalFilename);
    end
end

% gaze between "Experiments Starts" and "Experiments Stops"
if exist([EDFLocalFilename '.mat'], 'file') == 2 && exist('ExtractFromEDFfile', 'file')
    try
        [x, y] = ExtractFromEDFfile(EDFLocalFilename);
        save([EDFLocalFilename '_' ETstopNow '_gaze.mat'], 'x', 'y');
    catch ME
        fprintf('[%s]: could not extract gaze from %s.mat: %s\n', mfilename, EDFLocalFilename, ME.message);
    end
end

end
