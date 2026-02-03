% ------------------------------------------------------------------------------
% Plot trajectory parameter measurements with surounding profile ones.
%
% SYNTAX :
%   nc_trace_traj_adj_param ou nc_trace_traj_adj_param(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to plot
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/06/2024 - RNU - creation
% ------------------------------------------------------------------------------
function nc_trace_traj_adj_param(varargin)

% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

global g_NTTP_NC_DIR;
global g_NTTP_PDF_DIR;
global g_NTTP_FIG_HANDLE;
global g_NTTP_PRINT;
global g_NTTP_ALL_PROF_MEAS;
global g_NTTP_RT_PROF_MEAS;
global g_NTTP_PLOT_ERR;

global g_NTTP_CPT_LOOP;

global g_NTTP_PROF_SIZE;

global g_NTTP_ID_FLOAT;
global g_NTTP_FLOAT_LIST;

global g_NTTP_PARAM_NAME;
global g_NTTP_MC_LIST;

% global measurement codes
global g_MC_DriftAtPark;


g_NTTP_PARAM_NAME = 'PSAL';
g_NTTP_PARAM_NAME = 'DOXY';
g_NTTP_MC_LIST = [g_MC_DriftAtPark];

% top directory of NetCDF files to plot
g_NTTP_NC_DIR = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
g_NTTP_NC_DIR = 'C:\Users\jprannou\_DATA\TRAJ_DM_2024\snapshot-202401_nke_in_andro\';

% directory to store pdf output
g_NTTP_PDF_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\pdf\';

% default list of floats to plot
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\arvor_in_andro_psal_adj.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\cts3_in_andro_psal_adj.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\cts3_in_andro_doxy_adj.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\arvor_deep_psal_adj.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\TRAJ_DM\arvor_deep_doxy_adj.txt';


% to prevent infinite loop
g_NTTP_CPT_LOOP = 0;

% no pdf generation
g_NTTP_PRINT = 0;

% plot only reduced part of the profiles
g_NTTP_ALL_PROF_MEAS = 0;

% profile pressure interval above and below TRAJ measurements
g_NTTP_PROF_SIZE = 150;

% plot RT profile measurements
g_NTTP_RT_PROF_MEAS = 1;

% plot error on adjusted measurements
g_NTTP_PLOT_ERR = 1;

% force the plot of the first float
g_NTTP_ID_FLOAT = -1;

close(findobj('Name', 'Trajectory and profile adjusted measurements'));
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

g_NTTP_FLOAT_LIST = floatList;

fprintf('Plot management:\n');
fprintf('   Right Arrow: next float\n');
fprintf('   Left Arrow : previous float\n');
fprintf('   Down Arrow : next cycle\n');
fprintf('   Up Arrow   : previous cycle\n');
fprintf('Plot:\n');
fprintf('   a  : plot all profile measurements\n');
fprintf('   r  : plot RT measurements\n');
fprintf('Misc:\n');
fprintf('   p: pdf output file generation\n');
fprintf('   h: write help and current configuration\n');
fprintf('Escape: exit\n\n');

fprintf('Current configuration:\n');
fprintf('Plot all profile measurements: %d\n', g_NTTP_ALL_PROF_MEAS);
fprintf('Plot RT profile measurements: %d\n', g_NTTP_RT_PROF_MEAS);

% creation of the figure and its associated callback
screenSize = get(0, 'ScreenSize');
g_NTTP_FIG_HANDLE = figure('KeyPressFcn', @change_plot, ...
   'Name', 'Trajectory and profile adjusted measurements', ...
   'Position', [1+(screenSize(3)/2) screenSize(2)+40 screenSize(3)-(screenSize(3)/2)-10 screenSize(4)-125]);

% plot the first set of profiles of the first float
plot_param(0, 0);

return

% ------------------------------------------------------------------------------
% Plot the TRAJ and PROF measurements for a given float and cycle.
%
% SYNTAX :
%   plot_param(a_idFloat, a_idCycle)
%
% INPUT PARAMETERS :
%   a_idFloat : float Id in the list
%   a_idCycle : cycle Id in the list
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/06/2024 - RNU - creation
% ------------------------------------------------------------------------------
function plot_param(a_idFloat, a_idCycle)

global g_NTTP_PDF_DIR;
global g_NTTP_FIG_HANDLE;
global g_NTTP_ID_FLOAT;
global g_NTTP_FLOAT_LIST;
global g_NTTP_FLOAT_NUM;
global g_NTTP_PRINT;
global g_NTTP_ALL_PROF_MEAS;
global g_NTTP_RT_PROF_MEAS;
global g_NTTP_PLOT_ERR;

global g_NTTP_CPT_LOOP;

global g_NTTP_PROF_SIZE;

global g_NTTP_cycles;
global g_NTTP_idCycle;
global g_NTTP_nbCycles;

global g_NTTP_PARAM_NAME;
global g_NTTP_UNITS_PARAM;
global g_NTTP_PARAM_TYPE;
global g_NTTP_PARAM_LIST;

global g_NTTP_TRAJ_CY_NUM;
global g_NTTP_TRAJ_MC;

global g_NTTP_PRES_FILL_VAL;
global g_NTTP_PARAM_FILL_VAL;

global g_NTTP_TRAJ_PRES;
global g_NTTP_TRAJ_PRES_QC;
global g_NTTP_TRAJ_PRES_ADJ;
global g_NTTP_TRAJ_PRES_ADJ_QCD;
global g_NTTP_TRAJ_PRES_DATA_MODE;

global g_NTTP_TRAJ_PARAM;
global g_NTTP_TRAJ_PARAM_QC;
global g_NTTP_TRAJ_PARAM_ADJ;
global g_NTTP_TRAJ_PARAM_ADJ_QC;
global g_NTTP_TRAJ_PARAM_DATA_MODE;

global g_NTTP_PROF_DATA;

% QC flag values (char)
global g_decArgo_qcStrGood;
global g_decArgo_qcStrProbablyGood;
global g_decArgo_qcStrCorrectable;
global g_decArgo_qcStrBad;

global g_NTTP_MC_LIST;

global g_NTTP_LAST_CMD;


g_NTTP_idCycle = a_idCycle;

figure(g_NTTP_FIG_HANDLE);
clf;

if (a_idFloat ~= g_NTTP_ID_FLOAT)

   clc;

   % a new float is wanted
   g_NTTP_ID_FLOAT = a_idFloat;
   g_NTTP_FLOAT_NUM = g_NTTP_FLOAT_LIST(a_idFloat+1);
   g_NTTP_LAST_CMD = 1;
   g_NTTP_cycles = [];
   g_NTTP_CPT_LOOP = 0;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve and store the data of the new float

   % float number
   floatNum = g_NTTP_FLOAT_LIST(a_idFloat+1);

   fprintf('Float #%d: loading data\n', floatNum);

   paramPres = get_netcdf_param_attributes('PRES');
   paramStruct = get_netcdf_param_attributes(g_NTTP_PARAM_NAME);
   g_NTTP_UNITS_PARAM = paramStruct.units;
   g_NTTP_PRES_FILL_VAL = paramPres.fillValue;
   g_NTTP_PARAM_FILL_VAL = paramStruct.fillValue;
   paramList = [{'PRES'} {g_NTTP_PARAM_NAME}];
   g_NTTP_PARAM_LIST = paramList;
   if ((paramStruct.paramType == 'c') || (paramStruct.paramType == 'j'))
      paramType = 'c';
   else
      paramType = 'b';
   end
   g_NTTP_PARAM_TYPE = paramType;

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve data from trajectory file
   get_traj_data;

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve data from profile files
   get_prof_data;

   fprintf(' done\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot data

idMeas = find((g_NTTP_TRAJ_CY_NUM == g_NTTP_idCycle) & ismember(g_NTTP_TRAJ_MC, g_NTTP_MC_LIST));
if (~isempty(idMeas))
   trajPres = g_NTTP_TRAJ_PRES(idMeas);
   trajPresQc = g_NTTP_TRAJ_PRES_QC(idMeas);
   trajPresAdj = g_NTTP_TRAJ_PRES_ADJ(idMeas);
   trajPresAdjQc = g_NTTP_TRAJ_PRES_ADJ_QCD(idMeas);
   trajPresDataMode = g_NTTP_TRAJ_PRES_DATA_MODE(idMeas);
   trajParam = g_NTTP_TRAJ_PARAM(idMeas);
   trajParamQc = g_NTTP_TRAJ_PARAM_QC(idMeas);
   trajParamAdj = g_NTTP_TRAJ_PARAM_ADJ(idMeas);
   trajParamAdjQc = g_NTTP_TRAJ_PARAM_ADJ_QC(idMeas);
   trajParamDataMode = g_NTTP_TRAJ_PARAM_DATA_MODE(idMeas);
else
   trajPres = [];
   trajPresQc = [];
   trajPresAdj = [];
   trajPresAdjQc = [];
   trajPresDataMode = [];
   trajParam = [];
   trajParamQc = [];
   trajParamAdj = [];
   trajParamAdjQc = [];
   trajParamDataMode = [];
end

idProfPrev = find([g_NTTP_PROF_DATA{:, 1}] == g_NTTP_idCycle - 1);
if (~isempty(idProfPrev))
   prof = g_NTTP_PROF_DATA{idProfPrev, 4};
   profPrevPres = prof.data(:, 1);
   profPrevPresQc = prof.dataQc(:, 1);
   profPrevPresAdj = prof.dataAdj(:, 1);
   profPrevPresAdjQc = prof.dataAdjQc(:, 1);
   profPrevPresDataMode = prof.dataMode(:, 1);
   profPrevParam = prof.data(:, 2);
   profPrevParamQc = prof.dataQc(:, 2);
   profPrevParamAdj = prof.dataAdj(:, 2);
   profPrevParamAdjQc = prof.dataAdjQc(:, 2);
   profPrevParamAdjErr = prof.dataAdjErr(:, 2);
   profPrevParamDataMode = prof.dataMode(:, 2);
else
   profPrevPres = [];
   profPrevPresQc = [];
   profPrevPresAdj = [];
   profPrevPresAdjQc = [];
   profPrevPresDataMode = [];
   profPrevParam = [];
   profPrevParamQc = [];
   profPrevParamAdj = [];
   profPrevParamAdjQc = [];
   profPrevParamAdjErr = [];
   profPrevParamDataMode = [];
end

idProfCur = find([g_NTTP_PROF_DATA{:, 1}] == g_NTTP_idCycle);
if (~isempty(idProfCur))
   prof = g_NTTP_PROF_DATA{idProfCur, 4};
   profCurPres = prof.data(:, 1);
   profCurPresQc = prof.dataQc(:, 1);
   profCurPresAdj = prof.dataAdj(:, 1);
   profCurPresAdjQc = prof.dataAdjQc(:, 1);
   profCurPresDataMode = prof.dataMode(:, 1);
   profCurParam = prof.data(:, 2);
   profCurParamQc = prof.dataQc(:, 2);
   profCurParamAdj = prof.dataAdj(:, 2);
   profCurParamAdjQc = prof.dataAdjQc(:, 2);
   profCurParamAdjErr = prof.dataAdjErr(:, 2);
   profCurParamDataMode = prof.dataMode(:, 2);
else
   profCurPres = [];
   profCurPresQc = [];
   profCurPresAdj = [];
   profCurPresAdjQc = [];
   profCurPresDataMode = [];
   profCurParam = [];
   profCurParamQc = [];
   profCurParamAdj = [];
   profCurParamAdjQc = [];
   profCurParamAdjErr = [];
   profCurParamDataMode = [];
end

idNoDef1 = find(~isnan(trajPres) & ~isnan(trajParam));
yTrajData = trajPres(idNoDef1);
yTrajDataQc = trajPresQc(idNoDef1);
xTrajData = trajParam(idNoDef1);
xTrajDataQc = trajParamQc(idNoDef1);
minPres = min(yTrajData);
maxPres = max(yTrajData);

yProfPrevData = [];
yProfPrevRData = [];
yProfCurData = [];
yProfCurRData = [];
idNoDef22 = [];
idNoDef32 = [];
if (~isempty(idNoDef1))

   idNoDef2 = find(~isnan(profPrevPresAdj) & ~isnan(profPrevParamAdj) & ...
      (profPrevPresDataMode == 'D') & (profPrevParamDataMode == 'D') & ...
      (((profPrevPresAdjQc == g_decArgo_qcStrGood) | (profPrevPresAdjQc == g_decArgo_qcStrProbablyGood)) & ...
      ((profPrevParamAdjQc == g_decArgo_qcStrGood) | (profPrevParamAdjQc == g_decArgo_qcStrProbablyGood))));
   yProfPrevData = profPrevPresAdj(idNoDef2);
   yProfPrevDataQc = profPrevPresAdjQc(idNoDef2);
   xProfPrevData = profPrevParamAdj(idNoDef2);
   xProfPrevDataQc = profPrevParamAdjQc(idNoDef2);
   xProfPrevDataErr = profPrevParamAdjErr(idNoDef2);

   if (g_NTTP_RT_PROF_MEAS == 1)
      idNoDef22 = find(~isnan(profPrevPres) & ~isnan(profPrevParam));
      yProfPrevRData = profPrevPres(idNoDef22);
      yProfPrevRDataQc = profPrevPresQc(idNoDef22);
      xProfPrevRData = profPrevParam(idNoDef22);
      xProfPrevRDataQc = profPrevParamQc(idNoDef22);
   else
      yProfPrevRData = [];
      yProfPrevRDataQc = [];
      xProfPrevRData = [];
      xProfPrevRDataQc = [];
   end

   if (g_NTTP_ALL_PROF_MEAS == 0)
      idP = find((yProfPrevData <= maxPres + g_NTTP_PROF_SIZE) & (yProfPrevData >= minPres - g_NTTP_PROF_SIZE));
      yProfPrevData = yProfPrevData(idP);
      yProfPrevDataQc = yProfPrevDataQc(idP);
      xProfPrevData = xProfPrevData(idP);
      xProfPrevDataQc = xProfPrevDataQc(idP);
      xProfPrevDataErr = xProfPrevDataErr(idP);

      if (~isempty(idNoDef22))
         idP = find((yProfPrevRData <= maxPres + g_NTTP_PROF_SIZE) & (yProfPrevRData >= minPres - g_NTTP_PROF_SIZE));
         yProfPrevRData = yProfPrevRData(idP);
         yProfPrevRDataQc = yProfPrevRDataQc(idP);
         xProfPrevRData = xProfPrevRData(idP);
         xProfPrevRDataQc = xProfPrevRDataQc(idP);
      end
   end

   idNoDef3 = find(~isnan(profCurPresAdj) & ~isnan(profCurParamAdj) & ...
      (profCurPresDataMode == 'D') & (profCurParamDataMode == 'D') & ...
      (((profCurPresAdjQc == g_decArgo_qcStrGood) | (profCurPresAdjQc == g_decArgo_qcStrProbablyGood)) & ...
      ((profCurParamAdjQc == g_decArgo_qcStrGood) | (profCurParamAdjQc == g_decArgo_qcStrProbablyGood))));
   yProfCurData = profCurPresAdj(idNoDef3);
   yProfCurDataQc = profCurPresAdjQc(idNoDef3);
   xProfCurData = profCurParamAdj(idNoDef3);
   xProfCurDataQc = profCurParamAdjQc(idNoDef3);
   xProfCurDataErr = profCurParamAdjErr(idNoDef3);

   if (g_NTTP_RT_PROF_MEAS == 1)
      idNoDef32 = find(~isnan(profCurPres) & ~isnan(profCurParam));
      yProfCurRData = profCurPres(idNoDef32);
      yProfCurRDataQc = profCurPresQc(idNoDef32);
      xProfCurRData = profCurParam(idNoDef32);
      xProfCurRDataQc = profCurParamQc(idNoDef32);
   else
      yProfCurRData = [];
      yProfCurRDataQc = [];
      xProfCurRData = [];
      xProfCurRDataQc = [];
   end

   if (g_NTTP_ALL_PROF_MEAS == 0)
      idP = find((yProfCurData <= maxPres + g_NTTP_PROF_SIZE) & (yProfCurData >= minPres - g_NTTP_PROF_SIZE));
      yProfCurData = yProfCurData(idP);
      yProfCurDataQc = yProfCurDataQc(idP);
      xProfCurData = xProfCurData(idP);
      xProfCurDataQc = xProfCurDataQc(idP);
      xProfCurDataErr = xProfCurDataErr(idP);

      if (~isempty(idNoDef32))
         idP = find((yProfCurRData <= maxPres + g_NTTP_PROF_SIZE) & (yProfCurRData >= minPres - g_NTTP_PROF_SIZE));
         yProfCurRData = yProfCurRData(idP);
         yProfCurRDataQc = yProfCurRDataQc(idP);
         xProfCurRData = xProfCurRData(idP);
         xProfCurRDataQc = xProfCurRDataQc(idP);
      end
   end
end

% check if measurement should be plot
dataToPlot = 0;
if (~isempty(yTrajData) && ~isempty(yProfPrevData) && ~isempty(yProfCurData))
   ok1 = 0;
   if (min(yProfPrevData) <= min(yTrajData)) && (max(yProfPrevData) >= min(yTrajData))
      ok1 = 1;
   elseif (min(yProfPrevData) >= min(yTrajData)) && (min(yProfPrevData) <= max(yTrajData))
      ok1 = 1;
   end
   ok2 = 0;
   if (min(yProfCurData) <= min(yTrajData)) && (max(yProfCurData) >= min(yTrajData))
      ok2 = 1;
   elseif (min(yProfCurData) >= min(yTrajData)) && (min(yProfCurData) <= max(yTrajData))
      ok2 = 1;
   end
   if (ok1 + ok2 == 2)
      dataToPlot = 1;
   end
end

if (~dataToPlot)
   label = sprintf('%02d/%02d : float #%d cycle #%d: %s - NO DATA', ...
      a_idFloat+1, ...
      length(g_NTTP_FLOAT_LIST), ...
      g_NTTP_FLOAT_LIST(a_idFloat+1), ...
      g_NTTP_cycles(a_idCycle+1), ...
      regexprep(g_NTTP_PARAM_NAME, '_', ' '));
   % title(label);
   fprintf('%s\n', label);
   g_NTTP_CPT_LOOP = g_NTTP_CPT_LOOP + 1;
   if (g_NTTP_CPT_LOOP >= length(g_NTTP_cycles))
      label = sprintf('%02d/%02d : float #%d: %s - NO DATA', ...
         a_idFloat+1, ...
         length(g_NTTP_FLOAT_LIST), ...
         g_NTTP_FLOAT_LIST(a_idFloat+1), ...
         regexprep(g_NTTP_PARAM_NAME, '_', ' '));
      fprintf('%s\n', label);
   else
      plot_param(g_NTTP_ID_FLOAT, mod(g_NTTP_idCycle+g_NTTP_LAST_CMD, length(g_NTTP_cycles)));
   end
   return
end

g_NTTP_CPT_LOOP = 0;

minPres = min([yTrajData; yProfPrevData; yProfPrevRData; yProfCurData; yProfCurRData]);
maxPres = max([yTrajData; yProfPrevData; yProfPrevRData; yProfCurData; yProfCurRData]);
minParam = min([xTrajData; xProfPrevData; xProfPrevData-xProfPrevDataErr; xProfPrevData+xProfPrevDataErr; xProfPrevRData; xProfCurData; xProfCurData-xProfCurDataErr; xProfCurData+xProfCurDataErr; xProfCurRData]);
maxParam = max([xTrajData; xProfPrevData; xProfPrevData-xProfPrevDataErr; xProfPrevData+xProfPrevDataErr; xProfPrevRData; xProfCurData; xProfCurData-xProfCurDataErr; xProfCurData+xProfCurDataErr; xProfCurRData]);

minAxeParam = minParam - (maxParam-minParam)/6;
maxAxeParam = maxParam + (maxParam-minParam)/6;
if (minAxeParam == maxAxeParam)
   minAxeParam = minAxeParam - 0.5;
   maxAxeParam = maxAxeParam + 0.5;
end

prevProfColor = [223 109 20]/255;
curProfColor = [1 215 88]/255;
trajColor = [102 0 255]/255;

% previous profile measurements
markerSize = 5;
if (~isempty(xProfPrevData))
   plot(xProfPrevData, yProfPrevData, '-', 'color', prevProfColor);
   hold('on');
   if (g_NTTP_PLOT_ERR == 1)
      plot(xProfPrevData-xProfPrevDataErr, yProfPrevData, ':', 'color', prevProfColor);
      hold('on');
      plot(xProfPrevData+xProfPrevDataErr, yProfPrevData, ':', 'color', prevProfColor);
      hold('on');
   end

   idQcBad = find((xProfPrevDataQc == g_decArgo_qcStrCorrectable) | (xProfPrevDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(xProfPrevData), idQcBad);
   plot(xProfPrevData(idQcBad), yProfPrevData(idQcBad), 'r*', 'Markersize',  markerSize);
   hold('on');
   plot(xProfPrevData(idQcGood), yProfPrevData(idQcGood), '*', 'color', prevProfColor, 'Markersize',  markerSize);
   hold('on');

   idQcBad = find((yProfPrevDataQc == g_decArgo_qcStrCorrectable) | (yProfPrevDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(yProfPrevData), idQcBad);
   plot(ones(length(idQcBad), 1)*minAxeParam, yProfPrevData(idQcBad), 'r*', 'Markersize',  markerSize);
   hold('on');
   plot(ones(length(idQcGood), 1)*minAxeParam, yProfPrevData(idQcGood), '*', 'color', prevProfColor, 'Markersize',  markerSize);
   hold('on');
end
if (~isempty(xProfPrevRData))
   plot(xProfPrevRData, yProfPrevRData, '--', 'color', prevProfColor);
   hold('on');

   idQcBad = find((xProfPrevRDataQc == g_decArgo_qcStrCorrectable) | (xProfPrevRDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(xProfPrevRData), idQcBad);
   plot(xProfPrevRData(idQcBad), yProfPrevRData(idQcBad), 'ro', 'Markersize',  markerSize);
   hold('on');
   plot(xProfPrevRData(idQcGood), yProfPrevRData(idQcGood), 'o', 'color', prevProfColor, 'Markersize',  markerSize);
   hold('on');

   idQcBad = find((yProfPrevRDataQc == g_decArgo_qcStrCorrectable) | (yProfPrevRDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(yProfPrevRData), idQcBad);
   plot(ones(length(idQcBad), 1)*minAxeParam, yProfPrevRData(idQcBad), 'ro', 'Markersize',  markerSize);
   hold('on');
   plot(ones(length(idQcGood), 1)*minAxeParam, yProfPrevRData(idQcGood), 'o', 'color', prevProfColor, 'Markersize',  markerSize);
   hold('on');
end

% current profile measurements
markerSize = 5;
if (~isempty(xProfCurData))
   plot(xProfCurData, yProfCurData, '-', 'color', curProfColor);
   hold('on');
   if (g_NTTP_PLOT_ERR == 1)
      plot(xProfCurData-xProfCurDataErr, yProfCurData, ':', 'color', curProfColor);
      hold('on');
      plot(xProfCurData+xProfCurDataErr, yProfCurData, ':', 'color', curProfColor);
      hold('on');
   end

   idQcBad = find((xProfCurDataQc == g_decArgo_qcStrCorrectable) | (xProfCurDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(xProfCurData), idQcBad);
   plot(xProfCurData(idQcBad), yProfCurData(idQcBad), 'r*', 'Markersize',  markerSize);
   hold('on');
   plot(xProfCurData(idQcGood), yProfCurData(idQcGood), '*', 'color', curProfColor, 'Markersize',  markerSize);
   hold('on');

   idQcBad = find((yProfCurDataQc == g_decArgo_qcStrCorrectable) | (yProfCurDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(yProfCurData), idQcBad);
   plot(ones(length(idQcBad), 1)*minAxeParam, yProfCurData(idQcBad), 'r*', 'Markersize',  markerSize);
   hold('on');
   plot(ones(length(idQcGood), 1)*minAxeParam, yProfCurData(idQcGood), '*', 'color', curProfColor, 'Markersize',  markerSize);
   hold('on');
end
if (~isempty(xProfCurRData))
   plot(xProfCurRData, yProfCurRData, '--', 'color', curProfColor);
   hold('on');

   idQcBad = find((xProfCurRDataQc == g_decArgo_qcStrCorrectable) | (xProfCurRDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(xProfCurRData), idQcBad);
   plot(xProfCurRData(idQcBad), yProfCurRData(idQcBad), 'ro', 'Markersize',  markerSize);
   hold('on');
   plot(xProfCurRData(idQcGood), yProfCurRData(idQcGood), 'o', 'color', curProfColor, 'Markersize',  markerSize);
   hold('on');

   idQcBad = find((yProfCurRDataQc == g_decArgo_qcStrCorrectable) | (yProfCurRDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(yProfCurRData), idQcBad);
   plot(ones(length(idQcBad), 1)*minAxeParam, yProfCurRData(idQcBad), 'ro', 'Markersize',  markerSize);
   hold('on');
   plot(ones(length(idQcGood), 1)*minAxeParam, yProfCurRData(idQcGood), 'o', 'color', curProfColor, 'Markersize',  markerSize);
   hold('on');
end

% TRAJ measurements
markerSize = 10;
if (~isempty(xTrajData))
   plot(xTrajData, yTrajData, '-', 'color', trajColor);
   hold('on');

   idQcBad = find((xTrajDataQc == g_decArgo_qcStrCorrectable) | (xTrajDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(xTrajData), idQcBad);
   plot(xTrajData(idQcBad), yTrajData(idQcBad), 'r.', 'Markersize',  markerSize);
   hold('on');
   plot(xTrajData(idQcGood), yTrajData(idQcGood), '.', 'color', trajColor, 'Markersize',  markerSize);
   hold('on');

   idQcBad = find((yTrajDataQc == g_decArgo_qcStrCorrectable) | (yTrajDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(yTrajData), idQcBad);
   plot(ones(length(idQcBad), 1)*minAxeParam, yTrajData(idQcBad), 'r.', 'Markersize',  markerSize);
   hold('on');
   plot(ones(length(idQcGood), 1)*minAxeParam, yTrajData(idQcGood), '.', 'color', trajColor, 'Markersize',  markerSize);
   hold('on');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalize the plots

% increasing pressures
set(gca, 'YDir', 'reverse');

% Y axis boundaries
minAxePres = minPres;
maxAxePres = maxPres;
if (minAxePres == maxAxePres)
   minAxePres = minAxePres - 10;
   maxAxePres = maxAxePres + 10;
end
set(gca, 'Ylim', [minAxePres maxAxePres]);

% X axis boundaries
set(gca, 'Xlim', [minAxeParam maxAxeParam]);

% titre des axes
set(get(gca, 'XLabel'), 'String', regexprep([g_NTTP_PARAM_NAME ' (' g_NTTP_UNITS_PARAM ')'], '_', ' '));
set(get(gca, 'YLabel'), 'String', 'Pressure (dbar)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot title

label = sprintf('%02d/%02d : float #%d cycle #%d: %s - %d meas', ...
   a_idFloat+1, ...
   length(g_NTTP_FLOAT_LIST), ...
   g_NTTP_FLOAT_LIST(a_idFloat+1), ...
   g_NTTP_cycles(a_idCycle+1), ...
   regexprep(g_NTTP_PARAM_NAME, '_', ' '), ...
   length(idNoDef1));
title(label);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pdf output management

if (g_NTTP_PRINT)
   orient tall
   orient landscape
   print('-dpdf', [g_NTTP_PDF_DIR '/' sprintf('nc_trace_traj_adj_param_%s_%03d_%03d', num2str(g_NTTP_FLOAT_LIST(a_idFloat+1)), g_NTTP_cycles(a_idCycle+1), g_NTTP_cycles(a_idCycle+1+g_NTTP_nbCycles-1)) '.pdf']);
   g_NTTP_PRINT = 0;
end

return

% ------------------------------------------------------------------------------
% Retrieve TRAJ data from NetCDf file.
%
% SYNTAX :
%   get_traj_data
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
%   03/06/2024 - RNU - creation
% ------------------------------------------------------------------------------
function get_traj_data

global g_NTTP_NC_DIR;
global g_NTTP_FLOAT_NUM;
global g_NTTP_PARAM_LIST;

global g_NTTP_cycles;

global g_NTTP_TRAJ_CY_NUM;
global g_NTTP_TRAJ_MC;
global g_NTTP_TRAJ_JULD;
global g_NTTP_TRAJ_JULD_QC;
global g_NTTP_TRAJ_JULD_ADJ;
global g_NTTP_TRAJ_JULD_ADJ_QC;
global g_NTTP_TRAJ_JULD_DATA_MODE;

global g_NTTP_TRAJ_PRES;
global g_NTTP_TRAJ_PRES_QC;
global g_NTTP_TRAJ_PRES_ADJ;
global g_NTTP_TRAJ_PRES_ADJ_QCD;
global g_NTTP_TRAJ_PRES_DATA_MODE;

global g_NTTP_TRAJ_PARAM;
global g_NTTP_TRAJ_PARAM_QC;
global g_NTTP_TRAJ_PARAM_ADJ;
global g_NTTP_TRAJ_PARAM_ADJ_QC;
global g_NTTP_TRAJ_PARAM_DATA_MODE;

global g_NTTP_PRES_FILL_VAL;
global g_NTTP_PARAM_FILL_VAL;


% retrieve data from TRAJ file
trajFile = dir([g_NTTP_NC_DIR sprintf('/%d/%d_Rtraj.nc', g_NTTP_FLOAT_NUM, g_NTTP_FLOAT_NUM)]);
if (isempty(trajFile))
   fprintf('INFO: No trajectory file for float %d - ignored\n', ...
      g_NTTP_FLOAT_NUM);
   return
end
trajFileName = trajFile(1).name;
trajFilePathName = [g_NTTP_NC_DIR '/' num2str(g_NTTP_FLOAT_NUM) '/' trajFileName];

wantedVars = [ ...
   {'FORMAT_VERSION'} ...
   {'TRAJECTORY_PARAMETERS'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'JULD_ADJUSTED'} ...
   {'JULD_ADJUSTED_QC'} ...
   {'CYCLE_NUMBER'} ...
   {'MEASUREMENT_CODE'} ...
   {'TRAJECTORY_PARAMETER_DATA_MODE'} ...
   {'JULD_DATA_MODE'} ...
   ];
for idParam = 1:length(g_NTTP_PARAM_LIST)
   paramName = g_NTTP_PARAM_LIST{idParam};
   wantedVars = [wantedVars ...
      {paramName} {[paramName '_QC']} ...
      {[paramName '_ADJUSTED']} {[paramName '_ADJUSTED_QC']} ...
      ];
end

ncTrajData = get_data_from_nc_file(trajFilePathName, wantedVars);

formatVersion = strtrim(get_data_from_name('FORMAT_VERSION', ncTrajData)');
if (~strcmp(formatVersion, '3.2'))
   fprintf('INFO: Input trajectory file (%s) is expected to be of 3.2 format version (but FORMAT_VERSION = %s) - ignored\n', ...
      trajFileName, formatVersion);
   return
end
trajectoryParameters = get_data_from_name('TRAJECTORY_PARAMETERS', ncTrajData);
juld = get_data_from_name('JULD', ncTrajData);
juldQc = get_data_from_name('JULD_QC', ncTrajData);
juldAdj = get_data_from_name('JULD_ADJUSTED', ncTrajData);
juldAdjQc = get_data_from_name('JULD_ADJUSTED_QC', ncTrajData);
cycleNumber = get_data_from_name('CYCLE_NUMBER', ncTrajData);
measurementCode = get_data_from_name('MEASUREMENT_CODE', ncTrajData);
trajParamDataMode = get_data_from_name('TRAJECTORY_PARAMETER_DATA_MODE', ncTrajData);
juldDataMode = get_data_from_name('JULD_DATA_MODE', ncTrajData);

% store needed data
g_NTTP_TRAJ_CY_NUM = cycleNumber;
g_NTTP_TRAJ_MC = measurementCode;
g_NTTP_TRAJ_JULD = juld;
g_NTTP_TRAJ_JULD_QC = juldQc;
g_NTTP_TRAJ_JULD_ADJ = juldAdj;
g_NTTP_TRAJ_JULD_ADJ_QC = juldAdjQc;
g_NTTP_TRAJ_JULD_DATA_MODE = juldDataMode;
g_NTTP_cycles = unique(cycleNumber);
g_NTTP_cycles(g_NTTP_cycles < 0) = [];

[~, nParam] = size(trajectoryParameters);
for idP = 1:length(g_NTTP_PARAM_LIST)
   paramName = g_NTTP_PARAM_LIST{idP};
   paramNameQc = [paramName '_QC'];
   paramAdjName = [paramName '_ADJUSTED'];
   paramAdjNameQc = [paramAdjName '_QC'];
   data = get_data_from_name(paramName, ncTrajData);
   if (size(data, 2) > 1)
      data = permute(data, ndims(data):-1:1);
   end
   dataQc = get_data_from_name(paramNameQc, ncTrajData);
   dataAdj = get_data_from_name(paramAdjName, ncTrajData);
   if (size(dataAdj, 2) > 1)
      dataAdj = permute(dataAdj, ndims(dataAdj):-1:1);
   end
   dataAdjQc = get_data_from_name(paramAdjNameQc, ncTrajData);

   for idParam = 1:nParam
      pName = deblank(trajectoryParameters(:, idP)');
      if (strcmp(pName, paramName))
         paramDataMode = trajParamDataMode(idParam, :)';
         break
      end
   end

   if (idP == 1)
      data(data == g_NTTP_PRES_FILL_VAL) = nan;
      dataAdj(dataAdj == g_NTTP_PRES_FILL_VAL) = nan;
      g_NTTP_TRAJ_PRES = data;
      g_NTTP_TRAJ_PRES_QC = dataQc;
      g_NTTP_TRAJ_PRES_ADJ = dataAdj;
      g_NTTP_TRAJ_PRES_ADJ_QCD = dataAdjQc;
      g_NTTP_TRAJ_PRES_DATA_MODE = paramDataMode;
   else
      data(data == g_NTTP_PARAM_FILL_VAL) = nan;
      dataAdj(dataAdj == g_NTTP_PARAM_FILL_VAL) = nan;
      g_NTTP_TRAJ_PARAM = data;
      g_NTTP_TRAJ_PARAM_QC = dataQc;
      g_NTTP_TRAJ_PARAM_ADJ = dataAdj;
      g_NTTP_TRAJ_PARAM_ADJ_QC = dataAdjQc;
      g_NTTP_TRAJ_PARAM_DATA_MODE = paramDataMode;
   end
end

% ------------------------------------------------------------------------------
% Retrieve PROF data from NetCDf files.
%
% SYNTAX :
%   get_prof_data
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
%   03/06/2024 - RNU - creation
% ------------------------------------------------------------------------------
function get_prof_data

global g_NTTP_NC_DIR;
global g_NTTP_FLOAT_NUM;
global g_NTTP_PARAM_NAME;
global g_NTTP_PARAM_TYPE;
global g_NTTP_PARAM_LIST;

global g_NTTP_PRES_FILL_VAL;
global g_NTTP_PARAM_FILL_VAL;

global g_NTTP_PROF_DATA;


profDirName = [g_NTTP_NC_DIR '/' num2str(g_NTTP_FLOAT_NUM) '/profiles/'];
if ~(exist(profDirName, 'dir') == 7)
   fprintf('INFO: Float %d: Directory not found: %s\n', ...
      g_NTTP_FLOAT_NUM, profDirName);
else

   % retrieve data from PROF files
   floatCFilesD = dir([profDirName '/' sprintf('D%d_*.nc', g_NTTP_FLOAT_NUM)]);
   floatCFilesR = dir([profDirName '/' sprintf('R%d_*.nc', g_NTTP_FLOAT_NUM)]);
   floatBFilesD = dir([profDirName '/' sprintf('BD%d_*.nc', g_NTTP_FLOAT_NUM)]);
   floatBFilesR = dir([profDirName '/' sprintf('BR%d_*.nc', g_NTTP_FLOAT_NUM)]);
   if (g_NTTP_PARAM_TYPE == 'c')
      floatFiles = [floatCFilesD; floatCFilesR];
   else
      floatFiles = [floatBFilesD; floatBFilesR; floatCFilesD; floatCFilesR];
   end

   cProfData = [];
   bProfData = [];
   for idFile = 1:length(floatFiles)

      floatFileName = floatFiles(idFile).name;
      floatFilePathName = [profDirName '/' floatFileName];

      % retrieve data from file
      wantedVars = [ ...
         {'FORMAT_VERSION'} ...
         {'STATION_PARAMETERS'} ...
         {'CYCLE_NUMBER'} ...
         {'DIRECTION'} ...
         {'DATA_MODE'} ...
         {'PARAMETER_DATA_MODE'} ...
         {'JULD'} ...
         {'JULD_QC'} ...
         {'VERTICAL_SAMPLING_SCHEME'} ...
         ];
      for idParam = 1:length(g_NTTP_PARAM_LIST)
         paramName = g_NTTP_PARAM_LIST{idParam};
         wantedVars = [wantedVars ...
            {paramName} {[paramName '_QC']} ...
            {[paramName '_ADJUSTED']} {[paramName '_ADJUSTED_QC']} {[paramName '_ADJUSTED_ERROR']} ...
            ];
      end
      ncData = get_data_from_nc_file(floatFilePathName, wantedVars);

      formatVersion = strtrim(get_data_from_name('FORMAT_VERSION', ncData)');
      % check the file format version
      if (~strcmp(formatVersion, '3.1'))
         fprintf('INFO: Input mono prof file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s) - ignored\n', ...
            g_NTTP_FLOAT_NUM, formatVersion);
         continue
      end

      stationParameters = get_data_from_name('STATION_PARAMETERS', ncData);
      cycleNumber = get_data_from_name('CYCLE_NUMBER', ncData);
      direction = get_data_from_name('DIRECTION', ncData);
      profDataMode = get_data_from_name('DATA_MODE', ncData);
      parameterDataMode = get_data_from_name('PARAMETER_DATA_MODE', ncData);
      juld = get_data_from_name('JULD', ncData);
      juldQc = get_data_from_name('JULD_QC', ncData);
      vertSampScheme = get_data_from_name('VERTICAL_SAMPLING_SCHEME', ncData);

      %%%%%%%%%%%%%%
      % core profile
      if ((floatFileName(1) == 'D') || (floatFileName(1) == 'R'))

         if (g_NTTP_PARAM_TYPE == 'c')
            profIdList = [];
            [~, nParam, nProf] = size(stationParameters);
            for idProf = 1:nProf
               for idParam = 1:nParam
                  paramName = strtrim(stationParameters(:, idParam, idProf)');
                  if (strcmp(paramName, g_NTTP_PARAM_NAME))
                     profIdList = [profIdList idProf];
                  end
               end
            end
         else
            profDir = 2;
            if (direction(1) == 'D')
               profDir = 1;
            end
            idF = find( ...
               ([bProfData{:, 1}] == cycleNumber(1)) & ...
               ([bProfData{:, 2}] == profDir));
            profIdList = [bProfData{idF, 3}];
         end

         for idProf = profIdList
            % temporary ignore descent profile
            if (direction(idProf) == 'D')
               continue
            end
            prof = [];
            prof.proId = idProf;
            prof.cycleNumber = cycleNumber(idProf);
            profDir = 2;
            if (direction(idProf) == 'D')
               profDir = 1;
            end
            prof.direction = profDir;
            prof.dataMode = profDataMode(idProf);
            prof.juld = juld(idProf);
            prof.juldQc = juldQc(idProf);
            prof.vss = vertSampScheme(:, idProf)';

            for idParam = 1:length(g_NTTP_PARAM_LIST)
               if ((g_NTTP_PARAM_TYPE == 'b') && (idParam > 1))
                  break
               end
               paramName = g_NTTP_PARAM_LIST{idParam};
               paramNameQc = [paramName '_QC'];
               paramAdjName = [paramName '_ADJUSTED'];
               paramAdjNameQc = [paramAdjName '_QC'];
               paramAdjErrName = [paramName '_ADJUSTED_ERROR'];
               paramData = get_data_from_name(paramName, ncData);
               if (idParam == 1)
                  if (g_NTTP_PARAM_TYPE == 'c')
                     data = repmat([g_NTTP_PRES_FILL_VAL g_NTTP_PARAM_FILL_VAL], size(paramData, 1), 1);
                     dataQc = repmat(' ', size(paramData, 1), 2);
                     dataAdj = repmat([g_NTTP_PRES_FILL_VAL g_NTTP_PARAM_FILL_VAL], size(paramData, 1), 1);
                     dataAdjQc = repmat(' ', size(paramData, 1), 2);
                     dataAdjErr = repmat([g_NTTP_PRES_FILL_VAL g_NTTP_PARAM_FILL_VAL], size(paramData, 1), 1);
                     dataMode = repmat(' ', size(paramData, 1), 2);
                  else
                     data = repmat(g_NTTP_PRES_FILL_VAL, size(paramData, 1), 1);
                     dataQc = repmat(' ', size(paramData, 1), 1);
                     dataAdj = repmat(g_NTTP_PRES_FILL_VAL, size(paramData, 1), 1);
                     dataAdjQc = repmat(' ', size(paramData, 1), 1);
                     dataAdjErr = repmat(g_NTTP_PRES_FILL_VAL, size(paramData, 1), 1);
                     dataMode = repmat(' ', size(paramData, 1), 1);
                  end
               end
               data(:, idParam) = paramData(:, idProf);
               paramDataQc = get_data_from_name(paramNameQc, ncData);
               dataQc(:, idParam) = paramDataQc(:, idProf);
               paramDataAdj = get_data_from_name(paramAdjName, ncData);
               dataAdj(:, idParam) = paramDataAdj(:, idProf);
               paramDataAdjQc = get_data_from_name(paramAdjNameQc, ncData);
               dataAdjQc(:, idParam) = paramDataAdjQc(:, idProf);
               paramDataAdjErr = get_data_from_name(paramAdjErrName, ncData);
               dataAdjErr(:, idParam) = paramDataAdjErr(:, idProf);
               dataMode((dataQc(:, idParam) ~= ' '), idParam) = prof.dataMode;
            end

            data(data(:, 1) == g_NTTP_PRES_FILL_VAL, 1) = nan;
            if (g_NTTP_PARAM_TYPE == 'c')
               data(data(:, 2) == g_NTTP_PARAM_FILL_VAL, 2) = nan;
            end
            dataAdj(dataAdj(:, 1) == g_NTTP_PRES_FILL_VAL, 1) = nan;
            if (g_NTTP_PARAM_TYPE == 'c')
               dataAdj(dataAdj(:, 2) == g_NTTP_PARAM_FILL_VAL, 2) = nan;
            end
            dataAdjErr(dataAdjErr(:, 1) == g_NTTP_PRES_FILL_VAL, 1) = nan;
            if (g_NTTP_PARAM_TYPE == 'c')
               dataAdjErr(dataAdjErr(:, 2) == g_NTTP_PARAM_FILL_VAL, 2) = nan;
            end
            prof.data = data;
            prof.dataQc = dataQc;
            prof.dataAdj = dataAdj;
            prof.dataAdjQc = dataAdjQc;
            prof.dataAdjErr = dataAdjErr;
            prof.dataMode = dataMode;

            cProfData = [cProfData; ...
               {prof.cycleNumber} {prof.direction} {prof.proId} {prof} ];
         end
      end

      %%%%%%%%%%%%%%
      % bgc profile
      if (floatFileName(1) == 'B')

         profIdList = [];
         [~, nParam, nProf] = size(stationParameters);
         for idProf = 1:nProf
            for idParam = 1:nParam
               paramName = strtrim(stationParameters(:, idParam, idProf)');
               if (strcmp(paramName, g_NTTP_PARAM_NAME))
                  profIdList = [profIdList idProf];
               end
            end
         end

         for idProf = profIdList
            % temporary ignore descent profile
            if (direction(idProf) == 'D')
               continue
            end
            prof = [];
            prof.proId = idProf;
            prof.cycleNumber = cycleNumber(idProf);
            profDir = 2;
            if (direction(idProf) == 'D')
               profDir = 1;
            end
            prof.direction = profDir;
            prof.dataMode = profDataMode(idProf);
            prof.juld = juld(idProf);
            prof.juldQc = juldQc(idProf);
            prof.vss = vertSampScheme(:, idProf)';

            for idParam = 1:length(g_NTTP_PARAM_LIST)
               paramName = g_NTTP_PARAM_LIST{idParam};
               paramNameQc = [paramName '_QC'];
               paramAdjName = [paramName '_ADJUSTED'];
               paramAdjNameQc = [paramAdjName '_QC'];
               paramAdjErrName = [paramName '_ADJUSTED_ERROR'];
               paramData = get_data_from_name(paramName, ncData);
               if (idParam == 1)
                  data = repmat([g_NTTP_PRES_FILL_VAL g_NTTP_PARAM_FILL_VAL], size(paramData, 1), 1);
                  dataQc = repmat(' ', size(paramData, 1), 2);
                  dataAdj = repmat([g_NTTP_PRES_FILL_VAL g_NTTP_PARAM_FILL_VAL], size(paramData, 1), 1);
                  dataAdjQc = repmat(' ', size(paramData, 1), 2);
                  dataAdjErr = repmat([g_NTTP_PRES_FILL_VAL g_NTTP_PARAM_FILL_VAL], size(paramData, 1), 1);
                  dataMode = repmat(' ', size(paramData, 1), 2);
               end
               data(:, idParam) = paramData(:, idProf);
               paramDataQc = get_data_from_name(paramNameQc, ncData);
               if (~isempty(paramDataQc))
                  dataQc(:, idParam) = paramDataQc(:, idProf);
               end
               paramDataAdj = get_data_from_name(paramAdjName, ncData);
               if (~isempty(paramDataAdj))
                  dataAdj(:, idParam) = paramDataAdj(:, idProf);
               end
               paramDataAdjQc = get_data_from_name(paramAdjNameQc, ncData);
               if (~isempty(paramDataAdjQc))
                  dataAdjQc(:, idParam) = paramDataAdjQc(:, idProf);
               end
               paramDataAdjErr = get_data_from_name(paramAdjErrName, ncData);
               if (~isempty(paramDataAdjErr))
                  dataAdjErr(:, idParam) = paramDataAdjErr(:, idProf);
               end
               if (idParam == 2)
                  paramDataMode = '';
                  for idP = 1:nParam
                     parName = strtrim(stationParameters(:, idP, idProf)');
                     if (strcmp(parName, paramName))
                        paramDataMode = parameterDataMode(idP, idProf)';
                        break
                     end
                  end
                  if (~isempty(paramDataMode))
                     dataMode((dataQc(:, idParam) ~= ' '), idParam) = paramDataMode;
                  else
                     fprintf('ERROR: Anomaly\n');
                  end
               end
            end

            data(data(:, 1) == g_NTTP_PRES_FILL_VAL, 1) = nan;
            data(data(:, 2) == g_NTTP_PARAM_FILL_VAL, 2) = nan;
            dataAdj(dataAdj(:, 1) == g_NTTP_PRES_FILL_VAL, 1) = nan;
            dataAdj(dataAdj(:, 2) == g_NTTP_PARAM_FILL_VAL, 2) = nan;
            dataAdjErr(dataAdjErr(:, 1) == g_NTTP_PRES_FILL_VAL, 1) = nan;
            dataAdjErr(dataAdjErr(:, 2) == g_NTTP_PARAM_FILL_VAL, 2) = nan;
            prof.data = data;
            prof.dataQc = dataQc;
            prof.dataAdj = dataAdj;
            prof.dataAdjQc = dataAdjQc;
            prof.dataAdjErr = dataAdjErr;
            prof.dataMode = dataMode;

            bProfData = [bProfData; ...
               {prof.cycleNumber} {prof.direction} {prof.proId} {prof} ];
         end
      end
   end

   % concat primary and NS profiles and merge BGC data in CORE ones
   g_NTTP_PROF_DATA = concat_profile(cProfData, bProfData);
end

return

% ------------------------------------------------------------------------------
% Concat primary and NS profiles (and copy BGC data in core profiles).
%
% SYNTAX :
%   [o_profileData] = concat_profile(a_cProfileData, a_bProfileData)
%
% INPUT PARAMETERS :
%   a_cProfileData : input core profile data
%   a_bProfileData : input BGC profile data
%
% OUTPUT PARAMETERS :
%   o_profileData : output profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/06/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profileData] = concat_profile(a_cProfileData, a_bProfileData)

% output parameters initialization
o_profileData = [];


%%%%%%%%%%%%%%%%%%%%%%
% concatenate profiles

% one loop for core profiles, one loop for bgc profiles
for idLoop = 1:2
   if (idLoop == 1)
      profileData = a_cProfileData;
   else
      if (~isempty(a_bProfileData))
         profileData = a_bProfileData;
      else
         break
      end
   end

   cyNumList = [profileData{:, 1}];
   dirList = [profileData{:, 2}];
   uCyNumList = unique(cyNumList);
   uDirList = unique(dirList);
   idToDel = [];
   for cyNum = uCyNumList
      for direction = uDirList
         idForCy = find((cyNumList == cyNum) & (dirList == direction));
         if (length(idForCy) == 2)
            prof1 = profileData{idForCy(1), 4};
            prof2 = profileData{idForCy(2), 4};
            if (strncmp(prof1.vss, 'Primary sampling:', length('Primary sampling:')) && ...
                  strncmp(prof2.vss, 'Near-surface sampling:', length('Near-surface sampling:')))
               idPrim = idForCy(1);
               idNs = idForCy(2);
            elseif (strncmp(prof2.vss, 'Primary sampling:', length('Primary sampling:')) && ...
                  strncmp(prof1.vss, 'Near-surface sampling:', length('Near-surface sampling:')))
               idPrim = idForCy(2);
               idNs = idForCy(1);
            else
               fprintf('ERROR: Anomaly\n');
               continue
            end

            profPrim = profileData{idPrim, 4};
            profNs = profileData{idNs, 4};

            dataNs = profNs.data;
            while (sum(isnan(dataNs(end, :))) == size(dataNs, 2))
               dataNs(end, :) = [];
            end
            measId = 1:size(dataNs, 1);
            profPrim.data = cat(1, profNs.data(measId, :), profPrim.data);
            profPrim.dataQc = cat(1, profNs.dataQc(measId, :), profPrim.dataQc);
            profPrim.dataAdj = cat(1, profNs.dataAdj(measId, :), profPrim.dataAdj);
            profPrim.dataAdjQc = cat(1, profNs.dataAdjQc(measId, :), profPrim.dataAdjQc);
            profPrim.dataAdjErr = cat(1, profNs.dataAdjErr(measId, :), profPrim.dataAdjErr);
            profPrim.dataMode = cat(1, profNs.dataMode(measId, :), profPrim.dataMode);
            profPrim.vss = 'Concatenated';

            profileData{idPrim, 4} = profPrim;
            idToDel = [idToDel; idNs];
         elseif (length(idForCy) > 2)
            fprintf('ERROR: Anomaly\n');
         end
      end
   end
   profileData(idToDel, :) = [];

   if (idLoop == 1)
      a_cProfileData = profileData;
   else
      a_bProfileData = profileData;
   end
end

o_profileData = a_cProfileData;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% copy BGC parameter measurement in core data
if (~isempty(a_bProfileData))
   cyNumList = [a_cProfileData{:, 1}];
   dirList = [a_cProfileData{:, 2}];
   profIdList = [a_cProfileData{:, 3}];
   uCyNumList = unique(cyNumList);
   uDirList = unique(dirList);
   uProfIdList = unique(profIdList);
   for cyNum = uCyNumList
      for direction = uDirList
         for profId = uProfIdList
            idFc = find((cyNumList == cyNum) & (dirList == direction) & (profIdList == profId));
            if (~isempty(idFc))
               idFb = find( ...
                  ([a_bProfileData{:, 1}] == cyNum) & ...
                  ([a_bProfileData{:, 2}] == direction) & ...
                  ([a_bProfileData{:, 3}] == profId));
               if (~isempty(idFb))
                  prof = o_profileData{idFc, 4};
                  profB = a_bProfileData{idFb, 4};

                  prof.data = cat(2, prof.data, profB.data(:, 2));
                  prof.dataQc = cat(2, prof.dataQc, profB.dataQc(:, 2));
                  prof.dataAdj = cat(2, prof.dataAdj, profB.dataAdj(:, 2));
                  prof.dataAdjQc = cat(2, prof.dataAdjQc, profB.dataAdjQc(:, 2));
                  prof.dataAdjErr = cat(2, prof.dataAdjErr, profB.dataAdjErr(:, 2));
                  prof.dataMode = cat(2, prof.dataMode, profB.dataMode(:, 2));

                  o_profileData{idFc, 4} = prof;
               else
                  fprintf('ERROR: Anomaly\n');
               end
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Callback to manage plots:
%   - right Arrow : next float
%   - left Arrow  : previous float
%   - down Arrow  : next set of profiles
%   - up Arrow    : previous set of profiles
%   - "-"         : decrease the number of profiles per set
%   - "+"         : increase the number of profiles per set
%   - "a"         : plot all the profiles of the float
%   - "d"         : back to plot the default number of profiles per set
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/03/2014 - RNU - creation
% ------------------------------------------------------------------------------
function change_plot(a_src, a_eventData)

global g_NTTP_FIG_HANDLE;
global g_NTTP_ALL_PROF_MEAS;
global g_NTTP_RT_PROF_MEAS;
global g_NTTP_PLOT_ERR;
global g_NTTP_PRINT;

global g_NTTP_ID_FLOAT g_NTTP_FLOAT_LIST;
global g_NTTP_idCycle g_NTTP_nbCycles;
global g_NTTP_cycles;

global g_NTTP_LAST_CMD;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% exit
if (strcmp(a_eventData.Key, 'escape'))
   set(g_NTTP_FIG_HANDLE, 'KeyPressFcn', '');
   close(g_NTTP_FIG_HANDLE);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % previous float
elseif (strcmp(a_eventData.Key, 'leftarrow'))
   plot_param(mod(g_NTTP_ID_FLOAT-1, length(g_NTTP_FLOAT_LIST)), 0);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % next float
elseif (strcmp(a_eventData.Key, 'rightarrow'))
   plot_param(mod(g_NTTP_ID_FLOAT+1, length(g_NTTP_FLOAT_LIST)), 0);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % previous cycle
elseif (strcmp(a_eventData.Key, 'uparrow'))
   g_NTTP_LAST_CMD = -1;
   plot_param(g_NTTP_ID_FLOAT, mod(g_NTTP_idCycle-1, length(g_NTTP_cycles)));

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % next cycle
elseif (strcmp(a_eventData.Key, 'downarrow'))
   g_NTTP_LAST_CMD = 1;
   plot_param(g_NTTP_ID_FLOAT, mod(g_NTTP_idCycle+1, length(g_NTTP_cycles)));

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot all the profile measurements
elseif (strcmp(a_eventData.Key, 'a'))
   if (g_NTTP_ALL_PROF_MEAS == 0)
      g_NTTP_ALL_PROF_MEAS = 1;
   else
      g_NTTP_ALL_PROF_MEAS = 0;
   end
   fprintf('Plot all profile measurements: %d\n', g_NTTP_ALL_PROF_MEAS);
   plot_param(g_NTTP_ID_FLOAT, g_NTTP_idCycle);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot RT measurements
elseif (strcmp(a_eventData.Key, 'r'))
   if (g_NTTP_RT_PROF_MEAS == 0)
      g_NTTP_RT_PROF_MEAS = 1;
   else
      g_NTTP_RT_PROF_MEAS = 0;
   end
   fprintf('Plot RT profile measurements: %d\n', g_NTTP_RT_PROF_MEAS);
   plot_param(g_NTTP_ID_FLOAT, g_NTTP_idCycle);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot error on adjusted measurements
elseif (strcmp(a_eventData.Key, 'e'))
   if (g_NTTP_PLOT_ERR == 0)
      g_NTTP_PLOT_ERR = 1;
   else
      g_NTTP_PLOT_ERR = 0;
   end
   fprintf('Plot error on adjusted measurements: %d\n', g_NTTP_PLOT_ERR);
   plot_param(g_NTTP_ID_FLOAT, g_NTTP_idCycle);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % pdf output file generation
elseif (strcmp(a_eventData.Key, 'p'))
   g_NTTP_PRINT = 1;
   plot_param(g_NTTP_ID_FLOAT, g_NTTP_idCycle);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % write help and current configuration
elseif (strcmp(a_eventData.Key, 'h'))
   fprintf('Plot management:\n');
   fprintf('   Right Arrow: next float\n');
   fprintf('   Left Arrow : previous float\n');
   fprintf('   Down Arrow : next cycle\n');
   fprintf('   Up Arrow   : previous cycle\n');
   fprintf('Plot:\n');
   fprintf('   a  : plot all profile measurements\n');
   fprintf('   r  : plot RT measurements\n');
   fprintf('   e  : plot error on adjusted measurements\n');
   fprintf('Misc:\n');
   fprintf('   p: pdf output file generation\n');
   fprintf('   h: write help and current configuration\n');
   fprintf('Escape: exit\n\n');

   fprintf('Current configuration:\n');
   fprintf('Plot all profile measurements: %d\n', g_NTTP_ALL_PROF_MEAS);
   fprintf('Plot RT profile measurements: %d\n', g_NTTP_RT_PROF_MEAS);
   fprintf('Plot error on adjusted measurements: %d\n', g_NTTP_PLOT_ERR);
end

return
