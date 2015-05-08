% post-process the posterior (unnormalized) p, together with high passed
% signal wave1.
%
% Run driver_signal, noise_model first
%
% author: Rex
%

% left and right window size
lwSize = 20;
rwSize = 20;
wSize = lwSize + rwSize + 1;
threshold = 1.5;

lscore = zeros(size(p));
rscore = zeros(size(p));
% onset: p has high value in left window, low value in right window
for i = lwSize + 1: length(p) - rwSize
    l = p(i - lwSize: i);
    r = p(i: i + rwSize);
    lscore(i) = sum(l <= threshold);
    rscore(i) = sum(r <= threshold);
end

figure
subplot(2, 1, 1);
plot(inds(1: end - 1), lscore);
subplot(2, 1, 2);
posterior = lscore - rscore;
plot(inds(1: end - 1), lscore - rscore);
csvwrite('data/GA7-15-98RPEARF-posterior.csv', posterior);

%% Isolate signal regions

% posterior threshold
postThresh = 3;

% we allow this amount of zero entries within the signal. If the gap is
% larger than that, we split the signal into two.
allowedGap = wSize * 2;

% sign does not matter here
posterior = abs(posterior);

nSignalRegions = 0;
onsets = zeros(length(posterior), 1);
offsets = zeros(length(posterior), 1);
inSignal = false;
for i = 1: length(posterior) - allowedGap
    seg = posterior(i: i + allowedGap - 1);
    % transfer into signal region
    if ~inSignal && seg(1) >= postThresh
        inSignal = true;
        nSignalRegions = nSignalRegions + 1;
        onsets(nSignalRegions) = i;
    % transfer out of signal region:
    % When the values are less than 4 in allowed gap, followed by a
    % sequence of zeros
    elseif inSignal && ~any(seg >= postThresh) && ~any(posterior(i + allowedGap: i + 2*allowedGap))
        inSignal = false;
        
        % if the length of this detected signal is too insignificant,
        % discard
        if i - onsets(nSignalRegions) <= wSize
            onsets(nSignalRegions) = 0;
            nSignalRegions = nSignalRegions - 1;
        else
            offsets(nSignalRegions) = i;
        end
    end
end
if inSignal
    offsets(nSignalRegions) = length(posterior);
end
onsets = onsets(1: nSignalRegions);
offsets = offsets(1: nSignalRegions);

%% visualize
figure
subplot(2, 1, 1);
hold on
for i = 1: nSignalRegions
    if i == 1
        plot(1: onsets(i) - 1, wave2(1: onsets(i) - 1), 'b');
    else
        plot(offsets(i-1) + 1: onsets(i) - 1, wave2(offsets(i-1) + 1: onsets(i) - 1), 'b');
    end
    plot(onsets(i): offsets(i), wave2(onsets(i): offsets(i)), 'r');
end
if offsets(nSignalRegions) <= length(posterior)
    tmpInds = offsets(nSignalRegions-1) + 1: length(posterior);
    plot(tmpInds, wave2(tmpInds), 'b');
end

hold off
title('singals classified');

subplot(2, 1, 2);
plot(wave2);
