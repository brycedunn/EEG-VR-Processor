% This script takes as input a .csv file output from the Brightline VR
% system and processes the data.
% Bryce Dunn 2021
%% Select File (Brightline .csv file)
fprintf("Select .csv file to import: \n")
[fname, fdir] = uigetfile( ...
    {'*.csv*', 'Text Files (*.csv)'}, ...
    'Pick a file');
% Create fully-formed filename as a string
filename = fullfile(fdir, fname);
% Check that file exists
assert(exist(filename, 'file') == 2, '%s does not exist.', filename);
%% Import Data as table of chars
fprintf("Importing Data...\n")
T = readtable(filename,...
    'ReadVariableNames', true,... % Keep column headers as var names
    'Format','%s%s%s%s'); % Format every column as char array
T.Properties.Description = fname;
%% Detect number of recording sessions in file
num_scenes = numel(find(T.EntryType == "BeginScene"));
fprintf("Number of scenes recorded in this file: %d \n", num_scenes)
%% Prepare EEG Data Arrays
FP1 = str2double(T.Value(find(string(T.EntryType) == "EEG_FP1")));
FP2 = str2double(T.Value(find(string(T.EntryType) == "EEG_FP2")));
C3 = str2double(T.Value(find(string(T.EntryType) == "EEG_C3")));
C4 = str2double(T.Value(find(string(T.EntryType) == "EEG_C4")));
P7 = str2double(T.Value(find(string(T.EntryType) == "EEG_P7")));
P8 = str2double(T.Value(find(string(T.EntryType) == "EEG_P8")));
O1 = str2double(T.Value(find(string(T.EntryType) == "EEG_O1")));
O2 = str2double(T.Value(find(string(T.EntryType) == "EEG_O2")));
%% EMP_BIO Array
EMP = str2double(strip(string(T.Value(find(string(T.EntryType) == "EMP_BIO"))),'"'));
%% Timestamp
EEG_time = str2double(T.TimeStamp(find(string(T.EntryType) == "EEG_FP1")));
EMP_time = str2double(T.TimeStamp(find(string(T.EntryType) == "EMP_BIO")));
%% Create New Table for Blink Data (first 50 samples)
blink_header = {'FP1', 'FP2', 'C3', 'C4', 'P7', 'P8', 'O1', 'O2', 'Time'};
blinktime = EEG_time(1:50);
blinktime = blinktime-blinktime(1); % Blink time is zero'd
Blink = table(FP1(1:50),FP2(1:50),C3(1:50),C4(1:50),P7(1:50),P8(1:50),O1(1:50),O2(1:50),blinktime);
Blink.Properties.VariableNames = blink_header;
Blink.Properties.Description = 'Blink';
%% New Table for Session EEG Data
EEG_session_time = EEG_time(51:end);
session_header = {'FP1', 'FP2', 'C3', 'C4', 'P7', 'P8', 'O1', 'O2', 'Time'};
Session = table(FP1(51:end),FP2(51:end),C3(51:end),C4(51:end),P7(51:end),P8(51:end),O1(51:end),O2(51:end),EEG_session_time);
Session.Properties.VariableNames = session_header;
%% New Table for E4 Empatica Data
E4_header = {'BPM', 'Time'};
E4 = table(EMP, EMP_time);
E4.Properties.VariableNames = E4_header;
figure; plot(E4.Time,E4.BPM) % Plot EMP Data
xlabel("Time (sec)");ylabel("BPM");title("EMP Data")
%% Identify Cue Events
prop_index = find(string(T.EntryType) == "PROP_LookAt");
fade_index = find(string(T.EntryType) == "PROP_FadeOut");
BeginScene_index = find(string(T.EntryType) == "BeginScene");
%% Blink Plot
%% EEG Raw Signal Plot
s = 1:numel(FP1);
figure; plot(s,FP1)
hold on
plot(s,FP2)
plot(s,C3)
plot(s,C4)
plot(s,P7)
plot(s,P8)
plot(s,O1)
plot(s,O2)
title('Raw EEG Signal')
xlabel('EEG Sample')
ylabel('Signal Amplitude, uV')
%% EEG Data as an Array
global EEGData
% Session data is separated from blink data
EEGData = [Session.FP1 Session.FP2 Session.C3 Session.C4 Session.P7 Session.P8 Session.O1 Session.O2]';
%% Open EEGLAB
addpath(genpath('EEGLAB')); % The folder name containing EEGLAB
%eeglab
%% Import EEG data to EEGLAB
chanfile = 'C:\\Users\\Shenanigans\\Documents\\GMU\\GRA\\ChanLoc.ced'; % Location of channel loc file
EEG = pop_importdata('dataformat','array','nbchan',8,'data','EEGData','srate',25,'pnts',0,'xmin',0,'chanlocs',chanfile);
EEG.setname=fname; % Name the dataset
EEG=pop_chanedit(EEG, 'forcelocs',[],'nosedir','+Y'); % Rotate channels so nose is in +Y direction
EEG = pop_eegfiltnew(EEG, 'locutoff',0.5); % High-Pass Filter, 0.5 Hz
EEG = eeg_checkset( EEG );
figure; topoplot([],EEG.chanlocs, 'style', 'blank',  'electrodes', 'labelpoint', 'chaninfo', EEG.chaninfo); % Plot chanlocs
pop_eegplot( EEG, 1, 1, 1);
