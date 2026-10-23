function [el, edfFile] = st_etSetup(display, et)
% Connect to the EyeLink, open the EDF file on the host and run
% calibration + validation (or only a drift check) on the stimulus window.
%
%   [el, edfFile] = st_etSetup(display, et)
%
% display : params.display, with windowPtr and rect of the stimulus window
% et      : struct with fields
%   .edfFile          host file name, max 8 chars (letters, digits, _)
%   .calibrate        1 = calibration + validation, 0 = drift check only
%   .dummy            1 = EyeLink dummy mode (no tracker, for testing)
%   .calibType        e.g. 'HV13' (BCBL default) or 'HV9'
%   .calibValidRatio  [x y] proportion of the screen used for calib/valid
%   .targetSize       calibration target size in % of screen width
%   .targetWidth      calibration target inner width in % of screen width
%   .backColor        calibration background, should match the stimulus
%
% Adapted from BCBLViennaSoft/measurementlaptop/ConfigEyetracker.m and
% DriftCorrection.m, but it uses the stimulus window instead of opening
% a new full-screen window, so gaze coordinates match the stimulus rect.

edfFile = et.edfFile;
win     = display.windowPtr;
width   = display.rect(3) - display.rect(1);
height  = display.rect(4) - display.rect(2);

% Provide Eyelink with details about the graphics environment
el = EyelinkInitDefaults(win);

% Initialization of the connection with the Eyelink tracker
if ~EyelinkInit(et.dummy)
    Eyelink('Shutdown');
    sca;
    error('[%s]: Eyelink Init aborted. Is the tracker on and the ethernet connected?', mfilename);
end

[~, vs] = Eyelink('GetTrackerVersion');
fprintf('[%s]: Running experiment on a ''%s'' tracker.\n', mfilename, vs);

% open file to record data to (on the host PC)
if Eyelink('Openfile', edfFile) ~= 0
    Eyelink('Shutdown');
    sca;
    error('[%s]: Cannot create EDF file ''%s''', mfilename, edfFile);
end
Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox stPRF''');

% screen coordinates, same as the stimulus window
Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);

% calibration type and area
Eyelink('command', ['calibration_type = ' et.calibType]);
Eyelink('command', 'calibration_area_proportion = %s %s', ...
    num2str(et.calibValidRatio(1)), num2str(et.calibValidRatio(2)));
Eyelink('command', 'validation_area_proportion = %s %s', ...
    num2str(et.calibValidRatio(1)), num2str(et.calibValidRatio(2)));

% EDF file and link contents
Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT');
Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');

% make sure we're still connected.
if Eyelink('IsConnected') ~= 1 && ~et.dummy
    Eyelink('Shutdown');
    sca;
    error('[%s]: Eyelink not connected.', mfilename);
end

% calibration colors and targets, background matches the stimulus
el.backgroundcolour        = et.backColor;
el.calibrationtargetcolour = [0 0 0];
el.msgfontcolour           = [0 0 0];
el.calibrationtargetsize   = et.targetSize;
el.calibrationtargetwidth  = et.targetWidth;

% frequency, volume, duration. Set volume to 0 to turn off the sound
el.cal_target_beep              = [600 0.5 0.05];
el.drift_correction_target_beep = [600 0.5 0.05];
el.calibration_failed_beep      = [400 0.5 0.25];
el.calibration_success_beep     = [800 0.5 0.25];
el.drift_correction_failed_beep = [400 0.5 0.25];
el.drift_correction_success_beep= [800 0.5 0.25];
% you must call this function to apply the changes from above
EyelinkUpdateDefaults(el);

HideCursor;

if et.calibrate
    fprintf(['\n[%s]: CALIBRATION / VALIDATION on the stimulus screen\n' ...
             '   Enter = camera image (adjust pupil/CR), C = calibrate,\n' ...
             '   V = validate, Enter = accept, Esc = exit setup and continue\n\n'], mfilename);
    EyelinkDoTrackerSetup(el);
else
    % no new calibration: drift check at the fixation point
    fprintf('[%s]: DRIFT CHECK, ask the subject to look at the dot, then press Space.\n', mfilename);
    EyelinkDoDriftCorrection(el, round(width/2), round(height/2));
end

% back to the experiment background
Screen('FillRect', win, et.backColor);
Screen('Flip', win);

end
