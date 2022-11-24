% ------------------------------------------------------------------------------
% Retrieve the list of Apex APF11 float files associated to a given list of
% cycle numbers.
%
% SYNTAX :
%  [o_fileList] = get_cycle_float_file_list_iridium_rudics_apx_apf11( ...
%    a_floatNum, a_floatRudicsId, a_cycleList, a_floatLaunchDate)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_floatRudicsId   : float Rudics Id
%   a_cycleList       : list of cycles to consider
%   a_floatLaunchDate : float launch date
%
% OUTPUT PARAMETERS :
%   o_fileList  : associated list of float files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/06/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileList] = get_cycle_float_file_list_iridium_rudics_apx_apf11( ...
   a_floatNum, a_floatRudicsId, a_cycleList, a_floatLaunchDate)

% output parameters initialization
o_fileList = [];

% configuration values
global g_decArgo_iridiumDataDirectory;

% default values
global g_decArgo_janFirst1950InMatlab;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% delay to recover config messages before launch date
global g_decArgo_maxIntervalToRecoverConfigMessageBeforeLaunchDate;


% search for existing float files
iriDirName = [g_decArgo_iridiumDataDirectory '/' a_floatRudicsId '_' num2str(a_floatNum) '/archive/'];
if ~(exist(iriDirName, 'dir') == 7)
   fprintf('ERROR: Iridium directory not found: %s\n', iriDirName);
   return
end

fileNameList = [];
fileNames = dir([iriDirName a_floatRudicsId '*.gz']);
prevDate = '';
for idFile = 1:length(fileNames)
   fileName = fileNames(idFile).name;
   idF1 = strfind(fileName(length(a_floatRudicsId)+1:end), '.');
   cyNum = fileName(length(a_floatRudicsId)+idF1(1)+1:length(a_floatRudicsId)+idF1(2)-1);
   [cyNum, status] = str2num(cyNum);
   if ((status == 1) && ismember(cyNum, a_cycleList))
      if (~isempty(a_floatLaunchDate))
         fileDateStr = fileName(length(a_floatRudicsId)+idF1(2)+1:length(a_floatRudicsId)+idF1(3)-1);
         fileDate = datenum(fileDateStr, 'yyyymmddTHHMMSS') - g_decArgo_janFirst1950InMatlab;
         if (strcmp(fileDateStr, '00000000T000000') && ~isempty(prevDate)) % 6904113 #68
            fileDate = prevDate;
         end
         if (isempty(g_decArgo_outputCsvFileId))
            if (fileDate < a_floatLaunchDate)
               continue
            end
         else
            % in the CSV decoder, we try to recover production_log files
            if (fileDate < a_floatLaunchDate - g_decArgo_maxIntervalToRecoverConfigMessageBeforeLaunchDate)
               continue
            end
         end
         prevDate = fileDate;
      end
      fileNameList{end+1} = fileName;
   end
end

o_fileList = fileNameList;

return
