% ------------------------------------------------------------------------------
% Export VSS detailed information with Coriolis data base technical
% parameter codes.
%
% SYNTAX :
%   export_data_for_vss
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function export_data_for_vss()

% file with meta-data for VSS
inputFileName = 'C:\users\RNU\Argo\work\data_for_vss.txt';
inputFileName = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\misc_info\data_for_vss_nke_old_versions.txt';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


logFile = [DIR_LOG_CSV_FILE '/' 'export_data_for_vss_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'export_data_for_vss_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return;
end
header = ['PLATFORM_CODE; TECH_PARAMETER_ID; DIM_LEVEL; ' ...
   'CORIOLIS_TECH_METADATA.PARAMETER_VALUE; TECH_PARAMETER_CODE'];
fprintf(fidOut, '%s\n', header);

data = load(inputFileName);
wmo = data(:, 1);
dacFormatId = data(:, 2);
nbThreshold = data(:, 3);
thresholds = data(:, 4:5);
thicknesses = data(:, 6:8);

for idF = 1:length(wmo)
   if (nbThreshold(idF) == 1)
      threshold1 = thresholds(idF, 1);
      if (threshold1 ~= 9999)
         fprintf(fidOut, '%d; %d; %d; %d; %s; %f\n', ...
            wmo(idF), 2148, 1, ...
            threshold1, 'SHALLOW_DEEP_THRESHOLD', dacFormatId(idF));
      end
      
      thickness1 = thicknesses(idF, 1);
      if (thickness1 ~= 9999)
         fprintf(fidOut, '%d; %d; %d; %d; %s; %f\n', ...
            wmo(idF), 1358, 1, ...
            thickness1, 'SURF_SLICE_THICKNESS', dacFormatId(idF));
      end
      thickness2 = thicknesses(idF, 2);
      if (thickness2 ~= 9999)
         fprintf(fidOut, '%d; %d; %d; %d; %s; %f\n', ...
            wmo(idF), 1360, 1, ...
            thickness2, 'DEPTH_SLICE_THICKNESS', dacFormatId(idF));
      end
   else
      threshold1 = thresholds(idF, 1);
      if (threshold1 ~= 9999)
         fprintf(fidOut, '%d; %d; %d; %d; %s; %f\n', ...
            wmo(idF), 1356, 1, ...
            threshold1, 'INT_SURF_THRESHOLD', dacFormatId(idF));
      end
      threshold2 = thresholds(idF, 2);
      if (threshold2 ~= 9999)
         fprintf(fidOut, '%d; %d; %d; %d; %s; %f\n', ...
            wmo(idF), 1357, 1, ...
            threshold2, 'DEPTH_INT_THRESHOLD', dacFormatId(idF));
      end
      
      thickness1 = thicknesses(idF, 1);
      if (thickness1 ~= 9999)
         fprintf(fidOut, '%d; %d; %d; %d; %s; %f\n', ...
            wmo(idF), 1358, 1, ...
            thickness1, 'SURF_SLICE_THICKNESS', dacFormatId(idF));
      end
      thickness2 = thicknesses(idF, 2);
      if (thickness2 ~= 9999)
         fprintf(fidOut, '%d; %d; %d; %d; %s; %f\n', ...
            wmo(idF), 1359, 1, ...
            thickness2, 'INT_SLICE_THICKNESS', dacFormatId(idF));
      end
      thickness3 = thicknesses(idF, 3);
      if (thickness3 ~= 9999)
         fprintf(fidOut, '%d; %d; %d; %d; %s; %f\n', ...
            wmo(idF), 1360, 1, ...
            thickness3, 'DEPTH_SLICE_THICKNESS', dacFormatId(idF));
      end
   end
end

fclose(fidOut);

fprintf('done\n');

diary off;

return;
