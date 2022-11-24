% ------------------------------------------------------------------------------
% Plot of cycle timings and parking and profile pressure levels.
%
% SYNTAX :
%   nc_trace_times or nc_trace_times(6900189, 7900118)
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
%   31/07/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_trace_times(varargin)

global g_NTT_NC_DIR;
global g_NTT_PDF_DIR;
global g_NTT_FIG_TIMES_HANDLE;
global g_NTT_ID_FLOAT;
global g_NTT_FLOAT_LIST;
global g_NTT_DRIFT_MES;
global g_NTT_ALL_MES_PROF;
global g_NTT_PRINT;
global g_NTT_CYCLE_0;
global g_NTT_ADJ;
global g_NTT_FLOAT_TIMES;

% top directory of NetCDF files to plot
% g_NTT_NC_DIR = 'C:\Users\jprannou\_DATA\OUT\nc_output_decPrv\';
% g_NTT_NC_DIR = 'C:\Users\jprannou\_DATA\OUT\nc_output_decApx\';
g_NTT_NC_DIR = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% g_NTT_NC_DIR = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo_TrajCheck\';
% g_NTT_NC_DIR = 'H:\archive_201702\incois\';

% directory to store pdf output
g_NTT_PDF_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default list of floats to plot
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_071412.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_062608.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_061609.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_021009.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_061810.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_093008.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_all2.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_021208.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_032213.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_110613.txt';
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
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nova_dova.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_arn_ir.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_4.54.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_apmt_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_apmt_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TrajChecker\_arvor_ir_decId_201.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TrajChecker\_arvor_ir_decId_202.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TrajChecker\_arvor_ir_decId_203.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TrajChecker\_arvor_ir_decId_205.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TrajChecker\_arvor_ir_decId_210.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TrajChecker\_arvor_ir_decId_211.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TrajChecker\_arvor_ir_ALL_decId_2xx.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TrajChecker\_nke_argos.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TrajChecker\_nova_dova.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TrajChecker\_apex_argos.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TrajChecker\_nke_rem_rudics.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.43.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.44.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.45.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\provor_5.74.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\provor_5.75.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_deep_5.64.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.44_BODC.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_rem_bodc.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_ir_rudics_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_ir_rudics_finland.txt';

fprintf('Plot management:\n');
fprintf('   Right Arrow  : next float\n');
fprintf('   Left Arrow   : previous float\n');
fprintf('   Up/Down Arrow: time TOTAL/DOWN/UP\n');
fprintf('   d            : plot of parking drift measurement times\n');
fprintf('   f            : plot AET and TST from float\n');
fprintf('   j            : use adjusted times and pressures\n');
fprintf('   m            : plot of profile bin levels\n');
fprintf('   z            : ignore cycle #0 data\n');
fprintf('   h            : write help and current configuration\n');
fprintf('p: pdf output file generation\n');
fprintf('Escape: exit\n\n');

% force the plot of the first float
g_NTT_ID_FLOAT = -1;

% plot of parking drift measurement
g_NTT_DRIFT_MES = 1;

% plot of profile bin levels
g_NTT_ALL_MES_PROF = 0;

% no pdf generation
g_NTT_PRINT = 0;

% display cycle #0 data
g_NTT_CYCLE_0 = 1;

% use adjusted data
g_NTT_ADJ = 2;

% display float times
g_NTT_FLOAT_TIMES = 0;

% default values initialization
init_default_values;

close(findobj('Name', 'Times'));
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

g_NTT_FLOAT_LIST = floatList;

% creation of the figure and its associated callback
screenSize = get(0, 'ScreenSize');
g_NTT_FIG_TIMES_HANDLE = figure('KeyPressFcn', @change_plot, ...
   'Name', 'Times', ...
   'Position', [1 screenSize(4)*(1/3) screenSize(3) screenSize(4)*(2/3)-90]);

% callback to manage the plot after a zoom
zoomMode = zoom(g_NTT_FIG_TIMES_HANDLE);
set(zoomMode, 'ActionPostCallback', @after_zoom);

% plot the DOWN times of the first float
plot_times(0, 0, 0);

return;

% ------------------------------------------------------------------------------
% Plot of cycle timings and parking and profile pressure levels of a given float.
%
% SYNTAX :
%  plot_times(a_idFloat, a_downOrUp, a_reload)
%
% INPUT PARAMETERS :
%   a_idFloat  : float Id in the list
%   a_downOrUp : times to plot (0: all, 1: UP times, 2: DOWN times)
%   a_reload   : reload nc data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   31/07/2014 - RNU - creation
% ------------------------------------------------------------------------------
function plot_times(a_idFloat, a_downOrUp, a_reload)

global g_NTT_NC_DIR;
global g_NTT_PDF_DIR;
global g_NTT_FIG_TIMES_HANDLE;
global g_NTT_ID_FLOAT;
global g_NTT_FLOAT_LIST;
global g_NTT_downOrUp;
global g_NTT_DRIFT_MES;
global g_NTT_ALL_MES_PROF;
global g_NTT_PRINT;
global g_NTT_CYCLE_0;
global g_NTT_ADJ;
global g_NTT_FLOAT_TIMES;

global g_NTT_cycles;
global g_NTT_cycleTime;
global g_NTT_diveStart;
global g_NTT_descentStart;
global g_NTT_descentEnd;
global g_NTT_firstDescProf;
global g_NTT_descProf;
global g_NTT_lastDescProf;
global g_NTT_firstDriftMes;
global g_NTT_driftMes;
global g_NTT_lastDriftMes;
global g_NTT_toProfStart;
global g_NTT_toProfEnd;
global g_NTT_ascentStart;
global g_NTT_ascentStartFloat;
global g_NTT_downTimeEndDate;
global g_NTT_ascentEnd;
global g_NTT_ascentEndFloat;
global g_NTT_argosStart;
global g_NTT_argosStartFloat;
global g_NTT_firstAscProf;
global g_NTT_ascProf;
global g_NTT_lastAscProf;
global g_NTT_argosFirstMsg;
global g_NTT_argosLoc;
global g_NTT_argosLastMsg;
global g_NTT_argosStop;

global g_NTT_tabParkPres;
global g_NTT_tabProfPres;
global g_NTT_tabMesProfPres;
global g_NTT_tabCyclesEtopo;
global g_NTT_tabEtopoMin;
global g_NTT_tabEtopoMax;

% default values initialization
init_valdef;

global g_dateDef;
global g_latDef;
global g_lonDef;
global g_presDef;
global g_elevDef;

% measurement codes initialization
init_measurement_codes;

% global measurement codes
global g_MC_DST;
global g_MC_DescProf;
global g_MC_PST;
global g_MC_DriftAtPark;
global g_MC_PET;
global g_MC_RPP;
global g_MC_DPST;
global g_MC_AST;
global g_MC_AST_Float;
global g_MC_DownTimeEnd;
global g_MC_AscProf;
global g_MC_AET;
global g_MC_AET_Float;
global g_MC_TST;
global g_MC_TST_Float;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;

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


% plot the current float
figure(g_NTT_FIG_TIMES_HANDLE);
clf;

g_NTT_downOrUp = a_downOrUp;

if ((a_idFloat ~= g_NTT_ID_FLOAT) || (a_reload == 1))
   
   % a new float is wanted
   g_NTT_ID_FLOAT = a_idFloat;
   g_NTT_cycles = [];
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve and store the data of the new float
   
   % float number
   floatNum = g_NTT_FLOAT_LIST(a_idFloat+1);
   floatNumStr = num2str(floatNum);
   
   % from META file
   metaFileName = [g_NTT_NC_DIR '/' floatNumStr '/' floatNumStr '_meta.nc'];
   
   % retrieve information from META file
   wantedVars = [ ...
      {'FORMAT_VERSION'} ...
      {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
      {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
      {'CONFIG_PARAMETER_NAME'} ...
      {'CONFIG_PARAMETER_VALUE'} ...
      ];
   [metaData] = get_data_from_nc_file(metaFileName, wantedVars);
   
   idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)) == 1, 1);
   metaFileFormatVersion = strtrim(metaData{2*idVal}');
   
   % check the meta file format version
   if (~strcmp(metaFileFormatVersion, '3.1'))
      fprintf('ERROR: Input meta file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s)\n', ...
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
   
   cycleTimeMeta = -1;
   idF = find(strcmp('CONFIG_CycleTime_days', launchConfigName(:)) == 1, 1);
   if (~isempty(idF) && (launchConfigValue(idF) ~= 99999))
      cycleTimeMeta = launchConfigValue(idF);
   else
      idF = find(strcmp('CONFIG_CycleTime_hours', launchConfigName(:)) == 1, 1);
      if (~isempty(idF) && (launchConfigValue(idF) ~= 99999))
         cycleTimeMeta = launchConfigValue(idF)/24;
      else
         idF = find(strcmp('CONFIG_CycleTime_seconds', launchConfigName(:)) == 1, 1);
         if (~isempty(idF) && (launchConfigValue(idF) ~= 99999))
            cycleTimeMeta = launchConfigValue(idF)/86400;
         else
            idF = find(strcmp('CONFIG_CycleTime_minutes', launchConfigName(:)) == 1, 1);
            if (~isempty(idF) && (launchConfigValue(idF) ~= 99999))
               cycleTimeMeta = launchConfigValue(idF)/1440;
            end
         end
      end
   end
   idF = find(strcmp('CONFIG_CycleTime_days', configName(:)) == 1, 1);
   if (~isempty(idF))
      cycleTime = configValue(idF, :);
      cycleTime(find(cycleTime == 99999)) = [];
      cycleTimeMeta = cycleTime(end);
   else
      idF = find(strcmp('CONFIG_CycleTime_hours', configName(:)) == 1, 1);
      if (~isempty(idF))
         cycleTime = configValue(idF, :);
         cycleTime(find(cycleTime == 99999)) = [];
         cycleTimeMeta = cycleTime(end)/24;
      else
         idF = find(strcmp('CONFIG_CycleTime_seconds', configName(:)) == 1, 1);
         if (~isempty(idF))
            cycleTime = configValue(idF, :);
            cycleTime(find(cycleTime == 99999)) = [];
            cycleTimeMeta = cycleTime(end)/86400;
         else
            idF = find(strcmp('CONFIG_CycleTime_minutes', configName(:)) == 1, 1);
            if (~isempty(idF))
               cycleTime = configValue(idF, :);
               cycleTime(find(cycleTime == 99999)) = [];
               cycleTimeMeta = cycleTime(end)/1440;
            end
         end
      end
   end
   
   % Remocean floats
   %    if (cycleTimeMeta == -1)
   %       idF = find(strcmp('CONFIG_InternalCycleTime1_hours', launchConfigName(:)) == 1, 1);
   %       if (~isempty(idF) && (launchConfigValue(idF) ~= 99999))
   %          cycleTimeMeta = launchConfigValue(idF)/24;
   %       end
   %       idF = find(strcmp('CONFIG_InternalCycleTime1_hours', configName(:)) == 1, 1);
   %       if (~isempty(idF))
   %          cycleTime = configValue(idF, :);
   %          cycleTime(find(cycleTime == 99999)) = [];
   %          cycleTimeMeta = cycleTime(end)/24;
   %       end
   %    end
   if (cycleTimeMeta == -1)
      fprintf('ERROR: Unable to retrieve CONFIG_CycleTime_days from meta file (%s) => CONFIG_CycleTime_days set to 10\n', ...
         metaFileName);
      cycleTimeMeta = 10;
      
      %       fprintf('ERROR: Unable to retrieve CONFIG_CycleTime_days from meta file (%s)\n', ...
      %          metaFileName);
      %       return;
   end
   cycleTimeMeta = cycleTimeMeta*24;
   
   % from TRAJ file
   trajFileName = [g_NTT_NC_DIR '/' floatNumStr '/' floatNumStr '_Rtraj.nc'];
   
   % retrieve information from TRAJ file
   wantedVars = [ ...
      {'FORMAT_VERSION'} ...
      {'JULD'} ...
      {'JULD_ADJUSTED'} ...
      {'LATITUDE'} ...
      {'LONGITUDE'} ...
      {'POSITION_ACCURACY'} ...
      {'CYCLE_NUMBER'} ...
      {'MEASUREMENT_CODE'} ...
      {'PRES'} ...
      {'PRES_ADJUSTED'} ...
      {'DATA_MODE'} ...
      {'CYCLE_NUMBER_INDEX'} ...
      ];
   [trajData] = get_data_from_nc_file(trajFileName, wantedVars);
   
   if (isempty(trajData))
      label = sprintf('%02d/%02d : %s no data', ...
         a_idFloat+1, ...
         length(g_NTT_FLOAT_LIST), ...
         num2str(g_NTT_FLOAT_LIST(a_idFloat+1)));
      title(label, 'FontSize', 14);
      return;
   end
   
   idVal = find(strcmp('FORMAT_VERSION', trajData(1:2:end)) == 1, 1);
   trajFileFormatVersion = strtrim(trajData{2*idVal}');
   
   % check the traj file format version
   if (~strcmp(trajFileFormatVersion, '3.1'))
      fprintf('ERROR: Input traj file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s)\n', ...
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
   
   idVal = find(strcmp('DATA_MODE', trajData(1:2:end)) == 1, 1);
   dataMode = trajData{2*idVal};
   
   idVal = find(strcmp('CYCLE_NUMBER_INDEX', trajData(1:2:end)) == 1, 1);
   cycleNumberIndexTraj = trajData{2*idVal};
   
   if (g_NTT_ADJ == 2)
      idVal = find(strcmp('JULD_ADJUSTED', trajData(1:2:end)) == 1, 1);
      juldAdj = trajData{2*idVal};
      
      idVal = find(strcmp('PRES_ADJUSTED', trajData(1:2:end)) == 1, 1);
      trajPresAdj = trajData{2*idVal};
      
      idVal = find(strcmp('JULD', trajData(1:2:end)) == 1, 1);
      juldNotAdj = trajData{2*idVal};
      
      idVal = find(strcmp('PRES', trajData(1:2:end)) == 1, 1);
      trajPresNotAdj = trajData{2*idVal};
      
      juld = juldAdj;
      trajPres = trajPresAdj;
      idNotAdj = find(dataMode == 'R');
      cycleNumNotAdj = unique(cycleNumberIndexTraj(idNotAdj));
      idNotAdj = find(ismember(cycleNumberTraj, cycleNumNotAdj));
      juld(idNotAdj) = juldNotAdj(idNotAdj);
      trajPres(idNotAdj) = trajPresNotAdj(idNotAdj);
   elseif (g_NTT_ADJ == 1)
      idVal = find(strcmp('JULD_ADJUSTED', trajData(1:2:end)) == 1, 1);
      juld = trajData{2*idVal};
      
      idVal = find(strcmp('PRES_ADJUSTED', trajData(1:2:end)) == 1, 1);
      trajPres = trajData{2*idVal};
   else
      idVal = find(strcmp('JULD', trajData(1:2:end)) == 1, 1);
      juld = trajData{2*idVal};
      
      idVal = find(strcmp('PRES', trajData(1:2:end)) == 1, 1);
      trajPres = trajData{2*idVal};
   end
   
   % from PROF file
   profFileName = [g_NTT_NC_DIR '/' floatNumStr '/' floatNumStr '_prof.nc'];
   
   % retrieve information from PROF file
   wantedVars = [ ...
      {'FORMAT_VERSION'} ...
      {'CYCLE_NUMBER'} ...
      {'DIRECTION'} ...
      {'PRES'} ...
      ];
   [profData] = get_data_from_nc_file(profFileName, wantedVars);
   
   if (isempty(profData))
      cycleNumberProf = [];
      maxMesProf = 0;
   else
      
      idVal = find(strcmp('FORMAT_VERSION', profData(1:2:end)) == 1, 1);
      profFileFormatVersion = strtrim(profData{2*idVal}');
      
      % check the prof file format version
      if (~strcmp(profFileFormatVersion, '3.1'))
         fprintf('ERROR: Input prof file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s)\n', ...
            profFileName, profFileFormatVersion);
         %          return;
      end
      
      idVal = find(strcmp('CYCLE_NUMBER', profData(1:2:end)) == 1, 1);
      cycleNumberProf = profData{2*idVal};
      
      idVal = find(strcmp('DIRECTION', profData(1:2:end)) == 1, 1);
      profDir = profData{2*idVal};
      
      idVal = find(strcmp('PRES', profData(1:2:end)) == 1, 1);
      profPres = profData{2*idVal};
      [nLev, nProf] = size(profPres);
      maxMesProf = nLev;
   end
   
   % cycles to consider
   cycles = cycleNumberTraj(find(cycleNumberTraj >= 0));
   cycles = [0:max(cycles)]';
   
   % compute the dimension of the arrays
   maxArgosLoc = 0;
   maxMesDrift = 0;
   maxMesDateDescProf = 0;
   maxMesDateAscProf = 0;
   for idCy = 1:length(cycles)
      numCycle = cycles(idCy);
      idCycle = find(cycleNumberTraj == numCycle);
      
      nbArgosLoc = length(find((measCode(idCycle) == g_MC_Surface) & (latitude(idCycle) ~= 99999)));
      maxArgosLoc = max([maxArgosLoc nbArgosLoc]);
      
      nbMesDrift = length(find(measCode(idCycle) == g_MC_DriftAtPark));
      maxMesDrift = max([maxMesDrift nbMesDrift]);
      
      nbMesDateDescProf = length(find(measCode(idCycle) == g_MC_DescProf));
      maxMesDateDescProf = max([maxMesDateDescProf nbMesDateDescProf]);
      
      nbMesDateAscProf = length(find(measCode(idCycle) == g_MC_AscProf));
      maxMesDateAscProf = max([maxMesDateAscProf nbMesDateAscProf]);
   end
   
   % arrays to store the data
   g_NTT_cycles = cycles;
   
   % times
   g_NTT_diveStart = ones(length(cycles), 1)*g_dateDef;
   g_NTT_descentStart = ones(length(cycles), 1)*g_dateDef;
   g_NTT_firstDescProf = ones(length(cycles), 1)*g_dateDef;
   g_NTT_descProf = ones(length(cycles), maxMesDateDescProf)*g_dateDef;
   g_NTT_lastDescProf = ones(length(cycles), 1)*g_dateDef;
   g_NTT_descentEnd = ones(length(cycles), 1)*g_dateDef;
   g_NTT_firstDriftMes = ones(length(cycles), 1)*g_dateDef;
   g_NTT_driftMes = ones(length(cycles), maxMesDrift)*g_dateDef;
   g_NTT_lastDriftMes = ones(length(cycles), 1)*g_dateDef;
   g_NTT_toProfStart = ones(length(cycles), 1)*g_dateDef;
   g_NTT_toProfEnd = ones(length(cycles), 1)*g_dateDef;
   g_NTT_ascentStart = ones(length(cycles), 1)*g_dateDef;
   g_NTT_ascentStartFloat = ones(length(cycles), 1)*g_dateDef;
   g_NTT_downTimeEndDate = ones(length(cycles), 1)*g_dateDef;
   g_NTT_firstAscProf = ones(length(cycles), 1)*g_dateDef;
   g_NTT_ascProf = ones(length(cycles), maxMesDateAscProf)*g_dateDef;
   g_NTT_lastAscProf = ones(length(cycles), 1)*g_dateDef;
   g_NTT_ascentEnd = ones(length(cycles), 1)*g_dateDef;
   g_NTT_argosStart = ones(length(cycles), 1)*g_dateDef;
   g_NTT_ascentEndFloat = ones(length(cycles), 1)*g_dateDef;
   g_NTT_argosStartFloat = ones(length(cycles), 1)*g_dateDef;
   g_NTT_argosFirstMsg = ones(length(cycles), 1)*g_dateDef;
   g_NTT_argosLoc = ones(length(cycles), maxArgosLoc)*g_dateDef;
   g_NTT_argosLastMsg = ones(length(cycles), 1)*g_dateDef;
   g_NTT_argosStop = ones(length(cycles), 1)*g_dateDef;
   
   % pressures
   g_NTT_tabParkPres = ones(length(cycles), 1)*g_presDef;
   g_NTT_tabProfPres = ones(length(cycles), 1)*g_presDef;
   g_NTT_tabMesProfPres = ones(length(cycles), maxMesProf)*g_presDef;
   tabFirstArgosLon = ones(length(cycles), 1)*g_lonDef;
   tabFirstArgosLat = ones(length(cycles), 1)*g_latDef;
   tabLastArgosLon = ones(length(cycles), 1)*g_lonDef;
   tabLastArgosLat = ones(length(cycles), 1)*g_latDef;
   g_NTT_tabCyclesEtopo = g_NTT_cycles;
   g_NTT_tabEtopoMin = ones(length(cycles), 1)*g_elevDef;
   g_NTT_tabEtopoMax = ones(length(cycles), 1)*-g_elevDef;
   
   % cycle duration
   g_NTT_cycleTime = cycleTimeMeta/24;
   
   % data storage
   for idCy = 1:length(cycles)
      numCycle = cycles(idCy);
      
      if (g_NTT_CYCLE_0 == 0)
         % for DPF floats
         if (numCycle == 0)
            continue;
         end
      end
      
      % from TRAJ file
      idCycle = find(cycleNumberTraj == numCycle);
      if (isempty(idCycle))
         continue;
      end
      
      idDescentStart = find(measCode(idCycle) == g_MC_DST);
      if (length(idDescentStart) > 1)
         fprintf('ERROR: Cycle number %d: %d DescentStart\n', ...
            numCycle, length(idDescentStart));
         idDescentStart = idDescentStart(1);
      end
      if (~isempty(idDescentStart) && (juld(idCycle(idDescentStart)) ~= 999999))
         g_NTT_descentStart(numCycle+1) = juld(idCycle(idDescentStart));
      end
      
      idMesDescProf = find(measCode(idCycle) == g_MC_DescProf);
      if (~isempty(idMesDescProf))
         dates = juld(idCycle(idMesDescProf));
         dates(find(dates == 999999)) = g_dateDef;
         g_NTT_descProf(numCycle+1, 1:length(idMesDescProf)) = dates;
         dates(find(dates == g_dateDef)) = [];
         if (~isempty(dates))
            g_NTT_firstDescProf(numCycle+1) = dates(1);
            g_NTT_lastDescProf(numCycle+1) = dates(end);
         end
      end
      
      idDescentEnd = find(measCode(idCycle) == g_MC_PST);
      if (length(idDescentEnd) > 1)
         fprintf('ERROR: Cycle number %d: %d DescentEnd\n', ...
            numCycle, length(idDescentEnd));
         idDescentEnd = idDescentEnd(1);
      end
      if (~isempty(idDescentEnd) && (juld(idCycle(idDescentEnd)) ~= 999999))
         g_NTT_descentEnd(numCycle+1) = juld(idCycle(idDescentEnd));
      end
      
      idDriftMes = find(measCode(idCycle) == g_MC_DriftAtPark);
      if (~isempty(idDriftMes))
         idDef = find(juld(idCycle(idDriftMes)) ~= 999999);
         if (~isempty(idDef))
            dates = juld(idCycle(idDriftMes(idDef)));
            dates(find(dates == 999999)) = g_dateDef;
            g_NTT_driftMes(numCycle+1, 1:length(idDriftMes)) = dates;
            dates(find(dates == g_dateDef)) = [];
            if (~isempty(dates))
               g_NTT_firstDriftMes(numCycle+1) = dates(1);
               g_NTT_lastDriftMes(numCycle+1) = dates(end);
            end
         end
      end
      
      idToProfStart = find(measCode(idCycle) == g_MC_PET);
      if (length(idToProfStart) > 1)
         fprintf('ERROR: Cycle number %d: %d ToProfStart\n', ...
            numCycle, length(idToProfStart));
         idToProfStart = idToProfStart(1);
      end
      if (~isempty(idToProfStart) && (juld(idCycle(idToProfStart)) ~= 999999))
         g_NTT_toProfStart(numCycle+1) = juld(idCycle(idToProfStart));
      end
      
      idToProfEnd = find(measCode(idCycle) == g_MC_DPST);
      if (length(idToProfEnd) > 1)
         fprintf('ERROR: Cycle number %d: %d ToProfEnd\n', ...
            numCycle, length(idToProfEnd));
         idToProfEnd = idToProfEnd(1);
      end
      if (~isempty(idToProfEnd) && (juld(idCycle(idToProfEnd)) ~= 999999))
         g_NTT_toProfEnd(numCycle+1) = juld(idCycle(idToProfEnd));
      end
      
      idAscentStart = find(measCode(idCycle) == g_MC_AST);
      if (length(idAscentStart) > 1)
         fprintf('ERROR: Cycle number %d: %d AscentStart\n', ...
            numCycle, length(idAscentStart));
         idAscentStart = idAscentStart(1);
      end
      if (~isempty(idAscentStart) && (juld(idCycle(idAscentStart)) ~= 999999))
         g_NTT_ascentStart(numCycle+1) = juld(idCycle(idAscentStart));
      end
      
      idAscentStartFloat = find(measCode(idCycle) == g_MC_AST_Float);
      if (length(idAscentStartFloat) > 1)
         fprintf('ERROR: Cycle number %d: %d AscentStartFloat\n', ...
            numCycle, length(idAscentStartFloat));
         idAscentStartFloat = idAscentStartFloat(1);
      end
      if (~isempty(idAscentStartFloat) && (juld(idCycle(idAscentStartFloat)) ~= 999999))
         g_NTT_ascentStartFloat(numCycle+1) = juld(idCycle(idAscentStartFloat));
      end
      
      idDownTimeEnd = find(measCode(idCycle) == g_MC_DownTimeEnd);
      if (length(idDownTimeEnd) > 1)
         fprintf('ERROR: Cycle number %d: %d DownTimeEnd\n', ...
            numCycle, length(idDownTimeEnd));
         idDownTimeEnd = idDownTimeEnd(1);
      end
      if (~isempty(idDownTimeEnd) && (juld(idCycle(idDownTimeEnd)) ~= 999999))
         g_NTT_downTimeEndDate(numCycle+1) = juld(idCycle(idDownTimeEnd));
      end
      
      idMesAscProf = find(measCode(idCycle) == g_MC_AscProf);
      if (~isempty(idMesAscProf))
         dates = juld(idCycle(idMesAscProf));
         dates(find(dates == 999999)) = g_dateDef;
         g_NTT_ascProf(numCycle+1, 1:length(idMesAscProf)) = dates;
         dates(find(dates == g_dateDef)) = [];
         if (~isempty(dates))
            g_NTT_firstAscProf(numCycle+1) = dates(1);
            g_NTT_lastAscProf(numCycle+1) = dates(end);
         end
      end
      
      idAscentEnd = find(measCode(idCycle) == g_MC_AET);
      if (length(idAscentEnd) > 1)
         fprintf('ERROR: Cycle number %d: %d AscentEnd\n', ...
            numCycle, length(idAscentEnd));
         idAscentEnd = idAscentEnd(1);
      end
      if (~isempty(idAscentEnd) && (juld(idCycle(idAscentEnd)) ~= 999999))
         g_NTT_ascentEnd(numCycle+1) = juld(idCycle(idAscentEnd));
      end
      
      if (g_NTT_FLOAT_TIMES == 1)
         idAscentEndFloat = find(measCode(idCycle) == g_MC_AET_Float);
         if (length(idAscentEndFloat) > 1)
            fprintf('ERROR: Cycle number %d: %d AscentEndFloat\n', ...
               numCycle, length(idAscentEndFloat));
            idAscentEndFloat = idAscentEndFloat(1);
         end
         if (~isempty(idAscentEndFloat) && (juld(idCycle(idAscentEndFloat)) ~= 999999))
            g_NTT_ascentEndFloat(numCycle+1) = juld(idCycle(idAscentEndFloat));
         end
      end
      
      idArgosStart = find(measCode(idCycle) == g_MC_TST);
      if (length(idArgosStart) > 1)
         fprintf('ERROR: Cycle number %d: %d ArgosStart\n', ...
            numCycle, length(idArgosStart));
         idArgosStart = idArgosStart(1);
      end
      if (~isempty(idArgosStart) && (juld(idCycle(idArgosStart)) ~= 999999))
         g_NTT_argosStart(numCycle+1) = juld(idCycle(idArgosStart));
      end
      
      if (g_NTT_FLOAT_TIMES == 1)
         idArgosStartFloat = find(measCode(idCycle) == g_MC_TST_Float);
         if (length(idArgosStartFloat) > 1)
            fprintf('ERROR: Cycle number %d: %d ArgosStartFloat\n', ...
               numCycle, length(idArgosStartFloat));
            idArgosStartFloat = idArgosStartFloat(1);
         end
         if (~isempty(idArgosStartFloat) && (juld(idCycle(idArgosStartFloat)) ~= 999999))
            g_NTT_argosStartFloat(numCycle+1) = juld(idCycle(idArgosStartFloat));
         end
      end
      
      idArgosFirstMsg = find(measCode(idCycle) == g_MC_FMT);
      if (length(idArgosFirstMsg) > 1)
         fprintf('ERROR: Cycle number %d: %d ArgosFirstMsg\n', ...
            numCycle, length(idArgosFirstMsg));
         idArgosFirstMsg = idArgosFirstMsg(1);
      end
      if (~isempty(idArgosFirstMsg) && (juld(idCycle(idArgosFirstMsg)) ~= 999999))
         g_NTT_argosFirstMsg(numCycle+1) = juld(idCycle(idArgosFirstMsg));
      end
      
      idArgosLoc = find((measCode(idCycle) == g_MC_Surface) & (latitude(idCycle) ~= 99999));
      if (~isempty(idArgosLoc))
         dates = juld(idCycle(idArgosLoc));
         dates(find(dates == 999999)) = g_dateDef;
         g_NTT_argosLoc(numCycle+1, 1:length(idArgosLoc)) = dates;
      end
      
      idArgosLastMsg = find(measCode(idCycle) == g_MC_LMT);
      if (length(idArgosLastMsg) > 1)
         fprintf('ERROR: Cycle number %d: %d ArgosLastMsg\n', ...
            numCycle, length(idArgosLastMsg));
         idArgosLastMsg = idArgosLastMsg(1);
      end
      if (~isempty(idArgosLastMsg) && (juld(idCycle(idArgosLastMsg)) ~= 999999))
         g_NTT_argosLastMsg(numCycle+1) = juld(idCycle(idArgosLastMsg));
      end
      
      idArgosStop = find(measCode(idCycle) == g_MC_TET);
      if (length(idArgosStop) > 1)
         fprintf('ERROR: Cycle number %d: %d ArgosStop\n', ...
            numCycle, length(idArgosStop));
         idArgosStop = idArgosStop(1);
      end
      if (~isempty(idArgosStop) && (juld(idCycle(idArgosStop)) ~= 999999))
         g_NTT_argosStop(numCycle+1) = juld(idCycle(idArgosStop));
      end
      
      idMeanParkMes = find(measCode(idCycle) == g_MC_RPP);
      if (length(idMeanParkMes) > 1)
         fprintf('ERROR: Cycle number %d: %d MeanParkMes\n', ...
            numCycle, length(idMeanParkMes));
         idMeanParkMes = idMeanParkMes(1);
      end
      if (~isempty(idMeanParkMes) && (trajPres(idCycle(idMeanParkMes)) ~= 99999))
         g_NTT_tabParkPres(numCycle+1) = trajPres(idCycle(idMeanParkMes));
      end
      
      idArgosLoc = find((measCode(idCycle) == g_MC_Surface) & (latitude(idCycle) ~= 99999));
      if (~isempty(idArgosLoc))
         tabLon = longitude(idCycle(idArgosLoc));
         tabLat = latitude(idCycle(idArgosLoc));
         tabPosQc = posAcc(idCycle(idArgosLoc));
         
         idGoodPos = find((tabPosQc == g_decArgo_qcStrGood) | (tabPosQc == g_decArgo_qcStrProbablyGood) | (tabPosQc == g_decArgo_qcStrCorrectable) | (tabPosQc == 'G'));
         tabLon = tabLon(idGoodPos);
         tabLat = tabLat(idGoodPos);
         
         if (~isempty(idGoodPos))
            tabFirstArgosLon(numCycle+1) = tabLon(1);
            tabFirstArgosLat(numCycle+1) = tabLat(1);
            tabLastArgosLon(numCycle+1) = tabLon(end);
            tabLastArgosLat(numCycle+1) = tabLat(end);
         end
      end
      
      % from PROF file
      idCycle = find(cycleNumberProf == numCycle);
      if (isempty(idCycle))
         continue;
      end
      
      idProfAsc = find(profDir(idCycle) == 'A');
      if (~isempty(idProfAsc))
         tabPres = profPres(:, idCycle(idProfAsc));
         tabPres(find(tabPres == 99999)) = [];
         g_NTT_tabProfPres(numCycle+1) = tabPres(end);
         g_NTT_tabMesProfPres(numCycle+1, 1:length(tabPres)) = tabPres;
      end
   end
   
   % retrieve ETOPO2 elevations at the first and last Argos locations
   for idCy = 2:length(cycles)
      if (tabLastArgosLon(idCy-1) ~= g_lonDef)
         [firstElev, lon, lat] = m_etopo2( ...
            [tabLastArgosLon(idCy-1) tabLastArgosLon(idCy-1) ...
            tabLastArgosLat(idCy-1) tabLastArgosLat(idCy-1)]);
         g_NTT_tabEtopoMin(idCy-1) = min(min(firstElev));
         g_NTT_tabEtopoMax(idCy-1) = max(max(firstElev));
      end
      
      if (tabFirstArgosLon(idCy) ~= g_lonDef)
         [secondElev, lon, lat] = m_etopo2( ...
            [tabFirstArgosLon(idCy) tabFirstArgosLon(idCy) ...
            tabFirstArgosLat(idCy) tabFirstArgosLat(idCy)]);
         g_NTT_tabEtopoMin(idCy-1) = min([g_NTT_tabEtopoMin(idCy-1) min(min(secondElev))]);
         g_NTT_tabEtopoMax(idCy-1) = max([g_NTT_tabEtopoMax(idCy-1) max(max(secondElev))]);
      end
   end
   
   idKo = find(g_NTT_tabEtopoMin == g_elevDef);
   g_NTT_tabCyclesEtopo(idKo) = [];
   g_NTT_tabEtopoMin(idKo) = [];
   g_NTT_tabEtopoMax(idKo) = [];
   g_NTT_tabEtopoMin = -g_NTT_tabEtopoMin;
   g_NTT_tabEtopoMax = -g_NTT_tabEtopoMax;
   
end

if (isempty(g_NTT_cycles))
   label = sprintf('%02d/%02d : %s no data', ...
      a_idFloat+1, ...
      length(g_NTT_FLOAT_LIST), ...
      num2str(g_NTT_FLOAT_LIST(a_idFloat+1)));
   title(label, 'FontSize', 14);
   return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TIME DATA

timeAxes = subplot('Position', [0.044 0.085 0.63 0.85]);

if ((a_downOrUp == 0) || (a_downOrUp == 1))
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % DESCENT
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % data pre-processing
   
   xArgosLastMsgData = [g_dateDef; g_NTT_argosLastMsg(1:end-1)];
   yArgosLastMsgData = g_NTT_cycles;
   idKo = find(xArgosLastMsgData == g_dateDef);
   xArgosLastMsgData(idKo) = [];
   yArgosLastMsgData(idKo) = [];
   
   xDiveStartData = g_NTT_diveStart;
   yDiveStartData = g_NTT_cycles;
   idKo = find(xDiveStartData == g_dateDef);
   xDiveStartData(idKo) = [];
   yDiveStartData(idKo) = [];
   
   xDescentStartData = g_NTT_descentStart;
   yDescentStartData = g_NTT_cycles;
   idKo = find(xDescentStartData == g_dateDef);
   xDescentStartData(idKo) = [];
   yDescentStartData(idKo) = [];
   
   if (g_NTT_DRIFT_MES == 1)
      xFirstDescProf = g_NTT_firstDescProf;
      yFirstDescProf = g_NTT_cycles;
      idKo = find(xFirstDescProf == g_dateDef);
      xFirstDescProf(idKo) = [];
      yFirstDescProf(idKo) = [];
      
      xLastDescProf = g_NTT_lastDescProf;
      yLastDescProf = g_NTT_cycles;
      idKo = find(xLastDescProf == g_dateDef);
      xLastDescProf(idKo) = [];
      yLastDescProf(idKo) = [];
   end
   
   xDescentEndData = g_NTT_descentEnd;
   yDescentEndData = g_NTT_cycles;
   idKo = find(xDescentEndData == g_dateDef);
   xDescentEndData(idKo) = [];
   yDescentEndData(idKo) = [];
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot the data
   
   if (~isempty(xArgosLastMsgData))
      xArgosLastMsgData = xArgosLastMsgData - double(yArgosLastMsgData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xArgosLastMsgData, yArgosLastMsgData, 'r.-');
      hold on;
   end
   
   if (~isempty(xDiveStartData))
      xDiveStartData = xDiveStartData - double(yDiveStartData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xDiveStartData, yDiveStartData, 'c.-');
      hold on;
   end
   
   if (~isempty(xDescentStartData))
      xDescentStartData = xDescentStartData - double(yDescentStartData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xDescentStartData, yDescentStartData, 'm*-');
      hold on;
   end
   
   if (g_NTT_DRIFT_MES == 1)
      if (~isempty(xFirstDescProf))
         xFirstDescProf = xFirstDescProf - double(yFirstDescProf-g_NTT_cycles(1))*g_NTT_cycleTime;
         plot(timeAxes, xFirstDescProf, yFirstDescProf, 'r-');
         hold on;
      end
      
      [nlig ncol] = size(g_NTT_descProf);
      for id = 1:nlig
         xDescProf = g_NTT_descProf(id, :)';
         idKo = find(xDescProf == g_dateDef);
         xDescProf(idKo) = [];
         
         if (~isempty(xDescProf))
            yDescProf = ones(length(xDescProf), 1)*double(g_NTT_cycles(id));
            xDescProf = xDescProf - double(g_NTT_cycles(id)-g_NTT_cycles(1))*g_NTT_cycleTime;
            plot(timeAxes, xDescProf, yDescProf, 'r.');
            hold on;
         end
      end
      
      if (~isempty(xLastDescProf))
         xLastDescProf = xLastDescProf - double(yLastDescProf-g_NTT_cycles(1))*g_NTT_cycleTime;
         plot(timeAxes, xLastDescProf, yLastDescProf, 'r-');
         hold on;
      end
   end
   
   if (~isempty(xDescentEndData))
      xDescentEndData = xDescentEndData - double(yDescentEndData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xDescentEndData, yDescentEndData, 'mo-');
      hold on;
   end
   
end

if ((a_downOrUp == 0) || (a_downOrUp == 2))
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % ASCENT
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % data pre-processing
   
   xToProfStartData = g_NTT_toProfStart;
   yToProfStartData = g_NTT_cycles;
   idKo = find(xToProfStartData == g_dateDef);
   xToProfStartData(idKo) = [];
   yToProfStartData(idKo) = [];
   
   xToProfEndData = g_NTT_toProfEnd;
   yToProfEndData = g_NTT_cycles;
   idKo = find(xToProfEndData == g_dateDef);
   xToProfEndData(idKo) = [];
   yToProfEndData(idKo) = [];
   
   xAscentStartData = g_NTT_ascentStart;
   yAscentStartData = g_NTT_cycles;
   idKo = find(xAscentStartData == g_dateDef);
   xAscentStartData(idKo) = [];
   yAscentStartData(idKo) = [];
   
   xAscentStartFloatData = g_NTT_ascentStartFloat;
   yAscentStartFloatData = g_NTT_cycles;
   idKo = find(xAscentStartFloatData == g_dateDef);
   xAscentStartFloatData(idKo) = [];
   yAscentStartFloatData(idKo) = [];
   
   xDownTimeEndData = g_NTT_downTimeEndDate;
   yDownTimeEndData = g_NTT_cycles;
   idKo = find(xDownTimeEndData == g_dateDef);
   xDownTimeEndData(idKo) = [];
   yDownTimeEndData(idKo) = [];
   
   if (g_NTT_DRIFT_MES == 1)
      xFirstAscProf = g_NTT_firstAscProf;
      yFirstAscProf = g_NTT_cycles;
      idKo = find(xFirstAscProf == g_dateDef);
      xFirstAscProf(idKo) = [];
      yFirstAscProf(idKo) = [];
      
      xLastAscProf = g_NTT_lastAscProf;
      yLastAscProf = g_NTT_cycles;
      idKo = find(xLastAscProf == g_dateDef);
      xLastAscProf(idKo) = [];
      yLastAscProf(idKo) = [];
   end
   
   xAscentEndData = g_NTT_ascentEnd;
   yAscentEndData = g_NTT_cycles;
   idKo = find(xAscentEndData == g_dateDef);
   xAscentEndData(idKo) = [];
   yAscentEndData(idKo) = [];
   
   xAscentEndFloatData = g_NTT_ascentEndFloat;
   yAscentEndFloatData = g_NTT_cycles;
   idKo = find(xAscentEndFloatData == g_dateDef);
   xAscentEndFloatData(idKo) = [];
   yAscentEndFloatData(idKo) = [];
   
   xArgosStartData = g_NTT_argosStart;
   yArgosStartData = g_NTT_cycles;
   idKo = find(xArgosStartData == g_dateDef);
   xArgosStartData(idKo) = [];
   yArgosStartData(idKo) = [];
   
   xArgosStartFloatData = g_NTT_argosStartFloat;
   yArgosStartFloatData = g_NTT_cycles;
   idKo = find(xArgosStartFloatData == g_dateDef);
   xArgosStartFloatData(idKo) = [];
   yArgosStartFloatData(idKo) = [];
   
   xArgosFirstMsgData = g_NTT_argosFirstMsg;
   yArgosFirstMsgData = g_NTT_cycles;
   idKo = find(xArgosFirstMsgData == g_dateDef);
   xArgosFirstMsgData(idKo) = [];
   yArgosFirstMsgData(idKo) = [];
   
   xArgosLastMsgData = g_NTT_argosLastMsg;
   yArgosLastMsgData = g_NTT_cycles;
   idKo = find(xArgosLastMsgData == g_dateDef);
   xArgosLastMsgData(idKo) = [];
   yArgosLastMsgData(idKo) = [];
   
   xArgosStopData = g_NTT_argosStop;
   yArgosStopData = g_NTT_cycles;
   idKo = find(xArgosStopData == g_dateDef);
   xArgosStopData(idKo) = [];
   yArgosStopData(idKo) = [];
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot the data
   
   if (~isempty(xToProfStartData))
      xToProfStartData = xToProfStartData - double(yToProfStartData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xToProfStartData, yToProfStartData, 'c.-');
      hold on;
   end
   
   if (~isempty(xToProfEndData))
      xToProfEndData = xToProfEndData - double(yToProfEndData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xToProfEndData, yToProfEndData, 'co-');
      hold on;
   end
   
   if (~isempty(xAscentStartData))
      xAscentStartData = xAscentStartData - double(yAscentStartData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xAscentStartData, yAscentStartData, 'm*-');
      hold on;
   end
   
   if (~isempty(xAscentStartFloatData))
      xAscentStartFloatData = xAscentStartFloatData - double(yAscentStartFloatData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xAscentStartFloatData, yAscentStartFloatData, 'b.-');
      hold on;
   end
   
   if (~isempty(xDownTimeEndData))
      xDownTimeEndData = xDownTimeEndData - double(yDownTimeEndData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xDownTimeEndData, yDownTimeEndData, 'go-');
      hold on;
   end
   
   if (g_NTT_DRIFT_MES == 1)
      if (~isempty(xFirstAscProf))
         xFirstAscProf = xFirstAscProf - double(yFirstAscProf-g_NTT_cycles(1))*g_NTT_cycleTime;
         plot(timeAxes, xFirstAscProf, yFirstAscProf, 'r-');
         hold on;
      end
      
      [nlig ncol] = size(g_NTT_ascProf);
      for id = 1:nlig
         xAscProf = g_NTT_ascProf(id, :)';
         idKo = find(xAscProf == g_dateDef);
         xAscProf(idKo) = [];
         
         if (~isempty(xAscProf))
            yAscProf = ones(length(xAscProf), 1)*double(g_NTT_cycles(id));
            xAscProf = xAscProf - double(g_NTT_cycles(id)-g_NTT_cycles(1))*g_NTT_cycleTime;
            plot(timeAxes, xAscProf, yAscProf, 'r.');
            hold on;
         end
      end
      
      if (~isempty(xLastAscProf))
         xLastAscProf = xLastAscProf - double(yLastAscProf-g_NTT_cycles(1))*g_NTT_cycleTime;
         plot(timeAxes, xLastAscProf, yLastAscProf, 'r-');
         hold on;
      end
   end
   
   if (~isempty(xAscentEndData))
      xAscentEndData = xAscentEndData - double(yAscentEndData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xAscentEndData, yAscentEndData, 'mo-');
      hold on;
   end
   
   if (~isempty(xAscentEndFloatData))
      xAscentEndFloatData = xAscentEndFloatData - double(yAscentEndFloatData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xAscentEndFloatData, yAscentEndFloatData, 'ko-');
      hold on;
   end
   
   if (~isempty(xArgosStartData))
      xArgosStartData = xArgosStartData - double(yArgosStartData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xArgosStartData, yArgosStartData, 'c.-');
      hold on;
   end
   
   if (~isempty(xArgosStartFloatData))
      xArgosStartFloatData = xArgosStartFloatData - double(yArgosStartFloatData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xArgosStartFloatData, yArgosStartFloatData, 'k.-');
      hold on;
   end
   
   if (~isempty(xArgosFirstMsgData))
      xArgosFirstMsgData = xArgosFirstMsgData - double(yArgosFirstMsgData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xArgosFirstMsgData, yArgosFirstMsgData, 'r.-');
      hold on;
   end
   
   [nlig ncol] = size(g_NTT_argosLoc);
   for id = 1:nlig
      xArgosLocData = g_NTT_argosLoc(id, :)';
      idKo = find(xArgosLocData == g_dateDef);
      xArgosLocData(idKo) = [];
      
      if (~isempty(xArgosLocData))
         yArgosLocData = ones(length(xArgosLocData), 1)*double(g_NTT_cycles(id));
         xArgosLocData = xArgosLocData - double(g_NTT_cycles(id)-g_NTT_cycles(1))*g_NTT_cycleTime;
         plot(timeAxes, xArgosLocData, yArgosLocData, 'b.');
         hold on;
      end
   end
   
   if (~isempty(xArgosLastMsgData))
      xArgosLastMsgData = xArgosLastMsgData - double(yArgosLastMsgData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xArgosLastMsgData, yArgosLastMsgData, 'r.-');
      hold on;
   end
   
   if (~isempty(xArgosStopData))
      xArgosStopData = xArgosStopData - double(yArgosStopData-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xArgosStopData, yArgosStopData, 'c.-');
      hold on;
   end
   
end

if ((a_downOrUp == 0) && (g_NTT_DRIFT_MES == 1))
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % PARKING DRIFT
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % data pre-processing
   
   xFirstDriftMes = g_NTT_firstDriftMes;
   yFirstDriftMes = g_NTT_cycles;
   idKo = find(xFirstDriftMes == g_dateDef);
   xFirstDriftMes(idKo) = [];
   yFirstDriftMes(idKo) = [];
   
   xLastDriftMes = g_NTT_lastDriftMes;
   yLastDriftMes = g_NTT_cycles;
   idKo = find(xLastDriftMes == g_dateDef);
   xLastDriftMes(idKo) = [];
   yLastDriftMes(idKo) = [];
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot the data
   
   if (~isempty(xFirstDriftMes))
      xFirstDriftMes = xFirstDriftMes - double(yFirstDriftMes-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xFirstDriftMes, yFirstDriftMes, 'g-');
      hold on;
   end
   
   [nlig ncol] = size(g_NTT_driftMes);
   for id = 1:nlig
      xDriftMes = g_NTT_driftMes(id, :)';
      idKo = find(xDriftMes == g_dateDef);
      xDriftMes(idKo) = [];
      
      if (~isempty(xDriftMes))
         yDriftMes = ones(length(xDriftMes), 1)*double(g_NTT_cycles(id));
         xDriftMes = xDriftMes - double(g_NTT_cycles(id)-g_NTT_cycles(1))*g_NTT_cycleTime;
         plot(timeAxes, xDriftMes, yDriftMes, 'g.');
         hold on;
      end
   end
   
   if (~isempty(xLastDriftMes))
      xLastDriftMes = xLastDriftMes - double(yLastDriftMes-g_NTT_cycles(1))*g_NTT_cycleTime;
      plot(timeAxes, xLastDriftMes, yLastDriftMes, 'g-');
      hold on;
   end
   
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRESSURE DATA

presAxes = subplot('Position', [0.73 0.085 0.25 0.85]);
maxPres = -g_presDef;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% data pre-processing

xParkPresData = g_NTT_tabParkPres;
yParkPresData = g_NTT_cycles;
idKo = find(xParkPresData == g_presDef);
xParkPresData(idKo) = [];
yParkPresData(idKo) = [];

xProfPresData = g_NTT_tabProfPres;
yProfPresData = g_NTT_cycles;
idKo = find(xProfPresData == g_presDef);
xProfPresData(idKo) = [];
yProfPresData(idKo) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the data

if (g_NTT_ALL_MES_PROF ~= 0)
   [nlig ncol] = size(g_NTT_tabMesProfPres);
   for id = 1:nlig
      xMesProfPresData = g_NTT_tabMesProfPres(id, :)';
      yMesProfPresData = ones(length(xMesProfPresData), 1)*(id-1);
      
      idKo = find(xMesProfPresData == g_presDef);
      xMesProfPresData(idKo) = [];
      yMesProfPresData(idKo) = [];
      
      if (~isempty(xMesProfPresData))
         plot(presAxes, xMesProfPresData, yMesProfPresData, 'b.');
         hold on;
         maxPres = max([maxPres max(xMesProfPresData)]);
      end
   end
end

if (~isempty(xProfPresData))
   plot(presAxes, xProfPresData, yProfPresData, 'b.-');
   hold on;
   maxPres = max([maxPres max(xProfPresData)]);
end

if (~isempty(xParkPresData))
   plot(presAxes, xParkPresData, yParkPresData, 'r.-');
   hold on;
   maxPres = max([maxPres max(xParkPresData)]);
end

% ETOPO2 bathymetry
if (~isempty(g_NTT_tabCyclesEtopo))
   if (~isempty(find(g_NTT_tabEtopoMax < maxPres)))
      plot(presAxes, g_NTT_tabEtopoMin, g_NTT_tabCyclesEtopo, 'k.-');
      hold on;
      
      plot(presAxes, g_NTT_tabEtopoMax, g_NTT_tabCyclesEtopo, 'k.-');
      hold on;
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot post-processing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% time plot

% cycle axis

% Y axis min and max values
yMax = ceil((double(max(g_NTT_cycles)) + 1)/5)*5;
set(timeAxes, 'Ylim', [-1 yMax]);

% increasing cycles
set(timeAxes,'YDir','reverse');

% title of Y axis
set(get(timeAxes, 'YLabel'), 'String', 'Cycles');

% time axis

% X ticks management
xTick = get(timeAxes, 'XTick');
referenceDate = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
xTick = xTick + referenceDate;
if (max(xTick) - min(xTick) > 2)
   xTickLabel = datestr(xTick, 'dd/mm/yyyy');
else
   xTickLabel = datestr(xTick, 'dd/mm/yyyy HH:MM:SS');
end
[lig, col] = size(xTickLabel);
xTickLabel(2:2:lig, 1:col) = ' ';
set(timeAxes, 'XTickLabel', xTickLabel);

% title of X axis
set(get(timeAxes, 'XLabel'), 'String', 'Times');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pressure plot

% cycle axis

% Y axis min and max values
set(presAxes, 'Ylim', [-1 yMax]);

% increasing cycles
set(presAxes,'YDir','reverse');

% title of Y axis
% set(get(presAxes, 'YLabel'), 'String', 'Cycles');

% pressure axis

% X axis min and max values
maxPres = 100*ceil(maxPres/100);
if (maxPres <= 0)
   maxPres = 1;
end
set(presAxes, 'Xlim', [0 maxPres]);

% title of X axis
set(get(presAxes, 'XLabel'), 'String', 'Pressure (dbar)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot title

if (a_downOrUp == 0)
   comment = 'times';
elseif (a_downOrUp == 1)
   comment = 'down times';
elseif (a_downOrUp == 2)
   comment = 'up times';
end

labelTime = sprintf('%02d/%02d : %s %s', ...
   a_idFloat+1, ...
   length(g_NTT_FLOAT_LIST), ...
   num2str(g_NTT_FLOAT_LIST(a_idFloat+1)), ...
   comment);

labelPres = sprintf('%02d/%02d : %s park & prof pressures', ...
   a_idFloat+1, ...
   length(g_NTT_FLOAT_LIST), ...
   num2str(g_NTT_FLOAT_LIST(a_idFloat+1)));

title(timeAxes, labelTime, 'FontSize', 14);
title(presAxes, labelPres, 'FontSize', 14);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pdf output management

if (g_NTT_PRINT)
   orient landscape
   print('-dpdf', [g_NTT_PDF_DIR '/' sprintf('nc_trace_times_%s', num2str(g_NTT_FLOAT_LIST(a_idFloat+1))) '.pdf']);
   g_NTT_PRINT = 0;
   orient portrait
end

return;

% ------------------------------------------------------------------------------
% Callback to manage plots:
%   - right Arrow   : next float
%   - left Arrow    : previous float
%   - up/down Arrow : time TOTAL/DOWN/UP
%   - d             : plot of parking drift measurement times
%   - m             : plot of profile bin levels
%   - h             : write help and current configuration
%   - p             : pdf output file generation
%   - escape        : exit
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
%   07/30/2014 - RNU - creation
% ------------------------------------------------------------------------------
function change_plot(a_src, a_eventData)

global g_NTT_FIG_TIMES_HANDLE;
global g_NTT_ID_FLOAT g_NTT_FLOAT_LIST;
global g_NTT_downOrUp;
global g_NTT_DRIFT_MES;
global g_NTT_ALL_MES_PROF;
global g_NTT_PRINT;
global g_NTT_CYCLE_0;
global g_NTT_ADJ;
global g_NTT_FLOAT_TIMES;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% exit
if (strcmp(a_eventData.Key, 'escape'))
   set(g_NTT_FIG_TIMES_HANDLE, 'KeyPressFcn', '');
   close(g_NTT_FIG_TIMES_HANDLE);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % next float
elseif (strcmp(a_eventData.Key, 'rightarrow'))
   plot_times( ...
      mod(g_NTT_ID_FLOAT+1, length(g_NTT_FLOAT_LIST)), ...
      g_NTT_downOrUp, 0);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % previous float
elseif (strcmp(a_eventData.Key, 'leftarrow'))
   plot_times( ...
      mod(g_NTT_ID_FLOAT-1, length(g_NTT_FLOAT_LIST)), ...
      g_NTT_downOrUp, 0);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % time TOTAL/DOWN/UP
elseif (strcmp(a_eventData.Key, 'uparrow'))
   plot_times( ...
      g_NTT_ID_FLOAT, ...
      mod(g_NTT_downOrUp-1, 3), 0);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % time TOTAL/DOWN/UP
elseif (strcmp(a_eventData.Key, 'downarrow'))
   plot_times( ...
      g_NTT_ID_FLOAT, ...
      mod(g_NTT_downOrUp+1, 3), 0);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % ignore cycle #0 data
elseif (strcmp(a_eventData.Key, 'z'))
   g_NTT_CYCLE_0 = mod(g_NTT_CYCLE_0+1, 2);
   plot_times(g_NTT_ID_FLOAT, g_NTT_downOrUp, 1);
   
   display_current_config;
      
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % use adjusted times and pressures
elseif (strcmp(a_eventData.Key, 'j'))
   g_NTT_ADJ = mod(g_NTT_ADJ+1, 3);
   plot_times(g_NTT_ID_FLOAT, g_NTT_downOrUp, 1);
   
   display_current_config;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot float times
elseif (strcmp(a_eventData.Key, 'f'))
   g_NTT_FLOAT_TIMES = mod(g_NTT_FLOAT_TIMES+1, 2);
   plot_times(g_NTT_ID_FLOAT, g_NTT_downOrUp, 1);
   
   display_current_config;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot of parking drift measurement times
elseif (strcmp(a_eventData.Key, 'd'))
   g_NTT_DRIFT_MES = mod(g_NTT_DRIFT_MES+1, 2);
   plot_times(g_NTT_ID_FLOAT, g_NTT_downOrUp, 0);
   
   display_current_config;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot of profile bin levels
elseif (strcmp(a_eventData.Key, 'm'))
   g_NTT_ALL_MES_PROF = mod(g_NTT_ALL_MES_PROF+1, 2);
   plot_times(g_NTT_ID_FLOAT, g_NTT_downOrUp, 0);
   
   display_current_config;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % pdf output file generation
elseif (strcmp(a_eventData.Key, 'p'))
   g_NTT_PRINT = 1;
   plot_times(g_NTT_ID_FLOAT, g_NTT_downOrUp, 0);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % write help and current configuration
elseif (strcmp(a_eventData.Key, 'h'))
   fprintf('Plot management:\n');
   fprintf('   Right Arrow  : next float\n');
   fprintf('   Left Arrow   : previous float\n');
   fprintf('   Up/Down Arrow: time TOTAL/DOWN/UP\n');
   fprintf('   d            : plot of parking drift measurement times\n');
   fprintf('   f            : plot AET and TST from float\n');
   fprintf('   j            : use adjusted times and pressures\n');
   fprintf('   m            : plot of profile bin levels\n');
   fprintf('   z            : ignore cycle #0 data\n');
   fprintf('   h            : write help and current configuration\n');
   fprintf('p: pdf output file generation\n');
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

global g_NTT_DRIFT_MES;
global g_NTT_ALL_MES_PROF;
global g_NTT_CYCLE_0;
global g_NTT_ADJ;
global g_NTT_FLOAT_TIMES;

fprintf('\nCurrent configuration:\n');
fprintf('DRIFT MES           : %d\n', g_NTT_DRIFT_MES);
fprintf('PROF MES            : %d\n', g_NTT_ALL_MES_PROF);
fprintf('DISPLAY CYCLE #0    : %d\n', g_NTT_CYCLE_0);
if (g_NTT_ADJ == 0)
   comment = 'real time data only';
elseif  (g_NTT_ADJ == 1)
   comment = 'adjusted data only';
elseif  (g_NTT_ADJ == 2)
   comment = 'real time and adjusted data merged';
end
fprintf('USE ADJUSTED DATA   : %d, %s\n', g_NTT_ADJ, comment);
fprintf('DISPLAY FLOAT TIMES : %d\n', g_NTT_FLOAT_TIMES);

return;

% ------------------------------------------------------------------------------
% Callback used to update the X tick labels after a zoom
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
% ------------------------------------------------------------------------------
% RELEASES :
%   07/30/2014 - RNU - creation
% ------------------------------------------------------------------------------
function after_zoom(a_src, a_eventData)

% retrieve the time axis
timeAxes = subplot('Position', [0.044 0.085 0.63 0.85]);

if (a_eventData.Axes == timeAxes)
   % X ticks management
   xTick = get(a_eventData.Axes, 'XTick');
   referenceDate = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
   xTick = xTick + referenceDate;
   if (max(xTick) - min(xTick) > 2)
      xTickLabel = datestr(xTick, 'dd/mm/yyyy');
   else
      xTickLabel = datestr(xTick, 'dd/mm/yyyy HH:MM:SS');
   end
   [lig, col] = size(xTickLabel);
   xTickLabel(2:2:lig, :) = ' ';
   set(timeAxes, 'XTickLabel', xTickLabel);
end

return;
