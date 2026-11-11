function [keys RT] = recordKeys(startTime,duration,deviceNumber)
% Collects all keypresses for a given duration (in secs).
% Written by KGS Lab
% Edited by AS 8/2014
%
% deviceNumber is the list of keyboard devices whose KbQueues were started
% before the run (KbQueueCreate/KbQueueStart). Presses are read from the
% queues, so short button-box presses are not missed between polls, and
% the scanner trigger 's' is ignored. RT is relative to startTime.

keys = [];
RT = [];
triggerCode = KbName('s');

% check for pressed keys
while 1
    for d = deviceNumber
        while KbEventAvail(d) > 0
            event = KbEventGet(d);
            if event.Pressed && event.Keycode ~= triggerCode
                keys = [keys KbName(event.Keycode)];
                RT = [RT event.Time-startTime];
            end
        end
    end
    if (GetSecs-startTime) > duration
        break
    end
    WaitSecs('YieldSecs', 0.001);
end

% label null responses noanswer
if isempty(keys)
    keys = 'noanswer';
    RT = 0;
end

end
