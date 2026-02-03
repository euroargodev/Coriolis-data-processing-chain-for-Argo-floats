% ------------------------------------------------------------------------------
% Print technical data in a CSV file.
%
% SYNTAX :
% print_pfv2_conf_data_in_csv(a_floatData)
%
% INPUT PARAMETERS :
%   a_floatData : float data information
%                 1: fileType
%                 2: missionNum
%                 3: cycleNum
%                 4: fileName
%                 5: tabTechEvt or tabTech or measData or confLabels
%                 6: tabTechTime or confValues
%                 7: tabTechTraj
%                 8: tabTechBuoy
%                 9: tabTechSpy
%                 10: selfTestDate or settingDate or cycleLastDate
%                 11: float HEX base file Name
%                 12: float final file name
%                 13: zip file size
%                 14: final file size
%                 15: SBD file information (1: SBD file name, 2: SBD file date, 3: SBD file size, 4: data file size
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/02/2024 - RNU - creation
% ------------------------------------------------------------------------------
function print_pfv2_conf_data_in_csv(a_floatData)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_floatData))
   return
end

fileTypeStr = 'Config';
missionNum = a_floatData{2};
cycleNum = a_floatData{3};
fileName = a_floatData{4};
confLabels = a_floatData{5};
confValues = a_floatData{6};
settingDate = a_floatData{10};

fprintf(g_decArgo_outputCsvFileId, '%d;%d;%d;%s;File name;%s;File date; %s\n', ...
   g_decArgo_floatNum, ...
   missionNum, ...
   cycleNum, ...
   fileTypeStr, ...
   fileName, ...
   julian_2_gregorian_dec_argo(settingDate));

for idCfg = 1:length(confLabels)
   fprintf(g_decArgo_outputCsvFileId, '%d;%d;%d;%s;%s;%s\n', ...
      g_decArgo_floatNum, ...
      missionNum, ...
      cycleNum, ...
      fileTypeStr, ...
      confLabels{idCfg}, ...
      confValues{idCfg});
end

return
