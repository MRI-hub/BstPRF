function st_run()
%% stPRF experimental 
% ========================================================================
% each run %%%%%%%%%
% stimulus radius = 9
% trial Dur = 5, blank Dur =10
% Number of Direction 4, number of steps 9
% Stimulus [4 directions * 9 steps * 5 seconds/location ] = 180 sec
% Initial blank (10s) + stimulus (4 * 9 * 5 = 180s) + 2 Blanks (10s*2) + Blank (10)
% Total duration = 220 sec => 3.6 min
% ========================================================================
% press 'g' (trigger key) to begin
% ========================================================================
% 9 runs conducted in the original experiment
%

%% SET PATHS
cd      '/home/tempread/toolboxes/stPRF/experiment'
addpath(genpath(    '/home/tempread/toolboxes/BCBLViennaSoft/Psychtoolbox-3'))
addpath(            '/home/tempread/toolboxes/BCBLViennaSoft/measurementlaptop/edfmex-master') % EDF -> .mat
addpath(genpath(    './'))

%% constants
% HHSC 1X5 D HID KEY BYGRT

%subject
[a, b]=GetKeyboardIndices;
deviceNumber= max(a);

subject.name = 'test_2110'; % put subject ID
subject.scanner = 0; % if you want to trigger scanner do 1

% stimulus
params.radius = 9;
params.doShuffle = 0;

% temporal
params.trial_dur = 5;
params.blank_dur = 10;
params.tr = 1;

% scanner
triggerKey = 's'; % press g to start
comTrigScan = true;

%save
saveStim = 0;

%eyelink
params.eyelink = [];        % [] = ask at start, 0 = off, 1 = on
params.et.calibrate = [];   % [] = ask, 1 = calibration + validation, 0 = drift check only
params.et.dummy = 0;        % 1 = EyeLink dummy mode, test without tracker
params.et.calibType = 'HV13';
params.et.calibValidRatio = [0.715 0.715]; % BCBL 9 deg setting from BCBLViennaSoft
params.et.targetSize = 2.5;  % 'small' in BCBLViennaSoft
params.et.targetWidth = 1;
params.et.backColor = [125 125 125]; % same as the stimulus background


%% COLLECT SESSION INFORMATION

subject.name = deblank(subject.name);
subject.date = date;


while ~ismember(params.eyelink,[0 1])
    params.eyelink = input('Would you like to eyetrack? (Y=1,N=0): ');
end

if params.eyelink
    while ~ismember(params.et.calibrate,[0 1])
        params.et.calibrate = input('Calibrate and validate? (Y=1, N=0 drift check only): ');
    end
    fprintf(['\nwfret paused to make sure that you have turned off the' ...
             ' wifi, press any key to continue\n\n'])
    pause;
end



%%
path.baseDir = pwd; addpath(genpath(path.baseDir));
path.dataDir = fullfile(path.baseDir,'data',subject.name);

if ~exist(path.dataDir) &&  ~strcmp(subject.name,'tes'), mkdir(path.dataDir); end
runN = getAllFiles(path.dataDir,'*.txt',1);
runN=length(runN)+1;



if runN ==1 && exist([path.dataDir '/ExpDesign.mat'], 'file')  ~= 2
    ExpDesign =  mkExpDesign(36,9);
    save([path.dataDir '/ExpDesign.mat'], 'ExpDesign');
    disp('######## Created and Saved ExpDesign');
else
   load([path.dataDir '/ExpDesign.mat']);
   disp('######## loading ExpDesign');
end

subject.nRun =runN;
subject.saveName = fullfile(path.dataDir,sprintf('stPRF_Run%d.txt',runN));
subject.ExpDesign =ExpDesign;
disp(runN)
disp(size(ExpDesign))
ExpDesign = ExpDesign(runN,:);


%% Experiment params

% load display
params.display =loadDisplayParams;
temporal.trial_dur = params.trial_dur;
temporal.fs = 1/params.display.frameRate;
viewTime = temporal.fs;

params.temporal.motionSteps = 30;

params.stimSize = params.radius;
params.temporal.frequency =1;
params.ncycles = 1;
params.period = 36;
params.ringDeg          = params.radius./4;			% Ring radius/width (deg)
params.prescanDuration = 0;
params.framePeriod  = params.tr;
params.numImages    = round(params.period/params.framePeriod)*2;
params.type = 'bar';

% various time measurements:
duration.stimframe          = 1./params.temporal.frequency./(params.temporal.motionSteps);
duration.cycle.seconds      = params.period;


params.ringWidth        = params.ringDeg;
ringWidth       = params.ringWidth;
halfNumImages   = params.numImages./2;
numMotSteps     = params.temporal.motionSteps;
outerRad=params.radius;

numSubRings     = 1;
bk = params.display.backColorIndex;


% made outerRad to be 1/3 because matrix becomes to big
% I will re-scale the image it later on
m = round(2 * angle2pix(params.display, outerRad/3));
n = round(2 * angle2pix(params.display, outerRad/3));
[x,y]=meshgrid(linspace(-outerRad,outerRad,n),linspace(outerRad,-outerRad,m));

% r = eccentricity;
r = sqrt (x.^2  + y.^2);

% loop over different orientations and make checkerboard
% first define which orientations
orientations = (0:45:360)./360*(2*pi); % degrees -> rad
orientations = orientations([1 6 3 8 5 2 7 4]);
remake_xy    = zeros(1,params.numImages)-1;
remake_xy(1:length(remake_xy)/length(orientations):length(remake_xy)) = orientations;
original_x   = x;
original_y   = y;
% step size of the bar
step_nx      = duration.cycle.seconds./params.tr/4;
step_x       = (2*outerRad) ./ step_nx;
step_startx  = (step_nx-1)./2.*-step_x - (ringWidth./2);
%[0:step_nx-1].*step_x+step_startx+ringWidth./2
fprintf('[%s]:stepsize: %f degrees.\n',mfilename,step_x);

% if we create colored bars we want to make the edges soft.
softmask = ones(m);

% Loop that creates the final images
fprintf('[%s]:Creating %d images:',mfilename,halfNumImages);
images=zeros(m,n,3,halfNumImages*numMotSteps,'uint8');
%%
picked = randperm(6,1);
cacheImg =[path.baseDir '/img_' num2str(picked) '.mat'];
if exist(cacheImg, 'file')  ~= 2
    for imgNum=1:halfNumImages
        
        if remake_xy(imgNum) >=0
            x = original_x .* cos(remake_xy(imgNum)) - original_y .* sin(remake_xy(imgNum));
            y = original_x .* sin(remake_xy(imgNum)) + original_y .* cos(remake_xy(imgNum));
            % Calculate checkerboard.
            % Wedges alternating between -1 and 1 within stimulus window.
            % The computational contortions are to avoid sign=0 for sin zero-crossings
            wedges    = sign(round((cos((x+step_startx)*numSubRings*(2*pi/ringWidth)))./2+.5).*2-1);
            posWedges = find(wedges== 1);
            negWedges = find(wedges==-1);
            rings     = zeros(size(wedges));
            
            checks    = zeros(size(rings,1),size(rings,2),params.temporal.motionSteps);
            
            % reset starting point
            loX = step_startx - step_x;
        end
        
        avail_imgs = 63;
        potential_imgs = randperm(avail_imgs,numMotSteps);
        for ii=1:numMotSteps
            
            % load image
            % update the image to be the same size
            filename = ['pic' mat2str(potential_imgs(ii)) '.jpg'];
            newfile = imread(filename);
            cropped_img = imresize(newfile,[m n]);
            toons(:,:,:,ii) = cropped_img;
            
        end
        
        loX   = loX + step_x;
        hiX   = loX + ringWidth;
        
        window = ( (x>=loX & x<=hiX) & r<outerRad);
        
        
        tmpvar = zeros(m,n);
        tmpvar(window) = 1;
        tmpvar = repmat(tmpvar, [1 1 3]);
        tmpvar = repmat(tmpvar,[1 1 1 numMotSteps]);
        window = tmpvar == 1;
        img         = bk*ones(size(toons));
        img(window) = toons(window);
        images(:,:,:,(imgNum-1).*numMotSteps+1:imgNum.*numMotSteps) = uint8(img); %#ok<*BDSCA>
        
        
        
        fprintf('.');drawnow;
        
    end
    save(cacheImg,...
        'images', '-v7.3');

else
    load(cacheImg)
end

fprintf('Done.\n');


%% get back image size
m = round(2 * angle2pix(params.display, outerRad));
n = round(2 * angle2pix(params.display, outerRad));

images = imresize(images,[m n]);


%% actual sequence

[img_sequence, nstim]= mkTemporal(ExpDesign,temporal);

temp = 1:size(images,4);
samp = reshape(temp,numMotSteps,[]); 

imageNumber=[];
for q = 1:params.period % 36
    imageNumber{q} = samp(1:nstim{q},q);
end
imageNumber = cellfun(@transpose, imageNumber,'UniformOutput',false);


sequence = [];

for q= 1:length(imageNumber)
    for i = 1:length(imageNumber{q})
        curpuls = imageNumber{q};
        sequence = [sequence curpuls(i)*img_sequence{q}];
    end

end

% sequence [frames X spatial location] 
% right now [300 frames = 5 sec, trial dur X 36 spatial location (9 step X 4 dir)] 
nF = params.trial_dur*params.display.frameRate;
nbF =  params.blank_dur*params.display.frameRate;
sequence = reshape(sequence,nF,[]);


% add Blanks
insert = @(a, x, n) cat(2,  x(1:n), a, x(n+1:end));
insert2 = @(a, x, n) cat(2,  x(:,1:n), a, x(:,n+1:end));
nImages = cell2mat(nstim);

% add blank inbetween
blankInd = [9 20];
for i = 1:length(blankInd)
    sequence  = insert2(zeros(nF,nbF/nF), sequence, blankInd(i));
    nImages   = insert(zeros(1,2), nImages, blankInd(i));
end

%add blank in the start & end
nImages  = [0 0 nImages 0 0];
sequence = [zeros(nF,nbF/nF) sequence zeros(nF,nbF/nF)];
sequence = sequence(:);
rs = reshape(sequence,nF,[]);




%% WRITE SCRIPT AND PARAMETER FILES

%%save expinfo
expInfo.tCond = ExpDesign;
expInfo.sequence = rs;
expInfo.nImages  = nImages;
save([path.dataDir '/info_' num2str(runN) '.mat'],'expInfo','-v7.3');

% header lines

cnames = strcat(num2str(params.trial_dur), 's, Shuffle', num2str(params.doShuffle));
header1 = ['stPRF conditions: ' cnames ' '];
header2 = ['Stimulus size (radius): ',num2str(params.radius),' '];
header3 = ['Run duration (s): ',num2str(length(sequence)*temporal.fs),' '];
header4 = ['Run Number: ',num2str(subject.nRun),' '];
header5 = 'Trial      Condition     Onset      Duration     Image';

% footer = '*** END SCRIPT ***';
% write separate script file for each run
fid = fopen(subject.saveName,'w');
fprintf(fid,'%s\n',header1);
fprintf(fid,'%s\n',header2);
fprintf(fid,'%s\n',header3);
fprintf(fid,'%s\n\n',header4);
fprintf(fid,'%s\n',header5);

fclose(fid);

%% fixation dot sequence
% change on the fastest every 6 seconds
minsec = round(6./temporal.fs);
fixSeq = ones(minsec,1)*round(rand(1,ceil(length(sequence)/minsec)));
fixSeq = fixSeq(:)+1;
% check that the sequence of fixations is at least as long as the sequence
% of stimuli. if not, pad the the fixation sequence.
if length(fixSeq) < length(sequence), fixSeq(end+1:length(sequence)) = 0; end
% if the fixation sequence is shorter, truncate it
fixSeq = fixSeq(1:length(sequence));
% force binary
fixSeq(fixSeq>2)=2;
fixSeq(fixSeq<1)=1;



%%
timing   = (0:length(sequence)-1)';
cmap     = params.display.gammaTable;
stimulus = createStimulusStruct(images,cmap,sequence,[],timing,fixSeq);

if subject.scanner == 1
    Screen('Preference', 'SkipSyncTests', 1);
    % params.display                = openScreen(params.display,2);
    % Screen('OpenWindow',1, [125 125 125])
    [params.display.windowPtr,params.display.rect] = Screen('OpenWindow',1,...
        [125 125 125]);

else
    screen_num = 0;
    % second_screen_rect = [1920, 0, 1920+1024, 768]; % 1024 768
    second_screen_rect = [1920 0 3840 1080]; % 1920 1080
    
    [params.display.windowPtr,params.display.rect] = Screen('OpenWindow',...
                        screen_num,[125 125 125], second_screen_rect);
    [params.display.fixX,params.display.fixY] = RectCenter( params.display.rect);

end


stimulus = createTextures(params.display,stimulus,0);

% reverse screen if needed
% retScreenReverse(params, stimulus);

display = params.display;
display.fixColorRgb = [255 0 0; 0 0 255];

nFrames = length(stimulus.seq);

disp(['######## RunN : ' num2str(runN)]);
disp(['######## StimSize : ' num2str(params.radius) ' radius']);
disp(['######## Shuffle : ' num2str(params.doShuffle)]);
disp(['######## ExpDur(s) : ' num2str(nFrames*temporal.fs)]);
disp(['######## Seq(s) : ' num2str(ExpDesign)]);

% ######### Eyelink Commands ######
if params.eyelink
    % host file name max 8 chars, the local copy gets the full name
    params.et.edfFile = sprintf('r%02d_%s', runN, datestr(now,'HHMM'));

    % Run calibration, validation, and drift correction
    [~, params.et.edfFile] = st_etSetup(params.display, params.et);

    % record while waiting for the trigger
    st_etStart(runN, subject.name);
end



pressKey2Begin(params.display, false, [], [], triggerKey);
if params.eyelink, Eyelink('Message', 'TRIGGER_RECEIVED'); end

if comTrigScan
    % Check if serial port trigger works start scan
    [status,~] = newStartScan; %time0 corresponds to clock time at start of pulse
    if status ~= 0
        %error(['Trigger failed'])
    end

end


if comTrigScan
    [s,time0] = StartScan;
else
    time0 = GetSecs;
end

t0 = time0; % "time 0" to keep timing going
% SYNCTIME marks t0 in the EDF; frame onsets are t0+(frame-1)*viewTime
if params.eyelink
    % same start marker as BCBLViennaSoft doRetinotopyScan.m
    Eyelink('Message', ['Experiments Starts. Time is: ',num2str(now,'%.8f')]);
    disp(['Experiments start time (',datestr(now,'yyyy-mm-dd HH:MM:SS.FFF'),') successfully sent to Eyetracker.'])
    Eyelink('Message', 'SYNCTIME');
    Eyelink('Message', 'STIM_START nFrames %d frameDur_ms %.3f', nFrames, viewTime*1000);
end
for frame = 1:nFrames
    if stimulus.seq(frame)>0
        % put in an image
        imgNum = stimulus.seq(frame);
        Screen('DrawTexture', display.windowPtr, stimulus.textures(imgNum), stimulus.srcRect, stimulus.destRect);
        drawFixation(display,stimulus.fixSeq(frame));
        VBLTimestamp = Screen('Flip',display.windowPtr);

    elseif stimulus.seq(frame)==0
        drawFixation(display,stimulus.fixSeq(frame));
            VBLTimestamp = Screen('Flip',display.windowPtr);


    end

    % ######### Eyelink sync messages ######
    if params.eyelink
        % offset (ms) between the flip and now, EyeLink subtracts it
        etOffset = round((GetSecs-VBLTimestamp)*1000);
        if mod(frame-1,nF) == 0
            trial = (frame-1)/nF + 1;
            Eyelink('Message', '%d TRIAL_ONSET %d frame %d blank %d nImages %d', ...
                etOffset, trial, frame, all(rs(:,trial)==0), nImages(trial));
        end
        if frame == 1 || stimulus.fixSeq(frame) ~= stimulus.fixSeq(frame-1)
            Eyelink('Message', '%d FIX_COLOR %d frame %d', etOffset, stimulus.fixSeq(frame), frame);
        end
    end

    [keys RT] = recordKeys(t0+(frame-1)*viewTime,viewTime,deviceNumber);

    if params.eyelink && ~strcmp(keys,'noanswer')
        Eyelink('Message', 'RESPONSE %s frame %d', keys, frame);
    end

    %--- update screen
    data.keys{frame} = keys;
    data.rt(frame) = min(RT);

end

tTime = GetSecs-t0;
tTime

%%
if params.eyelink
    % Stop eyetracking and copy the EDF to the subject data folder
    Eyelink('Message', 'STIM_END duration_s %.3f', tTime);
    % same stop marker as BCBLViennaSoft doRetinotopyScan.m
    Eyelink('Message', ['Experiments Stops. Time is: ',num2str(now,'%.8f')]);
    disp(['Experiments stop time (',datestr(now,'yyyy-mm-dd HH:MM:SS.FFF'),') successfully sent to Eyetracker.'])
    params.et.EDFLocalFilename = st_etStop(params.et.edfFile, path.dataDir, ...
        sprintf('%s_r%d', subject.name, runN));
end

%%

waitDur =1;

data.resp = [];
data.fixSeq = [];
data.nreps = [];
data.hits = [];
data.falseAlarms = [];
data.propHit = [];

% identify trials with a response
for t = 1:length(data.keys)
    if strcmp(data.keys{t},'noanswer') || strcmp(data.keys{t},triggerKey)
        data.resp(t) = 0;
    else
        data.resp(t) = 1;
    end
end

% specify time windows for hits
correctResp = zeros(length(data.keys),1);
repIndex = find(diff(fixSeq)~=0);
data.fixSeq = fixSeq;
nreps = length(repIndex);
for t = 1:nreps
    for i = 1:waitDur/viewTime
        correctResp(repIndex(t)+i-1) = 1;
    end
end
data.nreps = nreps;

% calculate proportion of hits
hitCnt = 0;
cnt = 0;
for i = 1:nreps
    cnt = cnt+1;
    if sum(data.resp(repIndex(i):repIndex(i)+waitDur/viewTime-1)) >= 1
        hitCnt = hitCnt+1;
    else
    end
end
data.hits = hitCnt;
data.propHit = hitCnt/nreps;


% count number of false alarms
faCnt = 0;
for t = 1:length(data.keys)
    if correctResp(t) == 0 && data.resp(t) == 1
        faCnt = faCnt+1;
    else
    end
end
data.falseAlarms = faCnt;

%%
% %% ANANLYZE DATA AND CLEAR WINDOWS
% record total time of experiment
hitStr = ['Hits: ' num2str(data.hits) '/' num2str(data.nreps) ' (' num2str(data.propHit*100) '%)'];
faStr = ['False alarms: ' num2str(data.falseAlarms)];
DrawFormattedText(display.windowPtr,[hitStr '\n' faStr '\n'],'center','center',[0 0 0]);
Screen('Flip',display.windowPtr);
WaitSecs(5);
ShowCursor;
Screen('CloseAll');




%% save stim
if saveStim == 1
    blankImage = uint8(ones(101,101,3).*bk);
    rs = reshape(sequence,nF,[]);
    stim=[];
    for a = 1:size(rs,2)
        stim_trial = uint8(zeros(101,101,3,nF));

        trial = rs(:,a);
        for i = 1:length(trial)
            if trial(i) ==0
                stim_trial(:,:,:,i) = blankImage;
            else
                curImg = images(:,:,:,trial(i));
                curImg = imresize(curImg,[101 101]);
                stim_trial(:,:,:,i) = curImg;
            end
        end
%         stim_trial = imresize(stim_trial,[101 101]);
        stim{a} = stim_trial;
    end
    save([path.dataDir '/stim_' num2str(runN) '.mat'],'stim','sequence','-v7.3');
end
%% Save lastbit
save([path.dataDir '/info_' num2str(runN) '.mat'],'expInfo','subject','data','params','-v7.3');

end
  
