% ------------------------------------------------------------------------------
% Plot the profiles of 2 parameters.
%
% SYNTAX :
%   nc_trace_param ou nc_trace_param(6900189, 7900118)
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
%   08/03/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_trace_param(varargin)

global g_NTP_NC_DIR;
global g_NTP_PDF_DIR;
global g_NTP_FIG_HANDLE;
global g_NTP_DEFAULT_NB_CYCLES;
global g_NTP_PRINT;

global g_NTP_ID_FLOAT;
global g_NTP_FLOAT_LIST;
global g_NTP_nbCyles;
global g_NTP_PROF_NUM;

global g_NTP_NAME_PARAM1;
global g_NTP_NAME_PARAM2;

% g_NTP_NAME_PARAM1 = 'TURBIDITY';
% g_NTP_NAME_PARAM1 = 'CHLA';
% g_NTP_NAME_PARAM1 = 'BPHASE_DOXY';
g_NTP_NAME_PARAM1 = 'TEMP';
% g_NTP_NAME_PARAM1 = 'FLUORESCENCE_CDOM';
% g_NTP_NAME_PARAM1 = 'TEMP_DOXY';
% g_NTP_NAME_PARAM1 = 'IFREMER_TEMPORARY_BLUE_REF';
% g_NTP_NAME_PARAM1 = 'IFREMER_TEMPORARY_NTU_REF';
g_NTP_NAME_PARAM1 = 'NITRATE';

% g_NTP_NAME_PARAM2 = 'TURBIDITY';
% g_NTP_NAME_PARAM2 = 'BBP700';
% g_NTP_NAME_PARAM2 = 'TEMP_DOXY';
g_NTP_NAME_PARAM2 = 'PSAL';
% g_NTP_NAME_PARAM2 = 'CDOM';
% g_NTP_NAME_PARAM2 = 'IFREMER_TEMPORARY_F_SIG';
% g_NTP_NAME_PARAM2 = 'IFREMER_TEMPORARY_NTU_SIG';
g_NTP_NAME_PARAM2 = 'NITRATE';
% g_NTP_NAME_PARAM2 = 'DOXY';

% top directory of NetCDF files to plot
g_NTP_NC_DIR = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% g_NTP_NC_DIR = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo_ref_apx_bascule\';
% g_NTP_NC_DIR = 'C:\Users\jprannou\Desktop\ftp\';

% directory to store pdf output
g_NTP_PDF_DIR = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default list of floats to plot
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_071412.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_062608.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_061609.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\new_062608.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_093008.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_061810.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_021208.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_032213.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_110613.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_090413.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_110813.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_082213.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_082213_1.txt';
% % FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_matlab_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_071807.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_082807.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_020110.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_090810.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_102015.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nova.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nova_dova.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_dova.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_arn_ir.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_4.54.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_apmt_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.43.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.44.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.45.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\provor_5.74.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% number of cycles to plot
g_NTP_DEFAULT_NB_CYCLES = 5;

fprintf('Plot management:\n');
fprintf('   Right Arrow: next float\n');
fprintf('   Left Arrow : previous float\n');
fprintf('   Down Arrow : next set of profiles\n');
fprintf('   Up Arrow   : previous set of profiles\n');
fprintf('Plot:\n');
fprintf('   +/-: increase/decrease the number of profiles per set\n');
fprintf('   a  : plot all the profiles of the float\n');
fprintf('   d  : back to plot %d profiles per set\n', ...
   g_NTP_DEFAULT_NB_CYCLES);
fprintf('Misc:\n');
fprintf('   p: pdf output file generation\n');
fprintf('   h: write help and current configuration\n');
fprintf('Escape: exit\n\n');

% no pdf generation
g_NTP_PRINT = 0;

% force the plot of the first float
g_NTP_ID_FLOAT = -1;

% set profile # to plot
g_NTP_PROF_NUM = 1;

% default values initialization
init_default_values;

close(findobj('Name', 'Temperature and salinity'));
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

g_NTP_FLOAT_LIST = floatList;

% number of cycles to plot
g_NTP_nbCyles = g_NTP_DEFAULT_NB_CYCLES;

% creation of the figure and its associated callback
screenSize = get(0, 'ScreenSize');
g_NTP_FIG_HANDLE = figure('KeyPressFcn', @change_plot, ...
   'Name', 'Temperature and salinity', ...
   'Position', [1 screenSize(4)*(1/3) screenSize(3) screenSize(4)*(2/3)-90]);

% plot the first set of profiles of the first float
plot_pt_ps(0, 0);

return;

% ------------------------------------------------------------------------------
% Plot the profiles of 2 parameters for a given float and set of cycles.
%
% SYNTAX :
%   plot_pt_ps(a_idFloat, a_idCycle)
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
%   08/03/2014 - RNU - creation
% ------------------------------------------------------------------------------
function plot_pt_ps(a_idFloat, a_idCycle)

global g_NTP_NC_DIR;
global g_NTP_PDF_DIR;
global g_NTP_FIG_HANDLE;
global g_NTP_ID_FLOAT;
global g_NTP_FLOAT_LIST;
global g_NTP_PRINT;

global g_NTP_cycles;
global g_NTP_tabPres1;
global g_NTP_tabPres1Qc;
global g_NTP_tabPres2;
global g_NTP_tabPres2Qc;
global g_NTP_tabParam1;
global g_NTP_tabParam1Qc;
global g_NTP_tabParam2;
global g_NTP_tabParam2Qc;
global g_NTP_idCycle;
global g_NTP_nbCyles;
global g_NTP_PROF_NUM;

global g_NTP_NAME_PARAM1;
global g_NTP_NAME_PARAM2;
global g_NTP_UNITS_PARAM1;
global g_NTP_UNITS_PARAM2;
global g_NTP_PARAM_PRES_FILL_VAL;
global g_NTP_NAME_PARAM1_FILL_VAL;
global g_NTP_NAME_PARAM2_FILL_VAL;

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


g_NTP_idCycle = a_idCycle;

figure(g_NTP_FIG_HANDLE);
clf;

if (a_idFloat ~= g_NTP_ID_FLOAT)
   
   % a new float is wanted
   g_NTP_ID_FLOAT = a_idFloat;
   
   g_NTP_cycles = [];
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve and store the data of the new float
   
   % float number
   floatNum = g_NTP_FLOAT_LIST(a_idFloat+1);
   floatNumStr = num2str(floatNum);
   
   % which param in which file
   paramPres = get_netcdf_param_attributes_3_1('PRES');
   param1Struct = get_netcdf_param_attributes_3_1(g_NTP_NAME_PARAM1);
   g_NTP_UNITS_PARAM1 = param1Struct.units;
   if (param1Struct.paramType == 'c')
      param1File = 'c';
   else
      param1File = 'b';
   end
   param2Struct = get_netcdf_param_attributes_3_1(g_NTP_NAME_PARAM2);
   g_NTP_UNITS_PARAM2 = param2Struct.units;
   if (param2Struct.paramType == 'c')
      param2File = 'c';
   else
      param2File = 'b';
   end
   
   % retrieve information from PROF file
   wantedCVars = [ ...
      {'FORMAT_VERSION'} ...
      {'CYCLE_NUMBER'} ...
      {'DIRECTION'} ...
      {'STATION_PARAMETERS'} ...
      {'PRES'} ...
      {'PRES_QC'} ...
      ];
   if (param1File == 'c')
      wantedCVars = [ ...
         wantedCVars ...
         {g_NTP_NAME_PARAM1} ...
         {[g_NTP_NAME_PARAM1 '_QC']} ...
         ];
   end
   if (param2File == 'c')
      wantedCVars = [ ...
         wantedCVars ...
         {g_NTP_NAME_PARAM2} ...
         {[g_NTP_NAME_PARAM2 '_QC']} ...
         ];
   end
   wantedBVars = [ ...
      {'FORMAT_VERSION'} ...
      {'CYCLE_NUMBER'} ...
      {'DIRECTION'} ...
      {'STATION_PARAMETERS'} ...
      {'PRES'} ...
      ];
   if (param1File ~= 'c')
      wantedBVars = [ ...
         wantedBVars ...
         {g_NTP_NAME_PARAM1} ...
         {[g_NTP_NAME_PARAM1 '_QC']} ...
         ];
   end
   if (param2File ~= 'c')
      wantedBVars = [ ...
         wantedBVars ...
         {g_NTP_NAME_PARAM2} ...
         {[g_NTP_NAME_PARAM2 '_QC']} ...
         ];
   end
   
   % arrays to store the data
   tabCycles1 = [];
   tabPres1 = [];
   tabPres1Qc = [];
   tabParam1 = [];
   tabParam1Qc = [];
   tabCycles2 = [];
   tabPres2 = [];
   tabPres2Qc = [];
   tabParam2 = [];
   tabParam2Qc = [];
   
   if ((param1File == 'c') || (param2File == 'c'))
      
      % retrieve the data from MULTI-PROF file
      profFileName = [g_NTP_NC_DIR '/' floatNumStr '/' floatNumStr '_prof.nc'];
      
      [profData] = get_data_from_nc_file(profFileName, wantedCVars);
      
      if (~isempty(profData) && (g_NTP_PROF_NUM == 1))
         
         idVal = find(strcmp('FORMAT_VERSION', profData(1:2:end)) == 1, 1);
         profFileFormatVersion = strtrim(profData{2*idVal}');
         
         % check the prof file format version
         if (~strcmp(profFileFormatVersion, '3.1'))
            fprintf('WARNING: Input prof file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s)', ...
               profFileName, profFileFormatVersion);
         end
         
         idVal = find(strcmp('CYCLE_NUMBER', profData(1:2:end)) == 1, 1);
         cycleNumberProf = profData{2*idVal};
         
         idVal = find(strcmp('DIRECTION', profData(1:2:end)) == 1, 1);
         profDir = profData{2*idVal};
         
         idVal = find(strcmp('PRES', profData(1:2:end)) == 1, 1);
         profPres = profData{2*idVal};
         
         idVal = find(strcmp('PRES_QC', profData(1:2:end)) == 1, 1);
         profPresQc = profData{2*idVal};
         
         if (param1File == 'c')
            idVal = find(strcmp(g_NTP_NAME_PARAM1, profData(1:2:end)) == 1, 1);
            profParam1 = profData{2*idVal};
            
            idVal = find(strcmp([g_NTP_NAME_PARAM1 '_QC'], profData(1:2:end)) == 1, 1);
            profParam1Qc = profData{2*idVal};
            
            idProf = find(profDir == 'A');
            tabCycles1 = cycleNumberProf(idProf);
            tabPres1 = profPres(:, idProf);
            tabPres1Qc = profPresQc(:, idProf);
            tabParam1 = profParam1(:, idProf);
            tabParam1Qc = profParam1Qc(:, idProf);
         end
         
         if (param2File == 'c')
            idVal = find(strcmp(g_NTP_NAME_PARAM2, profData(1:2:end)) == 1, 1);
            profParam2 = profData{2*idVal};
            
            idVal = find(strcmp([g_NTP_NAME_PARAM2 '_QC'], profData(1:2:end)) == 1, 1);
            profParam2Qc = profData{2*idVal};
            
            idProf = find(profDir == 'A');
            tabCycles2 = cycleNumberProf(idProf);
            tabPres2 = profPres(:, idProf);
            tabPres2Qc = profPresQc(:, idProf);
            tabParam2 = profParam2(:, idProf);
            tabParam2Qc = profParam2Qc(:, idProf);
         end
      else
         
         % retrieve the data from MONO-PROF files
         profFileNames = dir([g_NTP_NC_DIR '/' floatNumStr '/profiles/' '*' floatNumStr '*.nc']);
         
         fprintf('Reading c mono-profile files for float #%d wait ...', floatNum);
         
         for idFile = 1:length(profFileNames)
            
            profFileName = profFileNames(idFile).name;
            if (profFileName(1) == 'B')
               continue;
            end
            
            profFileName = [g_NTP_NC_DIR '/' floatNumStr '/profiles/' profFileNames(idFile).name];
            [profData] = get_data_from_nc_file(profFileName, wantedCVars);
            
            idVal = find(strcmp('FORMAT_VERSION', profData(1:2:end)) == 1, 1);
            profFileFormatVersion = strtrim(profData{2*idVal}');
            
            % check the prof file format version
            if (~strcmp(profFileFormatVersion, '3.1'))
               fprintf('WARNING: Input prof file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s)', ...
                  profFileName, profFileFormatVersion);
            end
            
            idVal = find(strcmp('CYCLE_NUMBER', profData(1:2:end)) == 1, 1);
            cycleNumberProf = profData{2*idVal};
            
            idVal = find(strcmp('DIRECTION', profData(1:2:end)) == 1, 1);
            profDir = profData{2*idVal};
            
            idVal = find(strcmp('STATION_PARAMETERS', profData(1:2:end)) == 1, 1);
            stationParameters = profData{2*idVal};
            [~, inputNParam, inputNProf] = size(stationParameters);
            
            idVal = find(strcmp('PRES', profData(1:2:end)) == 1, 1);
            profPres = profData{2*idVal};
            
            idVal = find(strcmp('PRES_QC', profData(1:2:end)) == 1, 1);
            profPresQc = profData{2*idVal};
            
            if (param1File == 'c')
               
               idVal = find(strcmp(g_NTP_NAME_PARAM1, profData(1:2:end)) == 1, 1);
               profParam1 = profData{2*idVal};
               
               idVal = find(strcmp([g_NTP_NAME_PARAM1 '_QC'], profData(1:2:end)) == 1, 1);
               profParam1Qc = profData{2*idVal};
               
               pres1 = [];
               profNum = '';
               for idProf = 1:inputNProf
                  for idParam = 1:inputNParam
                     param = deblank(stationParameters(:, idParam, idProf)');
                     if (strcmp(param, g_NTP_NAME_PARAM1))
                        if (idProf >= g_NTP_PROF_NUM)
                           profNum = idProf;
                           break;
                        end
                     end
                  end
                  if (~isempty(profNum))
                     break;
                  end
               end
               if ((~isempty(profNum)) && (profDir(profNum) == 'A'))
                  tabCycles1 = [tabCycles1; cycleNumberProf(profNum)];
                  pres1 = profPres(:, profNum);
                  pres1Qc = profPresQc(:, profNum);
                  param1 = profParam1(:, profNum);
                  param1Qc = profParam1Qc(:, profNum);
               end
               
               if (~isempty(pres1))
                  if (~isempty(tabPres1))
                     if (length(pres1) > size(tabPres1, 1))
                        nLineToAdd = length(pres1) - size(tabPres1, 1);
                        tabPres1 = cat(1, ...
                           tabPres1, ...
                           repmat(paramPres.fillValue, nLineToAdd, size(tabPres1, 2)));
                        tabPres1Qc = cat(1, ...
                           tabPres1Qc, ...
                           repmat(' ', nLineToAdd, size(tabPres1Qc, 2)));
                        tabParam1 = cat(1, ...
                           tabParam1, ...
                           repmat(param1Struct.fillValue, nLineToAdd, size(tabParam1, 2)));
                        tabParam1Qc = cat(1, ...
                           tabParam1Qc, ...
                           repmat(' ', nLineToAdd, size(tabParam1Qc, 2)));
                     elseif (length(pres1) < size(tabPres1, 1))
                        nLineToAdd = size(tabPres1, 1) - length(pres1);
                        pres1 = cat(1, ...
                           pres1, ...
                           repmat(paramPres.fillValue, nLineToAdd, 1));
                        pres1Qc = cat(1, ...
                           pres1Qc, ...
                           repmat(' ', nLineToAdd, 1));
                        param1 = cat(1, ...
                           param1, ...
                           repmat(param1Struct.fillValue, nLineToAdd, 1));
                        param1Qc = cat(1, ...
                           param1Qc, ...
                           repmat(' ', nLineToAdd, 1));
                     end
                     tabPres1 = [tabPres1 pres1];
                     tabPres1Qc = [tabPres1Qc pres1Qc];
                     tabParam1 = [tabParam1 param1];
                     tabParam1Qc = [tabParam1Qc param1Qc];
                  else
                     tabPres1 = pres1;
                     tabPres1Qc = pres1Qc;
                     tabParam1 = param1;
                     tabParam1Qc = param1Qc;
                  end
               end
            end
            
            if (param2File == 'c')
               
               idVal = find(strcmp(g_NTP_NAME_PARAM2, profData(1:2:end)) == 1, 1);
               profParam2 = profData{2*idVal};
               
               idVal = find(strcmp([g_NTP_NAME_PARAM2 '_QC'], profData(1:2:end)) == 1, 1);
               profParam2Qc = profData{2*idVal};
               
               pres2 = [];
               %                   profNum = '';
               %                   for idProf = 1:inputNProf
               %                      for idParam = 1:inputNParam
               %                         param = deblank(stationParameters(:, idParam, idProf)');
               %                         if (strcmp(param, g_NTP_NAME_PARAM2))
               %                            profNum = idProf;
               %                            break;
               %                         end
               %                      end
               %                      if (~isempty(profNum))
               %                         break;
               %                      end
               %                   end

               if ((~isempty(profNum)) && (profDir(profNum) == 'A'))
                  tabCycles2 = [tabCycles2; cycleNumberProf(profNum)];
                  pres2 = profPres(:, profNum);
                  pres2Qc = profPresQc(:, profNum);
                  param2 = profParam2(:, profNum);
                  param2Qc = profParam2Qc(:, profNum);
               end
               
               if (~isempty(pres2))
                  if (~isempty(tabPres2))
                     if (length(pres2) > size(tabPres2, 1))
                        nLineToAdd = length(pres2) - size(tabPres2, 1);
                        tabPres2 = cat(1, ...
                           tabPres2, ...
                           repmat(paramPres.fillValue, nLineToAdd, size(tabPres2, 2)));
                        tabPres2Qc = cat(1, ...
                           tabPres2Qc, ...
                           repmat(' ', nLineToAdd, size(tabPres2Qc, 2)));
                        tabParam2 = cat(1, ...
                           tabParam2, ...
                           repmat(param2Struct.fillValue, nLineToAdd, size(tabParam2, 2)));
                        tabParam2Qc = cat(1, ...
                           tabParam2Qc, ...
                           repmat(' ', nLineToAdd, size(tabParam2Qc, 2)));
                     elseif (length(pres2) < size(tabPres2, 1))
                        nLineToAdd = size(tabPres2, 1) - length(pres2);
                        pres2 = cat(1, ...
                           pres2, ...
                           repmat(paramPres.fillValue, nLineToAdd, 1));
                        pres2Qc = cat(1, ...
                           pres2Qc, ...
                           repmat(' ', nLineToAdd, 1));
                        param2 = cat(1, ...
                           param2, ...
                           repmat(param2Struct.fillValue, nLineToAdd, 1));
                        param2Qc = cat(1, ...
                           param2Qc, ...
                           repmat(' ', nLineToAdd, 1));
                     end
                     tabPres2 = [tabPres2 pres2];
                     tabPres2Qc = [tabPres2Qc pres2Qc];
                     tabParam2 = [tabParam2 param2];
                     tabParam2Qc = [tabParam2Qc param2Qc];
                  else
                     tabPres2 = pres2;
                     tabPres2Qc = pres2Qc;
                     tabParam2 = param2;
                     tabParam2Qc = param2Qc;
                  end
               end
            end
         end
         
         fprintf(' done\n');
      end
   end
   
   if ((param1File ~= 'c') || (param2File ~= 'c'))
      % retrieve the data from MONO-PROF files
      profFileNames = dir([g_NTP_NC_DIR '/' floatNumStr '/profiles/B' '*' floatNumStr '*.nc']);
      
      fprintf('Reading b mono-profile files for float #%d wait ...', floatNum);
      
      for idFile = 1:length(profFileNames)
         profFileName = [g_NTP_NC_DIR '/' floatNumStr '/profiles/' profFileNames(idFile).name];
         [profData] = get_data_from_nc_file(profFileName, wantedBVars);
         
         idVal = find(strcmp('FORMAT_VERSION', profData(1:2:end)) == 1, 1);
         profFileFormatVersion = strtrim(profData{2*idVal}');
         
         % check the prof file format version
         if (~strcmp(profFileFormatVersion, '3.1'))
            fprintf('ERROR: Input prof file (%s) is expected to be of 3.1 format version (but FORMAT_VERSION = %s)', ...
               profFileName, profFileFormatVersion);
         else
            
            idVal = find(strcmp('CYCLE_NUMBER', profData(1:2:end)) == 1, 1);
            cycleNumberProf = profData{2*idVal};
            
            idVal = find(strcmp('DIRECTION', profData(1:2:end)) == 1, 1);
            profDir = profData{2*idVal};
            
            idVal = find(strcmp('STATION_PARAMETERS', profData(1:2:end)) == 1, 1);
            stationParameters = profData{2*idVal};
            [~, inputNParam, inputNProf] = size(stationParameters);
            
            idVal = find(strcmp('PRES', profData(1:2:end)) == 1, 1);
            profPres = profData{2*idVal};
            
            %             idVal = find(strcmp('PRES_QC', profData(1:2:end)) == 1, 1);
            %             profPresQc = profData{2*idVal};
                        
            if (param1File ~= 'c')
               
               idVal = find(strcmp(g_NTP_NAME_PARAM1, profData(1:2:end)) == 1, 1);
               profParam1 = profData{2*idVal};
               
               idVal = find(strcmp([g_NTP_NAME_PARAM1 '_QC'], profData(1:2:end)) == 1, 1);
               profParam1Qc = profData{2*idVal};
               
               pres1 = [];
               profNum = '';
               for idProf = 1:inputNProf
                  for idParam = 1:inputNParam
                     param = deblank(stationParameters(:, idParam, idProf)');
                     if (strcmp(param, g_NTP_NAME_PARAM1))
                        profNum = idProf;
                        break;
                     end
                  end
                  if (~isempty(profNum))
                     break;
                  end
               end
               if ((~isempty(profNum)) && (profDir(profNum) == 'A'))
                  tabCycles1 = [tabCycles1; cycleNumberProf(profNum)];
                  pres1 = profPres(:, profNum);
%                   pres1Qc = profPresQc(:, profNum);
                  param1 = profParam1(:, profNum);
                  param1Qc = profParam1Qc(:, profNum);
               end
               
               if (~isempty(pres1))
                  if (~isempty(tabPres1))
                     if (length(pres1) > size(tabPres1, 1))
                        nLineToAdd = length(pres1) - size(tabPres1, 1);
                        tabPres1 = cat(1, ...
                           tabPres1, ...
                           repmat(paramPres.fillValue, nLineToAdd, size(tabPres1, 2)));
%                         tabPres1Qc = cat(1, ...
%                            tabPres1Qc, ...
%                            repmat(' ', nLineToAdd, size(tabPres1Qc, 2)));
                        tabParam1 = cat(1, ...
                           tabParam1, ...
                           repmat(param1Struct.fillValue, nLineToAdd, size(tabParam1, 2)));
                        tabParam1Qc = cat(1, ...
                           tabParam1Qc, ...
                           repmat(' ', nLineToAdd, size(tabParam1Qc, 2)));
                     elseif (length(pres1) < size(tabPres1, 1))
                        nLineToAdd = size(tabPres1, 1) - length(pres1);
                        pres1 = cat(1, ...
                           pres1, ...
                           repmat(paramPres.fillValue, nLineToAdd, 1));
%                         pres1Qc = cat(1, ...
%                            pres1Qc, ...
%                            repmat(' ', nLineToAdd, 1));
                        param1 = cat(1, ...
                           param1, ...
                           repmat(param1Struct.fillValue, nLineToAdd, 1));
                        param1Qc = cat(1, ...
                           param1Qc, ...
                           repmat(' ', nLineToAdd, 1));
                     end
                     tabPres1 = [tabPres1 pres1];
%                      tabPres1Qc = [tabPres1Qc pres1Qc];
                     tabParam1 = [tabParam1 param1];
                     tabParam1Qc = [tabParam1Qc param1Qc];
                  else
                     tabPres1 = pres1;
%                      tabPres1Qc = pres1Qc;
                     tabParam1 = param1;
                     tabParam1Qc = param1Qc;
                  end
               end
            end
            
            if (param2File ~= 'c')
               
               idVal = find(strcmp(g_NTP_NAME_PARAM2, profData(1:2:end)) == 1, 1);
               profParam2 = profData{2*idVal};
               
               idVal = find(strcmp([g_NTP_NAME_PARAM2 '_QC'], profData(1:2:end)) == 1, 1);
               profParam2Qc = profData{2*idVal};
               
               pres2 = [];
               %                if (~exist('profNum', 'var'))
               profNum = '';
               for idProf = 1:inputNProf
                  for idParam = 1:inputNParam
                     param = deblank(stationParameters(:, idParam, idProf)');
                     if (strcmp(param, g_NTP_NAME_PARAM2))
                        profNum = idProf;
                        break;
                     end
                  end
                  if (~isempty(profNum))
                     break;
                  end
               end
               %                end
               
               if ((~isempty(profNum)) && (profDir(profNum) == 'A'))
                  tabCycles2 = [tabCycles2; cycleNumberProf(profNum)];
                  pres2 = profPres(:, profNum);
%                   pres2Qc = profPresQc(:, profNum);
                  param2 = profParam2(:, profNum);
                  param2Qc = profParam2Qc(:, profNum);
               end
               
               if (~isempty(pres2))
                  if (~isempty(tabPres2))
                     if (length(pres2) > size(tabPres2, 1))
                        nLineToAdd = length(pres2) - size(tabPres2, 1);
                        tabPres2 = cat(1, ...
                           tabPres2, ...
                           repmat(paramPres.fillValue, nLineToAdd, size(tabPres2, 2)));
%                         tabPres2Qc = cat(1, ...
%                            tabPres2Qc, ...
%                            repmat(' ', nLineToAdd, size(tabPres2Qc, 2)));
                        tabParam2 = cat(1, ...
                           tabParam2, ...
                           repmat(param2Struct.fillValue, nLineToAdd, size(tabParam2, 2)));
                        tabParam2Qc = cat(1, ...
                           tabParam2Qc, ...
                           repmat(' ', nLineToAdd, size(tabParam2Qc, 2)));
                     elseif (length(pres2) < size(tabPres2, 1))
                        nLineToAdd = size(tabPres2, 1) - length(pres2);
                        pres2 = cat(1, ...
                           pres2, ...
                           repmat(paramPres.fillValue, nLineToAdd, 1));
%                         pres2Qc = cat(1, ...
%                            pres2Qc, ...
%                            repmat(' ', nLineToAdd, 1));
                        param2 = cat(1, ...
                           param2, ...
                           repmat(param2Struct.fillValue, nLineToAdd, 1));
                        param2Qc = cat(1, ...
                           param2Qc, ...
                           repmat(' ', nLineToAdd, 1));
                     end
                     tabPres2 = [tabPres2 pres2];
%                      tabPres2Qc = [tabPres2Qc pres2Qc];
                     tabParam2 = [tabParam2 param2];
                     tabParam2Qc = [tabParam2Qc param2Qc];
                  else
                     tabPres2 = pres2;
%                      tabPres2Qc = pres2Qc;
                     tabParam2 = param2;
                     tabParam2Qc = param2Qc;
                  end
               end
            end
         end
      end
      
      fprintf(' done\n');
   end
   
   % global arrays to store the data
   g_NTP_cycles = [];
   g_NTP_tabPres1 = [];
   g_NTP_tabPres1Qc = [];
   g_NTP_tabParam1 = [];
   g_NTP_tabParam1Qc = [];
   g_NTP_tabPres2 = [];
   g_NTP_tabPres2Qc = [];
   g_NTP_tabParam2 = [];
   g_NTP_tabParam2Qc = [];
   
   g_NTP_cycles = sort(unique([tabCycles1; tabCycles2]));
   for idCy = 1:length(g_NTP_cycles)
      cyNum = g_NTP_cycles(idCy);
      
      idF1 = find(tabCycles1 == cyNum);
      if (~isempty(idF1))
         g_NTP_tabPres1 = [g_NTP_tabPres1 tabPres1(:, idF1)];
         if (~isempty(tabPres1Qc))
            g_NTP_tabPres1Qc = [g_NTP_tabPres1Qc tabPres1Qc(:, idF1)];
         else
            g_NTP_tabPres1Qc = [g_NTP_tabPres1Qc repmat(' ', size(tabPres1, 1), 1)];
         end
         g_NTP_tabParam1 = [g_NTP_tabParam1 tabParam1(:, idF1)];
         g_NTP_tabParam1Qc = [g_NTP_tabParam1Qc tabParam1Qc(:, idF1)];
      else
         g_NTP_tabPres1 = [g_NTP_tabPres1 repmat(paramPres.fillValue, size(tabPres1, 1), 1)];
         g_NTP_tabPres1Qc = [g_NTP_tabPres1Qc repmat(' ', size(tabPres1Qc, 1), 1)];
         g_NTP_tabParam1 = [g_NTP_tabParam1 repmat(param1Struct.fillValue, size(tabParam1, 1), 1)];
         g_NTP_tabParam1Qc = [g_NTP_tabParam1Qc repmat(' ', size(tabParam1Qc, 1), 1)];
      end
      
      idF2 = find(tabCycles2 == cyNum);
      if (~isempty(idF2))
         g_NTP_tabPres2 = [g_NTP_tabPres2 tabPres2(:, idF2)];
         if (~isempty(tabPres2Qc))
            g_NTP_tabPres2Qc = [g_NTP_tabPres2Qc tabPres2Qc(:, idF2)];
         else
            g_NTP_tabPres2Qc = [g_NTP_tabPres2Qc repmat(' ', size(tabPres2, 1), 1)];
         end
         g_NTP_tabParam2 = [g_NTP_tabParam2 tabParam2(:, idF2)];
         g_NTP_tabParam2Qc = [g_NTP_tabParam2Qc tabParam2Qc(:, idF2)];
      else
         g_NTP_tabPres2 = [g_NTP_tabPres2 repmat(paramPres.fillValue, size(tabPres2, 1), 1)];
         g_NTP_tabPres2Qc = [g_NTP_tabPres2Qc repmat(' ', size(tabPres2Qc, 1), 1)];
         g_NTP_tabParam2 = [g_NTP_tabParam2 repmat(param2Struct.fillValue, size(tabParam2, 1), 1)];
         g_NTP_tabParam2Qc = [g_NTP_tabParam2Qc repmat(' ', size(tabParam2Qc, 1), 1)];
      end
   end
   
   g_NTP_PARAM_PRES_FILL_VAL = paramPres.fillValue;
   g_NTP_NAME_PARAM1_FILL_VAL = param1Struct.fillValue;
   g_NTP_NAME_PARAM2_FILL_VAL = param2Struct.fillValue;
end

if (isempty(g_NTP_cycles))
   label = sprintf('%02d/%02d : %s no data', ...
      a_idFloat+1, ...
      length(g_NTP_FLOAT_LIST), ...
      num2str(g_NTP_FLOAT_LIST(a_idFloat+1)));
   title(label, 'FontSize', 14);
   return;
end

param1Axes = subplot(1, 2, 1);
param2Axes = subplot(1, 2, 2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the PARAM1 data

minParam1 = g_NTP_NAME_PARAM1_FILL_VAL;
maxParam1 = -g_NTP_NAME_PARAM1_FILL_VAL;
minPres1 = g_NTP_PARAM_PRES_FILL_VAL;
maxPres1 = -g_NTP_PARAM_PRES_FILL_VAL;

[maxMesAscProf, ~] = size(g_NTP_tabPres1);
xParam1Data = ones(maxMesAscProf, g_NTP_nbCyles)*g_NTP_NAME_PARAM1_FILL_VAL;
xParam1DataQc = repmat(' ', maxMesAscProf, g_NTP_nbCyles);
yParam1Data = ones(maxMesAscProf, g_NTP_nbCyles)*g_NTP_PARAM_PRES_FILL_VAL;
yParam1DataQc = repmat(' ', maxMesAscProf, g_NTP_nbCyles);
for idCy = 1:g_NTP_nbCyles
   if (a_idCycle+1+idCy-1 <= length(g_NTP_cycles))
      xParam1Data(:, idCy) = g_NTP_tabParam1(:, a_idCycle+1+idCy-1);
      xParam1DataQc(:, idCy) = g_NTP_tabParam1Qc(:, a_idCycle+1+idCy-1);
      yParam1Data(:, idCy) = g_NTP_tabPres1(:, a_idCycle+1+idCy-1);
      yParam1DataQc(:, idCy) = g_NTP_tabPres1Qc(:, a_idCycle+1+idCy-1);
   end
end
param1Data = xParam1Data(find(xParam1Data ~= g_NTP_NAME_PARAM1_FILL_VAL));
if (~isempty(param1Data))
   minParam1 = min(param1Data);
   maxParam1 = max(param1Data);
   pres1Data = yParam1Data(find(yParam1Data ~= g_NTP_PARAM_PRES_FILL_VAL));
   minPres1 = min(pres1Data);
   maxPres1 = max(pres1Data);
   
   if (minParam1 ~= g_NTP_NAME_PARAM1_FILL_VAL)
      minAxeParam1 = minParam1 - (maxParam1-minParam1)/6;
      maxAxeParam1 = maxParam1 + (maxParam1-minParam1)/6;
      if (minAxeParam1 == maxAxeParam1)
         minAxeParam1 = minAxeParam1 - 0.5;
      end
   end
   
   for idCy = 1:g_NTP_nbCyles
      if (a_idCycle+1+idCy-1 <= length(g_NTP_cycles))
         xParam1 = xParam1Data(:, idCy);
         xParam1Qc = xParam1DataQc(:, idCy);
         yParam1 = yParam1Data(:, idCy);
         yParam1Qc = yParam1DataQc(:, idCy);

         idKo = find((xParam1 == g_NTP_NAME_PARAM1_FILL_VAL) | (yParam1 == g_NTP_PARAM_PRES_FILL_VAL));
         xParam1(idKo) = [];
         xParam1Qc(idKo) = [];
         yParam1(idKo) = [];
         yParam1Qc(idKo) = [];
         
         if (~isempty(xParam1))
            idQc0 = find(xParam1Qc == g_decArgo_qcStrNoQc);
            plot(param1Axes, xParam1(idQc0), yParam1(idQc0), 'b.');
            hold(param1Axes, 'on');
            idQc1 = find((xParam1Qc == g_decArgo_qcStrGood) | (xParam1Qc == g_decArgo_qcStrProbablyGood) | (xParam1Qc == g_decArgo_qcStrChanged) | (xParam1Qc == g_decArgo_qcStrInterpolated));
            plot(param1Axes, xParam1(idQc1), yParam1(idQc1), 'g.');
            hold(param1Axes, 'on');
            idQc3 = find(xParam1Qc == g_decArgo_qcStrCorrectable);
            plot(param1Axes, xParam1(idQc3), yParam1(idQc3), 'm.');
            hold(param1Axes, 'on');
            idQc4 = find(xParam1Qc == g_decArgo_qcStrBad);
            plot(param1Axes, xParam1(idQc4), yParam1(idQc4), 'r.');
            hold(param1Axes, 'on');
            plot(param1Axes, xParam1, yParam1, 'b-');
            hold(param1Axes, 'on');
            
            idQc0 = find(yParam1Qc == g_decArgo_qcStrNoQc);
            plot(param1Axes, ones(length(idQc0), 1)*minAxeParam1, yParam1(idQc0), 'b.');
            hold(param1Axes, 'on');
            idQc1 = find((yParam1Qc == g_decArgo_qcStrGood) | (yParam1Qc == g_decArgo_qcStrProbablyGood) | (yParam1Qc == g_decArgo_qcStrChanged) | (yParam1Qc == g_decArgo_qcStrInterpolated));
            plot(param1Axes, ones(length(idQc1), 1)*minAxeParam1, yParam1(idQc1), 'g.');
            hold(param1Axes, 'on');
            idQc3 = find(yParam1Qc == g_decArgo_qcStrCorrectable);
            plot(param1Axes, ones(length(idQc3), 1)*minAxeParam1, yParam1(idQc3), 'm.');
            hold(param1Axes, 'on');
            idQc4 = find(yParam1Qc == g_decArgo_qcStrBad);
            plot(param1Axes, ones(length(idQc4), 1)*minAxeParam1, yParam1(idQc4), 'r.');
            hold(param1Axes, 'on');
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the PARAM2 data

minParam2 = g_NTP_NAME_PARAM2_FILL_VAL;
maxParam2 = -g_NTP_NAME_PARAM2_FILL_VAL;
minPres2 = g_NTP_PARAM_PRES_FILL_VAL;
maxPres2 = -g_NTP_PARAM_PRES_FILL_VAL;

[maxMesAscProf, ~] = size(g_NTP_tabPres2);
xParam2Data = ones(maxMesAscProf, g_NTP_nbCyles)*g_NTP_NAME_PARAM2_FILL_VAL;
xParam2DataQc = repmat(' ', maxMesAscProf, g_NTP_nbCyles);
yParam2Data = ones(maxMesAscProf, g_NTP_nbCyles)*g_NTP_PARAM_PRES_FILL_VAL;
yParam2DataQc = repmat(' ', maxMesAscProf, g_NTP_nbCyles);
for idCy = 1:g_NTP_nbCyles
   if (a_idCycle+1+idCy-1 <= length(g_NTP_cycles))
      xParam2Data(:, idCy) = g_NTP_tabParam2(:, a_idCycle+1+idCy-1);
      xParam2DataQc(:, idCy) = g_NTP_tabParam2Qc(:, a_idCycle+1+idCy-1);
      yParam2Data(:, idCy) = g_NTP_tabPres2(:, a_idCycle+1+idCy-1);
      yParam2DataQc(:, idCy) = g_NTP_tabPres2Qc(:, a_idCycle+1+idCy-1);
   end
end
param2Data = xParam2Data(find(xParam2Data ~= g_NTP_NAME_PARAM2_FILL_VAL));
if (~isempty(param2Data))
   minParam2 = min(param2Data);
   maxParam2 = max(param2Data);
   pres2Data = yParam2Data(find(yParam2Data ~= g_NTP_PARAM_PRES_FILL_VAL));
   minPres2 = min(pres2Data);
   maxPres2 = max(pres2Data);
      
   if (minParam2 ~= g_NTP_NAME_PARAM2_FILL_VAL)
      minAxeParam2 = minParam2 - (maxParam2-minParam2)/6;
      maxAxeParam2 = maxParam2 + (maxParam2-minParam2)/6;
      if (minAxeParam2 == maxAxeParam2)
         minAxeParam2 = minAxeParam2 - 0.1;
      end
   end
   
   for idCy = 1:g_NTP_nbCyles
      if (a_idCycle+1+idCy-1 <= length(g_NTP_cycles))
         xParam2 = xParam2Data(:, idCy);
         xParam2Qc = xParam2DataQc(:, idCy);
         yParam2 = yParam2Data(:, idCy);
         yParam2Qc = yParam2DataQc(:, idCy);
         
         idKo = find((xParam2 == g_NTP_NAME_PARAM2_FILL_VAL) | (yParam2 == g_NTP_PARAM_PRES_FILL_VAL));
         xParam2(idKo) = [];
         xParam2Qc(idKo) = [];
         yParam2(idKo) = [];
         yParam2Qc(idKo) = [];
         
         if (~isempty(xParam2))
            idQc0 = find(xParam2Qc == g_decArgo_qcStrNoQc);
            plot(param2Axes, xParam2(idQc0), yParam2(idQc0), 'b.');
            hold(param2Axes, 'on');
            idQc1 = find((xParam2Qc == g_decArgo_qcStrGood) | (xParam2Qc == g_decArgo_qcStrProbablyGood) | (xParam2Qc == g_decArgo_qcStrChanged) | (xParam2Qc == g_decArgo_qcStrInterpolated));
            plot(param2Axes, xParam2(idQc1), yParam2(idQc1), 'g.');
            hold(param2Axes, 'on');
            idQc3 = find((xParam2Qc == g_decArgo_qcStrCorrectable) | (xParam2Qc == g_decArgo_qcStrBad));
            plot(param2Axes, xParam2(idQc3), yParam2(idQc3), 'r.');
            hold(param2Axes, 'on');
            plot(param2Axes, xParam2, yParam2, 'b-');
            hold(param2Axes, 'on');
            
            idQc0 = find(yParam2Qc == g_decArgo_qcStrNoQc);
            plot(param2Axes, ones(length(idQc0), 1)*minAxeParam2, yParam2(idQc0), 'b.');
            hold(param2Axes, 'on');
            idQc1 = find((yParam2Qc == g_decArgo_qcStrGood) | (yParam2Qc == g_decArgo_qcStrProbablyGood) | (yParam2Qc == g_decArgo_qcStrChanged) | (yParam2Qc == g_decArgo_qcStrInterpolated));
            plot(param2Axes, ones(length(idQc1), 1)*minAxeParam2, yParam2(idQc1), 'g.');
            hold(param2Axes, 'on');
            idQc3 = find(yParam2Qc == g_decArgo_qcStrCorrectable);
            plot(param2Axes, ones(length(idQc3), 1)*minAxeParam2, yParam2(idQc3), 'm.');
            hold(param2Axes, 'on');
            idQc4 = find(yParam2Qc == g_decArgo_qcStrBad);
            plot(param2Axes, ones(length(idQc4), 1)*minAxeParam2, yParam2(idQc4), 'r.');
            hold(param2Axes, 'on');
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finalize the plots

% increasing pressures
set(param1Axes, 'YDir', 'reverse');
set(param2Axes, 'YDir', 'reverse');

% Y axis boundaries
minAxePres1 = minPres1;
maxAxePres1 = maxPres1;
if (minPres1 ~= g_NTP_PARAM_PRES_FILL_VAL)
   if (minAxePres1 > 0)
      minAxePres1 = 0;
   elseif (g_NTP_PROF_NUM ~= 1)
      minAxePres1 = 5*floor(minAxePres1/5);
   end
   if (g_NTP_PROF_NUM == 1)
      maxAxePres1 = 100*ceil(maxAxePres1/100);
   else
      maxAxePres1 = 5*ceil(maxAxePres1/5);
   end
   if (maxAxePres1 == 0)
      maxAxePres1 = 1;
   end
   if (minAxePres1 == maxAxePres1)
      maxAxePres1 = minAxePres1 + 1;
   end
end
minAxePres2 = minPres2;
maxAxePres2 = maxPres2;
if (minPres2 ~= g_NTP_PARAM_PRES_FILL_VAL)
   if (minAxePres2 > 0)
      minAxePres2 = 0;
   end
   if (g_NTP_PROF_NUM == 1)
      maxAxePres2 = 100*ceil(maxAxePres2/100);
   else
      maxAxePres2 = 5*ceil(maxAxePres2/5);
   end
   if (maxAxePres2 == 0)
      maxAxePres2 = 1;
   end
   if (minAxePres2 == maxAxePres2)
      maxAxePres2 = minAxePres2 + 1;
   end
end
set(param1Axes, 'Ylim', [min(minAxePres1, minAxePres2) max(maxAxePres1, maxAxePres2)]);
set(param2Axes, 'Ylim', [min(minAxePres1, minAxePres2) max(maxAxePres1, maxAxePres2)]);

% X axis boundaries
if (minParam1 ~= g_NTP_NAME_PARAM1_FILL_VAL)
   minAxeParam1 = minParam1 - (maxParam1-minParam1)/6;
   maxAxeParam1 = maxParam1 + (maxParam1-minParam1)/6;
   if (minAxeParam1 == maxAxeParam1)
      minAxeParam1 = minAxeParam1 - 0.5;
      maxAxeParam1 = maxAxeParam1 + 0.5;
   end
   set(param1Axes, 'Xlim', [minAxeParam1 maxAxeParam1]);
end
if (minParam2 ~= g_NTP_NAME_PARAM2_FILL_VAL)
   minAxeParam2 = minParam2 - (maxParam2-minParam2)/6;
   maxAxeParam2 = maxParam2 + (maxParam2-minParam2)/6;
   if (minAxeParam2 == maxAxeParam2)
      minAxeParam2 = minAxeParam2 - 0.1;
      maxAxeParam2 = maxAxeParam2 + 0.1;
   end
   set(param2Axes, 'Xlim', [minAxeParam2 maxAxeParam2]);
end

% titre des axes
set(get(param1Axes, 'XLabel'), 'String', regexprep([g_NTP_NAME_PARAM1 ' (' g_NTP_UNITS_PARAM1 ')'], '_', ' '));
set(get(param2Axes, 'XLabel'), 'String', regexprep([g_NTP_NAME_PARAM2 ' (' g_NTP_UNITS_PARAM2 ')'], '_', ' '));
set(get(param1Axes, 'YLabel'), 'String', 'Pressure (dbar)');
set(get(param2Axes, 'YLabel'), 'String', 'Pressure (dbar)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot title

idLastCycleNum = a_idCycle+1+g_NTP_nbCyles-1;
if (idLastCycleNum <= length(g_NTP_cycles))
   lastCycleNum = g_NTP_cycles(idLastCycleNum);
else
   lastCycleNum = g_NTP_cycles(end);
end
label = sprintf('%02d/%02d : float #%d %s and %s (cycles #%d to #%d)', ...
   a_idFloat+1, ...
   length(g_NTP_FLOAT_LIST), ...
   g_NTP_FLOAT_LIST(a_idFloat+1), ...
   regexprep(g_NTP_NAME_PARAM1, '_', ' '), regexprep(g_NTP_NAME_PARAM2, '_', ' '), ...
   g_NTP_cycles(a_idCycle+1), lastCycleNum);
suptitle(label);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pdf output management

if (g_NTP_PRINT)
   orient landscape
   print('-dpdf', [g_NTP_PDF_DIR '/' sprintf('nc_trace_param_%s_%03d_%03d', num2str(g_NTP_FLOAT_LIST(a_idFloat+1)), g_NTP_cycles(a_idCycle+1), g_NTP_cycles(a_idCycle+1+g_NTP_nbCyles-1)) '.pdf']);
   g_NTP_PRINT = 0;
   orient portrait
end

return;

% ------------------------------------------------------------------------------
% Callback de gestion des tracés:
%   - escape     : arrêt
%   - leftArrow  : flotteur précédent
%   - rightArrow : flotteur suivant
%   - upArrow    : lot de profils précédent
%   - downArrow  : lot de profils suivant
%   - "-"        : diminution du nombre de profils tracés par lot
%   - "+"        : augmentation du nombre de profils tracés par lot
%   - "a"        : tracé de tous les profils du flotteur
%   - "d"        : retour au tracé par lots par défaut
%   - "p"        : impression du tracé dans un fichier pdf
%   - "h"        : affichage de l'aide et de la configuration courante
%
% SYNTAX :
%   change_plot(a_src, a_eventData)
%
% INPUT PARAMETERS :
%   a_src       : objet source
%   a_eventData : évènement déclencheur
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : plot_pt_ps
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   20/11/2008 - RNU - creation
% ------------------------------------------------------------------------------
fprintf('Plot management:\n');
fprintf('   Right Arrow: next float\n');
fprintf('   Left Arrow : previous float\n');
fprintf('   Down Arrow : next set of profiles\n');
fprintf('   Up Arrow   : previous set of profiles\n');
fprintf('Plot:\n');
fprintf('   +/-: increase/decrease the number of profiles per set\n');
fprintf('   a  : plot all the profiles of the float\n');
fprintf('   d  : back to plot %d profiles per set\n', ...
   g_NTP_DEFAULT_NB_CYCLES);
fprintf('Misc:\n');
fprintf('   p: pdf output file generation\n');
fprintf('   h: write help and current configuration\n');
fprintf('Escape: exit\n\n');



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
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/03/2014 - RNU - creation
% ------------------------------------------------------------------------------
function change_plot(a_src, a_eventData)

global g_NTP_FIG_HANDLE;
global g_NTP_DEFAULT_NB_CYCLES;
global g_NTP_PRINT;

global g_NTP_ID_FLOAT g_NTP_FLOAT_LIST;
global g_NTP_idCycle g_NTP_nbCyles;
global g_NTP_cycles;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% exit
if (strcmp(a_eventData.Key, 'escape'))
   set(g_NTP_FIG_HANDLE, 'KeyPressFcn', '');
   close(g_NTP_FIG_HANDLE);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % previous float
elseif (strcmp(a_eventData.Key, 'leftarrow'))
   plot_pt_ps(mod(g_NTP_ID_FLOAT-1, length(g_NTP_FLOAT_LIST)), 0);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % next float
elseif (strcmp(a_eventData.Key, 'rightarrow'))
   plot_pt_ps(mod(g_NTP_ID_FLOAT+1, length(g_NTP_FLOAT_LIST)), 0);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % previous set of profiles
elseif (strcmp(a_eventData.Key, 'uparrow'))
   if (g_NTP_idCycle - g_NTP_nbCyles >= 0)
      g_NTP_idCycle = g_NTP_idCycle - g_NTP_nbCyles;
   else
      g_NTP_idCycle = 0;
   end
   plot_pt_ps(g_NTP_ID_FLOAT, g_NTP_idCycle);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % next set of profiles
elseif (strcmp(a_eventData.Key, 'downarrow'))
   if (g_NTP_idCycle + g_NTP_nbCyles + 1 <= length(g_NTP_cycles))
      g_NTP_idCycle = g_NTP_idCycle + g_NTP_nbCyles;
   end
   plot_pt_ps(g_NTP_ID_FLOAT, g_NTP_idCycle);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % decrease the number of profiles per set
elseif (strcmp(a_eventData.Character, '-'))
   if (g_NTP_nbCyles > 1)
      g_NTP_nbCyles = g_NTP_nbCyles - 1;
   end
   fprintf('Plot of %d profiles per set\n', g_NTP_nbCyles);
   plot_pt_ps(g_NTP_ID_FLOAT, g_NTP_idCycle);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % increase the number of profiles per set
elseif (strcmp(a_eventData.Character, '+'))
   if (g_NTP_nbCyles < length(g_NTP_cycles))
      g_NTP_nbCyles = g_NTP_nbCyles + 1;
   end
   fprintf('Plot of %d profiles per set\n', g_NTP_nbCyles);
   plot_pt_ps(g_NTP_ID_FLOAT, g_NTP_idCycle);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % plot all the profiles of the float
elseif (strcmp(a_eventData.Key, 'a'))
   g_NTP_nbCyles = length(g_NTP_cycles);
   fprintf('Plot of %d profiles per set\n', g_NTP_nbCyles);
   plot_pt_ps(g_NTP_ID_FLOAT, 0);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % back to plot the default number of displacements per set
elseif (strcmp(a_eventData.Key, 'd'))
   g_NTP_nbCyles = g_NTP_DEFAULT_NB_CYCLES;
   fprintf('Plot of %d profiles per set\n', g_NTP_nbCyles);
   plot_pt_ps(g_NTP_ID_FLOAT, 0);
   
   fprintf('\nCurrent configuration:\n');
   fprintf('NB PROFILES / SET: %d\n', g_NTP_nbCyles);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % pdf output file generation
elseif (strcmp(a_eventData.Key, 'p'))
   g_NTP_PRINT = 1;
   plot_pt_ps(g_NTP_ID_FLOAT, g_NTP_idCycle);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % write help and current configuration
elseif (strcmp(a_eventData.Key, 'h'))
   fprintf('Plot management:\n');
   fprintf('   Right Arrow: next float\n');
   fprintf('   Left Arrow : previous float\n');
   fprintf('   Down Arrow : next set of profiles\n');
   fprintf('   Up Arrow   : previous set of profiles\n');
   fprintf('Plot:\n');
   fprintf('   +/-: increase/decrease the number of profiles per set\n');
   fprintf('   a  : plot all the profiles of the float\n');
   fprintf('   d  : back to plot %d profiles per set\n', ...
      g_NTP_DEFAULT_NB_CYCLES);
   fprintf('Misc:\n');
   fprintf('   p: pdf output file generation\n');
   fprintf('   h: write help and current configuration\n');
   fprintf('Escape: exit\n\n');
   
   fprintf('Current configuration:\n');
   fprintf('NB PROFILES / SET: %d\n', g_NTP_nbCyles);
end

return;

