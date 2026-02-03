% ------------------------------------------------------------------------------
% Print technical data in a CSV file.
%
% SYNTAX :
% print_pfv2_conf_diff_data_in_csv(a_floatData)
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
function print_pfv2_conf_diff_data_in_csv(a_floatData, a_floatDataPrev)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_floatData))
   return
end

fileTypeStr = 'ConfigDiff';
missionNum = a_floatData{2};
cycleNum = a_floatData{3};
fileName = a_floatData{4};
confLabels = a_floatData{5};
confValues = a_floatData{6};
settingDate = a_floatData{10};
fileNamePrev = a_floatDataPrev{4};
confLabelsPrev = a_floatDataPrev{5};
confValuesPrev = a_floatDataPrev{6};
settingDatePrev = a_floatDataPrev{10};

if (length(confLabels) == length(confLabelsPrev))
   if (all(strcmp(confLabels, confLabelsPrev) == 1))
      idDiff = find(~strcmp(confValues, confValuesPrev));

      if (~isempty(idDiff))

         fprintf(g_decArgo_outputCsvFileId, '%d;%d;%d;%s;File name;%s vs %s;File date; %s vs %s\n', ...
            g_decArgo_floatNum, ...
            missionNum, ...
            cycleNum, ...
            fileTypeStr, ...
            fileName, ...
            fileNamePrev, ...
            julian_2_gregorian_dec_argo(settingDate), ...
            julian_2_gregorian_dec_argo(settingDatePrev));

         for idCfg = idDiff
            fprintf(g_decArgo_outputCsvFileId, '%d;%d;%d;%s;%s;%s;=>;%s\n', ...
               g_decArgo_floatNum, ...
               missionNum, ...
               cycleNum, ...
               fileTypeStr, ...
               confLabels{idCfg}, confValuesPrev{idCfg}, confValues{idCfg});
         end
      end
   else
      fprintf('ERROR: Float #%d: Configuration labels fiffer %s vs %s\n', ...
         g_decArgo_floatNum, ...
         fileName, ...
         fileNamePrev);
   end
else
   fprintf('ERROR: Float #%d: Configuration length fiffer %s => %d vs %s => %d\n', ...
      g_decArgo_floatNum, ...
      fileName, length(confLabels), ...
      fileNamePrev, length(confValuesPrev));
end

return
