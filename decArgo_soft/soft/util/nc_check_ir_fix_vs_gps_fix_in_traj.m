% ------------------------------------------------------------------------------
% Compare Iridium fixes with GPS ones.
%
% SYNTAX :
%   nc_check_ir_fix_vs_gps_fix_in_traj or
%   nc_check_ir_fix_vs_gps_fix_in_traj(6900189, 7900118)
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
%   06/10/2025 - RNU - creation
% ------------------------------------------------------------------------------
function nc_check_ir_fix_vs_gps_fix_in_traj(varargin)

% list of floats to process (if empty, all encountered files will be checked)
FLOAT_LIST_FILE_NAME = '';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_romain_arvor_bulgary.txt';

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\traj_edac_co\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the XML file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% global measurement codes
global g_MC_Surface;

% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

logFile = [DIR_LOG_FILE '/' 'nc_check_ir_fix_vs_gps_fix_in_traj_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

header = 'WMO;Cycle;Fix type;Time;Lat;Lon;CEP;Ref used for comp;Diff time (HH:MM:SS);abs(Diff time) (hour);Diff loc (km)';

% input parameters management
floatList = [];
if (nargin == 0)
   if (~isempty(FLOAT_LIST_FILE_NAME))
      floatListFileName = FLOAT_LIST_FILE_NAME;

      % floats to process come from floatListFileName
      if ~(exist(floatListFileName, 'file') == 2)
         fprintf('ERROR: File not found: %s\n', floatListFileName);
         return
      end

      fprintf('Floats from list: %s\n', floatListFileName);
      floatList = load(floatListFileName);
   end
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'nc_check_ir_fix_vs_gps_fix_in_traj_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
fprintf(fidOut, '%s\n', header);

NB_LINE = 10000;
cptRes = 1;
results = [];

floatDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(floatDir)

   floatDirName = floatDir(idDir).name;
   floatDirPathName = [DIR_INPUT_NC_FILES '/' floatDirName];
   if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))

      [floatWmo, status] = str2num(floatDirName);
      if (status == 1)
         if ((isempty(floatList)) || (~isempty(floatList) && ismember(floatWmo, floatList)))

            % TRAJ file
            floatTrajFilePathName = [DIR_INPUT_NC_FILES '/' floatDirName '/' floatDirName '_Rtraj.nc'];
            if ~(exist(floatTrajFilePathName, 'file') == 2)
               floatTrajFilePathName = [DIR_INPUT_NC_FILES '/' floatDirName '/' floatDirName '_Dtraj.nc'];
            end

            if (exist(floatTrajFilePathName, 'file') == 2)

               % retrieve information from traj file
               wantedInputVars = [ ...
                  {'FORMAT_VERSION'} ...
                  {'JULD'} ...
                  {'LATITUDE'} ...
                  {'LONGITUDE'} ...
                  {'POSITION_ACCURACY'} ...
                  {'CYCLE_NUMBER'} ...
                  {'MEASUREMENT_CODE'} ...
                  {'AXES_ERROR_ELLIPSE_MAJOR'} ...
                  ];
               [trajData] = get_data_from_nc_file(floatTrajFilePathName, wantedInputVars);

               formatVersion = get_data_from_name('FORMAT_VERSION', trajData)';
               formatVersion = strtrim(formatVersion);
               if (~ismember(formatVersion, [{'3.1'} {'3.2'}]))
                  continue
               end

               fprintf('%03d/%03d %d\n', idDir-2, length(floatDir)-2, floatWmo);

               juld = get_data_from_name('JULD', trajData);
               latitude = get_data_from_name('LATITUDE', trajData);
               longitude = get_data_from_name('LONGITUDE', trajData);
               positionAccuracy = get_data_from_name('POSITION_ACCURACY', trajData);
               cycleNumber = get_data_from_name('CYCLE_NUMBER', trajData);
               measurementCode = get_data_from_name('MEASUREMENT_CODE', trajData);
               cepRadius = get_data_from_name('AXES_ERROR_ELLIPSE_MAJOR', trajData);

               cyNumList = unique(cycleNumber);
               cyNumList = cyNumList(cyNumList >= 0);
               for cyNum = cyNumList'

                  % collect GPS fix information
                  gpsFixData = [];
                  gpsFixIdList = find((cycleNumber == cyNum) & (measurementCode == g_MC_Surface) & (positionAccuracy == 'G'));
                  if (~isempty(gpsFixIdList))
                     gpsFixData = [juld(gpsFixIdList'), latitude(gpsFixIdList'), longitude(gpsFixIdList')];
                     [~, idSort] = sort(gpsFixData(:, 1));
                     gpsFixData = gpsFixData(idSort, :);
                  end

                  % collect Iridium fix information
                  iridiumFixData = [];
                  iridiumFixIdList = find((cycleNumber == cyNum) & (measurementCode == g_MC_Surface) & (positionAccuracy == 'I'));
                  if (~isempty(iridiumFixIdList))
                     iridiumFixData = [juld(iridiumFixIdList'), latitude(iridiumFixIdList'), longitude(iridiumFixIdList'), double(cepRadius(iridiumFixIdList'))];
                     [~, idSort] = sort(iridiumFixData(:, 1));
                     iridiumFixData = iridiumFixData(idSort, :);
                  end

                  if (~isempty(gpsFixData) && ~isempty(iridiumFixIdList))

                     for idF = 1:size(gpsFixData, 1)
                        fprintf(fidOut, '%d;%d;GPS_%d; %s;%.3f;%.3f\n', ...
                           floatWmo, cyNum, idF, ...
                           julian_2_gregorian_dec_argo(gpsFixData(idF, 1)), ...
                           gpsFixData(idF, 2), ...
                           gpsFixData(idF, 3));
                     end

                     for idF = 1:size(iridiumFixIdList, 1)

                        % find the timely closest GPS fix to use as reference
                        [~, idMin] = min(abs(iridiumFixData(idF, 1) - gpsFixData(:, 1)));
                        % compute the distance to the reference GPS fix
                        dist = distance_lpo([iridiumFixData(idF, 2) gpsFixData(idMin, 2)], [iridiumFixData(idF, 3) gpsFixData(idMin, 3)])/1000;

                        if (size(results, 1) < cptRes)
                           results = cat(1, results, nan(NB_LINE, 3));
                        end

                        results(cptRes, :) = [iridiumFixData(idF, 4)/1000, dist, abs(iridiumFixData(idF, 1) - gpsFixData(idMin, 1))*24];
                        cptRes = cptRes + 1;

                        fprintf(fidOut, '%d;%d;IRI_%d; %s;%.3f;%.3f;%d;GPS_%d;%s;%.4f;%.1f\n', ...
                           floatWmo, cyNum, idF, ...
                           julian_2_gregorian_dec_argo(iridiumFixData(idF, 1)), ...
                           iridiumFixData(idF, 2), ...
                           iridiumFixData(idF, 3), ...
                           iridiumFixData(idF, 4)/1000, ...
                           idMin, ...
                           format_time_hhmm((iridiumFixData(idF, 1) - gpsFixData(idMin, 1))*24), ...
                           abs(iridiumFixData(idF, 1) - gpsFixData(idMin, 1))*24, ...
                           dist);
                     end
                  end
               end
            end
         end
      end
   end
end
results(cptRes:end, :) = [];

fclose(fidOut);

if (~isempty(results))
   cepList = unique(results(:, 1));
   cepList = cepList(cepList <= 10);
   DIFF_MAX_HOUR = 1;
   fprintf('\n');
   fprintf('Stat for abs(Diff time) <= %d hour\n', DIFF_MAX_HOUR);
   fprintf('CEP dist_min dist_max dist_mean nb\n');
   for cep = cepList'
      idF = find((results(:, 1) == cep) & (results(:, 3) <= DIFF_MAX_HOUR));
      fprintf('%2d \t %.1f \t %.1f \t %.1f \t %d\n', cep, min(results(idF, 2)), max(results(idF, 2)), mean(results(idF, 2)), length(idF));
      % hist(results(idF, 2));
      % pause
   end
   fprintf('\n');
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Format a time (not a duration, i.e. no sign)
%
% SYNTAX :
%   [o_time] = format_time_hhmm(a_time)
%
% INPUT PARAMETERS :
%   a_time : hour (in float)
%
% OUTPUT PARAMETERS :
%   o_time : formated duration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/28/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_time] = format_time_hhmm(a_time)

% output parameters initialization
o_time = [];

if (a_time < 0)
   sign = '-';
else
   sign = '';
end
a_time = abs(a_time);
h = fix(a_time);
m = fix((a_time-h)*60);
s = round(((a_time-h)*60-m)*60);
if (s == 60)
   s = 0;
   m = m + 1;
   if (m == 60)
      m = 0;
      h = h + 1;
   end
end
o_time = sprintf(' %c %02d:%02d:%02d', sign, h, m, s);

return
