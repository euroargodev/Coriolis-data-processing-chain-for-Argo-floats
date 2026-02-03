% ------------------------------------------------------------------------------
% Collect the TECH_FLAG_IceAlgorithmStatus_bit values.
%
% SYNTAX :
%   nc_get_tech_ice_status
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2025 - RNU - creation
% ------------------------------------------------------------------------------
function nc_get_tech_ice_status(varargin)

% top directory of input NetCDF TECH_AUX files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\ARV_IR\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\APF9_IR_RUDICS\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\APF11_IR_RUDICS\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\CTS5_OSEAN\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\CTS5_USEA\';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';


floatList = [];
if (nargin == 0)
   fprintf('Process alla the flaots of the directory: %s\n', DIR_INPUT_NC_FILES);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

logFile = [DIR_LOG_FILE '/' 'nc_get_tech_ice_status_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'nc_get_tech_ice_status_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end

% output CSV file header
header = 'Status value;;1:Transmission;2:ICE activated;3:Avoidance enable;4:Abort profile;5:ISA;6:breakup;7:hanging;8:sat_mask;9:forced;10:AC1;11:ICE cycle;;Occ. float;Occ. cycle;;Floats and cycles lists';

fprintf(fidOut, '%s\n', header);

% variables to store information
tabValue = [];
tabFloat = [];
tabCycle = [];

floatDir = dir(DIR_INPUT_NC_FILES);
nbDone = 0;
for idDir = 1:length(floatDir)
   % for idDir = 1:10

   floatDirName = floatDir(idDir).name;
   floatDirPathName = [DIR_INPUT_NC_FILES '/' floatDirName];
   if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))

      floatNum = str2double(floatDirName);
      if (~isempty(floatList))
         if (nbDone == length(floatList))
            break
         end
         if (ismember(floatNum, floatList))
            fprintf('%s\n', floatDirName);
            nbDone = nbDone + 1;
         else
            continue
         end
      elseif (isempty(floatList))
         fprintf('%03d/%03d %s\n', idDir-2, length(floatDir)-2, floatDirName);
      end

      floatTechFilePathName = [floatDirPathName '/auxiliary/' floatDirName '_tech_aux.nc'];

      if (exist(floatTechFilePathName, 'file') == 2)

         % retrieve information from technical file
         wantedInputVars = [ ...
            {'CYCLE_NUMBER'} ...
            {'TECHNICAL_PARAMETER_NAME'} ...
            {'TECHNICAL_PARAMETER_VALUE'} ...
            ];
         [techData] = get_data_from_nc_file(floatTechFilePathName, wantedInputVars);
         idVal = find(strcmp('CYCLE_NUMBER', techData(1:2:end)) == 1, 1);
         cycleNumber = techData{2*idVal};
         idVal = find(strcmp('TECHNICAL_PARAMETER_NAME', techData(1:2:end)) == 1, 1);
         techParamNameList = cellstr(techData{2*idVal}');
         idVal = find(strcmp('TECHNICAL_PARAMETER_VALUE', techData(1:2:end)) == 1, 1);
         techParamValueList = cellstr(techData{2*idVal}');

         idF = find(strcmp('TECH_FLAG_IceAlgorithmStatus_bit', techParamNameList));
         if (isempty(idF))
            fprintf('WARNING: Variable %s not present in file : %s\n', ...
               'TECH_FLAG_IceAlgorithmStatus_bit', floatTechFilePathName);
         end
         for id = 1:length(idF)
            value = bin2dec(techParamValueList{idF(id)});
            cycle = cycleNumber(idF(id));

            idVal = find(tabValue == value);
            if (isempty(idVal))
               tabValue = [tabValue; value];
               tabFloat = [tabFloat; [length(tabValue) floatNum]];
               tabCycle = [tabCycle; [size(tabFloat, 1) cycle]];
            else
               idFloat = find((tabFloat(:, 1) == idVal) & (tabFloat(:, 2) == floatNum));
               if (isempty(idFloat))
                  tabFloat = [tabFloat; [idVal floatNum]];
                  tabCycle = [tabCycle; [size(tabFloat, 1) cycle]];
               else
                  tabCycle = [tabCycle; [idFloat cycle]];
               end
            end
         end
      end
   end
end

[~, idSort] = sort(tabValue);
for idVal = idSort'
   value = tabValue(idVal);
   floatListId = find(tabFloat(:, 1) == idVal);

   occCycle = 0;
   tabFloatCyFloatNum = [];
   tabFloatCyStr = [];
   for idFloat = floatListId'
      floatNum = tabFloat(idFloat, 2);
      cyNumListId = find(tabCycle(:, 1) == idFloat);
      cyNumList = tabCycle(cyNumListId, 2);
      occCycle = occCycle + length(cyNumList);
      floatCyStr = sprintf('%d:%s', floatNum, squeeze_cycle_num_list_for_ascii_output(cyNumList));
      tabFloatCyFloatNum = [tabFloatCyFloatNum; floatNum];
      tabFloatCyStr{end+1} = floatCyStr;
   end
   [~, idSort2] = sort(tabFloatCyFloatNum);
   tabFloatCyStr = tabFloatCyStr(idSort2);
   floatCyListStr = sprintf('%s;', tabFloatCyStr{:});

   valueBit = dec2bin(value, 11);
   valueBitStr = sprintf('%c;', fliplr(valueBit));

   fprintf(fidOut, '%d;;%s;;%d;%d;;%s\n', ...
      value, valueBitStr(1:end-1), length(floatListId), occCycle, floatCyListStr(1:end-1));

end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Create a squeezed string version of a given cycle number list.
%
% SYNTAX :
% [o_cyNumListStr] = squeeze_cycle_num_list_for_ascii_output(a_cyNumList)
%
% INPUT PARAMETERS :
%   a_cyNumList : input cycle number list
%
% OUTPUT PARAMETERS :
%   o_cyNumListStr : output char suqeezed version of the cycle number list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/13/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cyNumListStr] = squeeze_cycle_num_list_for_ascii_output(a_cyNumList)

% output parameters initialization
o_cyNumListStr = '';

if (isempty(a_cyNumList))
   return
end

cyNumList = unique(a_cyNumList);
idSet = find(diff(cyNumList) > 1);
idStart = 1;
o_cyNumListStr = '';
for id = 1:length(idSet)+1
   if (id <= length(idSet))
      idStop = idSet(id);
   else
      idStop = length(cyNumList);
   end
   if (length(cyNumList(idStart:idStop)) == 1)
      o_cyNumListStr = [o_cyNumListStr sprintf('%d,', cyNumList(idStart:idStop))];
   else
      o_cyNumListStr = [o_cyNumListStr sprintf('%d to %d,', cyNumList(idStart), cyNumList(idStop))];
   end
   idStart = idStop + 1;
end
if (~isempty(o_cyNumListStr))
   o_cyNumListStr(end) = [];
end

return
