% ------------------------------------------------------------------------------
% Create information on transmitted files.
%
% SYNTAX :
% print_pfv2_file_trans_info(a_floatData)
%
% INPUT PARAMETERS :
%   o_floatData : float data information
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/15/2024 - RNU - creation
% ------------------------------------------------------------------------------
function print_pfv2_file_trans_info(a_floatData)

% current float WMO number
global g_decArgo_floatNum;

% configuration values
global g_decArgo_dirOutputCsvFile;


% CSV output
csvFilepathName = [g_decArgo_dirOutputCsvFile '\' num2str(g_decArgo_floatNum) '_files_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fId = fopen(csvFilepathName, 'wt');
if (fId ~= -1)

   header = '#;File name;Data type;HEX base file name;File size;Zip file size;Zip gain (%);Nb SBD files;First date;End date;SBD file size;SBD data file size;SBD file size/File size (%)';
   fprintf(fId, '%s\n', header);

   fileSize = sum([a_floatData{:, 14}]);
   zipFileSize = sum([a_floatData{:, 13}]);
   zipGain = 100*(fileSize-zipFileSize)/fileSize;
   nbSbdFile = 0;
   dates = [];
   sbdFileSize = 0;
   sbdDataFileSize = 0;
   for idL = 1:size(a_floatData, 1)
      nbSbdFile = nbSbdFile + size(a_floatData{idL, 15}, 1);
      dates = [dates [a_floatData{idL, 15}{:, 2}]];
      sbdFileSize = sbdFileSize + sum([a_floatData{idL, 15}{:, 3}]);
      sbdDataFileSize = sbdDataFileSize + sum([a_floatData{idL, 15}{:, 4}]);
   end
   cost = 100*sbdFileSize/fileSize;

   fprintf(fId, '0;TOTAL (%d files %.1f SBD per file);;;%d;%d;%.1f;%d; %s; %s;%d;%d;%.1f\n0\n', ...
      size(a_floatData, 1), ...
      nbSbdFile/size(a_floatData, 1), ...
      fileSize, ...
      zipFileSize, ...
      zipGain, ...
      nbSbdFile, ...
      julian_2_gregorian_dec_argo(min(dates)), ...
      julian_2_gregorian_dec_argo(max(dates)), ...
      sbdFileSize, ...
      sbdDataFileSize, ...
      cost ...
      );

   for idL = 1:size(a_floatData, 1)

      fprintf(fId, '%d;%s;%s;0x%s;%d;%d;%.1f;%d; %s; %s;%d;%d;%.1f\n', ...
         idL, ...
         a_floatData{idL, 4}, ...
         get_type_str(a_floatData{idL, 1}), ...
         a_floatData{idL, 11}, ...
         a_floatData{idL, 14}, ...
         a_floatData{idL, 13}, ...
         100*(a_floatData{idL, 14}-a_floatData{idL, 13})/a_floatData{idL, 14}, ...
         size(a_floatData{idL, 15}, 1), ...
         julian_2_gregorian_dec_argo(min([a_floatData{idL, 15}{:, 2}])), ...
         julian_2_gregorian_dec_argo(max([a_floatData{idL, 15}{:, 2}])), ...
         sum([a_floatData{idL, 15}{:, 3}]), ...
         sum([a_floatData{idL, 15}{:, 4}]), ...
         100*sum([a_floatData{idL, 15}{:, 3}])/a_floatData{idL, 14} ...
         );
   end

   fclose(fId);

end

return

% ------------------------------------------------------------------------------
% Retrieve the description of a data type code.
%
% SYNTAX :
% [o_dataTypeStr] = get_type_str(a_dataType)
%
% INPUT PARAMETERS :
%   a_dataType  : data type number
%
% OUTPUT PARAMETERS :
%   o_dataTypeStr : data type description
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataTypeStr] = get_type_str(a_dataType)

switch (a_dataType)
   case -1
      o_dataTypeStr = 'Ignored';
   case 10
      o_dataTypeStr = 'Self test';
   case 11
      o_dataTypeStr = 'Tech #1';
   case 12
      o_dataTypeStr = 'Tech #2';
   case 13
      o_dataTypeStr = 'Eol';
   case 20
      o_dataTypeStr = 'Desc park';
   case 21
      o_dataTypeStr = 'Park drift';
   case 22
      o_dataTypeStr = 'Desc prof';
   case 23
      o_dataTypeStr = 'Prof drift';
   case 24
      o_dataTypeStr = 'Asc';
   case 25
      o_dataTypeStr = 'In air';
   case 30
      o_dataTypeStr = 'Config';
   case 40
      o_dataTypeStr = 'Cmd';

   otherwise
      fprintf('WARNING: Data packet type #%d\n', ...
         a_dataType);
      o_dataTypeStr = '';
end

return
