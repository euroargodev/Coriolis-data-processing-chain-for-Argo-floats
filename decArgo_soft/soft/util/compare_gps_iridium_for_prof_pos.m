% ------------------------------------------------------------------------------
% Compare the first GPS fix of a cycle with theoretical profile location
% computed from Iridium fixes with different methods.
%
% SYNTAX :
%   compare_gps_iridium_for_prof_pos(6902899)
%
% INPUT PARAMETERS :
%   varargin : WMO number of float to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/10/2022 - RNU - creation
% ------------------------------------------------------------------------------
function compare_gps_iridium_for_prof_pos(varargin)

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% top directory of the NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% global measurement codes
global g_MC_Surface;

% QC flag values (char)
global g_decArgo_qcStrGood;
global g_decArgo_qcStrProbablyGood;

% measurement codes initialization
init_measurement_codes;

% default values initialization
init_default_values;


if (nargin == 0)
   floatListFileName = FLOAT_LIST_FILE_NAME;
   
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = load(floatListFileName);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

timeInfo = datestr(now, 'yyyymmddTHHMMSS');

logFile = [DIR_LOG_FILE '/compare_gps_iridium_for_prof_pos' name '_' timeInfo '.log'];
diary(logFile);
tic;

% CSV file creation
outputFileName = [DIR_CSV_FILE '/compare_gps_iridium_for_prof_pos' name '_' timeInfo '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
   return
end

% print file header
header = ['WMO;CyNum;JuldLocGps;LatGps;LonGps;PosQcGps;' ...
   '@;NbIr1;JuldLocIr1;LatIr1;LonIr1;PosQcIr1;Dist1;' ...
   '@;NbIr2;JuldLocIr2;LatIr2;LonIr2;PosQcIr2;Dist2;' ...
   '@;NbIr3;CepIr3;JuldLocIr3;LatIr3;LonIr3;PosQcIr3;Dist3;MinDist3;MaxDist3' ...
   ];
fprintf(fidOut, '%s\n', header);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
   
   if (exist(ncFileDir, 'dir') == 7)

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % retrieve information from TRAJ file

      floatFileName = '';
      floatFiles = dir([ncFileDir '/' sprintf('%d_*traj.nc', floatNum)]);
      for idFile = 1:length(floatFiles)
         if (any(floatFiles(idFile).name == 'B'))
            continue
         end
         floatFileName = floatFiles(idFile).name;
      end

      if (isempty(floatFileName))
         fprintf('ERROR: Trajectory file not found - ignored\n');
         continue
      end

      floatFilePathName = [ncFileDir '/' floatFileName];

      % retrieve information from file
      wantedVars = [ ...
         {'FORMAT_VERSION'} ...
         {'JULD'} ...
         {'JULD_ADJUSTED'} ...
         {'JULD_QC'} ...
         {'CYCLE_NUMBER'} ...
         {'MEASUREMENT_CODE'} ...
         {'LATITUDE'} ...
         {'LONGITUDE'} ...
         {'POSITION_ACCURACY'} ...
         {'POSITION_QC'} ...
         {'AXES_ERROR_ELLIPSE_MAJOR'} ...
         {'AXES_ERROR_ELLIPSE_MINOR'} ...
         ];
      ncData = get_data_from_nc_file(floatFilePathName, wantedVars);

      formatVersion = get_data_from_name('FORMAT_VERSION', ncData)';
      formatVersion = strtrim(formatVersion);
      juld = get_data_from_name('JULD', ncData);
      juldAdj = get_data_from_name('JULD_ADJUSTED', ncData);
      juldQc = get_data_from_name('JULD_QC', ncData);
      cycleNumber = get_data_from_name('CYCLE_NUMBER', ncData);
      measCode = get_data_from_name('MEASUREMENT_CODE', ncData);
      latitude = get_data_from_name('LATITUDE', ncData);
      longitude = get_data_from_name('LONGITUDE', ncData);
      positionAccuracy = get_data_from_name('POSITION_ACCURACY', ncData);
      positionQc = get_data_from_name('POSITION_QC', ncData);
      errorEllipseMaj = get_data_from_name('AXES_ERROR_ELLIPSE_MAJOR', ncData);
      errorEllipseMin = get_data_from_name('AXES_ERROR_ELLIPSE_MINOR', ncData);

      % check the file format version
      if (~ismember(formatVersion, [{'3.1'} {'3.2'}]))
         fprintf('ERROR: Input trajectory file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s)\n', ...
            floatFileName, formatVersion);
         return
      end

      if (idFloat > 1)
         fprintf(fidOut, '%d\n', floatNum);
      end

      % process cycles with GPS and Iridium locations
      uCyNumList = unique(cycleNumber);
      for idC = 1:length(uCyNumList)
         idForCy = find(cycleNumber == uCyNumList(idC));
         if (any((measCode(idForCy) == g_MC_Surface) & (positionAccuracy(idForCy) == 'G')) && ...
               any((measCode(idForCy) == g_MC_Surface) & (positionAccuracy(idForCy) == 'I')))

            % first GPS location
            idGps = idForCy(find((measCode(idForCy) == g_MC_Surface) & (positionAccuracy(idForCy) == 'G')));
            idGps = idGps(1);
            juldGps = juld(idGps);
            latitudeGps = latitude(idGps);
            longitudeGps = longitude(idGps);
            positionQcGps = positionQc(idGps);

            % set of Iridium locations
            idIr = idForCy(find((measCode(idForCy) == g_MC_Surface) & (positionAccuracy(idForCy) == 'I')));
            juldIr = juld(idIr);
            latitudeIr = latitude(idIr);
            longitudeIr = longitude(idIr);
            positionQcIr = positionQc(idIr);
            cepRadIr = errorEllipseMaj(idIr)/1000;

            % longitudes must be in the [-180, 180[ interval
            % (see cycle #18 of float #6903190)
            idToShift = find(longitudeIr >= 180);
            longitudeIr(idToShift) = longitudeIr(idToShift) - 360;

            % compute profile position from Iridium locations

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Argo method

            weight = 1./(cepRadIr.*cepRadIr);
            juldIr1 = mean(juldIr);
            longitudeIr1 = sum(longitudeIr.*weight)/sum(weight);
            latitudeIr1 = sum(latitudeIr.*weight)/sum(weight);
            if (mean(cepRadIr) < 5)
               positionQcIr1 = g_decArgo_qcStrGood;
            else
               positionQcIr1 = g_decArgo_qcStrProbablyGood;
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Argo method but only for CEP radius < 5 km

            idIr2 = idIr(find(cepRadIr < 5));
            juldIr2All = juld(idIr2);
            latitudeIr2All = latitude(idIr2);
            longitudeIr2All = longitude(idIr2);
            positionQcIr2All = positionQc(idIr2);
            cepRadIr2All = errorEllipseMaj(idIr2)/1000;

            weight = 1./(cepRadIr2All.*cepRadIr2All);
            juldIr2 = mean(juldIr2All);
            longitudeIr2 = sum(longitudeIr2All.*weight)/sum(weight);
            latitudeIr2 = sum(latitudeIr2All.*weight)/sum(weight);
            if (mean(cepRadIr2All) < 5)
               positionQcIr2 = g_decArgo_qcStrGood;
            else
               positionQcIr2 = g_decArgo_qcStrProbablyGood;
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Argo method but only for locations with the minimum CEP radius

            idIr3 = idIr(find(cepRadIr == min(cepRadIr)));
            juldIr3All = juld(idIr3);
            latitudeIr3All = latitude(idIr3);
            longitudeIr3All = longitude(idIr3);
            positionQcIr3All = positionQc(idIr3);
            cepRadIr3All = errorEllipseMaj(idIr3)/1000;

            weight = 1./(cepRadIr3All.*cepRadIr3All);
            juldIr3 = mean(juldIr3All);
            longitudeIr3 = sum(longitudeIr3All.*weight)/sum(weight);
            latitudeIr3 = sum(latitudeIr3All.*weight)/sum(weight);
            if (mean(cepRadIr3All) < 5)
               positionQcIr3 = g_decArgo_qcStrGood;
            else
               positionQcIr3 = g_decArgo_qcStrProbablyGood;
            end

            distList = [];
            for idP = 1:length(juldIr3All)
               distList = [distList distance_lpo([latitudeGps latitudeIr3All(idP)], [longitudeGps longitudeIr3All(idP)])/1000];
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % output to csv file

            fprintf(fidOut, ...
               '%d;%d;%s;%.3f;%.3f;%c;@;%d;%s;%.3f;%.3f;%c;%.3f', ...
               floatNum, ...
               uCyNumList(idC), ...
               julian_2_gregorian_dec_argo(juldGps), ...
               latitudeGps, ...
               longitudeGps, ...
               positionQcGps, ...
               length(idIr), ...
               julian_2_gregorian_dec_argo(juldIr1), ...
               latitudeIr1, ...
               longitudeIr1, ...
               positionQcIr1, ...
               distance_lpo([latitudeGps latitudeIr1], [longitudeGps longitudeIr1])/1000);

            if (~isempty(idIr2))
               fprintf(fidOut, ...
                  ';@;%d;%s;%.3f;%.3f;%c;%.3f', ...
                  length(idIr2), ...
                  julian_2_gregorian_dec_argo(juldIr2), ...
                  latitudeIr2, ...
                  longitudeIr2, ...
                  positionQcIr2, ...
                  distance_lpo([latitudeGps latitudeIr2], [longitudeGps longitudeIr2])/1000);
            else
               fprintf(fidOut, ...
                  ';@;0;;;;;');
            end

            if (~isempty(idIr3))
               fprintf(fidOut, ...
                  ';@;%d;%d;%s;%.3f;%.3f;%c;%.3f;%.3f;%.3f', ...
                  length(idIr3), ...
                  min(cepRadIr), ...
                  julian_2_gregorian_dec_argo(juldIr3), ...
                  latitudeIr3, ...
                  longitudeIr3, ...
                  positionQcIr3, ...
                  distance_lpo([latitudeGps latitudeIr3], [longitudeGps longitudeIr3])/1000, ...
                  min(distList), ...
                  max(distList));
            else
               fprintf(fidOut, ...
                  ';@;0;;;;;;');
            end

            fprintf(fidOut, '\n');
         end
      end
   else
      fprintf('WARNING: Directory not found: %s\n', ncFileDir);
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Get data from name in a {var_name}/{var_data} list.
%
% SYNTAX :
%  [o_dataValues] = get_data_from_name(a_dataName, a_dataList)
%
% INPUT PARAMETERS :
%   a_dataName : name of the data to retrieve
%   a_dataList : {var_name}/{var_data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList(1:2:end)) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{2*idVal};
end

return
