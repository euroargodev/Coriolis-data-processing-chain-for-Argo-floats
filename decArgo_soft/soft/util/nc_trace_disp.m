% ------------------------------------------------------------------------------
% Plot of surface locations and raw deep displacements.
%
% SYNTAX :
%   nc_trace_disp ou nc_trace_disp(6900189,7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to plot
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_trace_disp(varargin)

global g_NTD_NC_DIR;
global g_NTD_PDF_DIR;
global g_NTD_FIG_HANDLE;
global g_NTD_ID_FLOAT;
global g_NTD_FLOAT_LIST;
global g_NTD_DEFAULT_NB_PLOT_CYCLE;
global g_NTD_NB_PLOT_CYCLE;
global g_NTD_ISOBATH;
global g_NTD_ISO_SRTM;
global g_NTD_PRINT;
global g_NTD_QC;
global g_NTD_LOAD_FLOAT;

global g_NTD_ZOOM_MODE;
global g_NTD_COMPUTE_BOUNDARIES;

% top directory of NetCDF files to plot
g_NTD_NC_DIR = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% g_NTD_NC_DIR = 'C:\Users\jprannou\_DATA\OUT\nc_output_decPrv_rem_for_rtqc\';

% directory to store pdf output
g_NTD_PDF_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default list of floats to plot
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_cm.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_071412.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_062608.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_061609.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_021009.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_061810.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_093008.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_matlab_all_2.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_021208.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_032213.txt';
% % FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_110613.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_090413.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_121512.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_110813.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_082213.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_082213_1.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_071807.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_082807.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_020110.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_102015.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nova.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_dova.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nova_dova.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_arn_ir.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_4.54.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_apmt_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.43.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.44.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.45.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\provor_5.74.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% number of displacements to plot
g_NTD_DEFAULT_NB_PLOT_CYCLE = 5;

fprintf('Plot management:\n');
fprintf('   Right Arrow: next float\n');
fprintf('   Left Arrow : previous float\n');
fprintf('   Down Arrow : next set of displacements\n');
fprintf('   Up Arrow   : previous set of displacements\n');
fprintf('Plot:\n');
fprintf('   q  : ignore locations with bad QC\n');
fprintf('   +/-: increase/decrease the number of displacements per set\n');
fprintf('   a  : plot all the displacements of the float\n');
fprintf('   d  : back to plot %d displacements per set\n', ...
   g_NTD_DEFAULT_NB_PLOT_CYCLE);
fprintf('Misc:\n');
fprintf('   i: plot useful isobath (ETOPO2)\n');
fprintf('   s: switch between bathymetric atlas to plot isobath (ETOPO2 or SRTM30+)\n');
fprintf('   p: pdf output file generation\n');
fprintf('   h: write help and current configuration\n');
fprintf('Escape: exit\n\n');

% do not plot isobath
g_NTD_ISOBATH = 0;

% use the ETOPO2 atlas
g_NTD_ISO_SRTM = 0;

% no pdf generation
g_NTD_PRINT = 0;

% do not consider poisition QC
g_NTD_QC = 0;

% force the plot of the first float
g_NTD_ID_FLOAT = -1;
g_NTD_LOAD_FLOAT = 0;

% compute the boundaries of the plot
g_NTD_COMPUTE_BOUNDARIES = 1;

% number of displacement in the set
g_NTD_NB_PLOT_CYCLE = g_NTD_DEFAULT_NB_PLOT_CYCLE;

close(findobj('Name', 'Surface locations and raw displacements'));
warning off;

% input parameters management
if (nargin == 0)
   % floats to process come from FLOAT_LIST_FILE_NAME
   floatListFileName = FLOAT_LIST_FILE_NAME;
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return;
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = textread(FLOAT_LIST_FILE_NAME, '%d');
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

g_NTD_FLOAT_LIST = floatList;

% creation of the figure and its associated callback
screenSize = get(0, 'ScreenSize');
g_NTD_FIG_HANDLE = figure('KeyPressFcn', @change_plot, ...
   'Name', 'Surface locations and raw displacements', ...
   'Position', [1 screenSize(4)*(1/3) screenSize(3) screenSize(4)*(2/3)-90], ...
   'Color', 'w');

% callback to manage the plot after a zoom
g_NTD_ZOOM_MODE = zoom(g_NTD_FIG_HANDLE);
set(g_NTD_ZOOM_MODE, 'ActionPostCallback', @after_zoom);

% plot the first cycle of the first float
plot_argos(0, 0);

return;

% ------------------------------------------------------------------------------
% Plot of surface locations and raw deep displacements of a given float for a
% given float and a given set of cycles.
%
% SYNTAX :
%   plot_argos(a_idFloat, a_idCycle)
%
% INPUT PARAMETERS :
%   a_idFloat : float Id in the list
%   a_idCycle : Id of the set of cycles
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function plot_argos(a_idFloat, a_idCycle)

global g_NTD_NC_DIR;
global g_NTD_PDF_DIR;
global g_NTD_FIG_HANDLE;
global g_NTD_ID_FLOAT;
global g_NTD_FLOAT_LIST;
global g_NTD_ID_CYCLE;
global g_NTD_NB_CYCLE;
global g_NTD_NB_PLOT_CYCLE;
global g_NTD_ISOBATH;
global g_NTD_ISO_SRTM;
global g_NTD_PRINT;
global g_NTD_QC;
global g_NTD_LOAD_FLOAT;

global g_NTD_floatWithPrelude;
global g_NTD_cycles;
global g_NTD_legendPlots;
global g_NTD_legendLabels;
global g_NTD_parkingPressure;
global g_NTD_deepestPressure;
global g_NTD_startDate;
global g_NTD_startLon;
global g_NTD_startLat;
global g_NTD_startAcc;
global g_NTD_launchDate;
global g_NTD_launchLon;
global g_NTD_launchLat;
global g_NTD_argosDate;
global g_NTD_argosLon;
global g_NTD_argosLat;
global g_NTD_argosAcc;
global g_NTD_numCycleStart;

global g_NTD_COMPUTE_BOUNDARIES;
global g_NTD_lonMin;
global g_NTD_lonMax;
global g_NTD_latMin;
global g_NTD_latMax;

% default values initialization
init_valdef;

% default values initialization
init_default_values;

global g_dateDef;
global g_latDef;
global g_lonDef;
global g_presDef;

% measurement codes initialization
init_measurement_codes;

% global measurement codes
global g_MC_Launch;
global g_MC_Surface;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;
global g_decArgo_qcStrGood;
global g_decArgo_qcStrProbablyGood;
global g_decArgo_qcStrCorrectable;
global g_decArgo_qcStrBad;
global g_decArgo_qcStrChanged;
global g_decArgo_qcStrUnused1;
global g_decArgo_qcStrUnused2;
global g_decArgo_qcStrInterpolated;
global g_decArgo_qcStrMissing;


g_NTD_ID_CYCLE = a_idCycle;

if ((g_NTD_ID_FLOAT ~= a_idFloat) || (g_NTD_LOAD_FLOAT == 1))
   
   g_NTD_LOAD_FLOAT = 0;
   
   % a new float is wanted
   g_NTD_ID_FLOAT = a_idFloat;
   
   g_NTD_parkingPressure = g_presDef;
   g_NTD_deepestPressure = g_presDef;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve and store the data of the new float
   
   % float number
   floatNum = g_NTD_FLOAT_LIST(a_idFloat+1);
   floatNumStr = num2str(floatNum);

   % from META file
   metaFileName = [g_NTD_NC_DIR '/' floatNumStr '/' floatNumStr '_meta.nc'];
   
   % retrieve information from META file
   wantedVars = [ ...
      {'FORMAT_VERSION'} ...
      {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
      {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
      {'CONFIG_PARAMETER_NAME'} ...
      {'CONFIG_PARAMETER_VALUE'} ...
      {'PLATFORM_TYPE'} ...
      {'DAC_FORMAT_ID'} ...
      ];
   [metaData] = get_data_from_nc_file(metaFileName, wantedVars);
   
   idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)) == 1, 1);
   metaFileFormatVersion = strtrim(metaData{2*idVal}');
   
   % check the meta file format version
   if (~strcmp(metaFileFormatVersion, '3.1'))
      fprintf('ERROR: Input meta file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s)', ...
         metaFileName, metaFileFormatVersion);
      return;
   end
   
   % retrieve the needed configuration parameters
   idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_NAME', metaData(1:2:end)) == 1, 1);
   launchConfigParamName = metaData{2*idVal};
   [~, nParam] = size(launchConfigParamName);
   launchConfigName = [];
   for idParam = 1:nParam
      launchConfigName{end+1} = deblank(launchConfigParamName(:, idParam)');
   end

   idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_VALUE', metaData(1:2:end)) == 1, 1);
   launchConfigValue = metaData{2*idVal};

   idVal = find(strcmp('CONFIG_PARAMETER_NAME', metaData(1:2:end)) == 1, 1);
   configParamName = metaData{2*idVal};
   [~, nParam] = size(configParamName);
   configName = [];
   for idParam = 1:nParam
      configName{end+1} = deblank(configParamName(:, idParam)');
   end

   idVal = find(strcmp('CONFIG_PARAMETER_VALUE', metaData(1:2:end)) == 1, 1);
   configValue = metaData{2*idVal};
   
   idVal = find(strcmp('PLATFORM_TYPE', metaData(1:2:end)) == 1, 1);
   platformType = metaData{2*idVal}';

   idVal = find(strcmp('DAC_FORMAT_ID', metaData(1:2:end)) == 1, 1);
   dacFormatIdStr = metaData{2*idVal}';
   dacFormatId = '';
   if (~isempty(dacFormatIdStr))
      dacFormatId = str2num(dacFormatIdStr);
   end

   parkPres = -1;
   profPres = -1;
   idF = find(strcmp('CONFIG_ParkPressure_dbar', launchConfigName(:)) == 1, 1);
   if (~isempty(idF) && (launchConfigValue(idF) ~= 99999))
      parkPres = launchConfigValue(idF);
   end
   idF = find(strcmp('CONFIG_ProfilePressure_dbar', launchConfigName(:)) == 1, 1);
   if (~isempty(idF) && (launchConfigValue(idF) ~= 99999))
      profPres = launchConfigValue(idF);
   end
   idF = find(strcmp('CONFIG_ParkPressure_dbar', configName(:)) == 1, 1);
   if (~isempty(idF))
      parkP = configValue(idF, :);
      parkP(find(parkP == 99999)) = [];
      parkPres = max([parkPres parkP]);
   end
   idF = find(strcmp('CONFIG_ProfilePressure_dbar', configName(:)) == 1, 1);
   if (~isempty(idF))
      profP = configValue(idF, :);
      profP(find(profP == 99999)) = [];
      profPres = max([profPres profP]);
   end
   if (parkPres == -1)
      fprintf('ERROR: Unable to retrieve CONFIG_ParkPressure_dbar from meta file (%s)', ...
         metaFileName);
      return;
   end
   if (profPres == -1)
      fprintf('ERROR: Unable to retrieve CONFIG_ProfilePressure_dbar from meta file (%s)', ...
         metaFileName);
      return;
   end   
   g_NTD_parkingPressure = parkPres;
   g_NTD_deepestPressure = profPres;
   
   % try to determine if the float has a prelude phase
   if (~isempty(strfind(platformType, 'APEX')))
      g_NTD_floatWithPrelude = 1;
   elseif (~isempty(strfind(platformType, 'PROVOR')) || ~isempty(strfind(platformType, 'ARVOR')))
      if (~isempty(dacFormatId))
         if ((dacFormatId <= 4.22) || (dacFormatId == 4.4) || (dacFormatId == 4.41))
            g_NTD_floatWithPrelude = 0;
         else
            g_NTD_floatWithPrelude = 1;
         end
      else
         g_NTD_floatWithPrelude = 0;
      end
   else
      g_NTD_floatWithPrelude = 0;
   end
   fprintf('Float with prelude phase: %d\n', g_NTD_floatWithPrelude);
   
   g_NTD_cycles = [];
   g_NTD_NB_CYCLE = 0;
   g_NTD_launchDate = g_dateDef;
   g_NTD_launchLon = g_lonDef;
   g_NTD_launchLat = g_latDef;
   g_NTD_startDate = [];
   g_NTD_startLon = [];
   g_NTD_startLat = [];
   g_NTD_startAcc = [];
   g_NTD_argosDate = [];
   g_NTD_argosLon = [];
   g_NTD_argosLat = [];
   g_NTD_argosAcc = [];

   % from TRAJ file
   trajFileName = [g_NTD_NC_DIR '/' floatNumStr '/' floatNumStr '_Rtraj.nc'];
   
   % retrieve information from TRAJ file
   wantedVars = [ ...
      {'FORMAT_VERSION'} ...
      {'JULD'} ...
      {'LATITUDE'} ...
      {'LONGITUDE'} ...
      {'POSITION_ACCURACY'} ...
      {'POSITION_QC'} ...
      {'CYCLE_NUMBER'} ...
      {'MEASUREMENT_CODE'} ...
      ];
   [trajData] = get_data_from_nc_file(trajFileName, wantedVars);
   
   if (isempty(trajData))
      % plot the wanted cycle
      figure(g_NTD_FIG_HANDLE);
      cla;
      delete(findobj('Tag', 'Legend'));
      
      label = sprintf('%02d/%02d : %d (no data)', ...
         a_idFloat+1, length(g_NTD_FLOAT_LIST), g_NTD_FLOAT_LIST(a_idFloat+1));
      title(label, 'FontSize', 14);
      return;
   end
   
   idVal = find(strcmp('FORMAT_VERSION', trajData(1:2:end)) == 1, 1);
   trajFileFormatVersion = strtrim(trajData{2*idVal}');
   
   % check the traj file format version
   if (~strcmp(trajFileFormatVersion, '3.1'))
      fprintf('ERROR: Input traj file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s)', ...
         trajFileName, trajFileFormatVersion);
      return;
   end

   idVal = find(strcmp('CYCLE_NUMBER', trajData(1:2:end)) == 1, 1);
   cycleNumberTraj = trajData{2*idVal};
   
   idVal = find(strcmp('MEASUREMENT_CODE', trajData(1:2:end)) == 1, 1);
   measCode = trajData{2*idVal};
   
   idVal = find(strcmp('LATITUDE', trajData(1:2:end)) == 1, 1);
   latitude = trajData{2*idVal};
   
   idVal = find(strcmp('LONGITUDE', trajData(1:2:end)) == 1, 1);
   longitude = trajData{2*idVal};
   
   idVal = find(strcmp('POSITION_ACCURACY', trajData(1:2:end)) == 1, 1);
   posAcc = trajData{2*idVal};
   
   idVal = find(strcmp('POSITION_QC', trajData(1:2:end)) == 1, 1);
   posQc = trajData{2*idVal};

   idVal = find(strcmp('JULD', trajData(1:2:end)) == 1, 1);
   juld = trajData{2*idVal};
     
   % launch date and location
   idLaunch = find(measCode == g_MC_Launch);
   if (~isempty(idLaunch))
      g_NTD_launchDate = juld(idLaunch);
      g_NTD_launchLon = longitude(idLaunch);
      g_NTD_launchLat = latitude(idLaunch);
   end
   
   % if the launch position is obviously erroneous, don't plot it
   %    g_NTD_launchDate = g_dateDef;
   %    g_NTD_launchLon = g_lonDef;
   %    g_NTD_launchLat = g_latDef;
   
   % cycles to consider
   cycles = sort(unique(cycleNumberTraj(find(cycleNumberTraj >= 0))));

   % compute the dimension of the array
   maxNbLoc = 0;
   for idCy = 1:length(cycles)
      numCycle = cycles(idCy);
      idCycle = find(cycleNumberTraj == numCycle);
      
      idCycleArgosLoc = find((measCode(idCycle) == g_MC_Surface) & (latitude(idCycle) ~= 99999));
      if (~isempty(idCycleArgosLoc))
         tabPosAcc = posAcc(idCycle(idCycleArgosLoc));
         idGoodPos = find((tabPosAcc == g_decArgo_qcStrGood) | (tabPosAcc == g_decArgo_qcStrProbablyGood) | (tabPosAcc == g_decArgo_qcStrCorrectable) | ...
            (tabPosAcc == 'G'));
         maxNbLoc = max([maxNbLoc length(idGoodPos)]);
      end
   end
   
   % data storage
   g_NTD_argosDate = [];
   g_NTD_argosLon = [];
   g_NTD_argosLat = [];
   g_NTD_argosAcc = [];
   idToDel = [];
   
   if (maxNbLoc > 0)
      g_NTD_argosDate = ones(length(cycles), maxNbLoc)*g_dateDef;
      g_NTD_argosLon = ones(length(cycles), maxNbLoc)*g_lonDef;
      g_NTD_argosLat = ones(length(cycles), maxNbLoc)*g_latDef;
      g_NTD_argosAcc = repmat(' ', length(cycles), maxNbLoc);
      
      for idCy = 1:length(cycles)
         numCycle = cycles(idCy);
         idCycle = find(cycleNumberTraj == numCycle);
         
         idCycleArgosLoc = find((measCode(idCycle) == g_MC_Surface) & (latitude(idCycle) ~= 99999));
         if (~isempty(idCycleArgosLoc))
            tabDate = juld(idCycle(idCycleArgosLoc));
            tabLon = longitude(idCycle(idCycleArgosLoc));
            tabLat = latitude(idCycle(idCycleArgosLoc));
            tabPosAcc = posAcc(idCycle(idCycleArgosLoc));
            tabPosQc = posQc(idCycle(idCycleArgosLoc));
            
            idGoodPos = find((tabPosAcc == g_decArgo_qcStrGood) | (tabPosAcc == g_decArgo_qcStrProbablyGood) | (tabPosAcc == g_decArgo_qcStrCorrectable) | ...
               (tabPosAcc == 'G'));
            tabDate = tabDate(idGoodPos);
            tabLon = tabLon(idGoodPos);
            tabLat = tabLat(idGoodPos);
            tabPosAcc = tabPosAcc(idGoodPos);
            tabPosQc = tabPosQc(idGoodPos);
            
            if (g_NTD_QC == 1)
               idKo = find((tabPosQc == g_decArgo_qcStrCorrectable) | (tabPosQc == g_decArgo_qcStrBad));
               tabDate(idKo) = [];
               tabLon(idKo) = [];
               tabLat(idKo) = [];
               tabPosAcc(idKo) = [];
            end

            if (~isempty(tabDate))
               g_NTD_argosDate(idCy, 1:length(tabDate)) = tabDate;
               g_NTD_argosLon(idCy, 1:length(tabDate)) = tabLon;
               g_NTD_argosLat(idCy, 1:length(tabDate)) = tabLat;
               g_NTD_argosAcc(idCy, 1:length(tabDate)) = tabPosAcc;
            else
               idToDel = [idToDel idCy];
            end
         else
            idToDel = [idToDel idCy];
         end
      end
   end
   
   % start position initialization
   
   % float with a prelude phase
   if (g_NTD_floatWithPrelude == 1)
      idCycle0 = find(cycles == 0);
      if (~isempty(idCycle0))
         launchDate = '';
         launchLon = '';
         launchLat = '';
         if (g_NTD_launchLon ~= g_lonDef)
            launchDate = g_NTD_launchDate;
            launchLon = g_NTD_launchLon;
            launchLat = g_NTD_launchLat;
         end
         argosDate = [launchDate squeeze(g_NTD_argosDate(idCycle0, :))];
         argosLon = [launchLon squeeze(g_NTD_argosLon(idCycle0, :))];
         argosLat = [launchLat squeeze(g_NTD_argosLat(idCycle0, :))];
         argosAcc = [' ' squeeze(g_NTD_argosAcc(idCycle0, :))];
         idNoData = find((argosDate == g_dateDef) | (argosLon == g_lonDef) | (argosLat == g_latDef));
         argosDate(idNoData) = [];
         argosLon(idNoData) = [];
         argosLat(idNoData) = [];
         argosAcc(idNoData) = [];
         g_NTD_startDate = argosDate;
         g_NTD_startLon = argosLon;
         g_NTD_startLat = argosLat;
         g_NTD_startAcc = argosAcc;
         idToDel = [idToDel idCycle0];
         g_NTD_numCycleStart = 0;
      else
         if (g_NTD_launchLon ~= g_lonDef)
            g_NTD_startDate = g_NTD_launchDate;
            g_NTD_startLon = g_NTD_launchLon;
            g_NTD_startLat = g_NTD_launchLat;
            g_NTD_startAcc = ' ';
            g_NTD_numCycleStart = 0;
         end
      end
   end
   
   % if the start position has not been found yet, use the first received one
   if (isempty(g_NTD_startDate))
      if (g_NTD_launchLon == g_lonDef)
         idFirst = min(setdiff([1:length(cycles)], idToDel));
         argosDate = squeeze(g_NTD_argosDate(idFirst, :));
         argosLon = squeeze(g_NTD_argosLon(idFirst, :));
         argosLat = squeeze(g_NTD_argosLat(idFirst, :));
         argosAcc = squeeze(g_NTD_argosAcc(idFirst, :));
         idNoData = find((argosDate == g_dateDef) | (argosLon == g_lonDef) | (argosLat == g_latDef));
         argosDate(idNoData) = [];
         argosLon(idNoData) = [];
         argosLat(idNoData) = [];
         argosAcc(idNoData) = [];
         g_NTD_startDate = argosDate;
         g_NTD_startLon = argosLon;
         g_NTD_startLat = argosLat;
         g_NTD_startAcc = argosAcc;
         idToDel = [idToDel idFirst];
         g_NTD_numCycleStart = cycles(idFirst);
      end
   end
   
   % remove the cycles with no Argos data
   g_NTD_cycles = cycles;
   g_NTD_cycles(idToDel) = [];
   g_NTD_NB_CYCLE = length(g_NTD_cycles);
   
   g_NTD_argosDate(idToDel, :) = [];
   g_NTD_argosLon(idToDel, :) = [];
   g_NTD_argosLat(idToDel, :) = [];
   g_NTD_argosAcc(idToDel, :) = [];
end

% arrays to store legend information
g_NTD_legendPlots = [];
g_NTD_legendLabels = [];

% plot the wanted cycle
figure(g_NTD_FIG_HANDLE);
cla;
delete(findobj('Tag', 'Legend'));

if (isempty(g_NTD_cycles))
   label = sprintf('%02d/%02d : %d (no data)', ...
      a_idFloat+1, length(g_NTD_FLOAT_LIST), g_NTD_FLOAT_LIST(a_idFloat+1));
   title(label, 'FontSize', 14);
   return;
end

% define the cycles to plot
idCycleStart = a_idCycle + 1;
idCycleEnd = idCycleStart + g_NTD_NB_PLOT_CYCLE - 1;
if (idCycleEnd > g_NTD_NB_CYCLE)
   idCycleEnd = g_NTD_NB_CYCLE;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% geographic boundaries of the plot

if (g_NTD_COMPUTE_BOUNDARIES == 1)
   % retrieve the positions to plot
   if (idCycleStart == 1)
      if (isempty(g_NTD_startDate))
         date = g_NTD_launchDate;
         x = g_NTD_launchLon;
         y = g_NTD_launchLat;
      else
         date = g_NTD_startDate;
         x = g_NTD_startLon;
         y = g_NTD_startLat;
      end  
   else
      date = g_NTD_argosDate(idCycleStart-1, :);
      x = g_NTD_argosLon(idCycleStart-1, :);
      y = g_NTD_argosLat(idCycleStart-1, :);
   end

   for idCycle = idCycleStart:idCycleEnd
      date = [date g_NTD_argosDate(idCycle, :)];
      x = [x g_NTD_argosLon(idCycle, :)];
      y = [y g_NTD_argosLat(idCycle, :)];
   end
         
   % compute the geographic boundaries of the plot
   [g_NTD_lonMin, g_NTD_lonMax, g_NTD_latMin, g_NTD_latMax] = compute_geo_extrema(date, x, y, 0);
end
g_NTD_COMPUTE_BOUNDARIES = 0;
latMin = g_NTD_latMin;
latMax = g_NTD_latMax;
lonMin = g_NTD_lonMin;
lonMax = g_NTD_lonMax;

m_proj('mercator', 'latitudes', [latMin latMax], 'longitudes', [lonMin lonMax]);
m_grid('box', 'fancy', 'tickdir', 'out', 'linestyle', 'none');
hold on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the parking and profile pressure isobath

if (g_NTD_ISOBATH == 1)
   
   fprintf('Getting and plotting isobath wait ...');

   isoDerive = floor((g_NTD_parkingPressure-30)/100)*100;
   isoProfil1 = ceil((g_NTD_parkingPressure+30)/100)*100;
   isoProfil2 = floor((g_NTD_deepestPressure-30)/100)*100;
   isoProfilLevels = [-isoProfil1:-100:-isoProfil2]';
   if (length(isoProfilLevels) == 1)
      isoProfilLevels = [isoProfilLevels isoProfilLevels];
   end

   if (g_NTD_ISO_SRTM == 0)
      [contourMatrix, contourHdl] = m_etopo2('contour', [-g_NTD_parkingPressure-30 -g_NTD_parkingPressure+30], 'g');
      if (~isempty(contourMatrix))
         set(contourHdl, 'ShowText', 'off', 'TextStep', get(contourHdl, 'LevelStep')*4);
         g_NTD_legendPlots = [g_NTD_legendPlots contourHdl];
         g_NTD_legendLabels = [g_NTD_legendLabels {'Park. press. iso. (ETOPO)'}];
      end

      [contourMatrix, contourHdl] = m_etopo2('contour', [0:-100:-isoDerive]', 'g:');
      if (~isempty(contourMatrix))
         set(contourHdl, 'ShowText', 'off', 'TextStep', get(contourHdl, 'LevelStep')*4);
      end

      [contourMatrix, contourHdl] = m_etopo2('contour', [-g_NTD_deepestPressure-30 -g_NTD_deepestPressure+30], 'r');
      if (~isempty(contourMatrix))
         set(contourHdl, 'ShowText', 'off', 'TextStep', get(contourHdl, 'LevelStep')*4);
         g_NTD_legendPlots = [g_NTD_legendPlots contourHdl];
         g_NTD_legendLabels = [g_NTD_legendLabels {'Prof. press. iso. (ETOPO)'}];
      end

      [contourMatrix, contourHdl] = m_etopo2('contour', isoProfilLevels, 'r:');
      if (~isempty(contourMatrix))
         set(contourHdl, 'ShowText', 'off', 'TextStep', get(contourHdl, 'LevelStep')*4);
      end
      
      [contourMatrix, contourHdl] = m_etopo2('contour', [0 0], 'k');
      if (~isempty(contourMatrix))
         g_NTD_legendPlots = [g_NTD_legendPlots contourHdl];
         g_NTD_legendLabels = [g_NTD_legendLabels {'Coastline (ETOPO)'}];
      end
   else
      [elev, lon , lat] = get_srtm_elev(lonMin, lonMax, latMin, latMax);
      
      [contourMatrix, contourHdl] = m_contour(lon, lat, elev, [-g_NTD_parkingPressure-30 -g_NTD_parkingPressure+30], 'g');
      if (~isempty(contourMatrix))
         set(contourHdl, 'ShowText', 'off', 'TextStep', get(contourHdl, 'LevelStep')*4);
         g_NTD_legendPlots = [g_NTD_legendPlots contourHdl];
         g_NTD_legendLabels = [g_NTD_legendLabels {'Park. press. iso. (SRTM)'}];
      end

      [contourMatrix, contourHdl] = m_contour(lon, lat, elev, [0:-100:-isoDerive]', 'b');
      if (~isempty(contourMatrix))
         set(contourHdl, 'ShowText', 'off', 'TextStep', get(contourHdl, 'LevelStep')*4);
      end

      [contourMatrix, contourHdl] = m_contour(lon, lat, elev, [-g_NTD_deepestPressure-30 -g_NTD_deepestPressure+30], 'r');
      if (~isempty(contourMatrix))
         set(contourHdl, 'ShowText', 'off', 'TextStep', get(contourHdl, 'LevelStep')*4);
         g_NTD_legendPlots = [g_NTD_legendPlots contourHdl];
         g_NTD_legendLabels = [g_NTD_legendLabels {'Prof. press. iso. (SRTM)'}];
      end

      [contourMatrix, contourHdl] = m_contour(lon, lat, elev, isoProfilLevels, 'm');
      if (~isempty(contourMatrix))
         set(contourHdl, 'ShowText', 'off', 'TextStep', get(contourHdl, 'LevelStep')*4);
      end

      [contourMatrix, contourHdl] = m_contour(lon, lat, elev, [0 0], 'k');
      if (~isempty(contourMatrix))
         g_NTD_legendPlots = [g_NTD_legendPlots contourHdl];
         g_NTD_legendLabels = [g_NTD_legendLabels {'Coastline (SRTM)'}];
      end
   end
   
   fprintf('done\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the surface locations

lineSpec(1,1) = {'r^'};
lineSpec(1,2) = {'m^'};
lineSpec(1,3) = {'g^'};
lineSpec(2,1) = {'rh'};
lineSpec(2,2) = {'mh'};
lineSpec(2,3) = {'gh'};
lineSpec(3,1) = {'rv'};
lineSpec(3,2) = {'mv'};
lineSpec(3,3) = {'gv'};
markerSize(1) = 6;
markerSize(2) = 5;
markerSize(3) = 6;

% launch position (or cycle #0 for a float with a prelude phase)
oneMore = 1;
if (idCycleStart == 1)
   oneMore = 0;
   if (isempty(g_NTD_startDate))
      
      date = g_NTD_launchDate;
      x = g_NTD_launchLon;
      y = g_NTD_launchLat;
      
      idNoData = find((date == g_dateDef) || (x == g_lonDef) || (y == g_latDef));
      x(idNoData) = [];
      y(idNoData) = [];
            
      if (g_NTD_lonMax > 180)
         id = find(x < 0);
         x(id) = x(id) + 360;
      end
      
      plotHdl = m_plot(x, y, 'ro', 'Markersize', 5);
      g_NTD_legendPlots = [g_NTD_legendPlots plotHdl];
      g_NTD_legendLabels = [g_NTD_legendLabels {'Launch pos.'}];
   else
      
      date = g_NTD_startDate;
      x = g_NTD_startLon;
      y = g_NTD_startLat;
      acc = g_NTD_startAcc;
      
      idNoData = find((date == g_dateDef) | (x == g_lonDef) | (y == g_latDef));
      x(idNoData) = [];
      y(idNoData) = [];
      acc(idNoData) = [];
           
      if (g_NTD_lonMax > 180)
         id = find(x < 0);
         x(id) = x(id) + 360;
      end

      % surface trajectory
      plotHdl = m_plot(x, y, 'b-');
      
      % surface locations
      if ((g_NTD_floatWithPrelude == 1) && (g_NTD_launchLon ~= g_lonDef))
         [g_NTD_legendPlots, g_NTD_legendLabels] = plot_argos_positions(x, y, acc, ...
            [], [], [], lineSpec, markerSize, g_NTD_legendPlots, g_NTD_legendLabels, 4);
      else
         [g_NTD_legendPlots, g_NTD_legendLabels] = plot_argos_positions(x, y, acc, ...
            [], [], [], lineSpec, markerSize, g_NTD_legendPlots, g_NTD_legendLabels, 1);
      end
   end
end

% surface trajectories
for idCycle = idCycleStart-oneMore:idCycleEnd
   
   date = g_NTD_argosDate(idCycle, :);
   x = g_NTD_argosLon(idCycle, :);
   y = g_NTD_argosLat(idCycle, :);
   acc = g_NTD_argosAcc(idCycle, :);
   
   idNoData = find((date == g_dateDef) | (x == g_lonDef) | (y == g_latDef));
   x(idNoData) = [];
   y(idNoData) = [];
   acc(idNoData) = [];
      
   if (g_NTD_lonMax > 180)
      id = find(x < 0);
      x(id) = x(id) + 360;
   end

   % surface trajectory
   plotHdl = m_plot(x, y, 'b-');

   % surface locations
   [g_NTD_legendPlots, g_NTD_legendLabels] = plot_argos_positions(x, y, acc, ...
      [], [], [], lineSpec, markerSize, g_NTD_legendPlots, g_NTD_legendLabels, 1);
end
g_NTD_legendPlots = [g_NTD_legendPlots plotHdl];
g_NTD_legendLabels = [g_NTD_legendLabels {'Argos traj.'}];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot raw displacements

tailleFleche = 0.761 * 0.005 * (lonMax - lonMin)/16;
dispLegend = 0;

% first displacement start location
if (idCycleStart == 1)
   if (isempty(g_NTD_startDate))
      numCycleStart = -1;
      lonArrow(1) = g_NTD_launchLon;
      latArrow(1) = g_NTD_launchLat;
   else
      startLon = g_NTD_startLon;
      startLat = g_NTD_startLat;
      startQc = g_NTD_startLon;
      
      if (g_NTD_QC == 1)
         idKo = find((startQc == g_decArgo_qcStrCorrectable) | (startQc == g_decArgo_qcStrBad));
         startLon(idKo) = [];
         startLat(idKo) = [];
         
         if (isempty(startLon))
            numCycleStart = -1;
            lonArrow(1) = g_NTD_launchLon;
            latArrow(1) = g_NTD_launchLat;
         else
            numCycleStart = g_NTD_numCycleStart;
            lonArrow(1) = startLon(end);
            latArrow(1) = startLat(end);
         end
      else
         numCycleStart = g_NTD_numCycleStart;
         lonArrow(1) = startLon(end);
         latArrow(1) = startLat(end);
      end
   end
else
   numCycleStart = g_NTD_cycles(idCycleStart-1);
   argosLon = g_NTD_argosLon(idCycleStart-1, :);
   argosLat = g_NTD_argosLat(idCycleStart-1, :);
   idNoData = find((argosLon == g_lonDef) | (argosLat == g_latDef));
   argosLon(idNoData) = [];
   argosLat(idNoData) = [];
   lonArrow(1) = argosLon(end);
   latArrow(1) = argosLat(end);
end

% following displacements
for idCycle = idCycleStart:idCycleEnd
   numCycleEnd = g_NTD_cycles(idCycle);
   argosLon = g_NTD_argosLon(idCycle, :);
   argosLat = g_NTD_argosLat(idCycle, :);
   idNoData = find((argosLon == g_lonDef) | (argosLat == g_latDef));
   argosLon(idNoData) = [];
   argosLat(idNoData) = [];
   lonArrow(2) = argosLon(1);
   latArrow(2) = argosLat(1);

   if (g_NTD_lonMax > 180)
      id = find(lonArrow < 0);
      lonArrow(id) = lonArrow(id) + 360;
   end
   
   % manage missing cycles
   if (numCycleEnd == numCycleStart + 1)
      linStl = '-';
   else
      linStl = '--';
   end

   % plot the displacement
   [xArrow, yArrow] = m_ll2xy(lonArrow, latArrow);
   arrowHdl = plot_arrow2(xArrow(1), yArrow(1), xArrow(2), yArrow(2), ...
      tailleFleche, tailleFleche, 'linestyle', linStl);
   dispLegend = 1;

   numCycleStart = numCycleEnd;
   lonArrow(1) = argosLon(end);
   latArrow(1) = argosLat(end);
end

if (dispLegend == 1)
   g_NTD_legendPlots = [g_NTD_legendPlots arrowHdl(1)];
   g_NTD_legendLabels = [g_NTD_legendLabels {'Subsurface raw disp.'}];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot legend

legendHdl = legend(g_NTD_legendPlots, g_NTD_legendLabels, 'Location', 'NorthEastOutside', 'Tag', 'Legend');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% distance mark

[xMin, yMin] = m_ll2xy(lonMin, latMin);
[xMin, yMax] = m_ll2xy(lonMin, latMax);
[xMax, yMin] = m_ll2xy(lonMax, latMin);

xStart = xMin + (xMax - xMin)/20;
yStart = yMin + (yMax - yMin)/20;
lon = [];
lat = [];
[lon(1), lat(1)] = m_xy2ll(xStart, yStart);

dixKmEnDegDeLon = 10000/(60*1852*cosd(lat(1)));
lon(2) = lon(1) + dixKmEnDegDeLon;
lat(2) = lat(1);
[xEnd, yEnd] = m_ll2xy(lon(2), lat(2));

m_plot(lon, lat, 'k-');
text(xStart + (xEnd-xStart)/2, yStart, '10 km', 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot title

label = sprintf('%02d/%02d : %d (#%d to #%d displacements)', ...
   a_idFloat+1, length(g_NTD_FLOAT_LIST), g_NTD_FLOAT_LIST(a_idFloat+1), ...
   g_NTD_cycles(idCycleStart), g_NTD_cycles(idCycleEnd));

title(label, 'FontSize', 14);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pdf output management

if (g_NTD_PRINT)
   orient landscape
   print('-dpdf', [g_NTD_PDF_DIR '/' ...
      sprintf('nc_trace_disp_%d_%03d_%03d', ...
      g_NTD_FLOAT_LIST(a_idFloat+1), ...
      g_NTD_cycles(idCycleStart), ...
      g_NTD_cycles(idCycleEnd)) '.pdf']);
   g_NTD_PRINT = 0;
   orient portrait
end

return;

% ------------------------------------------------------------------------------
% Callback to manage plots:
%   - right Arrow : next float
%   - left Arrow  : previous float
%   - down Arrow  : next set of displacements
%   - up Arrow    : previous set of displacements
%   - "-"         : decrease the number of displacements per set
%   - "+"         : increase the number of displacements per set
%   - "a"         : plot all the displacements of the float
%   - "d"         : back to plot the default number of displacements per set
%   - "i"         : plot useful isobath (ETOPO2)
%   - "s"         : switch between bathymetric atlas to plot isobath (ETOPO2 or
%                   SRTM30+)
%   - "p"         : pdf output file generation
%   - "h"         : write help and current configuration
%   - escape      : exit
%
% SYNTAX :
%   change_plot(a_src, a_eventData)
%
% INPUT PARAMETERS :
%   a_src        : object
%   a_eventData  : event
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function change_plot(a_src, a_eventData)

global g_NTD_FIG_HANDLE;
global g_NTD_ID_FLOAT;
global g_NTD_FLOAT_LIST;
global g_NTD_ID_CYCLE;
global g_NTD_NB_CYCLE;
global g_NTD_DEFAULT_NB_PLOT_CYCLE;
global g_NTD_NB_PLOT_CYCLE;
global g_NTD_ISOBATH;
global g_NTD_ISO_SRTM;
global g_NTD_PRINT;
global g_NTD_QC;
global g_NTD_LOAD_FLOAT;

global g_NTD_COMPUTE_BOUNDARIES;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% exit
if (strcmp(a_eventData.Key, 'escape'))
   set(g_NTD_FIG_HANDLE, 'KeyPressFcn', '');
   close(g_NTD_FIG_HANDLE);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % previous set of displacements
elseif (strcmp(a_eventData.Key, 'uparrow'))
   g_NTD_COMPUTE_BOUNDARIES = 1;
   g_NTD_ID_CYCLE = g_NTD_ID_CYCLE - g_NTD_NB_PLOT_CYCLE;
   if (g_NTD_ID_CYCLE < 0)
      g_NTD_ID_CYCLE = 0;
   end
   plot_argos(g_NTD_ID_FLOAT, g_NTD_ID_CYCLE);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % next set of displacements
elseif (strcmp(a_eventData.Key, 'downarrow'))
   g_NTD_COMPUTE_BOUNDARIES = 1;
   g_NTD_ID_CYCLE = g_NTD_ID_CYCLE + g_NTD_NB_PLOT_CYCLE;
   if (g_NTD_ID_CYCLE > g_NTD_NB_CYCLE-1)
      g_NTD_ID_CYCLE = 0;
   end
   plot_argos(g_NTD_ID_FLOAT, g_NTD_ID_CYCLE);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % next float
elseif (strcmp(a_eventData.Key, 'rightarrow'))
   g_NTD_COMPUTE_BOUNDARIES = 1;
   plot_argos(mod(g_NTD_ID_FLOAT+1, length(g_NTD_FLOAT_LIST)), 0);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % previous float
elseif (strcmp(a_eventData.Key, 'leftarrow'))
   g_NTD_COMPUTE_BOUNDARIES = 1;
   plot_argos(mod(g_NTD_ID_FLOAT-1, length(g_NTD_FLOAT_LIST)), 0);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot useful isobath (ETOPO2)
elseif (strcmp(a_eventData.Key, 'i'))
   g_NTD_ISOBATH = mod(g_NTD_ISOBATH+1, 2);
   if (g_NTD_ISOBATH == 0)
      g_NTD_ISO_SRTM = 0;
   end
   plot_argos(g_NTD_ID_FLOAT, g_NTD_ID_CYCLE);
   
   display_current_config;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % switch between bathymetric atlas to plot isobath (ETOPO2 or SRTM30+)
elseif (strcmp(a_eventData.Key, 's'))
   if (g_NTD_ISOBATH == 1)
      g_NTD_ISO_SRTM = mod(g_NTD_ISO_SRTM+1, 2);
      plot_argos(g_NTD_ID_FLOAT, g_NTD_ID_CYCLE);
   end
   
   display_current_config;

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % decrease the number of displacements per set
elseif (strcmp(a_eventData.Character, '-'))
   g_NTD_COMPUTE_BOUNDARIES = 1;
   if (g_NTD_NB_PLOT_CYCLE > 1)
      g_NTD_NB_PLOT_CYCLE = g_NTD_NB_PLOT_CYCLE - 1;
   end
   fprintf('Plot of %d displacements per set\n', g_NTD_NB_PLOT_CYCLE);
   plot_argos(g_NTD_ID_FLOAT, g_NTD_ID_CYCLE);
   
   display_current_config;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % increase the number of displacements per set
elseif (strcmp(a_eventData.Character, '+'))
   g_NTD_COMPUTE_BOUNDARIES = 1;
   if (g_NTD_NB_PLOT_CYCLE < g_NTD_NB_CYCLE)
      g_NTD_NB_PLOT_CYCLE = g_NTD_NB_PLOT_CYCLE + 1;
   end
   fprintf('Plot of %d displacements per set\n', g_NTD_NB_PLOT_CYCLE);
   plot_argos(g_NTD_ID_FLOAT, g_NTD_ID_CYCLE);
   
   display_current_config;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot all the displacements of the float
elseif (strcmp(a_eventData.Key, 'a'))
   g_NTD_COMPUTE_BOUNDARIES = 1;
   g_NTD_NB_PLOT_CYCLE = g_NTD_NB_CYCLE;
   fprintf('Plot of %d displacements per set\n', g_NTD_NB_PLOT_CYCLE);
   g_NTD_ID_CYCLE = 0;
   plot_argos(g_NTD_ID_FLOAT, g_NTD_ID_CYCLE);
   
   display_current_config;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % back to plot the default number of displacements per set
elseif (strcmp(a_eventData.Key, 'd'))
   g_NTD_COMPUTE_BOUNDARIES = 1;
   g_NTD_NB_PLOT_CYCLE = g_NTD_DEFAULT_NB_PLOT_CYCLE;
   fprintf('Plot of %d displacements per set\n', g_NTD_NB_PLOT_CYCLE);
   g_NTD_ID_CYCLE = 0;
   plot_argos(g_NTD_ID_FLOAT, g_NTD_ID_CYCLE);
   
   display_current_config;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % pdf output file generation
elseif (strcmp(a_eventData.Key, 'p'))
   g_NTD_PRINT = 1;
   plot_argos(g_NTD_ID_FLOAT, g_NTD_ID_CYCLE);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % ignore locations with bad QC
elseif (strcmp(a_eventData.Key, 'q'))
   g_NTD_COMPUTE_BOUNDARIES = 1;
   g_NTD_LOAD_FLOAT = 1;
   g_NTD_QC = mod(g_NTD_QC+1, 2);
   plot_argos(g_NTD_ID_FLOAT, g_NTD_ID_CYCLE);
   
   display_current_config;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % write help and current configuration
elseif (strcmp(a_eventData.Key, 'h'))
   fprintf('Plot management:\n');
   fprintf('   Right Arrow: next float\n');
   fprintf('   Left Arrow : previous float\n');
   fprintf('   Down Arrow : next set of displacements\n');
   fprintf('   Up Arrow   : previous set of displacements\n');
   fprintf('Plot:\n');
   fprintf('   q  : ignore locations with bad QC\n');
   fprintf('   +/-: increase/decrease the number of displacements per set\n');
   fprintf('   a  : plot all the displacements of the float\n');
   fprintf('   d  : back to plot %d displacements per set\n', ...
      g_NTD_DEFAULT_NB_PLOT_CYCLE);
   fprintf('Misc:\n');
   fprintf('   i: plot useful isobath (ETOPO2)\n');
   fprintf('   s: switch between bathymetric atlas to plot isobath (ETOPO2 or SRTM30+)\n');
   fprintf('   p: pdf output file generation\n');
   fprintf('   h: write help and current configuration\n');
   fprintf('Escape: exit\n\n');

   display_current_config;
end

return;

% ------------------------------------------------------------------------------
% Display the current visualization configuration.
%
% SYNTAX :
%   display_current_config
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
%   10/18/2016 - RNU - creation
% ------------------------------------------------------------------------------
function display_current_config

global g_NTD_NB_PLOT_CYCLE;
global g_NTD_ISOBATH;
global g_NTD_ISO_SRTM;
global g_NTD_QC;

fprintf('\nCurrent configuration:\n');
fprintf('NB DISP / SET: %d\n', g_NTD_NB_PLOT_CYCLE);
fprintf('QC           : %d\n', g_NTD_QC);
fprintf('ISOBATH      : %d\n', g_NTD_ISOBATH);
fprintf('ISOBATH SRTM : %d\n', g_NTD_ISO_SRTM);

return;

%------------------------------------------------------------------------------
% Callback used to update the plot after a zoom
%
% SYNTAX :
%   after_zoom(a_src, a_eventData)
%
% INPUT PARAMETERS :
%   a_src        : object
%   a_eventData  : event
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
%------------------------------------------------------------------------------
% RELEASES :
%   08/01/2014 - RNU - creation
%------------------------------------------------------------------------------
function after_zoom(a_src, a_eventData)

global g_NTD_ID_FLOAT;
global g_NTD_ID_CYCLE;

global g_NTD_ZOOM_MODE;
global g_NTD_COMPUTE_BOUNDARIES;
global g_NTD_lonMin;
global g_NTD_lonMax;
global g_NTD_latMin;
global g_NTD_latMax;

zoomDirection = get(g_NTD_ZOOM_MODE, 'Direction');

if (strcmp(zoomDirection, 'in'))
   g_NTD_COMPUTE_BOUNDARIES = 0;
   xLim = get(gca, 'XLim');
   yLim = get(gca, 'YLim');

   [g_NTD_lonMin, g_NTD_latMin] = m_xy2ll(xLim(1), yLim(1));
   [g_NTD_lonMax, g_NTD_latMax] = m_xy2ll(xLim(2), yLim(2));
else
   g_NTD_COMPUTE_BOUNDARIES = 1;
end

plot_argos(g_NTD_ID_FLOAT, g_NTD_ID_CYCLE);

return;
