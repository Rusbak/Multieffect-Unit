function MultiEffectUnit()
    %% MAIN
    % Overall parameters
    fs = 44100; % Sampling frequency
    t = 0:1/fs:4; % 4 second time vector
    
    % Extra parameters
    audioToPlay = [];
    selectedAudioClip = 1;
    isPlaying = false;
    
    % Initial audio effect parameters
    delayTime = 1.0;
    delayIntensity = 1.0;
    chorusRate = 1.0;
    chorusDepth = 1.0;
    flangerRate = 1.0;
    flangerDepth = 1.0;
    flangerDelay = 1.0;
    reverbTime = 1.0;
    reverbFeedback = 1.0;
    
    createUI(isPlaying);
    
    %% AUDIO
    audioClips = generateAudio(t);
    % Generating audio straigth into the audio array
    function audioClips = generateAudio(t)    
        audioClips = {sineWave(t, 440), sineWave(t, 880), sineWave(t, 1320), ...
            squareWave(t, 440), triangleWave(t, 440), sawtoothWave(t, 440), ...
            chirpEffect(t, 100, 2000), whiteNoise(t), brownNoise(t), ...
            greyNoise(t), blueNoise(t), pinkNoise(t)};
    end

    % dropdown.Value does not give an index like I thought it would, so I
    % have to do this workaround instead...
    function selectedAudioClip = getSelectedAudioClip(selectedAudio)
        % this function could probably be swithed for a strcmp() loop
        selectedAudioClip = [];

        switch selectedAudio
            case 'Sine Wave - Low'
                selectedAudioClip = audioClips(1);
            case 'Sine Wave - Med'
                selectedAudioClip = audioClips(2);
            case 'Sine Wave - High'
                selectedAudioClip = audioClips(3);
            case 'Square Wave'
                selectedAudioClip = audioClips(4);
            case 'Triangle Wave'
                selectedAudioClip = audioClips(5);
            case 'Sawtooth Wave'
                selectedAudioClip = audioClips(6);
            case 'Chirp'
                selectedAudioClip = audioClips(7);
            case 'White Noise'
                selectedAudioClip = audioClips(8);
            case 'Brown Noise'
                selectedAudioClip = audioClips(9);
            case 'Grey Noise'
                selectedAudioClip = audioClips(10);
            case 'Blue Noise'
                selectedAudioClip = audioClips(11);
            case 'Pink Noise'
                selectedAudioClip = audioClips(12);
        end
    end
    
    % Sine waves
    function sineWaveOutput = sineWave(timeVector, freq)
        sineWaveOutput = sin(2 * pi * freq * timeVector);
    end
    
    % Square wave
    function squareWaveOutput = squareWave(timeVector, freq)
        squareWaveOutput = square(2 * pi * freq * timeVector);
    end
    
    % Triangle wave
    function triangleWaveOutput = triangleWave(timeVector, freq)
        triangleWaveOutput = sawtooth(2 * pi * freq * timeVector, 0.5);
    end
    
    % Sawtooth
    function sawtoothWaveOutput = sawtoothWave(timeVector, freq)
        sawtoothWaveOutput = sawtooth(2 * pi * freq * timeVector);
    end
    
    % Chirp
    function chirpOutput = chirpEffect(timeVector, minFreq, maxFreq)
        chirpOutput = chirp(timeVector, minFreq, max(timeVector), maxFreq);
    end
    
    % White noise
    function whiteNoiseOutput = whiteNoise(timeVector)
        whiteNoiseOutput = randn(1, length(timeVector));
    end
    
    % Brown noise (Red)
    function brownNoiseOutput = brownNoise(timeVector)
        whiteNoiseInput = whiteNoise(timeVector);
        brownNoiseInput = cumsum(whiteNoiseInput);
        brownNoiseOutput = brownNoiseInput / max(abs(brownNoiseInput));
    end
    
    % Grey noise
    function greyNoiseOutput = greyNoise(timeVector)
        whiteNoiseInput = whiteNoise(timeVector);
        coefficients = [0.2177 -0.4157 0.9794 -0.4146 0.2171];
        greyNoiseInput = filter(coefficients, 1, whiteNoiseInput);
        greyNoiseOutput = greyNoiseInput / max(abs(greyNoiseInput));
    end
    
    % Blue noise
    function blueNoiseOutput = blueNoise(timeVector)
        whiteNoiseInput = whiteNoise(timeVector);
        blueNoiseInput = diff(whiteNoiseInput);
        blueNoiseOutput = blueNoiseInput / max(abs(blueNoiseInput));
    end
    
    % Pink noise
    function pinkNoiseOutput = pinkNoise(timeVector)
        coefficients = [0.021 0.0711 0.6887 0.03231]; % Simplified Voss-McCartney coefficients
        whiteNoiseInput = whiteNoise(timeVector);
        pinkNoiseOutput = filter(coefficients, 1, whiteNoiseInput);
    end
    
    %% EFFECTS
    % DELAY
    function delayedAudio = delay(audio, delayTime, intensity)
        %inputAudio = cell2mat(audio);
        numSamplesDelay = round(delayTime * fs);
        delayedAudio = audio;

        for i = numSamplesDelay + 1:length(audio)
            delayedAudio(i) = audio(i) + intensity * audio(i - numSamplesDelay);
        end
    end
    
    % CHORUS
    function chorusAudio = chorusXXX(audio, rate, depth) % Obsolete
        time = (0:length(audio) - 1) / fs;
        modSignal = depth * sin(2 * pi * rate * time);
        
        audio = cell2mat(audio);
        % Apparently 'audio' has to of type double
        %audio = double(audio); % Apparently not i guess?

        % The audio is layered on top of each other
        chorusAudio = audio + interp1(1:length(audio), audio, (1:length(audio)) + modSignal, 'linear', 0);

        % Testing
        disp(['Audio: ', num2str(audio)]);
        disp(['Chorus audio: ', num2str(chorusAudio)]);
    end

    function chorusAudio = chorus(audio, rate, depth)
        inputAudio = cell2mat(audio);

        % Audio has to be a coloum vector
        if size(inputAudio, 1) < size(inputAudio, 2)
            inputAudio = inputAudio';
        end
        
        audioLength = length(inputAudio);        
        chorusAudio = zeros(audioLength, 1);
        numDelays = rate;
        
        % Precompute delay samples
        delaySamples = round(linspace(0, depth, numDelays));
        
        % Mix the original signal with delayed versions
        for i = 1:numDelays
            delay = delaySamples(i);
            if delay == 0
                chorusAudio = chorusAudio + inputAudio;
            else
                chorusAudio(delay+1:end) = chorusAudio(delay+1:end) + inputAudio(1:end-delay);
            end
        end
        
        % Normalizing the output to avoid clipping
        chorusAudio = chorusAudio / max(abs(chorusAudio));

        % Testing
        disp(['Audio: ', num2str(inputAudio')]);
        disp(['Chorus audio: ', num2str(chorusAudio')]);
    end


    
    % FLANGER
    function flangerAudio = flangerXXX(audio, rate, depth, delayTime) % Obsolete
        time = (0:length(audio) - 1) / fs;
        modSignal = depth * sin(2 * pi * rate * time);
        delaySamples = round(delayTime * fs);
        modulatedDelay = delaySamples + modSignal;
        flangerAudio = zeros(size(audio));

        for i = 1:length(audio)
            delayIndex = round(i - modulatedDelay(i));
            if delayIndex > 0
                flangerAudio(i) = audio(i) + audio(delayIndex);
            else
                flangerAudio(i) = audio(i);
            end
        end

        % Testing
        disp(['Audio: ', num2str(audio')]);
        disp(['Flanger audio: ', num2str(flangerAudio')]);
    end

    function flangerAudio = flanger(audio, rate, depth, delayTime)
        inputAudio = audio;

        % Convert delayTime and depth from milliseconds to samples
        delayTimeSamples = round((delayTime / 1000) * fs);
        depthSamples = round((depth / 1000) * fs);
        
        % Sine wave modulation signal
        time = (0:length(inputAudio)-1)' / fs;
        modulation = depthSamples * sin(2 * pi * rate * time);
        
        flangerAudio = zeros(size(inputAudio));
        
        % Apply the flanger effect
        for n = 1:length(inputAudio)
            % Calculating delay for the current sample
            currentDelay = round(delayTimeSamples + modulation(n));
            
            % Ensure the delay is within bounds
            if n - currentDelay > 0
                flangerAudio(n) = inputAudio(n) + inputAudio(n - round(currentDelay));
            else
                % If the current delay exceeds the sample index, the
                % original sample is copied
                flangerAudio(n, :) = inputAudio(n, :);
            end
        end
        
        % Normalize the output to prevent clipping
        flangerAudio = flangerAudio / max(abs(flangerAudio(:)));

        % Testing
        disp(['Audio: ', num2str(inputAudio')]);
        disp(['Flanger audio: ', num2str(flangerAudio')]);
    end
    
    % REVERB
    function reverbAudio = reverbXXX(audio, reverbTime) % Obsolete
        reverbAudio = audio;
        reverbSamples = round(reverbTime * fs);

        for i = 1:length(audio)
            reverbAudio(i) = audio(i) + 0.5 * audio(max(1, i - reverbSamples));
        end

        % Testing
        disp(['Audio: ', num2str(audio')]);
        disp(['Reverb audio: ', num2str(reverbAudio')]);
    end
    
    function reverbAudio = reverb(audio, reverbTime, feedbackGain)
        % Convert delay time to samples
        delaySamples = round(reverbTime * fs);
        
        reverbAudio = zeros(size(audio));
        buffer = zeros(delaySamples, size(audio, 2));
        
        % Process the audio sample by sample
        for n = 1:length(audio)
            currentSample = audio(n, :);
            
            delayedSample = buffer(mod(n-1, delaySamples) + 1, :);
            
            % Calculate the new sample with feedback
            newSample = currentSample + feedbackGain * delayedSample;
            
            reverbAudio(n, :) = newSample;
            buffer(mod(n-1, delaySamples) + 1, :) = newSample;
        end
        
        % Normalize the output to avoid clipping
        reverbAudio = reverbAudio / max(abs(reverbAudio(:)));

        % Testing
        disp(['Audio: ', num2str(audio')]);
        disp(['Reverb audio: ', num2str(reverbAudio')]);
    end


    % I need to somehow get the information about the effects... 
    % (turned the script into a big function, to make everything 'public')
    function modifiedAudio = modifyAudio(audio) % make sure all effects are present
        modifiedAudio = delay(audio, delayTime, delayIntensity);
        modifiedAudio = chorus(modifiedAudio, chorusRate, chorusDepth);
        modifiedAudio = flanger(modifiedAudio, flangerRate, flangerDepth, flangerDelay);
        modifiedAudio = reverb(modifiedAudio, reverbTime, reverbFeedback);
    end
    
    %% UI
    function createUI(isPlaying)
        % Figure for the UI
        fig = uifigure('Name', 'Multi-Effect Unit', 'Position', [100, 100, 666, 444]);
    
        %% UI components
        % Drop down for audio file selction
        audioFileLabel = uilabel(fig, 'Position', [20, 400, 100, 22], 'Text', 'Audio File:');
        audioFileDropdown = uidropdown(fig, 'Position', [120, 400, 200, 22], ...
            'Items', listAudioLabels(), ...
            'ValueChangedFcn', @(dd, event) updateAudio(dd, isPlaying));
    
        % % Play button
        % playButton = uicontrol('Style', 'pushbutton', 'String', 'Play', ...
        %     'Position', [80, 360, 50, 20], ...
        %     'Callback', {@playAudio, audioClip, fs});
        
        % Delay effect
        delayPos = [75, 300];
        delayLabel = uilabel(fig, 'Position', [delayPos(1), delayPos(2), 100, 22], 'Text', 'Delay');

        delayTimeLabel = uilabel(fig, 'Position', [delayPos(1)-25, delayPos(2)-33, 100, 22], 'Text', 'Time');
        delayTimeSlider = uiknob(fig, 'Position', [delayPos(1)-25, delayPos(2)-100, 50, 50], ...
            'Limits', [0.1, 1], 'Value', 0.1, 'MajorTicks', 0.0:0.2:1, ...
            'ValueChangedFcn', @(sld, event) updateDelayTime(sld.Value));

        delayIntensityLabel = uilabel(fig, 'Position', [delayPos(1)+25, delayPos(2)-133, 100, 22], 'Text', 'Intensity');
        delayIntensitySlider = uiknob(fig, 'Position', [delayPos(1)+25, delayPos(2)-200, 50, 50], ...
            'Limits', [0.1, 1], 'Value', 0.1, 'MajorTicks', 0.0:0.2:1, ...
            'ValueChangedFcn', @(sld, event) updateDelayIntensity(sld.Value));
        
        % Chorus effect
        chorusPos = [200, 300];
        chorusLabel = uilabel(fig, 'Position', [chorusPos(1), chorusPos(2), 100, 22], 'Text', 'Chorus');

        chorusRateLabel = uilabel(fig, 'Position', [chorusPos(1)-25, chorusPos(2)-33, 100, 22], 'Text', 'Rate');
        chorusRateSlider = uiknob(fig, 'Position', [chorusPos(1)-25, chorusPos(2)-100, 50, 50], ...
            'Limits', [0.1, 5], 'Value', 0.1, 'MajorTicks', 0.5:0.5:5, ...
            'ValueChangedFcn', @(sld, event) updateChorusRate(sld.Value));

        chorusDepthLabel = uilabel(fig, 'Position', [chorusPos(1)+25, chorusPos(2)-133, 100, 22], 'Text', 'Depth');
        chorusDepthSlider = uiknob(fig, 'Position', [chorusPos(1)+25, chorusPos(2)-200, 50, 50], ...
            'Limits', [0.1, 1], 'Value', 0.1, 'MajorTicks', 0.0:0.1:1, ...
            'ValueChangedFcn', @(sld, event) updateChorusDepth(sld.Value));
        
        % Flanger effect
        flangerPos = [400, 300];
        flangerLabel = uilabel(fig, 'Position', [flangerPos(1), flangerPos(2), 100, 22], 'Text', 'Flanger');

        flangerRateLabel = uilabel(fig, 'Position', [flangerPos(1), flangerPos(2)-33, 100, 22], 'Text', 'Rate');
        flangerRateSlider = uiknob(fig, 'Position', [flangerPos(1), flangerPos(2)-100, 50, 50], ...
            'Limits', [0.1, 5], 'Value', 0.1, 'MajorTicks', 0.0:1.0:5, ...
            'ValueChangedFcn', @(sld, event) updateFlangerRate(sld.Value));

        flangerDepthLabel = uilabel(fig, 'Position', [flangerPos(1)-55, flangerPos(2)-133, 100, 22], 'Text', 'Depth');
        flangerDepthSlider = uiknob(fig, 'Position', [flangerPos(1)-55, flangerPos(2)-200, 50, 50], ...
            'Limits', [0.1, 0.5], 'Value', 0.1, 'MajorTicks', 0.0:0.1:0.5, ...
            'ValueChangedFcn', @(sld, event) updateFlangerDepth(sld.Value));

        flangerDelayLabel = uilabel(fig, 'Position', [flangerPos(1)+55, flangerPos(2)-133, 100, 22], 'Text', 'Delay');
        flangerDelaySlider = uiknob(fig, 'Position', [flangerPos(1)+55, flangerPos(2)-200, 50, 50], ...
            'Limits', [0.1, 1], 'Value', 0.1, 'MajorTicks', 0.0:0.1:1, ...
            'ValueChangedFcn', @(sld, event) updateFlangerDelay(sld.Value));
        
        % Reverb effect
        reverbPos = [550, 300];
        reverbLabel = uilabel(fig, 'Position', [reverbPos(1), reverbPos(2), 100, 22], 'Text', 'Reverb');

        reverbTimeLabel = uilabel(fig, 'Position', [reverbPos(1)-25, reverbPos(2)-33, 100, 22], 'Text', 'Time');
        reverbTimeSlider = uiknob(fig, 'Position', [reverbPos(1)-25, reverbPos(2)-100, 50, 50], ...
            'Limits', [0.1, 1], 'Value', 0.1, 'MajorTicks', 0.0:0.1:1, ...
            'ValueChangedFcn', @(sld, event) updateReverbTime(sld.Value));

        reverbFeedbackLabel = uilabel(fig, 'Position', [reverbPos(1)+25, reverbPos(2)-133, 100, 22], 'Text', 'Feedback:');
        reverbFeedbackSlider = uiknob(fig, 'Position', [reverbPos(1)+25, reverbPos(2)-200, 50, 50], ...
            'Limits', [0.1, 1], 'Value', 0.1, 'MajorTicks', 0.0:0.1:1, ...
            'ValueChangedFcn', @(sld, event) updateReverbFeedback(sld.Value));
    
        % List audio in the audio folder
        function audioLabels = listAudioLabels()
            audioLabels = ["Sine Wave - Low", "Sine Wave - Med", "Sine Wave - High", ...
            "Square Wave", "Triangle Wave", "Sawtooth Wave", "Chirp", "White Noise", ...
            "Brown Noise", "Grey Noise", "Blue Noise", "Pink Noise"];
        end
        
        %% Callbacks for updating audio clip and effects
        % AUDIO CLIP
        function updateAudio(dropdown, isPlaying)
            % This might seem unnecessary, but it makes sense to me, since
            % I first have to stop the playing audio to 'update' it, and on
            % the first loop around the 'audioToPlay' is not actually an
            % audioplayer yet :)
            if (isPlaying)
                stop(audioToPlay);
                isPlaying = false;
            end
            
            % Make a function with switch case that strcmp(),
            % dropdown.Value, an return the selected audio
            selectedAudioClip = getSelectedAudioClip(dropdown.Value);
            disp(['Dropdown Value: ', num2str(dropdown.Value)]);

            % Apply the effects
            %disp(['Normal Audio: ', num2str(selectedAudioClip]);
            modifiedAudio = modifyAudio(selectedAudioClip);
            %disp(['Modified Audio: ', num2str(modifiedAudio)]);
    
            audioToPlay = audioplayer(modifiedAudio, fs); %IDK where to actually play this

            play(audioToPlay);
            %disp('Im playing something now!');
            isPlaying = true;
        end
        
        % DELAY
        function updateDelayTime(sld)
            delayTime = sld;
            disp(['Delay time updated to: ', num2str(delayTime)]);
        end
        function updateDelayIntensity(sld)
            delayIntensity = sld;
            disp(['Delay intensity updated to: ', num2str(delayIntensity)]);
        end
    
        % CHORUS
        function updateChorusRate(sld)
            chorusRate = sld;
            disp(['Chorus rate updated to: ', num2str(chorusRate)]);
        end
        function updateChorusDepth(sld)
            chorusDepth = sld;
            disp(['Chorus depth updated to: ', num2str(chorusDepth)]);
        end
    
        % FLANGER
        function updateFlangerRate(sld)
            flangerRate = sld;
            disp(['Flanger rate updated to: ', num2str(flangerRate)]);
        end
        function updateFlangerDepth(sld)
            flangerDepth = sld;
            disp(['Flanger depth updated to: ', num2str(flangerDepth)]);
        end
        function updateFlangerDelay(sld)
            flangerDelay = sld;
            disp(['Flanger delay updated to: ', num2str(flangerDelay)]);
        end
    
        % REVERB
        function updateReverbTime(sld)
            reverbTime = sld;
            disp(['Reverb time updated to: ', num2str(reverbTime)]);
        end
        function updateReverbFeedback(sld)
            reverbFeedback = sld;
            disp(['Reverb feedback updated to: ', num2str(reverbFeedback)]);
        end
    end
end

%%NOTES
%{
opdater interaktion til instrumentalt look
	give interaktionerne navne
		skal måske lave en 'parent'?
lav en knap ved siden af dropdown til at starte audio (brug audioPlayer, da man kan stoppe lyd)
	stop lyd ved input
lav flere effekter?
gå mere i dybden med effekterne
	lige nu er de meget overfladiske
hav en graf for at visualisere ændringen i outputtet?

Sounds:
Sine Wave
Square Wave
Triangle Wave
Sawtooth
'Coloured' noise

Wahoo (Mario)
Wahh (Luigi)
Wilhelm Scream
Vine Boom
Windows Crash
Metal Pipe  

Effects:
Delay (Repeat)
Reverb (Trailing)
Chorus (Choir)
Flanger (Jet Plane Flyby)

Equalizer (leveling)
Phaser (wahwahwahwah)
Pitch Shifter (Shifts the pitch)
Tremolo (change of volume)
Vibrato (change of pitch)
Distortion (pretty self explanatory)

Design:
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓                                                    ▓
▓ Dropdown      ▓▓▓▓▓▓▓▓▓▓▓▓▓▓      Master Volume    ▓
▓ ▓______▓      ▓            ▓      0..33..66..100   ▓
▓               ▓            ▓                       ▓
▓               ▓▓▓▓▓▓▓▓▓▓▓▓▓▓                       ▓
▓                                                    ▓
▓            Effect1              Effect2            ▓
▓               O                    O               ▓
▓   Effect3            Effect4             Effect5   ▓
▓      O                  O                   O      ▓
▓                                                    ▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
%}