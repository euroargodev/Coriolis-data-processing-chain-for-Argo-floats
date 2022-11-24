% ------------------------------------------------------------------------------
% Collect important nc meta-data and store them in a CSV file.
%
% SYNTAX :
%   get_meta_data_from_nc ou get_meta_data_from_nc(6900189,7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/15/2009 - RNU - creation
% ------------------------------------------------------------------------------
function get_meta_data_from_nc(varargin)

% default values initialization
init_default_values;

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/arvor_deep_3500.txt';
FLOAT_LIST_FILE_NAME = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/tmp.txt';

% directory to store the log and csv files
DIR_LOG_CSV_FILE = 'C:\users\RNU\Argo\work\';

% top directory of the NetCDF files to process
DIR_INPUT_NC_FILES = 'C:\users\RNU\Argo\GDAC_IFREMER_all_dacs\dac\coriolis\';
DIR_INPUT_NC_FILES = 'C:\users\RNU\Argo\work\nc_output_decPrv\';

if (nargin == 0)
   floatListFileName = FLOAT_LIST_FILE_NAME;
   
   % floats to process come from FLOAT_LIST_FILE_NAME
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return;
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = load(floatListFileName);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

if (nargin == 0)
   [~, name, ~] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

% create and start log file recording
logFile = [DIR_LOG_CSV_FILE '/get_meta_data_from_nc' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/get_meta_data_from_nc' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('Erreur ouverture fichier: %s\n', outputFileName);
   return;
end

header = [';;', ...
   'Nc tech;', ...
   'Nc meta'];
fprintf(fidOut, '%s\n', header);

header = ['#;Wmo;', ...
   'Format;', ...
   'Mission #;Rep rate;Cycle time;Park pres;Prof Pres;', ...
   'Ptt;Trans system;Pos system;Pltf model;Pltf maker;Inst ref;', ...
   'Proj name;PI name;Launch date;Launch lon;Launch lat;Start date;Launch date;Ref date'];
fprintf(fidOut, '%s\n', header);

% traitement des flotteurs
idLig = 0;
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   % FICHIER NETCDF DE META-DONNEES
   
   % lecture du contenu du fichier de meta données
   metaFileName = [DIR_INPUT_NC_FILES '/' floatNumStr '/' floatNumStr '_meta.nc'];
   [nCyclesMeta, nParamMeta, ...
      platformNumberMeta, pttMeta, transSystemMeta, transSystemIdMeta, transFrequencyMeta, ...
      transRepetitionMeta, positioningSystemMeta, clockDriftMeta, platformModelMeta, ...
      platformMakerMeta, instReferenceMeta, wmoInstTypeMeta, directionMeta, projectNameMeta, ...
      dataCentreMeta, piNameMeta, anomalyMeta, ...
      launchDateMeta, launchLatitudeMeta, launchLongitudeMeta, launchQcMeta, startDateMeta, ...
      startDateQcMeta, deployPlatformMeta, deployMissionMeta, deployAvailableProfileIdMeta, ...
      endMissionDateMeta, endMissionStatusMeta, ...
      sensorMeta, sensorMakerMeta, sensorModelMeta, sensorSerialNoMeta, sensorUnitsMeta, ...
      sensorAccuracyMeta, sensorResolutionMeta, ...
      parameterMeta, predeploymentCalibEquationMeta, predeploymentCalibCoefficientMeta, ...
      predeploymentCalibCommentMeta, ...
      repetitionRateMeta, cycleTimeMeta, parkingTimeMeta, descendingProfilingTimeMeta, ...
      ascendingProfilingTimeMeta, surfaceTimeMeta, parkingPressureMeta, deepestPressureMeta, ...
      deepestPressureDescendingMeta] = read_file_meta_all(metaFileName);
   
   if (isempty(platformNumberMeta))
      fprintf('Flotteur #%d exclu car pas de fichier meta.nc\n', floatNum);
      continue;
   end
   
   launchDateStr = '';
   if (~strcmp(deblank(launchDateMeta), ''))
      launchDateVector = sscanf(launchDateMeta, '%4d%2d%2d%2d%2d%2d');
      if (length(launchDateVector) == 5)
         launchDateVector = [launchDateVector; 0];
      end
      if (length(launchDateVector) == 6)
         launchDateStr = datestr(launchDateVector', 'yyyy/mm/dd HH:MM:SS');
      else
         fprintf('ATTENTION: Flotteur #%d launchDateMeta mal formattée\n', floatNum);
      end
   end
   startDateStr = '';
   if (~strcmp(deblank(startDateMeta), ''))
      startDateVector = sscanf(startDateMeta, '%4d%2d%2d%2d%2d%2d');
      if (length(startDateVector) == 5)
         startDateVector = [startDateVector; 0];
      end
      if (length(startDateVector) == 6)
         startDateStr = datestr(startDateVector', 'yyyy/mm/dd HH:MM:SS');
      else
         fprintf('ATTENTION: Flotteur #%d startDateMeta mal formattée\n', floatNum);
      end
   end
   
   floatFormatTech = -1;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % écriture du fichier csv de sortie
   
   idLig = idLig + 1;
   
   % on constitue une ligne par mission
   for idMission = 1:nCyclesMeta
      
      if (idMission == 1)
         % numéro et format du flotteur
         fprintf(fidOut, '%d;%d;%d;', idLig, floatNum, floatFormatTech);
      else
         fprintf(fidOut, ';;;');
      end
      
      % paramètres théoriques (issus des méta données)
      fprintf(fidOut, '%d;%d;%.1f;%.1f;%.1f;', idMission, ...
         repetitionRateMeta(idMission), cycleTimeMeta(idMission), ...
         parkingPressureMeta(idMission), ...
         deepestPressureMeta(idMission));
      
      % paramètres théoriques (issus des méta données)
      if (idMission == 1)
         fprintf(fidOut, ' %s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s;%s\n', ...
            deblank(pttMeta), ...
            deblank(transSystemMeta), ...
            deblank(positioningSystemMeta), ...
            deblank(platformModelMeta), ...
            deblank(platformMakerMeta), ...
            deblank(instReferenceMeta), ...
            deblank(projectNameMeta), ...
            deblank(piNameMeta), ...
            launchDateStr, ...
            sprintf(' %8.3f', launchLongitudeMeta), ...
            sprintf('%7.3f', launchLatitudeMeta), ...
            startDateStr, ...
            [launchDateStr(1:4) launchDateStr(6:7) launchDateStr(9:10) ...
            launchDateStr(12:13) launchDateStr(15:16) launchDateStr(18:19)], ...
            [launchDateStr(1:4) launchDateStr(6:7) launchDateStr(9:10)]);
      else
         fprintf(fidOut, ';%s;;;;;;;;;;;\n', ...
            deblank(transSystemMeta));
      end
   end
end

diary off;

fclose(fidOut);

return;
