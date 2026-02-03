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

global g_NTTP_NC_TRAJ_DIR;
global g_NTTP_NC_PROF_DIR;
global g_NTTP_PDF_DIR;
global g_NTTP_FIG_HANDLE;
global g_NTTP_PRINT;
global g_NTTP_ALL_PROF_MEAS;
global g_NTTP_RT_PROF_MEAS;
global g_NTTP_PLOT_ERR;
global g_NTTP_PLOT_THETA;
global g_NTTP_LOAD_DATA;

global g_NTTP_CPT_LOOP;

global g_NTTP_PROF_SIZE;

global g_NTTP_ID_FLOAT;
global g_NTTP_FLOAT_LIST;

global g_NTTP_PARAM_NAME;
global g_NTTP_MC_LIST;

% global measurement codes
global g_MC_DriftAtPark;
global g_MC_DescProf;
global g_MC_AscProf;
global g_MC_LastAscPumpedCtd;

g_NTTP_PARAM_NAME = 'PSAL';
% g_NTTP_PARAM_NAME = 'TEMP';
g_NTTP_MC_LIST = [g_MC_DriftAtPark];
% g_NTTP_MC_LIST = [g_MC_AscProf];
% g_NTTP_MC_LIST = [g_MC_DescProf];
% g_NTTP_MC_LIST = [g_MC_LastAscPumpedCtd];

% top directory of NetCDF TRAJ DM files to plot
g_NTTP_NC_TRAJ_DIR = 'C:\Users\jprannou\_DATA\OUT\TRAJ_DM_2024\';
g_NTTP_NC_TRAJ_DIR = 'C:\Users\jprannou\_DATA\TRAJ_DM_2024\TRAJ_DM_2024_OUT\';

% top directory of NetCDF PROF DM files to plot
g_NTTP_NC_PROF_DIR = 'C:\Users\jprannou\_DATA\TRAJ_DM_2024\snapshot-202405_arvor_ir_in_andro_325\';

% directory to store pdf output
g_NTTP_PDF_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\pdf\';

% default list of floats to plot
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ANDRO_2_TRAJ-DM\Decomptes_20240621\arvor_in_andro_with_prof_DM.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ANDRO_2_TRAJ-DM\Decomptes_20240621\arvor_in_andro_with_prof_DM_psal_adj_not_null.txt';


% to prevent infinite loop
g_NTTP_CPT_LOOP = 0;

% no pdf generation
g_NTTP_PRINT = 0;

% plot only reduced part of the profiles
g_NTTP_ALL_PROF_MEAS = 0;

% plot theta-s
g_NTTP_PLOT_THETA = 0;

% plot RT profile measurements
g_NTTP_RT_PROF_MEAS = 0;
g_NTTP_LOAD_DATA = 0;

% plot error on adjusted measurements
g_NTTP_PLOT_ERR = 0;

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
fprintf('   t  : plot theta-s data\n');
fprintf('   r  : plot RT measurements\n');
fprintf('   e  : plot error on adjusted measurements\n');
fprintf('Misc:\n');
fprintf('   p: pdf output file generation\n');
fprintf('   h: write help and current configuration\n');
fprintf('Escape: exit\n\n');

fprintf('Current configuration:\n');
fprintf('Plot all profile measurements: %d\n', g_NTTP_ALL_PROF_MEAS);
fprintf('Plot theta-s instead of pres-s: %d\n', g_NTTP_PLOT_THETA);
fprintf('Plot RT profile measurements: %d\n', g_NTTP_RT_PROF_MEAS);
fprintf('Plot error on adjusted measurements: %d\n', g_NTTP_PLOT_ERR);

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
global g_NTTP_PLOT_THETA;
global g_NTTP_LOAD_DATA;

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
global g_NTTP_TRAJ_PRES_ADJ_QC;
global g_NTTP_TRAJ_PRES_DATA_MODE;

global g_NTTP_TRAJ_PARAM;
global g_NTTP_TRAJ_PARAM_QC;
global g_NTTP_TRAJ_PARAM_ADJ;
global g_NTTP_TRAJ_PARAM_ADJ_QC;
global g_NTTP_TRAJ_PARAM_ADJ_ERR;
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

if ((a_idFloat ~= g_NTTP_ID_FLOAT) || g_NTTP_LOAD_DATA)

   clc;

   % a new float is wanted
   g_NTTP_ID_FLOAT = a_idFloat;
   g_NTTP_FLOAT_NUM = g_NTTP_FLOAT_LIST(a_idFloat+1);
   g_NTTP_LAST_CMD = 1;
   g_NTTP_cycles = [];
   g_NTTP_CPT_LOOP = 0;
   g_NTTP_LOAD_DATA = 0;

   % profile pressure interval above and below TRAJ measurements
   if (~ g_NTTP_PLOT_THETA)
      g_NTTP_PROF_SIZE = 150;
   else
      g_NTTP_PROF_SIZE = 0.5;
   end
   
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

xTrajData = [];
xTrajDataQc = [];
xTrajDataAdj = [];
xTrajDataAdjQc = [];
xTrajDataAdjErr = [];
yTrajData = [];
yTrajDataQc = [];
yTrajDataAdj = [];
yTrajDataAdjQc = [];
idNoDef1 = [];
idNoDef12 = [];

idMeas = find((g_NTTP_TRAJ_CY_NUM == g_NTTP_cycles(g_NTTP_idCycle+1)) & ...
   (g_NTTP_TRAJ_PARAM_DATA_MODE == 'D') & ...
   ismember(g_NTTP_TRAJ_MC, g_NTTP_MC_LIST));
if (~isempty(idMeas))
   trajPres = g_NTTP_TRAJ_PRES(idMeas);
   trajPresQc = g_NTTP_TRAJ_PRES_QC(idMeas);
   trajPresAdj = g_NTTP_TRAJ_PRES_ADJ(idMeas);
   trajPresAdjQc = g_NTTP_TRAJ_PRES_ADJ_QC(idMeas);
   trajPresDataMode = g_NTTP_TRAJ_PRES_DATA_MODE(idMeas);
   trajParam = g_NTTP_TRAJ_PARAM(idMeas);
   trajParamQc = g_NTTP_TRAJ_PARAM_QC(idMeas);
   trajParamAdj = g_NTTP_TRAJ_PARAM_ADJ(idMeas);
   trajParamAdjQc = g_NTTP_TRAJ_PARAM_ADJ_QC(idMeas);
   trajParamAdjErr = g_NTTP_TRAJ_PARAM_ADJ_ERR(idMeas);
   trajParamDataMode = g_NTTP_TRAJ_PARAM_DATA_MODE(idMeas);

   % idNoDef1 = find(~isnan(trajPresAdj) & ~isnan(trajParamAdj) & ...
   %    (trajPresDataMode == 'D') & (trajParamDataMode == 'D') & ...
   %    (((trajPresAdjQc == g_decArgo_qcStrGood) | (trajPresAdjQc == g_decArgo_qcStrProbablyGood)) & ...
   %    ((trajParamAdjQc == g_decArgo_qcStrGood) | (trajParamAdjQc == g_decArgo_qcStrProbablyGood))));
   idNoDef1 = find(~isnan(trajPresAdj) & ~isnan(trajParamAdj) & ...
      (trajPresDataMode == 'D') & (trajParamDataMode == 'D'));
   xTrajDataAdj = trajParamAdj(idNoDef1);
   xTrajDataAdjQc = trajParamAdjQc(idNoDef1);
   xTrajDataAdjErr = trajParamAdjErr(idNoDef1);
   yTrajDataAdj = trajPresAdj(idNoDef1);
   yTrajDataAdjQc = trajPresAdjQc(idNoDef1);
   minPres = min(yTrajDataAdj);
   maxPres = max(yTrajDataAdj);

   if (~isempty(idNoDef1))
      if (g_NTTP_RT_PROF_MEAS == 1)
         idNoDef12 = find(~isnan(trajPres) & ~isnan(trajParam));
         xTrajData = trajParam(idNoDef12);
         xTrajDataQc = trajParamQc(idNoDef12);
         yTrajData = trajPres(idNoDef12);
         yTrajDataQc = trajPresQc(idNoDef12);
      end

      if (g_NTTP_ALL_PROF_MEAS == 0)
         idP = find((yTrajDataAdj <= maxPres + g_NTTP_PROF_SIZE) & (yTrajDataAdj >= minPres - g_NTTP_PROF_SIZE));
         xTrajDataAdj = xTrajDataAdj(idP);
         xTrajDataAdjQc = xTrajDataAdjQc(idP);
         xTrajDataAdjErr = xTrajDataAdjErr(idP);
         yTrajDataAdj = yTrajDataAdj(idP);
         yTrajDataAdjQc = yTrajDataAdjQc(idP);

         if (~isempty(idNoDef12))
            idP = find((yTrajData <= maxPres + g_NTTP_PROF_SIZE) & (yTrajData >= minPres - g_NTTP_PROF_SIZE));
            xTrajData = xTrajData(idP);
            xTrajDataQc = xTrajDataQc(idP);
            yTrajData = yTrajData(idP);
            yTrajDataQc = yTrajDataQc(idP);
         end
      end
   end
end

xProfPrevData = [];
xProfPrevDataQc = [];
xProfPrevDataAdj = [];
xProfPrevDataAdjQc = [];
xProfPrevDataAdjErr = [];
yProfPrevData = [];
yProfPrevDataQc = [];
yProfPrevDataAdj = [];
yProfPrevDataAdjQc = [];
idNoDef22 = [];

xProfCurData = [];
xProfCurDataQc = [];
xProfCurDataAdj = [];
xProfCurDataAdjQc = [];
xProfCurDataAdjErr = [];
yProfCurData = [];
yProfCurDataQc = [];
yProfCurDataAdj = [];
yProfCurDataAdjQc = [];
idNoDef32 = [];

if (~isempty(idNoDef1))

   idProfPrev = find([g_NTTP_PROF_DATA{:, 1}] == g_NTTP_cycles(g_NTTP_idCycle+1) - 1);
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

      % idNoDef2 = find(~isnan(profPrevPresAdj) & ~isnan(profPrevParamAdj) & ...
      %    (profPrevPresDataMode == 'D') & (profPrevParamDataMode == 'D') & ...
      %    (((profPrevPresAdjQc == g_decArgo_qcStrGood) | (profPrevPresAdjQc == g_decArgo_qcStrProbablyGood)) & ...
      %    ((profPrevParamAdjQc == g_decArgo_qcStrGood) | (profPrevParamAdjQc == g_decArgo_qcStrProbablyGood))));
      idNoDef2 = find(~isnan(profPrevPresAdj) & ~isnan(profPrevParamAdj) & ...
         (profPrevPresDataMode == 'D') & (profPrevParamDataMode == 'D'));
      xProfPrevDataAdj = profPrevParamAdj(idNoDef2);
      xProfPrevDataAdjQc = profPrevParamAdjQc(idNoDef2);
      xProfPrevDataAdjErr = profPrevParamAdjErr(idNoDef2);
      yProfPrevDataAdj = profPrevPresAdj(idNoDef2);
      yProfPrevDataAdjQc = profPrevPresAdjQc(idNoDef2);

      if (~isempty(idNoDef2))
         if (g_NTTP_RT_PROF_MEAS == 1)
            idNoDef22 = find(~isnan(profPrevPres) & ~isnan(profPrevParam));
            xProfPrevData = profPrevParam(idNoDef22);
            xProfPrevDataQc = profPrevParamQc(idNoDef22);
            yProfPrevData = profPrevPres(idNoDef22);
            yProfPrevDataQc = profPrevPresQc(idNoDef22);
         end

         if (g_NTTP_ALL_PROF_MEAS == 0)
            idP = find((yProfPrevDataAdj <= maxPres + g_NTTP_PROF_SIZE) & (yProfPrevDataAdj >= minPres - g_NTTP_PROF_SIZE));
            xProfPrevDataAdj = xProfPrevDataAdj(idP);
            xProfPrevDataAdjQc = xProfPrevDataAdjQc(idP);
            xProfPrevDataAdjErr = xProfPrevDataAdjErr(idP);
            yProfPrevDataAdj = yProfPrevDataAdj(idP);
            yProfPrevDataAdjQc = yProfPrevDataAdjQc(idP);

            if (~isempty(idNoDef22))
               idP = find((yProfPrevData <= maxPres + g_NTTP_PROF_SIZE) & (yProfPrevData >= minPres - g_NTTP_PROF_SIZE));
               xProfPrevData = xProfPrevData(idP);
               xProfPrevDataQc = xProfPrevDataQc(idP);
               yProfPrevData = yProfPrevData(idP);
               yProfPrevDataQc = yProfPrevDataQc(idP);
            end
         end
      end
   end

   idProfCur = find([g_NTTP_PROF_DATA{:, 1}] == g_NTTP_cycles(g_NTTP_idCycle+1));
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

      % idNoDef3 = find(~isnan(profCurPresAdj) & ~isnan(profCurParamAdj) & ...
      %    (profCurPresDataMode == 'D') & (profCurParamDataMode == 'D') & ...
      %    (((profCurPresAdjQc == g_decArgo_qcStrGood) | (profCurPresAdjQc == g_decArgo_qcStrProbablyGood)) & ...
      %    ((profCurParamAdjQc == g_decArgo_qcStrGood) | (profCurParamAdjQc == g_decArgo_qcStrProbablyGood))));
      idNoDef3 = find(~isnan(profCurPresAdj) & ~isnan(profCurParamAdj) & ...
         (profCurPresDataMode == 'D') & (profCurParamDataMode == 'D'));
      xProfCurDataAdj = profCurParamAdj(idNoDef3);
      xProfCurDataAdjQc = profCurParamAdjQc(idNoDef3);
      xProfCurDataAdjErr = profCurParamAdjErr(idNoDef3);
      yProfCurDataAdj = profCurPresAdj(idNoDef3);
      yProfCurDataAdjQc = profCurPresAdjQc(idNoDef3);

      if (~isempty(idNoDef3))
         if (g_NTTP_RT_PROF_MEAS == 1)
            idNoDef32 = find(~isnan(profCurPres) & ~isnan(profCurParam));
            xProfCurData = profCurParam(idNoDef32);
            xProfCurDataQc = profCurParamQc(idNoDef32);
            yProfCurData = profCurPres(idNoDef32);
            yProfCurDataQc = profCurPresQc(idNoDef32);
         end

         if (g_NTTP_ALL_PROF_MEAS == 0)
            idP = find((yProfCurDataAdj <= maxPres + g_NTTP_PROF_SIZE) & (yProfCurDataAdj >= minPres - g_NTTP_PROF_SIZE));
            xProfCurDataAdj = xProfCurDataAdj(idP);
            xProfCurDataAdjQc = xProfCurDataAdjQc(idP);
            xProfCurDataAdjErr = xProfCurDataAdjErr(idP);
            yProfCurDataAdj = yProfCurDataAdj(idP);
            yProfCurDataAdjQc = yProfCurDataAdjQc(idP);

            if (~isempty(idNoDef32))
               idP = find((yProfCurData <= maxPres + g_NTTP_PROF_SIZE) & (yProfCurData >= minPres - g_NTTP_PROF_SIZE));
               xProfCurData = xProfCurData(idP);
               xProfCurDataQc = xProfCurDataQc(idP);
               yProfCurData = yProfCurData(idP);
               yProfCurDataQc = yProfCurDataQc(idP);
            end
         end
      end
   end
end

if (isempty(yTrajDataAdj))
   label = sprintf('%02d/%02d : float #%d cycle #%d: %s - NO DATA', ...
      a_idFloat+1, ...
      length(g_NTTP_FLOAT_LIST), ...
      g_NTTP_FLOAT_LIST(a_idFloat+1), ...
      g_NTTP_cycles(a_idCycle+1), ...
      regexprep(g_NTTP_PARAM_NAME, '_', ' '));
   % title(label);
   fprintf('%s\n', label);
   g_NTTP_CPT_LOOP = g_NTTP_CPT_LOOP + 1;
   if (g_NTTP_CPT_LOOP <= length(g_NTTP_cycles))
      %    label = sprintf('%02d/%02d : float #%d: %s - NO DATA', ...
      %       a_idFloat+1, ...
      %       length(g_NTTP_FLOAT_LIST), ...
      %       g_NTTP_FLOAT_LIST(a_idFloat+1), ...
      %       regexprep(g_NTTP_PARAM_NAME, '_', ' '));
      %    fprintf('%s\n', label);
      % else
      plot_param(g_NTTP_ID_FLOAT, mod(g_NTTP_idCycle+g_NTTP_LAST_CMD, length(g_NTTP_cycles)));
   end
   return
end

g_NTTP_CPT_LOOP = 0;

minParam = min([xTrajDataAdj-xTrajDataAdjErr; xTrajData; xProfPrevDataAdj-xProfPrevDataAdjErr; xProfPrevData; xProfCurDataAdj-xProfCurDataAdjErr; xProfCurData]);
maxParam = max([xTrajDataAdj+xTrajDataAdjErr; xTrajData; xProfPrevDataAdj+xProfPrevDataAdjErr; xProfPrevData; xProfCurDataAdj+xProfCurDataAdjErr; xProfCurData]);

minPres = min([yTrajDataAdj; yTrajData; yProfPrevDataAdj; yProfPrevData; yProfCurDataAdj; yProfCurData]);
maxPres = max([yTrajDataAdj; yTrajData; yProfPrevDataAdj; yProfPrevData; yProfCurDataAdj; yProfCurData]);

minAxeParam = minParam - (maxParam-minParam)/6;
maxAxeParam = maxParam + (maxParam-minParam)/6;
if (minAxeParam == maxAxeParam)
   minAxeParam = minAxeParam - 0.5;
   maxAxeParam = maxAxeParam + 0.5;
end

prevProfColor = [230 195 50]/255;
curProfColor = [11 230 20]/255;
trajColor = [0 0 255]/255;

lineWidth = 1.7;
markerSize = 9;

% previous profile measurements
if (~isempty(xProfPrevDataAdj))
   plot(xProfPrevDataAdj, yProfPrevDataAdj, '-', 'color', prevProfColor, 'linewidth', lineWidth);
   hold('on');
   if (g_NTTP_PLOT_ERR == 1)
      plot(xProfPrevDataAdj-xProfPrevDataAdjErr, yProfPrevDataAdj, ':', 'color', prevProfColor, 'linewidth', lineWidth);
      hold('on');
      plot(xProfPrevDataAdj+xProfPrevDataAdjErr, yProfPrevDataAdj, ':', 'color', prevProfColor, 'linewidth', lineWidth);
      hold('on');
   end

   idQcBad = find((xProfPrevDataAdjQc == g_decArgo_qcStrCorrectable) | (xProfPrevDataAdjQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(xProfPrevDataAdj), idQcBad);
   plot(xProfPrevDataAdj(idQcBad), yProfPrevDataAdj(idQcBad), 'r*', 'Markersize',  markerSize);
   hold('on');
   plot(xProfPrevDataAdj(idQcGood), yProfPrevDataAdj(idQcGood), '*', 'color', prevProfColor, 'Markersize',  markerSize);
   hold('on');

   idQcBad = find((yProfPrevDataAdjQc == g_decArgo_qcStrCorrectable) | (yProfPrevDataAdjQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(yProfPrevDataAdj), idQcBad);
   plot(ones(length(idQcBad), 1)*minAxeParam, yProfPrevDataAdj(idQcBad), 'r*', 'Markersize',  markerSize);
   hold('on');
   plot(ones(length(idQcGood), 1)*minAxeParam, yProfPrevDataAdj(idQcGood), '*', 'color', prevProfColor, 'Markersize',  markerSize);
   hold('on');
end
if (~isempty(xProfPrevData))
   plot(xProfPrevData, yProfPrevData, '--', 'color', prevProfColor, 'linewidth', lineWidth);
   hold('on');

   idQcBad = find((xProfPrevDataQc == g_decArgo_qcStrCorrectable) | (xProfPrevDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(xProfPrevData), idQcBad);
   plot(xProfPrevData(idQcBad), yProfPrevData(idQcBad), 'ro', 'Markersize',  markerSize);
   hold('on');
   plot(xProfPrevData(idQcGood), yProfPrevData(idQcGood), 'o', 'color', prevProfColor, 'Markersize',  markerSize);
   hold('on');

   idQcBad = find((yProfPrevDataQc == g_decArgo_qcStrCorrectable) | (yProfPrevDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(yProfPrevData), idQcBad);
   plot(ones(length(idQcBad), 1)*minAxeParam, yProfPrevData(idQcBad), 'ro', 'Markersize',  markerSize);
   hold('on');
   plot(ones(length(idQcGood), 1)*minAxeParam, yProfPrevData(idQcGood), 'o', 'color', prevProfColor, 'Markersize',  markerSize);
   hold('on');
end

% current profile measurements
if (~isempty(xProfCurDataAdj))
   plot(xProfCurDataAdj, yProfCurDataAdj, '-', 'color', curProfColor, 'linewidth', lineWidth);
   hold('on');
   if (g_NTTP_PLOT_ERR == 1)
      plot(xProfCurDataAdj-xProfCurDataAdjErr, yProfCurDataAdj, ':', 'color', curProfColor, 'linewidth', lineWidth);
      hold('on');
      plot(xProfCurDataAdj+xProfCurDataAdjErr, yProfCurDataAdj, ':', 'color', curProfColor, 'linewidth', lineWidth);
      hold('on');
   end

   idQcBad = find((xProfCurDataAdjQc == g_decArgo_qcStrCorrectable) | (xProfCurDataAdjQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(xProfCurDataAdj), idQcBad);
   plot(xProfCurDataAdj(idQcBad), yProfCurDataAdj(idQcBad), 'r*', 'Markersize',  markerSize);
   hold('on');
   plot(xProfCurDataAdj(idQcGood), yProfCurDataAdj(idQcGood), '*', 'color', curProfColor, 'Markersize',  markerSize);
   hold('on');

   idQcBad = find((yProfCurDataAdjQc == g_decArgo_qcStrCorrectable) | (yProfCurDataAdjQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(yProfCurDataAdj), idQcBad);
   plot(ones(length(idQcBad), 1)*minAxeParam, yProfCurDataAdj(idQcBad), 'r*', 'Markersize',  markerSize);
   hold('on');
   plot(ones(length(idQcGood), 1)*minAxeParam, yProfCurDataAdj(idQcGood), '*', 'color', curProfColor, 'Markersize',  markerSize);
   hold('on');
end
if (~isempty(xProfCurData))
   plot(xProfCurData, yProfCurData, '--', 'color', curProfColor, 'linewidth', lineWidth);
   hold('on');

   idQcBad = find((xProfCurDataQc == g_decArgo_qcStrCorrectable) | (xProfCurDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(xProfCurData), idQcBad);
   plot(xProfCurData(idQcBad), yProfCurData(idQcBad), 'ro', 'Markersize',  markerSize);
   hold('on');
   plot(xProfCurData(idQcGood), yProfCurData(idQcGood), 'o', 'color', curProfColor, 'Markersize',  markerSize);
   hold('on');

   idQcBad = find((yProfCurDataQc == g_decArgo_qcStrCorrectable) | (yProfCurDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(yProfCurData), idQcBad);
   plot(ones(length(idQcBad), 1)*minAxeParam, yProfCurData(idQcBad), 'ro', 'Markersize',  markerSize);
   hold('on');
   plot(ones(length(idQcGood), 1)*minAxeParam, yProfCurData(idQcGood), 'o', 'color', curProfColor, 'Markersize',  markerSize);
   hold('on');
end

% TRAJ measurements
if (~isempty(xTrajDataAdj))
   plot(xTrajDataAdj, yTrajDataAdj, '-', 'color', trajColor);
   hold('on');
   if (g_NTTP_PLOT_ERR == 1)
      plot(xTrajDataAdj-xTrajDataAdjErr, yTrajDataAdj, ':', 'color', trajColor, 'linewidth', lineWidth);
      hold('on');
      plot(xTrajDataAdj+xTrajDataAdjErr, yTrajDataAdj, ':', 'color', trajColor, 'linewidth', lineWidth);
      hold('on');
   end

   idQcBad = find((xTrajDataAdjQc == g_decArgo_qcStrCorrectable) | (xTrajDataAdjQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(xTrajDataAdj), idQcBad);
   plot(xTrajDataAdj(idQcBad), yTrajDataAdj(idQcBad), 'ro', 'Markersize', 4, 'MarkerFaceColor', 'r');
   hold('on');
   plot(xTrajDataAdj(idQcGood), yTrajDataAdj(idQcGood), 'o', 'color', trajColor, 'Markersize', 4, 'MarkerFaceColor', trajColor);
   hold('on');

   idQcBad = find((yTrajDataAdjQc == g_decArgo_qcStrCorrectable) | (yTrajDataAdjQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(yTrajDataAdj), idQcBad);
   plot(ones(length(idQcBad), 1)*minAxeParam, yTrajDataAdj(idQcBad), 'ro', 'Markersize', 4, 'MarkerFaceColor', 'r');
   hold('on');
   plot(ones(length(idQcGood), 1)*minAxeParam, yTrajDataAdj(idQcGood), 'o', 'color', trajColor, 'Markersize', 4, 'MarkerFaceColor', trajColor);
   hold('on');
end
if (~isempty(xTrajData))
   plot(xTrajData, yTrajData, '--', 'color', trajColor, 'linewidth', lineWidth);
   hold('on');

   idQcBad = find((xTrajDataQc == g_decArgo_qcStrCorrectable) | (xTrajDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(xTrajData), idQcBad);
   plot(xTrajData(idQcBad), yTrajData(idQcBad), 'ro', 'Markersize',  markerSize);
   hold('on');
   plot(xTrajData(idQcGood), yTrajData(idQcGood), 'o', 'color', trajColor, 'Markersize',  markerSize);
   hold('on');

   idQcBad = find((yTrajDataQc == g_decArgo_qcStrCorrectable) | (yTrajDataQc == g_decArgo_qcStrBad));
   idQcGood = setdiff(1:length(yTrajData), idQcBad);
   plot(ones(length(idQcBad), 1)*minAxeParam, yTrajData(idQcBad), 'ro', 'Markersize',  markerSize);
   hold('on');
   plot(ones(length(idQcGood), 1)*minAxeParam, yTrajData(idQcGood), 'o', 'color', trajColor, 'Markersize',  markerSize);
   hold('on');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalize the plots

if (~g_NTTP_PLOT_THETA)
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
else
   % Y axis boundaries
   minAxePres = minPres;
   maxAxePres = maxPres;
   if (minAxePres == maxAxePres)
      minAxePres = minAxePres - 1;
      maxAxePres = maxAxePres + 1;
   end
   set(gca, 'Ylim', [minAxePres maxAxePres]);

   % X axis boundaries
   set(gca, 'Xlim', [minAxeParam maxAxeParam]);

   % titre des axes
   set(get(gca, 'XLabel'), 'String', regexprep([g_NTTP_PARAM_NAME ' (' g_NTTP_UNITS_PARAM ')'], '_', ' '));
   set(get(gca, 'YLabel'), 'String', 'Potential temperature (degC)');
end

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

global g_NTTP_NC_TRAJ_DIR;
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
global g_NTTP_TRAJ_PRES_ADJ_QC;
global g_NTTP_TRAJ_PRES_DATA_MODE;

global g_NTTP_TRAJ_PARAM;
global g_NTTP_TRAJ_PARAM_QC;
global g_NTTP_TRAJ_PARAM_ADJ;
global g_NTTP_TRAJ_PARAM_ADJ_QC;
global g_NTTP_TRAJ_PARAM_ADJ_ERR;
global g_NTTP_TRAJ_PARAM_DATA_MODE;

global g_NTTP_PRES_FILL_VAL;
global g_NTTP_PARAM_FILL_VAL;

global g_NTTP_PLOT_THETA;


% retrieve data from TRAJ file
trajFile = dir([g_NTTP_NC_TRAJ_DIR sprintf('/%d/%d_Dtraj.nc', g_NTTP_FLOAT_NUM, g_NTTP_FLOAT_NUM)]);
if (isempty(trajFile))
   fprintf('INFO: No trajectory file for float %d - ignored\n', ...
      g_NTTP_FLOAT_NUM);
   return
end
trajFileName = trajFile(1).name;
trajFilePathName = [g_NTTP_NC_TRAJ_DIR '/' num2str(g_NTTP_FLOAT_NUM) '/' trajFileName];

% update param list for theta-s representation
paramList = g_NTTP_PARAM_LIST;
if (g_NTTP_PLOT_THETA)
   if (~ismember('TEMP', paramList))
      paramList = [paramList {'TEMP'}];
   end
   if (~ismember('PSAL', g_NTTP_PARAM_LIST))
      paramList = [paramList {'PSAL'}];
   end
end

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
for idParam = 1:length(paramList)
   paramName = paramList{idParam};
   wantedVars = [wantedVars ...
      {paramName} {[paramName '_QC']} ...
      {[paramName '_ADJUSTED']} {[paramName '_ADJUSTED_QC']} {[paramName '_ADJUSTED_ERROR']} ...
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
   paramAdjNameErr = [paramName '_ADJUSTED_ERROR'];
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
   dataAdjErr = get_data_from_name(paramAdjNameErr, ncTrajData);
   if (size(dataAdjErr, 2) > 1)
      dataAdjErr = permute(dataAdjErr, ndims(dataAdjErr):-1:1);
   end

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
      g_NTTP_TRAJ_PRES_ADJ_QC = dataAdjQc;
      g_NTTP_TRAJ_PRES_DATA_MODE = paramDataMode;
   else
      data(data == g_NTTP_PARAM_FILL_VAL) = nan;
      dataAdj(dataAdj == g_NTTP_PARAM_FILL_VAL) = nan;
      g_NTTP_TRAJ_PARAM = data;
      g_NTTP_TRAJ_PARAM_QC = dataQc;
      g_NTTP_TRAJ_PARAM_ADJ = dataAdj;
      g_NTTP_TRAJ_PARAM_ADJ_QC = dataAdjQc;
      g_NTTP_TRAJ_PARAM_ADJ_ERR = dataAdjErr;
      g_NTTP_TRAJ_PARAM_DATA_MODE = paramDataMode;
   end
end

if (g_NTTP_PLOT_THETA)
   % compute potential temperature
   pres = g_NTTP_TRAJ_PRES;
   presQc = g_NTTP_TRAJ_PRES_QC;
   presAdj = g_NTTP_TRAJ_PRES_ADJ;
   presAdjQc = g_NTTP_TRAJ_PRES_ADJ_QC;
   if (ismember('TEMP', g_NTTP_PARAM_LIST))
      temp = g_NTTP_TRAJ_PARAM;
      tempQc = g_NTTP_TRAJ_PARAM_QC;
      tempAdj = g_NTTP_TRAJ_PARAM_ADJ;
      tempAdjQc = g_NTTP_TRAJ_PARAM_ADJ_QC;
   else
      temp = get_data_from_name('TEMP', ncTrajData);
      if (size(temp, 2) > 1)
         temp = permute(temp, ndims(temp):-1:1);
      end
      tempQc = get_data_from_name('TEMP_QC', ncTrajData);
      tempAdj = get_data_from_name('TEMP_ADJUSTED', ncTrajData);
      if (size(tempAdj, 2) > 1)
         tempAdj = permute(tempAdj, ndims(tempAdj):-1:1);
      end
      tempAdjQc = get_data_from_name('TEMP_ADJUSTED_QC', ncTrajData);
   end
   if (ismember('PSAL', g_NTTP_PARAM_LIST))
      psal = g_NTTP_TRAJ_PARAM;
      psalQc = g_NTTP_TRAJ_PARAM_QC;
      psalAdj = g_NTTP_TRAJ_PARAM_ADJ;
      psalAdjQc = g_NTTP_TRAJ_PARAM_ADJ_QC;
   else
      psal = get_data_from_name('PSAL', ncTrajData);
      if (size(psal, 2) > 1)
         psal = permute(psal, ndims(psal):-1:1);
      end
      psalQc = get_data_from_name('PSAL_QC', ncTrajData);
      psalAdj = get_data_from_name('PSAL_ADJUSTED', ncTrajData);
      if (size(psalAdj, 2) > 1)
         psalAdj = permute(psalAdj, ndims(psalAdj):-1:1);
      end
      psalAdjQc = get_data_from_name('PSAL_ADJUSTED_QC', ncTrajData);
   end
   ptmp = nan(size(pres));
   idNoNan = find(~isnan(pres) & ~isnan(temp) & ~isnan(psal));
   ptmp(idNoNan) = sw_ptmp(psal(idNoNan), temp(idNoNan), pres(idNoNan), 0);
   ptmpQc = repmat(' ', size(pres));
   ptmpQc(idNoNan) = char(max([presQc(idNoNan) tempQc(idNoNan) psalQc(idNoNan)], [], 2));

   ptmpAdj = nan(size(presAdj));
   idNoNan = find(~isnan(presAdj) & ~isnan(tempAdj) & ~isnan(psalAdj));
   ptmpAdj(idNoNan) = sw_ptmp(psalAdj(idNoNan), tempAdj(idNoNan), presAdj(idNoNan), 0);
   ptmpAdjQc = repmat(' ', size(presAdj));
   ptmpAdjQc(idNoNan) = char(max([presAdjQc(idNoNan) tempAdjQc(idNoNan) psalAdjQc(idNoNan)], [], 2));

   % replace PRES by  potential temperature
   g_NTTP_TRAJ_PRES = ptmp;
   g_NTTP_TRAJ_PRES_QC = ptmpQc;
   g_NTTP_TRAJ_PRES_ADJ = ptmpAdj;
   g_NTTP_TRAJ_PRES_ADJ_QC = ptmpAdjQc;
   % g_NTTP_TRAJ_PRES_DATA_MODE = paramDataMode;
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

global g_NTTP_NC_PROF_DIR;
global g_NTTP_FLOAT_NUM;
global g_NTTP_PARAM_NAME;
global g_NTTP_PARAM_TYPE;
global g_NTTP_PARAM_LIST;

global g_NTTP_PRES_FILL_VAL;
global g_NTTP_PARAM_FILL_VAL;

global g_NTTP_PROF_DATA;

global g_NTTP_PLOT_THETA;


profDirName = [g_NTTP_NC_PROF_DIR '/' num2str(g_NTTP_FLOAT_NUM) '/profiles/'];
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

   % update param list for theta-s representation
   paramList = g_NTTP_PARAM_LIST;
   if (g_NTTP_PLOT_THETA)
      if (~ismember('TEMP', paramList))
         paramList = [paramList {'TEMP'}];
      end
      if (~ismember('PSAL', g_NTTP_PARAM_LIST))
         paramList = [paramList {'PSAL'}];
      end
   end

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
   for idParam = 1:length(paramList)
      paramName = paramList{idParam};
      wantedVars = [wantedVars ...
         {paramName} {[paramName '_QC']} ...
         {[paramName '_ADJUSTED']} {[paramName '_ADJUSTED_QC']} {[paramName '_ADJUSTED_ERROR']} ...
         ];
   end

   cProfData = [];
   bProfData = [];
   for idFile = 1:length(floatFiles)

      floatFileName = floatFiles(idFile).name;
      floatFilePathName = [profDirName '/' floatFileName];

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

            for idParam = 1:length(paramList)
               if ((g_NTTP_PARAM_TYPE == 'b') && (idParam > 1))
                  break
               end
               paramName = paramList{idParam};
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

            if (g_NTTP_PLOT_THETA)
               % compute potential temperature
               idPres = find(strcmp(paramList, 'PRES'));
               idTemp = find(strcmp(paramList, 'TEMP'));
               idPsal = find(strcmp(paramList, 'PSAL'));
               if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))
                  if (~ismember('TEMP', g_NTTP_PARAM_LIST))
                     paramTempInfo = get_netcdf_param_attributes('TEMP');
                     data(data(:, idTemp) == paramTempInfo.fillValue, idTemp) = nan;
                     dataAdj(dataAdj(:, idTemp) == paramTempInfo.fillValue, idTemp) = nan;
                     dataAdjErr(dataAdjErr(:, idTemp) == paramTempInfo.fillValue, idTemp) = nan;
                  end
                  if (~ismember('PSAL', g_NTTP_PARAM_LIST))
                     paramPsalInfo = get_netcdf_param_attributes('PSAL');
                     data(data(:, idPsal) == paramPsalInfo.fillValue, idPsal) = nan;
                     dataAdj(dataAdj(:, idPsal) == paramPsalInfo.fillValue, idTemp) = nan;
                     dataAdjErr(dataAdjErr(:, idPsal) == paramPsalInfo.fillValue, idPsal) = nan;
                  end
                  ptmp = nan(size(data, 1), 1);
                  idNoNan = find(~isnan(data(:, idPres)) & ~isnan(data(:, idTemp)) & ~isnan(data(:, idPsal)));
                  ptmp(idNoNan) = sw_ptmp(data(idNoNan, idPsal), data(idNoNan, idTemp), data(idNoNan, idPres), 0);
                  ptmpQc = repmat(' ', size(data, 1), 1);
                  ptmpQc(idNoNan) = char(max(dataQc(idNoNan, [idPres, idTemp, idPsal]), [], 2));

                  ptmpAdj = nan(size(dataAdj, 1), 1);
                  idNoNan = find(~isnan(dataAdj(:, idPres)) & ~isnan(dataAdj(:, idTemp)) & ~isnan(dataAdj(:, idPsal)));
                  ptmpAdj(idNoNan) = sw_ptmp(dataAdj(idNoNan, idPsal), dataAdj(idNoNan, idTemp), dataAdj(idNoNan, idPres), 0);
                  ptmpAdjQc = repmat(' ', size(dataAdj, 1), 1);
                  ptmpAdjQc(idNoNan) = char(max(dataAdjQc(idNoNan, [idPres, idTemp, idPsal]), [], 2));

                  ptmpAdjErr = nan(size(dataAdj, 1), 1);

                  % replace PRES by  potential temperature
                  data(:, idPres) = ptmp;
                  dataQc(:, idPres) = ptmpQc;
                  dataAdj(:, idPres) = ptmpAdj;
                  dataAdjQc(:, idPres) = ptmpAdjQc;
                  dataAdjErr(:, idPres) = ptmpAdjErr;
               end
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

            for idParam = 1:length(paramList)
               paramName = paramList{idParam};
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
global g_NTTP_PLOT_THETA;
global g_NTTP_LOAD_DATA;
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
   % switch to theta-s plot
elseif (strcmp(a_eventData.Key, 't'))
   if (g_NTTP_PLOT_THETA == 0)
      g_NTTP_PLOT_THETA = 1;
   else
      g_NTTP_PLOT_THETA = 0;
   end
   g_NTTP_LOAD_DATA = 1;
   fprintf('Plot theta-s instead of pres-s: %d\n', g_NTTP_PLOT_THETA);
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
   fprintf('   t  : plot theta-s data\n');
   fprintf('   r  : plot RT measurements\n');
   fprintf('   e  : plot error on adjusted measurements\n');
   fprintf('Misc:\n');
   fprintf('   p: pdf output file generation\n');
   fprintf('   h: write help and current configuration\n');
   fprintf('Escape: exit\n\n');

   fprintf('Current configuration:\n');
   fprintf('Plot all profile measurements: %d\n', g_NTTP_ALL_PROF_MEAS);
   fprintf('Plot theta-s instead of pres-s: %d\n', g_NTTP_PLOT_THETA);
   fprintf('Plot RT profile measurements: %d\n', g_NTTP_RT_PROF_MEAS);
   fprintf('Plot error on adjusted measurements: %d\n', g_NTTP_PLOT_ERR);
end

return
