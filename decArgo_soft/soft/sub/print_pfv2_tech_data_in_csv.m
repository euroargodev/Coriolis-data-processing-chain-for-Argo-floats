% ------------------------------------------------------------------------------
% Print technical data in a CSV file.
%
% SYNTAX :
% print_pfv2_tech_data_in_csv(a_floatData)
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
%                 10: selfTestDate or settingDate
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
function print_pfv2_tech_data_in_csv(a_floatData)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_floatData))
   return
end

fileType = a_floatData{1};
missionNum = a_floatData{2};
cycleNum = a_floatData{3};
fileName = a_floatData{4};
tabEvt = a_floatData{5};
selfTestDate = a_floatData{10};

switch (fileType)

   case 10 % seltTest
      missionNum = -1;
      cycleNum = -1;
      fileTypeStr = 'SelfTest';

      fprintf(g_decArgo_outputCsvFileId, '%d;%d;%d;%s;File name;%s;File date; %s\n', ...
         g_decArgo_floatNum, ...
         missionNum, ...
         cycleNum, ...
         fileTypeStr, ...
         fileName, ...
         julian_2_gregorian_dec_argo(selfTestDate));

   case 11 % tech_1

      fileTypeStr = 'Tech_1';

      fprintf(g_decArgo_outputCsvFileId, '%d;%d;%d;%s;File name;%s\n', ...
         g_decArgo_floatNum, ...
         missionNum, ...
         cycleNum, ...
         fileTypeStr, ...
         fileName);

   case 12 % tech_2

      fileTypeStr = 'Tech_2';

      fprintf(g_decArgo_outputCsvFileId, '%d;%d;%d;%s;File name;%s\n', ...
         g_decArgo_floatNum, ...
         missionNum, ...
         cycleNum, ...
         fileTypeStr, ...
         fileName);

   case 13 % Eol

      fileTypeStr = 'Eol';

      fprintf(g_decArgo_outputCsvFileId, '%d;%d;%d;%s;File name;%s\n', ...
         g_decArgo_floatNum, ...
         missionNum, ...
         cycleNum, ...
         fileTypeStr, ...
         fileName);

   otherwise
      fprintf('ERROR: Float #%d: File type (%d) not implemented yet for file %s\n', ...
         g_decArgo_floatNum, ...
         fileType, ...
         fileName);
      return
end

for idEvt = 1:length(tabEvt)
   evt = tabEvt(idEvt);

   fprintf(g_decArgo_outputCsvFileId, '%d;%d;%d;%s;%s;%s; %s\n', ...
      g_decArgo_floatNum, ...
      missionNum, ...
      cycleNum, ...
      fileTypeStr, ...
      evt.class, ...
      evt.label, ...
      evt.valueStr);
end

return
