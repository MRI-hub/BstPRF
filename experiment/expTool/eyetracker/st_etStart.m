function st_etStart(runN, subjectName)
% Start EyeLink recording before waiting for the scanner trigger.
% Adapted from BCBLViennaSoft/measurementlaptop/StartEyetracker.m

% This supplies the title at the bottom of the eyetracker display
Eyelink('command', 'record_status_message "stPRF %s run %d"', subjectName, runN);
Eyelink('Message', 'TRIALID %d', runN);

% Must be offline to draw to EyeLink screen
Eyelink('Command', 'set_idle_mode');
Eyelink('Command', 'clear_screen 0');
WaitSecs(0.05);

Eyelink('StartRecording');
% record a few samples before we actually start displaying
% otherwise you may lose a few msec of data
WaitSecs(0.1);

if Eyelink('CheckRecording') ~= 0
    warning('[%s]: Eyelink is not recording!', mfilename);
end
Eyelink('Message', 'WAITING_FOR_TRIGGER');

end
