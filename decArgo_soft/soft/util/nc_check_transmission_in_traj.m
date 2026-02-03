% ------------------------------------------------------------------------------
% Check transmission information (for bulgarian floats).
%
% SYNTAX :
%   nc_check_transmission_in_traj or
%   nc_check_transmission_in_traj(6900189, 7900118)
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
%   02/17/2025 - RNU - creation
% ------------------------------------------------------------------------------
function nc_check_transmission_in_traj(varargin)

% list of floats to process (if empty, all encountered files will be checked)
FLOAT_LIST_FILE_NAME = '';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_romain_arvor_bulgary.txt';

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the XML file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% global measurement codes
global g_MC_FillValue;
global g_MC_Launch;
global g_MC_CycleStart;
global g_MC_CycleStartBis;
global g_MC_DST;
global g_MC_PressureOffset
global g_MC_MinPresInDriftAtParkSupportMeas;
global g_MC_MaxPresInDriftAtParkSupportMeas;
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
global g_MC_DET;
global g_MC_DescProfDeepestBin;
global g_MC_PST;
global g_MC_SpyAtPark;
global g_MC_DriftAtPark;
global g_MC_RafosCorrelationStart;
global g_MC_DriftAtParkStd;
global g_MC_DriftAtParkMeanOfDiff;
global g_MC_DriftAtParkMean;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_PET;
global g_MC_RPP;
global g_MC_SpyInDescToProf;
global g_MC_Desc2Prof;
global g_MC_MaxPresInDescToProf;
global g_MC_DDET;
global g_MC_DPST;
global g_MC_SpyAtProf;
global g_MC_DriftAtProf;
global g_MC_MinPresInDriftAtProf;
global g_MC_MaxPresInDriftAtProf;
global g_MC_AST;
global g_MC_DownTimeEnd;
global g_MC_AST_Float;
global g_MC_AscProfDeepestBin;
global g_MC_SpyInAscProf;
global g_MC_AscProf;
global g_MC_MedianValueInAscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_IceAscentAbort;
global g_MC_ContinuousProfileStartOrStop;
global g_MC_AET;
global g_MC_AET_Float;
global g_MC_SpyAtSurface;
global g_MC_TST;
global g_MC_TST_Float;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;
global g_MC_Grounded;

% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

logFile = [DIR_LOG_FILE '/' 'nc_check_transmission_in_traj_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

header = ['WMO;Cycle;NbTrans;Trans/hour;TST;TET;TET-TST;' ...
   'TIME_ValveActionsAtSurface_seconds;' ...
   'NUMBER_ValveActionsAtSurfaceDuringDescent_COUNT;' ...
   'NUMBER_PumpActionsDuringAscentToSurface_COUNT;' ...
   'TIME_PumpActionsAdditionalAtSurfaceForGPSAcquisition_seconds' ...
   ];

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
outputFileName = [DIR_CSV_FILE '/' 'nc_check_transmission_in_traj_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
fprintf(fidOut, '%s\n', header);

paramJuld = get_netcdf_param_attributes('JULD');
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
                  {'POSITION_ACCURACY'} ...
                  {'CYCLE_NUMBER'} ...
                  {'MEASUREMENT_CODE'} ...
                  ];
               [trajData] = get_data_from_nc_file(floatTrajFilePathName, wantedInputVars);

               idVal = find(strcmp('FORMAT_VERSION', trajData(1:2:end)) == 1, 1);
               formatVersion = strtrim(trajData{2*idVal}');
               if (~ismember(formatVersion, [{'3.1'} {'3.2'}]))
                  continue
               end

               fprintf('%03d/%03d %d\n', idDir-2, length(floatDir)-2, floatWmo);

               idVal = find(strcmp('JULD', trajData(1:2:end)) == 1, 1);
               juld = trajData{2*idVal};
               juld(juld == paramJuld.fillValue) = nan;
               idVal = find(strcmp('POSITION_ACCURACY', trajData(1:2:end)) == 1, 1);
               positionAccuracy = trajData{2*idVal};
               idVal = find(strcmp('CYCLE_NUMBER', trajData(1:2:end)) == 1, 1);
               cycleNumber = trajData{2*idVal};
               idVal = find(strcmp('MEASUREMENT_CODE', trajData(1:2:end)) == 1, 1);
               measurementCode = trajData{2*idVal};

               transTimeId = find((measurementCode == g_MC_Surface) & (positionAccuracy == 'I'));
               transTime = juld(transTimeId);

               floatTechFilePathName = [DIR_INPUT_NC_FILES '/' floatDirName '/' floatDirName '_tech.nc'];

               if (exist(floatTechFilePathName, 'file') == 2)

                  % retrieve information from technical file
                  wantedInputVars = [ ...
                     {'FORMAT_VERSION'} ...
                     {'CYCLE_NUMBER'} ...
                     {'TECHNICAL_PARAMETER_NAME'} ...
                     {'TECHNICAL_PARAMETER_VALUE'} ...
                     ];
                  [techData] = get_data_from_nc_file(floatTechFilePathName, wantedInputVars);
                  idVal = find(strcmp('FORMAT_VERSION', techData(1:2:end)) == 1, 1);
                  formatVersion = techData{2*idVal}';
                  if (str2num(formatVersion) ~= 3.1)
                     continue
                  end
                  idVal = find(strcmp('CYCLE_NUMBER', techData(1:2:end)) == 1, 1);
                  cycleNumberTech = techData{2*idVal}';
                  idVal = find(strcmp('TECHNICAL_PARAMETER_NAME', techData(1:2:end)) == 1, 1);
                  techParamName = cellstr(techData{2*idVal}');
                  idVal = find(strcmp('TECHNICAL_PARAMETER_VALUE', techData(1:2:end)) == 1, 1);
                  techParamValue = cellstr(techData{2*idVal}');
               end

               cycleNumList = unique(cycleNumber);
               cyNumPlot = cycleNumList(1):cycleNumList(end);
               nbTransPlot = nan(size(cyNumPlot));
               ratioPlot = nan(size(cyNumPlot));
               tech1Plot = nan(size(cyNumPlot));
               tech2Plot = nan(size(cyNumPlot));
               tech3Plot = nan(size(cyNumPlot));
               for cyNum = cycleNumList(1):cycleNumList(end)
                  % if (cyNum == 101)
                  %    a=1
                  % end
                  if (cyNum < 1)
                     continue
                  end
                  transStartTime = nan;
                  transEndTime = nan;
                  idTST = find((measurementCode == g_MC_TST) & (cycleNumber == cyNum));
                  if (~isempty(idTST) && ~isnan(juld(idTST)))
                     transStartTime = juld(idTST);
                  end
                  idTET = find((measurementCode == g_MC_CycleStart) & (cycleNumber == cyNum+1));
                  if (~isempty(idTET) && ~isnan(juld(idTET)))
                     transEndTime = juld(idTET);
                  end

                  nbTrans = nan;
                  ratio = nan;
                  if (~isnan(transStartTime) && ~isnan(transEndTime))
                     transTimeCyId = find((transTime >= transStartTime) & (transTime <= transEndTime));
                     transTimeCy = transTime(transTimeCyId);
                     nbTrans = length(transTimeCy);
                     ratio = nbTrans/((transEndTime-transStartTime)*24);
                     idF = find(cyNumPlot == cyNum);
                     if (~isempty(idF))
                        nbTransPlot(idF) = nbTrans;
                        ratioPlot(idF) = ratio;
                     end
                  end

                  tech1 = nan;
                  idTech = find((cycleNumberTech' == cyNum) & ...
                     strcmp(techParamName, 'TIME_ValveActionsAtSurface_seconds'), 1, 'first');
                  if (~isempty(idTech))
                     tech1 = techParamValue{idTech};
                     idF = find(cyNumPlot == cyNum);
                     if (~isempty(idF))
                        tech1Plot(idF) = str2double(tech1);
                     end
                  end
                  tech2 = nan;
                  idTech = find((cycleNumberTech' == cyNum) & ...
                     strcmp(techParamName, 'NUMBER_ValveActionsAtSurfaceDuringDescent_COUNT'), 1, 'first');
                  if (~isempty(idTech))
                     tech2 = techParamValue{idTech};
                     idF = find(cyNumPlot == cyNum);
                     if (~isempty(idF))
                        tech2Plot(idF) = str2double(tech2);
                     end
                  end
                  tech3 = nan;
                  idTech = find((cycleNumberTech' == cyNum) & ...
                     strcmp(techParamName, 'NUMBER_PumpActionsDuringAscentToSurface_COUNT'), 1, 'first');
                  if (~isempty(idTech))
                     tech3 = techParamValue{idTech};
                     idF = find(cyNumPlot == cyNum);
                     if (~isempty(idF))
                        tech3Plot(idF) = str2double(tech3);
                     end
                  end
                  tech4 = nan;
                  idTech = find((cycleNumberTech' == cyNum) & ...
                     strcmp(techParamName, 'TIME_PumpActionsAdditionalAtSurfaceForGPSAcquisition_seconds'), 1, 'first');
                  if (~isempty(idTech))
                     tech4 = techParamValue{idTech};
                  end

                  fprintf(fidOut, '%d;%d;%d;%.1f; %s; %s; %s;%s;%s;%s;%s\n', ...
                     floatWmo, ...
                     cyNum, ...
                     nbTrans, ...
                     ratio, ...
                     julian_2_gregorian_dec_argo(transStartTime), ...
                     julian_2_gregorian_dec_argo(transEndTime), ...
                     format_time_mmss_dec_argo(transEndTime-transStartTime), ...
                     tech1, tech2, tech3, tech4 ...
                     );
               end
               plot(cyNumPlot, nbTransPlot);
               title('#1 Nb Trans');
               pause
               plot(cyNumPlot, ratioPlot);
               title('#2 Ratio');
               pause
               plot(cyNumPlot, tech1Plot);
               title('#3 TIME ValveActionsAtSurface seconds');
               pause
               plot(cyNumPlot, tech2Plot);
               title('#4 NUMBER ValveActionsAtSurfaceDuringDescent COUNT');
               pause
               plot(cyNumPlot, tech3Plot);
               title('#5 NUMBER PumpActionsDuringAscentToSurface COUNT');
               pause
            end
         end
      end
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
