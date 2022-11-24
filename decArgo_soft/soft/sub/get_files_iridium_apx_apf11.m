% ------------------------------------------------------------------------------
% Retrieve the list of science_log, irad_log, vitals_log system_log, 
% critical_log and production_log (CSV decoder only) files for a float and a
% given cycle.
%
% SYNTAX :
%  [o_scienceLogFileList, o_iradLogFileList, o_vitalsLogFileList, ...
%    o_systemLogFileList, o_criticalLogFileList, ...
%    o_productionLogFileList] = get_files_iridium_apx_apf11( ...
%    a_floatRudicsId, a_cycleNum, a_dirName)
%
% INPUT PARAMETERS :
%   a_floatRudicsId : float Rudics Id
%   a_cycleNum      : concerned cycle number
%   a_dirName       : directory containing the files
%
% OUTPUT PARAMETERS :
%   o_scienceLogFileList    : list of science_log files
%   o_iradLogFileList       : list of irad_log files
%   o_vitalsLogFileList     : list of vitals_log files
%   o_systemLogFileList     : list of system_log files
%   o_criticalLogFileList   : list of critical_log files
%   o_productionLogFileList : list of production_log files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_scienceLogFileList, o_iradLogFileList, o_vitalsLogFileList, ...
   o_systemLogFileList, o_criticalLogFileList, ...
   o_productionLogFileList] = get_files_iridium_apx_apf11( ...
   a_floatRudicsId, a_cycleNum, a_dirName)

% output parameters initialization
o_scienceLogFileList = [];
o_iradLogFileList = [];
o_vitalsLogFileList = [];
o_systemLogFileList = [];
o_criticalLogFileList = [];
o_productionLogFileList = [];

% output CSV file Id
global g_decArgo_outputCsvFileId;


% search for expected float files
floatIriDirName = a_dirName;
if ~(exist(floatIriDirName, 'dir') == 7)
   fprintf('ERROR: Iridium directory not found: %s\n', floatIriDirName);
   return
end

% science_log files
fileNames = dir([floatIriDirName sprintf('%s.%03d.*.science_log.bin', a_floatRudicsId, a_cycleNum)]);
for idFile = 1:length(fileNames)
   o_scienceLogFileList{end+1} = [floatIriDirName '/' fileNames(idFile).name];
end

% irad_log files
fileNames = dir([floatIriDirName sprintf('%s.%03d.*.irad_log.bin', a_floatRudicsId, a_cycleNum)]);
for idFile = 1:length(fileNames)
   o_iradLogFileList{end+1} = [floatIriDirName '/' fileNames(idFile).name];
end

% vitals_log files
fileNames = dir([floatIriDirName sprintf('%s.%03d.*.vitals_log.bin', a_floatRudicsId, a_cycleNum)]);
for idFile = 1:length(fileNames)
   o_vitalsLogFileList{end+1} = [floatIriDirName '/' fileNames(idFile).name];
end

% system_log files
fileNames = dir([floatIriDirName sprintf('%s.%03d.*.system_log.txt', a_floatRudicsId, a_cycleNum)]);
for idFile = 1:length(fileNames)
   o_systemLogFileList{end+1} = [floatIriDirName '/' fileNames(idFile).name];
end

% critical_log files
fileNames = dir([floatIriDirName sprintf('%s.%03d.*.critical_log.txt', a_floatRudicsId, a_cycleNum)]);
for idFile = 1:length(fileNames)
   o_criticalLogFileList{end+1} = [floatIriDirName '/' fileNames(idFile).name];
end

if (~isempty(g_decArgo_outputCsvFileId))
   % production_log files
   fileNames = dir([floatIriDirName sprintf('%s.%03d.*.production_log.txt', a_floatRudicsId, a_cycleNum)]);
   for idFile = 1:length(fileNames)
      o_productionLogFileList{end+1} = [floatIriDirName '/' fileNames(idFile).name];
   end
end
      
return
