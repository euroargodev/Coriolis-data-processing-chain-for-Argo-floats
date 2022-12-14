% ------------------------------------------------------------------------------
% Plot of cycle timings vs pressures.
%
% SYNTAX :
%   nc_trace_cycle_times or nc_trace_cycle_times(6900189, 7900118)
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
%   04/14/2017 - RNU - creation
% ------------------------------------------------------------------------------
function nc_trace_cycle_times(varargin)

% to switch between Coriolis and JPR configurations
CORIOLIS_CONFIGURATION_FLAG = 0;

global g_NTCT_NC_DIR;
global g_NTCT_NC_DIR_AUX;
global g_NTCT_PDF_DIR;

if (CORIOLIS_CONFIGURATION_FLAG)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % CORIOLIS CONFIGURATION - START

   % top directory of NetCDF files to plot (TRAJ and META)
   g_NTCT_NC_DIR = '/home/coriolis_exp/binlx/co04/co0414/co041402/data/nc/';

   % top directory of NetCDF auxiliary files to plot (TECH_AUX)
   g_NTCT_NC_DIR_AUX = '/home/coriolis_exp/binlx/co04/co0414/co041402/data/nc/';

   % directory to store pdf output
   g_NTCT_PDF_DIR = '/home/coriolis_exp/binlx/co04/co0414/co041402/data/pdf/';

   % default list of floats to plot
   FLOAT_LIST_FILE_NAME = '/home/idmtmp7/vincent/matlab/list/new_iridium.txt';
   % FLOAT_LIST_FILE_NAME = '/home/idmtmp7/vincent/matlab/list/new_rem.txt';

   % CORIOLIS CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % JPR CONFIGURATION - START

   % top directory of NetCDF files to plot (TRAJ and META)
   g_NTCT_NC_DIR = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

   % top directory of NetCDF auxiliary files to plot (TECH_AUX)
   g_NTCT_NC_DIR_AUX = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

   % directory to store pdf output
   g_NTCT_PDF_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\pdf\';

   % default list of floats to plot
   FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';
   FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\lists_20221013\list_decId_222_4.txt';

   % JPR CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

global g_NTCT_BATHY;
global g_NTCT_SURF;
global g_NTCT_PRINT;
global g_NTCT_FLOAT_LIST;
global g_NTCT_FIG_HANDLE;
global g_NTCT_FLOAT_ID;
global g_NTCT_PRES_DATA_MODE;

fprintf('Plot management:\n');
fprintf('   Right Arrow  : next float\n');
fprintf('   Left Arrow   : previous float\n');
fprintf('   Up/Down Arrow: previous/next cycle\n');
fprintf('   b            : bathy always visible\n');
fprintf('   s            : focus on surface data\n');
fprintf('   h            : write help and current configuration\n');
fprintf('   p            : pdf output file generation\n');
fprintf('   f            : pdf output file generation of all cycles\n');
fprintf('Escape: exit\n\n');

% bathy visible only if needed
g_NTCT_BATHY = 0;

% display all measurements
g_NTCT_SURF = 0;

% no pdf generation
g_NTCT_PRINT = 0;

% choose PRES data mode: 0 for merged PRES and PRES_ADJUSTED, 1 for PRES only
g_NTCT_PRES_DATA_MODE = 1;

% default values initialization
init_default_values;

close(findobj('Name', 'Cycle times'));
warning off;

% input parameters management
if (nargin == 0)
   % floats to process come from FLOAT_LIST_FILE_NAME
   floatListFileName = FLOAT_LIST_FILE_NAME;
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return
   end

   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = textread(FLOAT_LIST_FILE_NAME, '%d');
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

g_NTCT_FLOAT_LIST = floatList;
g_NTCT_FLOAT_ID = [];

% creation of the figure and its associated callback
screenSize = get(0, 'ScreenSize');
g_NTCT_FIG_HANDLE = figure('KeyPressFcn', @change_plot, ...
   'Name', 'Cycle times', ...
   'Position', [1 screenSize(4)*(1/3) screenSize(3) screenSize(4)*(2/3)-90]);

% callback to manage the plot after a zoom
zoomMode = zoom(g_NTCT_FIG_HANDLE);
set(zoomMode, 'ActionPostCallback', @after_zoom);

% callback to manage the data cursor label
dataCursorMode = datacursormode(g_NTCT_FIG_HANDLE);
set(dataCursorMode, 'UpdateFcn', @data_cursor_output)

% plot the first cycle of the first float
plot_cycle_times(0, 0, 0);

return

% ------------------------------------------------------------------------------
% Plot of cycle timings vs pressures.
%
% SYNTAX :
%  plot_cycle_times(a_idFloat, a_idCycle, a_reload)
%
% INPUT PARAMETERS :
%   a_idFloat : float Id in the list
%   a_idCycle : cycle Id in the list
%   a_reload  : reload nc data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/14/2017 - RNU - creation
% ------------------------------------------------------------------------------
function plot_cycle_times(a_idFloat, a_idCycle, a_reload)

global g_NTCT_NC_DIR;
global g_NTCT_NC_DIR_AUX;
global g_NTCT_PDF_DIR;
global g_NTCT_BATHY;
global g_NTCT_SURF;
global g_NTCT_PRINT;
global g_NTCT_FLOAT_LIST;
global g_NTCT_FIG_HANDLE;
global g_NTCT_FLOAT_ID;
global g_NTCT_PRES_DATA_MODE;

global g_NTCT_cycles;
global g_NTCT_cycle;

global g_NTCT_ParkPres;
global g_NTCT_ProfPres;
global g_NTCT_TolerancePres;

global g_NTCT_tabBathyJuld;
global g_NTCT_tabBathyMin;
global g_NTCT_tabBathyMax;

global g_NTCT_SpyInDescToPark_juld;
global g_NTCT_SpyInDescToPark_pres;
global g_NTCT_SpyInDescToPark_evFlag;
global g_NTCT_SpyAtPark_juld;
global g_NTCT_SpyAtPark_pres;
global g_NTCT_SpyAtPark_evFlag;
global g_NTCT_SpyInDescToProf_juld;
global g_NTCT_SpyInDescToProf_pres;
global g_NTCT_SpyInDescToProf_evFlag;
global g_NTCT_SpyAtProf_juld;
global g_NTCT_SpyAtProf_pres;
global g_NTCT_SpyAtProf_evFlag;
global g_NTCT_SpyInAscProf_juld;
global g_NTCT_SpyInAscProf_pres;
global g_NTCT_SpyInAscProf_evFlag;
global g_NTCT_SpyAtSurface_juld;
global g_NTCT_SpyAtSurface_pres;
global g_NTCT_SpyAtSurface_evFlag;

global g_NTCT_Surface1_juld;
global g_NTCT_Surface1_pres;
global g_NTCT_DescProf_juld;
global g_NTCT_DescProf_pres;
global g_NTCT_DriftAtPark1_juld;
global g_NTCT_DriftAtPark1_pres;
global g_NTCT_DriftAtPark_juld;
global g_NTCT_DriftAtPark_pres;
global g_NTCT_Desc2Prof1_juld;
global g_NTCT_Desc2Prof1_pres;
global g_NTCT_Desc2Prof2_juld;
global g_NTCT_Desc2Prof2_pres;
global g_NTCT_AscProf_juld;
global g_NTCT_AscProf_pres;
global g_NTCT_NearSurfaceSeriesOfMeas_juld;
global g_NTCT_NearSurfaceSeriesOfMeas_pres;
global g_NTCT_InAirSeriesOfMeas_juld;
global g_NTCT_InAirSeriesOfMeas_pres;
global g_NTCT_Surface_juld;
global g_NTCT_Surface2_juld;
global g_NTCT_Surface2_pres;
global g_NTCT_Grounded_flag_juld;
global g_NTCT_Grounded_flag_pres;

global g_NTCT_Launch_juld;
global g_NTCT_CycleStart_juld;
global g_NTCT_DST_juld;
global g_NTCT_FST_juld;
global g_NTCT_FST_pres;
global g_NTCT_PST_juld;
global g_NTCT_PET_juld;
global g_NTCT_MinPresInDriftAtPark_pres;
global g_NTCT_MaxPresInDriftAtPark_pres;
global g_NTCT_DPST_juld;
global g_NTCT_MinPresInDriftAtProf_pres;
global g_NTCT_MaxPresInDriftAtProf_pres;
global g_NTCT_AST_juld;
global g_NTCT_LastAscPumpedCtd_pres;
global g_NTCT_AET_juld;
global g_NTCT_TST_juld;
global g_NTCT_FMT_juld;
global g_NTCT_LMT_juld;
global g_NTCT_TET_juld;
global g_NTCT_Grounded_flag;

% default values initialization
init_valdef;

global g_dateDef;
global g_presDef;
global g_elevDef;

% measurement codes initialization
init_measurement_codes;

% global measurement codes
global g_MC_FillValue;
global g_MC_Launch;
global g_MC_CycleStart;
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
global g_MC_DriftAtParkStd;
global g_MC_DriftAtParkMeanOfDiff;
global g_MC_DriftAtParkMean;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_PET;
global g_MC_RPP;
global g_MC_SpyInDescToProf;
global g_MC_MaxPresInDescToProf;
global g_MC_DDET;
global g_MC_DPST;
global g_MC_SpyAtProf;
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
global g_MC_IceThermalDetectionTrue;
global g_MC_IceBreakupDetectionFlag;
global g_MC_IceAscentAbortNum;
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

global g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToDST;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToDST;
global g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST;
global g_MC_InAirSingleMeasRelativeToTST;
global g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSingleMeasRelativeToTET;


% plot the current float
figure(g_NTCT_FIG_HANDLE);
clf;

g_NTCT_cycle = a_idCycle;

if (isempty(g_NTCT_FLOAT_ID) || (a_idFloat ~= g_NTCT_FLOAT_ID) || (a_reload == 1))

   fprintf('Loading new float ... ');

   % a new float is wanted
   g_NTCT_FLOAT_ID = a_idFloat;
   g_NTCT_cycles = [];

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve and store the data of the new float

   % float number
   floatNum = g_NTCT_FLOAT_LIST(a_idFloat+1);

   if (exist([g_NTCT_NC_DIR '/' num2str(floatNum) '/'], 'dir') == 7)

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % from TRAJ file
      trajFileName = [g_NTCT_NC_DIR '/' num2str(floatNum) '/' num2str(floatNum) '_Rtraj.nc'];

      if ~(exist(trajFileName, 'file') == 2)
         fprintf('\n');
         fprintf('File not found: %s\n', trajFileName);
      end

      % retrieve information from TRAJ file
      wantedVars = [ ...
         {'FORMAT_VERSION'} ...
         {'JULD'} ...
         {'JULD_ADJUSTED'} ...
         {'PRES'} ...
         {'PRES_ADJUSTED'} ...
         {'CYCLE_NUMBER'} ...
         {'MEASUREMENT_CODE'} ...
         {'GROUNDED'} ...
         {'CONFIG_MISSION_NUMBER'} ...
         {'CYCLE_NUMBER_INDEX'} ...
         {'LATITUDE'} ...
         {'LONGITUDE'} ...
         ];
      [trajData] = get_data_from_nc_file(trajFileName, wantedVars);

      if (isempty(trajData))
         label = sprintf('%02d/%02d : %s no data', ...
            a_idFloat+1, ...
            length(g_NTCT_FLOAT_LIST), ...
            num2str(g_NTCT_FLOAT_LIST(a_idFloat+1)));
         title(label, 'FontSize', 14);
         fprintf('\n');
         return
      end

      idVal = find(strcmp('FORMAT_VERSION', trajData(1:2:end)) == 1, 1);
      formatVersion = strtrim(trajData{2*idVal}');

      % check the traj file format version
      if (~ismember(formatVersion, [{'3.1'} {'3.2'}]))
         fprintf('\n');
         fprintf('ERROR: Input traj file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s)\n', ...
            trajFileName, formatVersion);
         return
      end

      idVal = find(strcmp('CYCLE_NUMBER', trajData(1:2:end)) == 1, 1);
      cycleNumber = trajData{2*idVal};

      idVal = find(strcmp('MEASUREMENT_CODE', trajData(1:2:end)) == 1, 1);
      measCode = trajData{2*idVal};

      idVal = find(strcmp('JULD', trajData(1:2:end)) == 1, 1);
      juld = trajData{2*idVal};

      idVal = find(strcmp('JULD_ADJUSTED', trajData(1:2:end)) == 1, 1);
      juldAdj = trajData{2*idVal};

      idVal = find(strcmp('PRES', trajData(1:2:end)) == 1, 1);
      pres = double(trajData{2*idVal});

      idVal = find(strcmp('PRES_ADJUSTED', trajData(1:2:end)) == 1, 1);
      presAdj = double(trajData{2*idVal});

      idVal = find(strcmp('CYCLE_NUMBER_INDEX', trajData(1:2:end)) == 1, 1);
      cycleNumberIndex = trajData{2*idVal};

      idVal = find(strcmp('GROUNDED', trajData(1:2:end)) == 1, 1);
      grounded = trajData{2*idVal};

      idVal = find(strcmp('CONFIG_MISSION_NUMBER', trajData(1:2:end)) == 1, 1);
      configMissionNumberTraj = trajData{2*idVal};

      idVal = find(strcmp('LATITUDE', trajData(1:2:end)) == 1, 1);
      latitude = trajData{2*idVal};

      idVal = find(strcmp('LONGITUDE', trajData(1:2:end)) == 1, 1);
      longitude = trajData{2*idVal};

      % merge JULD and JULD_ADJUSTED
      idF = find(juldAdj ~= 999999);
      juld(idF) = juldAdj(idF);
      juld(juld == 999999) = g_dateDef;

      % merge PRES and PRES_ADJUSTED
      if (g_NTCT_PRES_DATA_MODE == 0)
         idF = find(presAdj ~= 99999);
         pres(idF) = presAdj(idF);
      end
      pres(pres == 99999) = g_presDef;

      % retrieve fixes
      idF = find((juld ~= g_dateDef) & (latitude ~= 99999) & (longitude ~= 99999));
      posJuld = juld(idF);
      posLat = latitude(idF);
      posLon = longitude(idF);

      % interpolate fixes along the displacements
      posPrecJuld = posJuld(1);
      posPrecLat = posLat(1);
      posPrecLon = posLon(1);
      posJuldAll = posPrecJuld;
      posLatAll = posPrecLat;
      posLonAll = posPrecLon;
      for idP = 2:length(posJuld)
         diffTime = posJuld(idP) - posPrecJuld;
         if (ceil(diffTime) > 1)
            times = [posPrecJuld:(diffTime/ceil(diffTime)):posJuld(idP)]';
            interpLocLat = interp1q([posPrecJuld; posJuld(idP)], [posPrecLat; posLat(idP)], times);
            interpLocLon = interp1q([posPrecJuld; posJuld(idP)], [posPrecLon; posLon(idP)], times);
            posJuldAll = [posJuldAll; times(2:end)];
            posLatAll = [posLatAll; interpLocLat(2:end)];
            posLonAll = [posLonAll; interpLocLon(2:end)];
         else
            posJuldAll = [posJuldAll; posJuld(idP)];
            posLatAll = [posLatAll; posLat(idP)];
            posLonAll = [posLonAll; posLon(idP)];
         end
         posPrecJuld = posJuld(idP);
         posPrecLat = posLat(idP);
         posPrecLon = posLon(idP);
      end

      % retrieve the bathymetry along the displacements
      g_NTCT_tabBathyJuld = posJuldAll;
      g_NTCT_tabBathyMin = ones(size(posJuldAll))*g_elevDef;
      g_NTCT_tabBathyMax = ones(size(posJuldAll))*-g_elevDef;

      for idP = 1:length(posJuldAll)
         [elev, lon, lat] = m_etopo2([posLonAll(idP) posLonAll(idP) posLatAll(idP) posLatAll(idP)]);
         g_NTCT_tabBathyMin(idP) = min(min(-elev));
         g_NTCT_tabBathyMax(idP) = max(max(-elev));
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % from TECH_AUX file
      techAuxFileName = [g_NTCT_NC_DIR_AUX '/' num2str(floatNum) '/auxiliary/' num2str(floatNum) '_tech_aux.nc'];

      valveAct = [];
      if ~(exist(techAuxFileName, 'file') == 2)
         fprintf('\n');
         fprintf('File not found: %s\n', techAuxFileName);
      else

         % retrieve information from TRAJ file
         wantedVars = [ ...
            {'JULD'} ...
            {'JULD_ADJUSTED'} ...
            {'VALVE_ACTION_DURATION'} ...
            {'VALVE_ACTION_FLAG'} ...
            {'PUMP_ACTION_DURATION'} ...
            {'PUMP_ACTION_FLAG'} ...
            {'CYCLE_NUMBER_MEAS'} ...
            {'MEASUREMENT_CODE'} ...
            ];
         [techAuxData] = get_data_from_nc_file(techAuxFileName, wantedVars);

         idVal = find(strcmp('CYCLE_NUMBER_MEAS', techAuxData(1:2:end)) == 1, 1);
         cycleNumberTech = techAuxData{2*idVal};

         idVal = find(strcmp('MEASUREMENT_CODE', techAuxData(1:2:end)) == 1, 1);
         measCodeTech = techAuxData{2*idVal};

         idVal = find(strcmp('JULD', techAuxData(1:2:end)) == 1, 1);
         juldTech = techAuxData{2*idVal};

         idVal = find(strcmp('JULD_ADJUSTED', techAuxData(1:2:end)) == 1, 1);
         juldTechAdj = techAuxData{2*idVal};

         idVal = find(strcmp('VALVE_ACTION_DURATION', techAuxData(1:2:end)) == 1, 1);
         valveActDuration = techAuxData{2*idVal};

         idVal = find(strcmp('VALVE_ACTION_FLAG', techAuxData(1:2:end)) == 1, 1);
         valveActFlag = techAuxData{2*idVal};

         idVal = find(strcmp('PUMP_ACTION_DURATION', techAuxData(1:2:end)) == 1, 1);
         pumpActDuration = techAuxData{2*idVal};

         idVal = find(strcmp('PUMP_ACTION_FLAG', techAuxData(1:2:end)) == 1, 1);
         pumpActFlag = techAuxData{2*idVal};

         % merge JULD and JULD_ADJUSTED
         idF = find(juldTechAdj ~= 999999);
         juldTech(idF) = juldTechAdj(idF);
         juldTech(find(juldTech == 999999)) = g_dateDef;

         % get valve information
         if (~isempty(valveActFlag))
            valveAct = valveActFlag;
         elseif (~isempty(pumpActFlag))
            valveAct = pumpActFlag;
            valveAct(find(valveAct == 1)) = -1;
         elseif (~isempty(valveActDuration))
            valveAct = valveActDuration;
         elseif (~isempty(pumpActDuration))
            valveAct = pumpActDuration;
            valveAct(find(valveAct ~= -1)) = -1;
         end
      end

      % process retrieved data

      % arrays to store the data
      g_NTCT_cycles = unique(cycleNumber(find(cycleNumber >= 0)));

      % buoyancy activitity
      idF = find(ismember(measCode, [239 g_MC_SpyInDescToPark g_MC_SpyAtPark g_MC_SpyInDescToProf g_MC_SpyAtProf g_MC_SpyInAscProf g_MC_SpyAtSurface])); % 239 = 250-11 for Apex
      nbMax = max(histc(cycleNumber(idF), min(cycleNumber(idF)):max(cycleNumber(idF))));

      g_NTCT_SpyInDescToPark_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_SpyInDescToPark_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_SpyInDescToPark_evFlag = ones(length(g_NTCT_cycles), nbMax)*-1;
      g_NTCT_SpyAtPark_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_SpyAtPark_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_SpyAtPark_evFlag = ones(length(g_NTCT_cycles), nbMax)*-1;
      g_NTCT_SpyInDescToProf_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_SpyInDescToProf_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_SpyInDescToProf_evFlag = ones(length(g_NTCT_cycles), nbMax)*-1;
      g_NTCT_SpyAtProf_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_SpyAtProf_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_SpyAtProf_evFlag = ones(length(g_NTCT_cycles), nbMax)*-1;
      g_NTCT_SpyInAscProf_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_SpyInAscProf_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_SpyInAscProf_evFlag = ones(length(g_NTCT_cycles), nbMax)*-1;
      g_NTCT_SpyAtSurface_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_SpyAtSurface_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_SpyAtSurface_evFlag = ones(length(g_NTCT_cycles), nbMax)*-1;

      if (~isempty(valveAct))
         for idC = 1:length(g_NTCT_cycles)
            idF = find((cycleNumber == g_NTCT_cycles(idC)) & ismember(measCode, [239 g_MC_SpyInDescToPark]));
            if (~isempty(idF))
               g_NTCT_SpyInDescToPark_juld(idC, 1:length(idF)) = juld(idF);
               g_NTCT_SpyInDescToPark_pres(idC, 1:length(idF)) = pres(idF);
               idF2 = find((cycleNumberTech == g_NTCT_cycles(idC)) & ismember(measCodeTech, [239 g_MC_SpyInDescToPark]));
               %             if ((length(idF) ~= length(idF2)) || any(abs(juld(idF) - juldTech(idF2)) > 1/86400))
               if (length(idF) ~= length(idF2))
                  fprintf('ERROR: Traj / Tech_aux consistency (nominal for APF11)\n');
               else
                  g_NTCT_SpyInDescToPark_evFlag(idC, 1:length(idF2)) = valveAct(idF2);
               end
            end
            idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_SpyAtPark));
            if (~isempty(idF))
               g_NTCT_SpyAtPark_juld(idC, 1:length(idF)) = juld(idF);
               g_NTCT_SpyAtPark_pres(idC, 1:length(idF)) = pres(idF);
               idF2 = find((cycleNumberTech == g_NTCT_cycles(idC)) & (measCodeTech == g_MC_SpyAtPark));
               %             if ((length(idF) ~= length(idF2)) || any(abs(juld(idF) - juldTech(idF2)) > 1/86400))
               if (length(idF) ~= length(idF2))
                  fprintf('ERROR: Traj / Tech_aux consistency (nominal for APF11)\n');
               else
                  g_NTCT_SpyAtPark_evFlag(idC, 1:length(idF2)) = valveAct(idF2);
               end
            end
            idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_SpyInDescToProf));
            if (~isempty(idF))
               g_NTCT_SpyInDescToProf_juld(idC, 1:length(idF)) = juld(idF);
               g_NTCT_SpyInDescToProf_pres(idC, 1:length(idF)) = pres(idF);
               idF2 = find((cycleNumberTech == g_NTCT_cycles(idC)) & (measCodeTech == g_MC_SpyInDescToProf));
               %             if ((length(idF) ~= length(idF2)) || any(abs(juld(idF) - juldTech(idF2)) > 1/86400))
               if (length(idF) ~= length(idF2))
                  fprintf('ERROR: Traj / Tech_aux consistency (nominal for APF11)\n');
               else
                  g_NTCT_SpyInDescToProf_evFlag(idC, 1:length(idF2)) = valveAct(idF2);
               end
            end
            idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_SpyAtProf));
            if (~isempty(idF))
               g_NTCT_SpyAtProf_juld(idC, 1:length(idF)) = juld(idF);
               g_NTCT_SpyAtProf_pres(idC, 1:length(idF)) = pres(idF);
               idF2 = find((cycleNumberTech == g_NTCT_cycles(idC)) & (measCodeTech == g_MC_SpyAtProf));
               %             if ((length(idF) ~= length(idF2)) || any(abs(juld(idF) - juldTech(idF2)) > 1/86400))
               if (length(idF) ~= length(idF2))
                  fprintf('ERROR: Traj / Tech_aux consistency (nominal for APF11)\n');
               else
                  g_NTCT_SpyAtProf_evFlag(idC, 1:length(idF2)) = valveAct(idF2);
               end
            end
            idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_SpyInAscProf));
            if (~isempty(idF))
               g_NTCT_SpyInAscProf_juld(idC, 1:length(idF)) = juld(idF);
               g_NTCT_SpyInAscProf_pres(idC, 1:length(idF)) = pres(idF);
               idF2 = find((cycleNumberTech == g_NTCT_cycles(idC)) & (measCodeTech == g_MC_SpyInAscProf));
               %             if ((length(idF) ~= length(idF2)) || any(abs(juld(idF) - juldTech(idF2)) > 1/86400))
               if (length(idF) ~= length(idF2))
                  fprintf('ERROR: Traj / Tech_aux consistency (nominal for APF11)\n');
               else
                  g_NTCT_SpyInAscProf_evFlag(idC, 1:length(idF2)) = valveAct(idF2);
               end
            end
            idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_SpyAtSurface));
            if (~isempty(idF))
               g_NTCT_SpyAtSurface_juld(idC, 1:length(idF)) = juld(idF);
               g_NTCT_SpyAtSurface_pres(idC, 1:length(idF)) = pres(idF);
               idF2 = find((cycleNumberTech == g_NTCT_cycles(idC)) & (measCodeTech == g_MC_SpyAtSurface));
               %             if ((length(idF) ~= length(idF2)) || any(abs(juld(idF) - juldTech(idF2)) > 1/86400))
               if (length(idF) ~= length(idF2))
                  fprintf('ERROR: Traj / Tech_aux consistency (nominal for APF11)\n');
               else
                  g_NTCT_SpyAtSurface_evFlag(idC, 1:length(idF2)) = valveAct(idF2);
               end
            end
         end
      end

      % series of measurements
      %    idF = find(ismember(measCode, [g_MC_DescProf g_MC_DriftAtPark g_MC_AscProf ...
      %       g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
      %       g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
      %       g_MC_Surface g_MC_Grounded]));

      idF = find(ismember(measCode, [ ...
         g_MC_DST-10 ...
         g_MC_DescProf ...
         g_MC_PST-10 ...
         g_MC_DriftAtPark ...
         g_MC_DDET-10 ...
         g_MC_AST-10 ...
         g_MC_AscProf ...
         g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST ...
         g_MC_InAirSingleMeasRelativeToTST ...
         g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
         g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
         g_MC_InAirSingleMeasRelativeToTET ...
         g_MC_Surface ...
         g_MC_TET-10 ...
         g_MC_Grounded ...
         ]));

      nbMax = max(histc(cycleNumber(idF), min(cycleNumber(idF)):max(cycleNumber(idF))));

      g_NTCT_Surface1_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_Surface1_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_DescProf_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_DescProf_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_DriftAtPark1_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_DriftAtPark1_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_DriftAtPark_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_DriftAtPark_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_Desc2Prof1_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_Desc2Prof1_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_Desc2Prof2_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_Desc2Prof2_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_AscProf_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_AscProf_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_NearSurfaceSeriesOfMeas_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_NearSurfaceSeriesOfMeas_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_InAirSeriesOfMeas_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_InAirSeriesOfMeas_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_Surface_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_Surface2_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_Surface2_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;
      g_NTCT_Grounded_flag_juld = ones(length(g_NTCT_cycles), nbMax)*g_dateDef;
      g_NTCT_Grounded_flag_pres = ones(length(g_NTCT_cycles), nbMax)*g_presDef;

      for idC = 1:length(g_NTCT_cycles)
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_DST-10));
         if (~isempty(idF))
            g_NTCT_Surface1_juld(idC, 1:length(idF)) = juld(idF);
            g_NTCT_Surface1_pres(idC, 1:length(idF)) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_DescProf));
         if (~isempty(idF))
            g_NTCT_DescProf_juld(idC, 1:length(idF)) = juld(idF);
            g_NTCT_DescProf_pres(idC, 1:length(idF)) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_PST-10));
         if (~isempty(idF))
            g_NTCT_DriftAtPark1_juld(idC, 1:length(idF)) = juld(idF);
            g_NTCT_DriftAtPark1_pres(idC, 1:length(idF)) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_DriftAtPark));
         if (~isempty(idF))
            g_NTCT_DriftAtPark_juld(idC, 1:length(idF)) = juld(idF);
            g_NTCT_DriftAtPark_pres(idC, 1:length(idF)) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_DDET-10));
         if (~isempty(idF))
            g_NTCT_Desc2Prof1_juld(idC, 1:length(idF)) = juld(idF);
            g_NTCT_Desc2Prof1_pres(idC, 1:length(idF)) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_AST-10));
         if (~isempty(idF))
            g_NTCT_Desc2Prof2_juld(idC, 1:length(idF)) = juld(idF);
            g_NTCT_Desc2Prof2_pres(idC, 1:length(idF)) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_AscProf));
         if (~isempty(idF))
            g_NTCT_AscProf_juld(idC, 1:length(idF)) = juld(idF);
            g_NTCT_AscProf_pres(idC, 1:length(idF)) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & ...
            ((measCode == g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) | ...
            (measCode == g_MC_InAirSingleMeasRelativeToTST) | ...
            (measCode == g_MC_InAirSingleMeasRelativeToTET)));
         if (~isempty(idF))
            g_NTCT_InAirSeriesOfMeas_juld(idC, 1:length(idF)) = juld(idF);
            g_NTCT_InAirSeriesOfMeas_pres(idC, 1:length(idF)) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & ...
            ((measCode == g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST) | ...
            (measCode == g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST)));
         if (~isempty(idF))
            g_NTCT_NearSurfaceSeriesOfMeas_juld(idC, 1:length(idF)) = juld(idF);
            g_NTCT_NearSurfaceSeriesOfMeas_pres(idC, 1:length(idF)) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_Surface));
         if (~isempty(idF))
            g_NTCT_Surface_juld(idC, 1:length(idF)) = juld(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_TET-10));
         if (~isempty(idF))
            g_NTCT_Surface2_juld(idC, 1:length(idF)) = juld(idF);
            g_NTCT_Surface2_pres(idC, 1:length(idF)) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_Grounded));
         if (~isempty(idF))
            g_NTCT_Grounded_flag_juld(idC, 1:length(idF)) = juld(idF);
            g_NTCT_Grounded_flag_pres(idC, 1:length(idF)) = pres(idF);
         end
      end

      % launch date
      g_NTCT_Launch_juld = g_dateDef;
      idF = find(measCode == g_MC_Launch);
      if (~isempty(idF))
         g_NTCT_Launch_juld = juld(idF);
      end

      % cycle timings
      g_NTCT_CycleStart_juld = ones(length(g_NTCT_cycles), 1)*g_dateDef;
      g_NTCT_DST_juld = ones(length(g_NTCT_cycles), 1)*g_dateDef;
      g_NTCT_FST_juld = ones(length(g_NTCT_cycles), 1)*g_dateDef;
      g_NTCT_FST_pres = ones(length(g_NTCT_cycles), 1)*g_presDef;
      g_NTCT_PST_juld = ones(length(g_NTCT_cycles), 1)*g_dateDef;
      g_NTCT_PET_juld = ones(length(g_NTCT_cycles), 1)*g_dateDef;
      g_NTCT_MinPresInDriftAtPark_pres = ones(length(g_NTCT_cycles), 1)*g_presDef;
      g_NTCT_MaxPresInDriftAtPark_pres = ones(length(g_NTCT_cycles), 1)*g_presDef;
      g_NTCT_DPST_juld = ones(length(g_NTCT_cycles), 1)*g_dateDef;
      g_NTCT_MinPresInDriftAtProf_pres = ones(length(g_NTCT_cycles), 1)*g_presDef;
      g_NTCT_MaxPresInDriftAtProf_pres = ones(length(g_NTCT_cycles), 1)*g_presDef;
      g_NTCT_AST_juld = ones(length(g_NTCT_cycles), 1)*g_dateDef;
      g_NTCT_LastAscPumpedCtd_pres = ones(length(g_NTCT_cycles), 1)*g_presDef;
      g_NTCT_AET_juld = ones(length(g_NTCT_cycles), 1)*g_dateDef;
      g_NTCT_TST_juld = ones(length(g_NTCT_cycles), 1)*g_dateDef;
      g_NTCT_FMT_juld = ones(length(g_NTCT_cycles), 1)*g_dateDef;
      g_NTCT_LMT_juld = ones(length(g_NTCT_cycles), 1)*g_dateDef;
      g_NTCT_TET_juld = ones(length(g_NTCT_cycles), 1)*g_dateDef;
      g_NTCT_Grounded_flag = zeros(length(g_NTCT_cycles), 1);

      for idC = 1:length(g_NTCT_cycles)
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_CycleStart));
         if (~isempty(idF))
            g_NTCT_CycleStart_juld(idC) = juld(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_DST));
         if (~isempty(idF))
            g_NTCT_DST_juld(idC) = juld(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_FST));
         if (~isempty(idF))
            g_NTCT_FST_juld(idC) = juld(idF);
            g_NTCT_FST_pres(idC) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_PST));
         if (~isempty(idF))
            g_NTCT_PST_juld(idC) = juld(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_PET));
         if (~isempty(idF))
            g_NTCT_PET_juld(idC) = juld(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_MinPresInDriftAtPark));
         if (~isempty(idF))
            g_NTCT_MinPresInDriftAtPark_pres(idC) = min(pres(idF));
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_MaxPresInDriftAtPark));
         if (~isempty(idF))
            g_NTCT_MaxPresInDriftAtPark_pres(idC) = max(pres(idF));
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_DPST));
         if (~isempty(idF))
            g_NTCT_DPST_juld(idC) = juld(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_MinPresInDriftAtProf));
         if (~isempty(idF))
            g_NTCT_MinPresInDriftAtProf_pres(idC) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_MaxPresInDriftAtProf));
         if (~isempty(idF))
            g_NTCT_MaxPresInDriftAtProf_pres(idC) = pres(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_AST));
         if (~isempty(idF))
            g_NTCT_AST_juld(idC) = juld(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_LastAscPumpedCtd));
         if (~isempty(idF))
            g_NTCT_LastAscPumpedCtd_pres(idC) = pres(idF(1));
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_AET));
         if (~isempty(idF))
            g_NTCT_AET_juld(idC) = juld(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_TST));
         if (~isempty(idF))
            g_NTCT_TST_juld(idC) = juld(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_FMT));
         if (~isempty(idF))
            if (length(idF) > 1)
               idF = idF(1)
            end
            g_NTCT_FMT_juld(idC) = juld(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_LMT));
         if (~isempty(idF))
            if (length(idF) > 1)
               idF = idF(1)
            end
            g_NTCT_LMT_juld(idC) = juld(idF);
         end
         idF = find((cycleNumber == g_NTCT_cycles(idC)) & (measCode == g_MC_TET));
         if (~isempty(idF))
            g_NTCT_TET_juld(idC) = juld(idF);
         end
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % from META file
      metaFileName = [g_NTCT_NC_DIR '/' num2str(floatNum) '/' num2str(floatNum) '_meta.nc'];

      if ~(exist(metaFileName, 'file') == 2)
         fprintf('\n');
         fprintf('File not found: %s\n', metaFileName);
      end

      % retrieve information from META file
      wantedVars = [ ...
         {'FORMAT_VERSION'} ...
         {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
         {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
         {'CONFIG_PARAMETER_NAME'} ...
         {'CONFIG_PARAMETER_VALUE'} ...
         {'CONFIG_MISSION_NUMBER'} ...
         ];
      [metaData] = get_data_from_nc_file(metaFileName, wantedVars);

      idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)) == 1, 1);
      metaFileFormatVersion = strtrim(metaData{2*idVal}');

      % check the meta file format version
      if (~strcmp(metaFileFormatVersion, '3.1'))
         fprintf('\n');
         fprintf('ERROR: Input meta file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s)\n', ...
            metaFileName, metaFileFormatVersion);
         return
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

      idVal = find(strcmp('CONFIG_MISSION_NUMBER', metaData(1:2:end)) == 1, 1);
      configMissionNumberMeta = metaData{2*idVal}';

      % process retrieved data
      parkP = g_presDef;
      idF = find(strcmp('CONFIG_ParkPressure_dbar', launchConfigName(:)) == 1, 1);
      if (~isempty(idF) && (launchConfigValue(idF) ~= 99999))
         parkP = launchConfigValue(idF);
      end
      parkPres = ones(size(configMissionNumberMeta))*parkP;
      idF = find(strcmp('CONFIG_ParkPressure_dbar', configName(:)) == 1, 1);
      if (~isempty(idF))
         parkPres = configValue(idF, :);
      end

      profP = g_presDef;
      idF = find(strcmp('CONFIG_ProfilePressure_dbar', launchConfigName(:)) == 1, 1);
      if (~isempty(idF) && (launchConfigValue(idF) ~= 99999))
         profP = launchConfigValue(idF);
      end
      profPres = ones(size(configMissionNumberMeta))*profP;
      idF = find(strcmp('CONFIG_ProfilePressure_dbar', configName(:)) == 1, 1);
      if (~isempty(idF))
         profPres = configValue(idF, :);
      end

      toleranceP = g_presDef;
      idF = find(strcmp('CONFIG_PressureTargetToleranceDuringDrift_dbar', launchConfigName(:)) == 1, 1);
      if (~isempty(idF) && (launchConfigValue(idF) ~= 99999))
         toleranceP = launchConfigValue(idF);
      end
      tolerancePres = ones(size(configMissionNumberMeta))*toleranceP;
      idF = find(strcmp('CONFIG_PressureTargetToleranceDuringDrift_dbar', configName(:)) == 1, 1);
      if (~isempty(idF))
         tolerancePres = configValue(idF, :);
      end

      % process retrieved data

      g_NTCT_ParkPres = ones(length(g_NTCT_cycles), 1)*g_presDef;
      g_NTCT_ProfPres = ones(length(g_NTCT_cycles), 1)*g_presDef;
      g_NTCT_TolerancePres = ones(length(g_NTCT_cycles), 1)*g_presDef;

      for idC = 1:length(g_NTCT_cycles)
         idF = find(cycleNumberIndex == g_NTCT_cycles(idC));
         if (~isempty(idF))
            confMisNum = configMissionNumberTraj(idF);
            if (confMisNum ~= 99999)
               idF2 = find((configMissionNumberMeta == confMisNum));
               if (~isempty(idF2) && (parkPres(idF2) ~= 99999))
                  g_NTCT_ParkPres(idC, 1) = parkPres(idF2);
                  g_NTCT_ProfPres(idC, 1) = profPres(idF2);
                  g_NTCT_TolerancePres(idC, 1) = tolerancePres(idF2);
               else
                  fprintf('ERROR: Configuration number\n');
               end
            end
            if (grounded(idF) == 'Y')
               g_NTCT_Grounded_flag(idC) = 1;
            end
         end
      end

      fprintf('done\n');

   else

      fprintf('ERROR: Float #%d: Directory not found (%s)\n', ...
         floatNum, [g_NTCT_NC_DIR '/' num2str(floatNum) '/']);
   end
end

if (isempty(g_NTCT_cycles))
   label = sprintf('%02d/%02d : %s no data', ...
      a_idFloat+1, ...
      length(g_NTCT_FLOAT_LIST), ...
      num2str(g_NTCT_FLOAT_LIST(a_idFloat+1)));
   title(label, 'FontSize', 14);
   return
end

presAxes = subplot(1, 1, 1);
timeData = [
   g_NTCT_SpyInDescToPark_juld(a_idCycle+1, :), ...
   g_NTCT_SpyAtPark_juld(a_idCycle+1, :), ...
   g_NTCT_SpyInDescToProf_juld(a_idCycle+1, :), ...
   g_NTCT_SpyAtProf_juld(a_idCycle+1, :), ...
   g_NTCT_SpyInAscProf_juld(a_idCycle+1, :), ...
   g_NTCT_SpyAtSurface_juld(a_idCycle+1, :), ...
   g_NTCT_Surface1_juld(a_idCycle+1, :), ...
   g_NTCT_DescProf_juld(a_idCycle+1, :), ...
   g_NTCT_DriftAtPark1_juld(a_idCycle+1, :), ...
   g_NTCT_DriftAtPark_juld(a_idCycle+1, :), ...
   g_NTCT_Desc2Prof1_juld(a_idCycle+1, :), ...
   g_NTCT_Desc2Prof2_juld(a_idCycle+1, :), ...
   g_NTCT_AscProf_juld(a_idCycle+1, :), ...
   g_NTCT_NearSurfaceSeriesOfMeas_juld(a_idCycle+1, :), ...
   g_NTCT_InAirSeriesOfMeas_juld(a_idCycle+1, :), ...
   g_NTCT_Surface_juld(a_idCycle+1, :), ...
   g_NTCT_Surface2_juld(a_idCycle+1, :), ...
   g_NTCT_Grounded_flag_juld(a_idCycle+1, :), ...
   g_NTCT_CycleStart_juld(a_idCycle+1, :), ...
   g_NTCT_DST_juld(a_idCycle+1, :), ...
   g_NTCT_FST_juld(a_idCycle+1, :), ...
   g_NTCT_PST_juld(a_idCycle+1, :), ...
   g_NTCT_PET_juld(a_idCycle+1, :), ...
   g_NTCT_DPST_juld(a_idCycle+1, :), ...
   g_NTCT_AST_juld(a_idCycle+1, :), ...
   g_NTCT_AET_juld(a_idCycle+1, :), ...
   g_NTCT_TST_juld(a_idCycle+1, :), ...
   g_NTCT_FMT_juld(a_idCycle+1, :), ...
   g_NTCT_LMT_juld(a_idCycle+1, :), ...
   g_NTCT_TET_juld(a_idCycle+1, :) ...
   ];

presData = [ 0, ...
   g_NTCT_ParkPres(a_idCycle+1), ...
   g_NTCT_ProfPres(a_idCycle+1), ...
   g_NTCT_SpyInDescToPark_pres(a_idCycle+1, :), ...
   g_NTCT_SpyAtPark_pres(a_idCycle+1, :), ...
   g_NTCT_SpyInDescToProf_pres(a_idCycle+1, :), ...
   g_NTCT_SpyAtProf_pres(a_idCycle+1, :), ...
   g_NTCT_SpyInAscProf_pres(a_idCycle+1, :), ...
   g_NTCT_SpyAtSurface_pres(a_idCycle+1, :), ...
   g_NTCT_Surface1_pres(a_idCycle+1, :), ...
   g_NTCT_DescProf_pres(a_idCycle+1, :), ...
   g_NTCT_DriftAtPark1_pres(a_idCycle+1, :), ...
   g_NTCT_DriftAtPark_pres(a_idCycle+1, :), ...
   g_NTCT_Desc2Prof1_pres(a_idCycle+1, :), ...
   g_NTCT_Desc2Prof2_pres(a_idCycle+1, :), ...
   g_NTCT_AscProf_pres(a_idCycle+1, :), ...
   g_NTCT_NearSurfaceSeriesOfMeas_pres(a_idCycle+1, :), ...
   g_NTCT_InAirSeriesOfMeas_pres(a_idCycle+1, :), ...
   g_NTCT_Surface2_pres(a_idCycle+1, :), ...
   g_NTCT_Grounded_flag_pres(a_idCycle+1, :), ...
   g_NTCT_FST_pres(a_idCycle+1, :), ...
   g_NTCT_MinPresInDriftAtPark_pres(a_idCycle+1, :), ...
   g_NTCT_MaxPresInDriftAtPark_pres(a_idCycle+1, :), ...
   g_NTCT_MinPresInDriftAtProf_pres(a_idCycle+1, :), ...
   g_NTCT_MaxPresInDriftAtProf_pres(a_idCycle+1, :), ...
   g_NTCT_LastAscPumpedCtd_pres(a_idCycle+1, :) ...
   ];

if (g_NTCT_cycles(a_idCycle+1) == 0)
   xLaunch = g_NTCT_Launch_juld;
   xLaunch(find(xLaunch == g_dateDef)) = [];
   yLaunch = zeros(size(xLaunch));
   if (~isempty(xLaunch))
      plot(presAxes, xLaunch, yLaunch, 'ch', 'MarkerFaceColor', 'c', 'MarkerSize', 10);
      hold on;
      timeData = [timeData xLaunch];
   end
end

xSurface1 = g_NTCT_Surface1_juld(a_idCycle+1, :);
ySurface1 = g_NTCT_Surface1_pres(a_idCycle+1, :);
idDel = find((xSurface1 == g_dateDef) | (ySurface1 == g_presDef));
xSurface1(idDel) = [];
ySurface1(idDel) = [];
if (~isempty(xSurface1))
   plot(presAxes, xSurface1, ySurface1, 'go-', 'MarkerFaceColor', 'g', 'MarkerSize', 3);
   hold on;
end

xDescProf = g_NTCT_DescProf_juld(a_idCycle+1, :);
yDescProf = g_NTCT_DescProf_pres(a_idCycle+1, :);
idDel = find((xDescProf == g_dateDef) | (yDescProf == g_presDef));
xDescProf(idDel) = [];
yDescProf(idDel) = [];
if (~isempty(xDescProf))
   plot(presAxes, xDescProf, yDescProf, 'go-', 'MarkerFaceColor', 'g', 'MarkerSize', 3);
   hold on;
end

xDriftAtPark1 = g_NTCT_DriftAtPark1_juld(a_idCycle+1, :);
yDriftAtPark1 = g_NTCT_DriftAtPark1_pres(a_idCycle+1, :);
idDel = find((xDriftAtPark1 == g_dateDef) | (yDriftAtPark1 == g_presDef));
xDriftAtPark1(idDel) = [];
yDriftAtPark1(idDel) = [];
if (~isempty(xDriftAtPark1))
   plot(presAxes, xDriftAtPark1, yDriftAtPark1, 'go-', 'MarkerFaceColor', 'g', 'MarkerSize', 3);
   hold on;
end

xDriftAtPark = g_NTCT_DriftAtPark_juld(a_idCycle+1, :);
yDriftAtPark = g_NTCT_DriftAtPark_pres(a_idCycle+1, :);
idDel = find((xDriftAtPark == g_dateDef) | (yDriftAtPark == g_presDef));
xDriftAtPark(idDel) = [];
yDriftAtPark(idDel) = [];
if (~isempty(xDriftAtPark))
   plot(presAxes, xDriftAtPark, yDriftAtPark, 'go-', 'MarkerFaceColor', 'g', 'MarkerSize', 3);
   hold on;
end

xDesc2Prof1 = g_NTCT_Desc2Prof1_juld(a_idCycle+1, :);
yDesc2Prof1 = g_NTCT_Desc2Prof1_pres(a_idCycle+1, :);
idDel = find((xDesc2Prof1 == g_dateDef) | (yDesc2Prof1 == g_presDef));
xDesc2Prof1(idDel) = [];
yDesc2Prof1(idDel) = [];
if (~isempty(xDesc2Prof1))
   plot(presAxes, xDesc2Prof1, yDesc2Prof1, 'go-', 'MarkerFaceColor', 'g', 'MarkerSize', 3);
   hold on;
end

xDesc2Prof2 = g_NTCT_Desc2Prof2_juld(a_idCycle+1, :);
yDesc2Prof2 = g_NTCT_Desc2Prof2_pres(a_idCycle+1, :);
idDel = find((xDesc2Prof2 == g_dateDef) | (yDesc2Prof2 == g_presDef));
xDesc2Prof2(idDel) = [];
yDesc2Prof2(idDel) = [];
if (~isempty(xDesc2Prof2))
   plot(presAxes, xDesc2Prof2, yDesc2Prof2, 'go-', 'MarkerFaceColor', 'g', 'MarkerSize', 3);
   hold on;
end

xAscProf = g_NTCT_AscProf_juld(a_idCycle+1, :);
yAscProf = g_NTCT_AscProf_pres(a_idCycle+1, :);
idDel = find((xAscProf == g_dateDef) | (yAscProf == g_presDef));
xAscProf(idDel) = [];
yAscProf(idDel) = [];
if (~isempty(xAscProf))
   plot(presAxes, xAscProf, yAscProf, 'go-', 'MarkerFaceColor', 'g', 'MarkerSize', 3);
   hold on;
end

xNearSurfaceSeriesOfMeas = g_NTCT_NearSurfaceSeriesOfMeas_juld(a_idCycle+1, :);
yNearSurfaceSeriesOfMeas = g_NTCT_NearSurfaceSeriesOfMeas_pres(a_idCycle+1, :);
idDel = find((xNearSurfaceSeriesOfMeas == g_dateDef) | (yNearSurfaceSeriesOfMeas == g_presDef));
xNearSurfaceSeriesOfMeas(idDel) = [];
yNearSurfaceSeriesOfMeas(idDel) = [];
if (~isempty(xNearSurfaceSeriesOfMeas))
   plot(presAxes, xNearSurfaceSeriesOfMeas, yNearSurfaceSeriesOfMeas, 'gs-', 'MarkerFaceColor', 'g', 'MarkerSize', 4);
   hold on;
end

xInAirSeriesOfMeas = g_NTCT_InAirSeriesOfMeas_juld(a_idCycle+1, :);
yInAirSeriesOfMeas = g_NTCT_InAirSeriesOfMeas_pres(a_idCycle+1, :);
idDel = find((xInAirSeriesOfMeas == g_dateDef) | (yInAirSeriesOfMeas == g_presDef));
xInAirSeriesOfMeas(idDel) = [];
yInAirSeriesOfMeas(idDel) = [];
if (~isempty(xInAirSeriesOfMeas))
   plot(presAxes, xInAirSeriesOfMeas, yInAirSeriesOfMeas, 'gs-', 'MarkerFaceColor', 'g', 'MarkerSize', 4);
   hold on;
end

xSpyInDescToPark = g_NTCT_SpyInDescToPark_juld(a_idCycle+1, :);
ySpyInDescToPark = g_NTCT_SpyInDescToPark_pres(a_idCycle+1, :);
idDel = find((xSpyInDescToPark == g_dateDef) | (ySpyInDescToPark == g_presDef));
xSpyInDescToPark(idDel) = [];
ySpyInDescToPark(idDel) = [];
if (~isempty(xSpyInDescToPark))
   plot(presAxes, xSpyInDescToPark, ySpyInDescToPark, 'k');
   hold on;

   evSpyInDescToPark = g_NTCT_SpyInDescToPark_evFlag(a_idCycle+1, 1:length(xSpyInDescToPark));
   idEv = find(evSpyInDescToPark > 0);
   plot(presAxes, xSpyInDescToPark(idEv), ySpyInDescToPark(idEv), 'bv', 'MarkerFaceColor', 'b', 'MarkerSize', 5);
   idPump = find(evSpyInDescToPark == -1);
   plot(presAxes, xSpyInDescToPark(idPump), ySpyInDescToPark(idPump), 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 5);
end

xSpyAtPark = g_NTCT_SpyAtPark_juld(a_idCycle+1, :);
ySpyAtPark = g_NTCT_SpyAtPark_pres(a_idCycle+1, :);
idDel = find((xSpyAtPark == g_dateDef) | (ySpyAtPark == g_presDef));
xSpyAtPark(idDel) = [];
ySpyAtPark(idDel) = [];
if (~isempty(xSpyAtPark))
   plot(presAxes, xSpyAtPark, ySpyAtPark, 'k');
   hold on;

   evSpyAtPark = g_NTCT_SpyAtPark_evFlag(a_idCycle+1, 1:length(xSpyAtPark));
   idEv = find(evSpyAtPark > 0);
   plot(presAxes, xSpyAtPark(idEv), ySpyAtPark(idEv), 'bv', 'MarkerFaceColor', 'b', 'MarkerSize', 5);
   idPump = find(evSpyAtPark == -1);
   plot(presAxes, xSpyAtPark(idPump), ySpyAtPark(idPump), 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 5);
end

xSpyInDescToProf = g_NTCT_SpyInDescToProf_juld(a_idCycle+1, :);
ySpyInDescToProf = g_NTCT_SpyInDescToProf_pres(a_idCycle+1, :);
idDel = find((xSpyInDescToProf == g_dateDef) | (ySpyInDescToProf == g_presDef));
xSpyInDescToProf(idDel) = [];
ySpyInDescToProf(idDel) = [];
if (~isempty(xSpyInDescToProf))
   plot(presAxes, xSpyInDescToProf, ySpyInDescToProf, 'k');
   hold on;

   evSpyInDescToProf = g_NTCT_SpyInDescToProf_evFlag(a_idCycle+1, 1:length(xSpyInDescToProf));
   idEv = find(evSpyInDescToProf > 0);
   plot(presAxes, xSpyInDescToProf(idEv), ySpyInDescToProf(idEv), 'bv', 'MarkerFaceColor', 'b', 'MarkerSize', 5);
   idPump = find(evSpyInDescToProf == -1);
   plot(presAxes, xSpyInDescToProf(idPump), ySpyInDescToProf(idPump), 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 5);
end

xSpyAtProf = g_NTCT_SpyAtProf_juld(a_idCycle+1, :);
ySpyAtProf = g_NTCT_SpyAtProf_pres(a_idCycle+1, :);
idDel = find((xSpyAtProf == g_dateDef) | (ySpyAtProf == g_presDef));
xSpyAtProf(idDel) = [];
ySpyAtProf(idDel) = [];
if (~isempty(xSpyAtProf))
   plot(presAxes, xSpyAtProf, ySpyAtProf, 'k');
   hold on;

   evSpyAtProf = g_NTCT_SpyAtProf_evFlag(a_idCycle+1, 1:length(xSpyAtProf));
   idEv = find(evSpyAtProf > 0);
   plot(presAxes, xSpyAtProf(idEv), ySpyAtProf(idEv), 'bv', 'MarkerFaceColor', 'b', 'MarkerSize', 5);
   idPump = find(evSpyAtProf == -1);
   plot(presAxes, xSpyAtProf(idPump), ySpyAtProf(idPump), 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 5);
end

xSpyInAscProf = g_NTCT_SpyInAscProf_juld(a_idCycle+1, :);
ySpyInAscProf = g_NTCT_SpyInAscProf_pres(a_idCycle+1, :);
idDel = find((xSpyInAscProf == g_dateDef) | (ySpyInAscProf == g_presDef));
xSpyInAscProf(idDel) = [];
ySpyInAscProf(idDel) = [];
firstSurfDate = g_dateDef;
firstSurfPres = g_presDef;
if (~isempty(xSpyInAscProf))
   plot(presAxes, xSpyInAscProf, ySpyInAscProf, 'k');
   hold on;

   evSpyInAscProf = g_NTCT_SpyInAscProf_evFlag(a_idCycle+1, 1:length(xSpyInAscProf));
   idEv = find(evSpyInAscProf > 0);
   plot(presAxes, xSpyInAscProf(idEv), ySpyInAscProf(idEv), 'bv', 'MarkerFaceColor', 'b', 'MarkerSize', 5);
   idPump = find(evSpyInAscProf == -1);
   plot(presAxes, xSpyInAscProf(idPump), ySpyInAscProf(idPump), 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 5);

   firstSurfDate = fliplr(xSpyInAscProf);
   firstSurfPres = fliplr(ySpyInAscProf);
   if (length(firstSurfDate) > 2)
      firstSurfDate = firstSurfDate(3);
      firstSurfPres = firstSurfPres(3);
   end
end

xSpyAtSurface = g_NTCT_SpyAtSurface_juld(a_idCycle+1, :);
ySpyAtSurface = g_NTCT_SpyAtSurface_pres(a_idCycle+1, :);
idDel = find((xSpyAtSurface == g_dateDef) | (ySpyAtSurface == g_presDef));
xSpyAtSurface(idDel) = [];
ySpyAtSurface(idDel) = [];
firstSurfDate = g_dateDef;
firstSurfPres = g_presDef;
if (~isempty(xSpyAtSurface))
   plot(presAxes, xSpyAtSurface, ySpyAtSurface, 'k');
   hold on;

   evSpyAtSurface = g_NTCT_SpyAtSurface_evFlag(a_idCycle+1, 1:length(xSpyAtSurface));
   idEv = find(evSpyAtSurface > 0);
   plot(presAxes, xSpyAtSurface(idEv), ySpyAtSurface(idEv), 'bv', 'MarkerFaceColor', 'b', 'MarkerSize', 5);
   idPump = find(evSpyAtSurface == -1);
   plot(presAxes, xSpyAtSurface(idPump), ySpyAtSurface(idPump), 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 5);

   firstSurfDate = fliplr(xSpyAtSurface);
   firstSurfPres = fliplr(ySpyAtSurface);
   if (length(firstSurfDate) > 2)
      firstSurfDate = firstSurfDate(3);
      firstSurfPres = firstSurfPres(3);
   end
end

xSurface = g_NTCT_Surface_juld(a_idCycle+1, :);
xSurface(find(xSurface == g_dateDef)) = [];
ySurface = zeros(size(xSurface));
if (~isempty(xSurface))
   plot(presAxes, xSurface, ySurface, 'cp', 'MarkerFaceColor', 'c', 'MarkerSize', 10);
   hold on;
end

xTST = g_NTCT_TST_juld(a_idCycle+1, :);
xTST(find(xTST == g_dateDef)) = [];
yTST = zeros(size(xTST));
if (~isempty(xTST))
   plot(presAxes, xTST, yTST, 'm^', 'MarkerFaceColor', 'm');
   hold on;
end

xFMT = g_NTCT_FMT_juld(a_idCycle+1, :);
xFMT(find(xFMT == g_dateDef)) = [];
yFMT = zeros(size(xFMT));
if (~isempty(xFMT))
   plot(presAxes, xFMT, yFMT, 'm>', 'MarkerFaceColor', 'm');
   hold on;
end

xLMT = g_NTCT_LMT_juld(a_idCycle+1, :);
xLMT(find(xLMT == g_dateDef)) = [];
yLMT = zeros(size(xLMT));
if (~isempty(xLMT))
   plot(presAxes, xLMT, yLMT, 'm<', 'MarkerFaceColor', 'm');
   hold on;
end

xTET = g_NTCT_TET_juld(a_idCycle+1, :);
xTET(find(xTET == g_dateDef)) = [];
yTET = zeros(size(xTET));
if (~isempty(xTET))
   plot(presAxes, xTET, yTET, 'mv', 'MarkerFaceColor', 'm');
   hold on;
end

xSurface2 = g_NTCT_Surface2_juld(a_idCycle+1, :);
ySurface2 = g_NTCT_Surface2_pres(a_idCycle+1, :);
idDel = find((xSurface2 == g_dateDef) | (ySurface2 == g_presDef));
xSurface2(idDel) = [];
ySurface2(idDel) = [];
if (~isempty(xSurface2))
   plot(presAxes, xSurface2, ySurface2, 'go-', 'MarkerFaceColor', 'g', 'MarkerSize', 3);
   hold on;
end

xGrounded = g_NTCT_Grounded_flag_juld(a_idCycle+1, :);
yGrounded = g_NTCT_Grounded_flag_pres(a_idCycle+1, :);
idDel = find((xGrounded == g_dateDef) | (yGrounded == g_presDef));
xGrounded(idDel) = [];
yGrounded(idDel) = [];
if (~isempty(xGrounded))
   plot(presAxes, xGrounded, yGrounded, 'c.', 'MarkerSize', 30);
   hold on;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% time axis

% axes boundaries
timeData(find(timeData == g_dateDef)) = [];
if (g_NTCT_SURF == 1)
   if (firstSurfDate ~= g_dateDef)
      timeData(find(timeData < firstSurfDate)) = [];
   end
end
timeDiff = round(max(timeData) - min(timeData));
if (timeDiff == 0)
   timeDiff = max(timeData) - min(timeData);
   minTime = min(timeData) - timeDiff/50;
   maxTime = max(timeData) + timeDiff/50;
else
   minTime = floor(min(timeData)) - timeDiff/200;
   maxTime = ceil(max(timeData)) + timeDiff/200;
end
set(presAxes, 'Xlim', [minTime maxTime]);

% bathymetry
idF = find((g_NTCT_tabBathyJuld >= minTime) & (g_NTCT_tabBathyJuld <= maxTime));
if (~isempty(idF))
   plot(presAxes, g_NTCT_tabBathyJuld(idF), g_NTCT_tabBathyMin(idF), 'color', [255 153 51]/255);
   plot(presAxes, g_NTCT_tabBathyJuld(idF), g_NTCT_tabBathyMax(idF), 'color', [255 153 51]/255);
   hold on;
   if (g_NTCT_BATHY == 1)
      presData = [presData g_NTCT_tabBathyMin(idF)'];
   end
end

% horizontal lines
line(get(presAxes, 'XLim'), [0 0], 'Color', 'k', 'LineStyle', '-');
if (g_NTCT_ParkPres(a_idCycle+1) ~= g_presDef)
   pres = g_NTCT_ParkPres(a_idCycle+1);
   line(get(presAxes, 'XLim'), [pres pres], 'Color', 'k', 'LineStyle', '--');
   hold on;
end
if ((g_NTCT_ParkPres(a_idCycle+1) ~= g_presDef) && ...
      (g_NTCT_TolerancePres(a_idCycle+1) ~= g_presDef))
   pres = g_NTCT_ParkPres(a_idCycle+1) - g_NTCT_TolerancePres(a_idCycle+1);
   line(get(presAxes, 'XLim'), [pres pres], 'Color', 'k', 'LineStyle', ':');
   hold on;
   presData = [presData pres];
   pres = g_NTCT_ParkPres(a_idCycle+1) + g_NTCT_TolerancePres(a_idCycle+1);
   line(get(presAxes, 'XLim'), [pres pres], 'Color', 'k', 'LineStyle', ':');
   hold on;
end

if (g_NTCT_ProfPres(a_idCycle+1) ~= g_presDef)
   pres = g_NTCT_ProfPres(a_idCycle+1);
   line(get(presAxes, 'XLim'), [pres pres], 'Color', 'k', 'LineStyle', '--');
   hold on;
end
if ((g_NTCT_ProfPres(a_idCycle+1) ~= g_presDef) && ...
      (g_NTCT_TolerancePres(a_idCycle+1) ~= g_presDef))
   pres = g_NTCT_ProfPres(a_idCycle+1) - g_NTCT_TolerancePres(a_idCycle+1);
   line(get(presAxes, 'XLim'), [pres pres], 'Color', 'k', 'LineStyle', ':');
   hold on;
   pres = g_NTCT_ProfPres(a_idCycle+1) + g_NTCT_TolerancePres(a_idCycle+1);
   line(get(presAxes, 'XLim'), [pres pres], 'Color', 'k', 'LineStyle', ':');
   hold on;
end

if ((g_NTCT_PST_juld(a_idCycle+1) ~= g_dateDef) && ...
      (g_NTCT_PET_juld(a_idCycle+1) ~= g_dateDef) && ...
      (g_NTCT_MinPresInDriftAtPark_pres(a_idCycle+1) ~= g_dateDef))
   pres = g_NTCT_MinPresInDriftAtPark_pres(a_idCycle+1);
   line([g_NTCT_PST_juld(a_idCycle+1) g_NTCT_PET_juld(a_idCycle+1)], ...
      [pres pres], 'Color', 'g', 'LineStyle', ':');
   hold on;
end
if ((g_NTCT_PST_juld(a_idCycle+1) ~= g_dateDef) && ...
      (g_NTCT_PET_juld(a_idCycle+1) ~= g_dateDef) && ...
      (g_NTCT_MaxPresInDriftAtPark_pres(a_idCycle+1) ~= g_dateDef))
   pres = g_NTCT_MaxPresInDriftAtPark_pres(a_idCycle+1);
   line([g_NTCT_PST_juld(a_idCycle+1) g_NTCT_PET_juld(a_idCycle+1)], ...
      [pres pres], 'Color', 'g', 'LineStyle', ':');
   hold on;
end

if ((g_NTCT_DPST_juld(a_idCycle+1) ~= g_dateDef) && ...
      (g_NTCT_AST_juld(a_idCycle+1) ~= g_dateDef) && ...
      (g_NTCT_MinPresInDriftAtProf_pres(a_idCycle+1) ~= g_dateDef))
   pres = g_NTCT_MinPresInDriftAtProf_pres(a_idCycle+1);
   line([g_NTCT_DPST_juld(a_idCycle+1) g_NTCT_AST_juld(a_idCycle+1)], ...
      [pres pres], 'Color', 'g', 'LineStyle', ':');
   hold on;
end
if ((g_NTCT_DPST_juld(a_idCycle+1) ~= g_dateDef) && ...
      (g_NTCT_AST_juld(a_idCycle+1) ~= g_dateDef) && ...
      (g_NTCT_MaxPresInDriftAtProf_pres(a_idCycle+1) ~= g_dateDef))
   pres = g_NTCT_MaxPresInDriftAtProf_pres(a_idCycle+1);
   line([g_NTCT_DPST_juld(a_idCycle+1) g_NTCT_AST_juld(a_idCycle+1)], ...
      [pres pres], 'Color', 'g', 'LineStyle', ':');
   hold on;
end

if (g_NTCT_LastAscPumpedCtd_pres(a_idCycle+1) ~= g_presDef)
   pres = g_NTCT_LastAscPumpedCtd_pres(a_idCycle+1);
   line(get(presAxes, 'XLim'), [pres pres], 'Color', 'm', 'LineStyle', ':');
   hold on;
end

% X ticks management
xTick = get(presAxes, 'XTick');
referenceDate = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
xTick = xTick + referenceDate;
if (max(xTick) - min(xTick) > 2)
   xTickLabel = datestr(xTick, 'dd/mm/yyyy');
else
   xTickLabel = datestr(xTick, 'dd/mm/yyyy HH:MM:SS');
end
if (length(xTick) > 8)
   xTickLabel(1:2:end, :) = ' ';
end
set(presAxes, 'XTickLabel', xTickLabel);

% title of X axis
set(get(presAxes, 'XLabel'), 'String', 'Times');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pressure axis

% increasing pressures
set(presAxes, 'YDir', 'reverse');

% axes boundaries
presData(find(presData == g_presDef)) = [];
if (g_NTCT_SURF == 1)
   if (firstSurfPres ~= g_presDef)
      presData(find(presData > firstSurfPres)) = [];
   end
end
maxPres = 100*ceil(max(presData)/100);
if (maxPres == 0)
   maxPres = 100;
end
set(presAxes, 'Ylim', [-100 maxPres+100]);

% vertical lines
if (g_NTCT_CycleStart_juld(a_idCycle+1) ~= g_dateDef)
   time = g_NTCT_CycleStart_juld(a_idCycle+1);
   line([time time], get(presAxes, 'yLim'), 'Color', 'm', 'LineStyle', ':');
   hold on;
end
if (g_NTCT_DST_juld(a_idCycle+1) ~= g_dateDef)
   time = g_NTCT_DST_juld(a_idCycle+1);
   line([time time], get(presAxes, 'yLim'), 'Color', 'm', 'LineStyle', '-');
   hold on;
end
if (g_NTCT_FST_juld(a_idCycle+1) ~= g_dateDef)
   time = g_NTCT_FST_juld(a_idCycle+1);
   if (g_NTCT_FST_pres(a_idCycle+1) ~= g_presDef)
      pres = g_NTCT_FST_pres(a_idCycle+1);
      plot(presAxes, time, pres, 'bO', 'MarkerSize', 10);
      hold on;
   else
      line([time time], get(presAxes, 'yLim'), 'Color', 'm', 'LineStyle', ':');
   end
   hold on;
end
if (g_NTCT_PST_juld(a_idCycle+1) ~= g_dateDef)
   time = g_NTCT_PST_juld(a_idCycle+1);
   line([time time], get(presAxes, 'yLim'), 'Color', 'm', 'LineStyle', '-');
   hold on;
end
if (g_NTCT_PET_juld(a_idCycle+1) ~= g_dateDef)
   time = g_NTCT_PET_juld(a_idCycle+1);
   line([time time], get(presAxes, 'yLim'), 'Color', 'm', 'LineStyle', '-');
   hold on;
end
if (g_NTCT_DPST_juld(a_idCycle+1) ~= g_dateDef)
   time = g_NTCT_DPST_juld(a_idCycle+1);
   line([time time], get(presAxes, 'yLim'), 'Color', 'm', 'LineStyle', ':');
   hold on;
end
if (g_NTCT_AST_juld(a_idCycle+1) ~= g_dateDef)
   time = g_NTCT_AST_juld(a_idCycle+1);
   line([time time], get(presAxes, 'yLim'), 'Color', 'm', 'LineStyle', '-');
   hold on;
end
if (g_NTCT_AET_juld(a_idCycle+1) ~= g_dateDef)
   time = g_NTCT_AET_juld(a_idCycle+1);
   line([time time], get(presAxes, 'yLim'), 'Color', 'm', 'LineStyle', '-');
   hold on;
end

% title of y axis
set(get(presAxes, 'YLabel'), 'String', 'Pressure (dbar)');

% plot title
grdStr = '';
if (g_NTCT_Grounded_flag(a_idCycle+1) == 1)
   grdStr = ' - GROUNDED';
end
label = sprintf('%02d/%02d : %s (cycle #%d%s)', ...
   a_idFloat+1, ...
   length(g_NTCT_FLOAT_LIST), ...
   num2str(g_NTCT_FLOAT_LIST(a_idFloat+1)), ...
   g_NTCT_cycles(a_idCycle+1), ...
   grdStr);
title(presAxes, label, 'FontSize', 14);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pdf output management

if (g_NTCT_PRINT)
   surfText = '';
   if (g_NTCT_SURF)
      surfText = '_surface';
   end
   orient tall
   orient landscape
   print('-dpdf', [g_NTCT_PDF_DIR '/' sprintf('nc_trace_cycle_times_%s_%s%s', ...
      num2str(g_NTCT_FLOAT_LIST(a_idFloat+1))), num2str(g_NTCT_cycles(a_idCycle+1)), surfText, '.pdf']);
   g_NTCT_PRINT = 0;
   orient portrait
end

return

% ------------------------------------------------------------------------------
% Callback to manage plots.
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
%   04/14/2017 - RNU - creation
% ------------------------------------------------------------------------------
function change_plot(a_src, a_eventData)

global g_NTCT_BATHY;
global g_NTCT_SURF;
global g_NTCT_PRINT;
global g_NTCT_FLOAT_LIST;
global g_NTCT_FIG_HANDLE;
global g_NTCT_FLOAT_ID;
global g_NTCT_cycles;
global g_NTCT_cycle;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% exit
if (strcmp(a_eventData.Key, 'escape'))
   set(g_NTCT_FIG_HANDLE, 'KeyPressFcn', '');
   close(g_NTCT_FIG_HANDLE);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % next float
elseif (strcmp(a_eventData.Key, 'rightarrow'))
   plot_cycle_times( ...
      mod(g_NTCT_FLOAT_ID+1, length(g_NTCT_FLOAT_LIST)), ...
      0, 0);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % previous float
elseif (strcmp(a_eventData.Key, 'leftarrow'))
   plot_cycle_times( ...
      mod(g_NTCT_FLOAT_ID-1, length(g_NTCT_FLOAT_LIST)), ...
      0, 0);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % previous cycle
elseif (strcmp(a_eventData.Key, 'uparrow'))
   plot_cycle_times( ...
      g_NTCT_FLOAT_ID, ...
      mod(g_NTCT_cycle-1, length(g_NTCT_cycles)), 0);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % next cycle
elseif (strcmp(a_eventData.Key, 'downarrow'))
   plot_cycle_times( ...
      g_NTCT_FLOAT_ID, ...
      mod(g_NTCT_cycle+1, length(g_NTCT_cycles)), 0);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % bathy visibility
elseif (strcmp(a_eventData.Key, 'b'))
   g_NTCT_BATHY = mod(g_NTCT_BATHY+1, 2);
   plot_cycle_times(g_NTCT_FLOAT_ID, g_NTCT_cycle, 0);

   display_current_config;

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % surf only visibility
elseif (strcmp(a_eventData.Key, 's'))
   g_NTCT_SURF = mod(g_NTCT_SURF+1, 2);
   plot_cycle_times(g_NTCT_FLOAT_ID, g_NTCT_cycle, 0);

   display_current_config;

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % pdf output file generation
elseif (strcmp(a_eventData.Key, 'p'))
   g_NTCT_PRINT = 1;
   plot_cycle_times(g_NTCT_FLOAT_ID, g_NTCT_cycle, 0);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % pdf output file generation of all cycles
elseif (strcmp(a_eventData.Key, 'f'))

   cycleNumTmp = g_NTCT_cycle;
   for idCy = g_NTCT_cycles'
      g_NTCT_PRINT = 1;
      plot_cycle_times(g_NTCT_FLOAT_ID, idCy, 0);
   end

   g_NTCT_cycle = cycleNumTmp;
   plot_cycle_times(g_NTCT_FLOAT_ID, g_NTCT_cycle, 0);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % write help and current configuration
elseif (strcmp(a_eventData.Key, 'h'))
   fprintf('Plot management:\n');
   fprintf('   Right Arrow  : next float\n');
   fprintf('   Left Arrow   : previous float\n');
   fprintf('   Up/Down Arrow: previous/next cycle\n');
   fprintf('   b            : bathy always visible\n');
   fprintf('   s            : focus on surface data\n');
   fprintf('   h            : write help and current configuration\n');
   fprintf('   p            : pdf output file generation\n');
   fprintf('   f            : pdf output file generation of all cycles\n');
   fprintf('Escape: exit\n\n');

   display_current_config;
end

return

% ------------------------------------------------------------------------------
% Display the current configuration.
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
%   04/14/2017 - RNU - creation
% ------------------------------------------------------------------------------
function display_current_config

global g_NTCT_BATHY;
global g_NTCT_SURF;

fprintf('\nCurrent configuration:\n');
fprintf('BATHY always visible flag: %d\n', g_NTCT_BATHY);
fprintf('SURFACE data focus flag  : %d\n', g_NTCT_SURF);

return

% ------------------------------------------------------------------------------
% Callback used to update the X tick labels after a zoom.
%
% SYNTAX :
%   after_zoom(a_src, a_eventData)
%
% INPUT PARAMETERS :
%   a_src       : object
%   a_eventData : event
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/14/2017 - RNU - creation
% ------------------------------------------------------------------------------
function after_zoom(a_src, a_eventData)

% retrieve the time axis
presAxes = subplot(1, 1, 1);

if (a_eventData.Axes == presAxes)
   % X ticks management
   xTick = get(a_eventData.Axes, 'XTick');
   referenceDate = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');
   xTick = xTick + referenceDate;
   if (max(xTick) - min(xTick) > 2)
      xTickLabel = datestr(xTick, 'dd/mm/yyyy');
   else
      xTickLabel = datestr(xTick, 'dd/mm/yyyy HH:MM:SS');
   end
   if (length(xTick) > 8)
      xTickLabel(1:2:end, :) = ' ';
   end
   set(presAxes, 'XTickLabel', xTickLabel);
end

return

% ------------------------------------------------------------------------------
% Callback used to customize text of data cursor.
%
% SYNTAX :
%   data_cursor_output(a_src, a_eventData)
%
% INPUT PARAMETERS :
%   a_src       : object
%   a_eventData : event
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/14/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_text] = data_cursor_output(a_src, a_eventData)

pos = get(a_eventData, 'Position');
o_text = {['Time: ', julian_2_gregorian_dec_argo(pos(1))],...
   ['Pres: ',num2str(pos(2)) ' dbar']};

return

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : NetCDF variables to retrieve from the file
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)

   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end

   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};

      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         %          fprintf('WARNING: Variable %s not present in file : %s\n', ...
         %             varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {''}];
      end

   end

   netcdf.close(fCdf);
end

return
