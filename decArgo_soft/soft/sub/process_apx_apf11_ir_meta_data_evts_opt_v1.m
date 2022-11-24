% ------------------------------------------------------------------------------
% Get OPTODE meta-data information from Apex APF11 events.
%
% SYNTAX :
%  [o_metaData] = process_apx_apf11_ir_meta_data_evts_opt_v1_1121_to_24_26_27(a_events, a_metaData)
%
% INPUT PARAMETERS :
%   a_events   : input system_log file event data
%   a_metaData : input meta-data
%
% OUTPUT PARAMETERS :
%   o_metaData : output meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/02/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = process_apx_apf11_ir_meta_data_evts_opt_v1(a_events, a_metaData)

% output parameters initialization
o_metaData = a_metaData;


% get OPTODE useful information
PATTERN_START = 'Optode ';
for idEv = 1:length(a_events)
   evt = a_events(idEv);
   dataStr = evt.message;
   if (strncmp(dataStr, PATTERN_START, length(PATTERN_START)))
      o_metaData = get_optode_meta(dataStr, o_metaData);
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve meta-data information from event label.
%
% SYNTAX :
%  [o_metaData] = get_optode_meta(a_eventdata, a_metaData)
%
% INPUT PARAMETERS :
%   a_eventdata : event label
%   a_metaData  : input meta-data
%
% OUTPUT PARAMETERS :
%   o_metaData  : output (updated) meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/05/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = get_optode_meta(a_eventdata, a_metaData)

% output parameters initialization
o_metaData = a_metaData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


PATTERN_USED = [ ...
   {'Optode Serial Number:'} {'OPTODE_SERIAL_NUMBER'}; ...
   {'Optode PhaseCoef:'} {'AANDERAA_OPTODE_PHASE_COEF_'}; ...
   {'Optode SVUFoilCoef:'} {'AANDERAA_OPTODE_COEF_'} ...
   ];

idF = cellfun(@(x) strfind(a_eventdata, x), PATTERN_USED(:, 1), 'UniformOutput', 0);
idF = find(~cellfun(@isempty, idF) == 1);
if (~isempty(idF))
   
   metaId = PATTERN_USED{idF, 2};
   switch (metaId)
      case 'OPTODE_SERIAL_NUMBER'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'OPTODE_SERIAL_NUMBER'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'OPTODE_SERIAL_NUMBER';
            metaData.techParamCode = 'SENSOR_SERIAL_NO';
            metaData.techParamId = 411;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'AANDERAA_OPTODE_PHASE_COEF_'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idSep = strfind(value, ' ');
         if (length(idSep) == 3)
            
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'AANDERAA_OPTODE_PHASE_COEF_0'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'AANDERAA_OPTODE_PHASE_COEF_0';
               metaData.techParamCode = 'AANDERAA_OPTODE_PHASE_COEF_0';
               metaData.techParamId = 1647;
               metaData.techParamValue = value(1:idSep(1)-1);
               o_metaData = [o_metaData metaData];
            else
               o_metaData(idF3).techParamValue = value(1:idSep(1)-1);
            end
            
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'AANDERAA_OPTODE_PHASE_COEF_1'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'AANDERAA_OPTODE_PHASE_COEF_1';
               metaData.techParamCode = 'AANDERAA_OPTODE_PHASE_COEF_1';
               metaData.techParamId = 1648;
               metaData.techParamValue = value(idSep(1)+1:idSep(2)-1);
               o_metaData = [o_metaData metaData];
            else
               o_metaData(idF3).techParamValue = value(idSep(1)+1:idSep(2)-1);
            end
            
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'AANDERAA_OPTODE_PHASE_COEF_2'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'AANDERAA_OPTODE_PHASE_COEF_2';
               metaData.techParamCode = 'AANDERAA_OPTODE_PHASE_COEF_2';
               metaData.techParamId = 1649;
               metaData.techParamValue = value(idSep(2)+1:idSep(3)-1);
               o_metaData = [o_metaData metaData];
            else
               o_metaData(idF3).techParamValue = value(idSep(2)+1:idSep(3)-1);
            end
            
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'AANDERAA_OPTODE_PHASE_COEF_3'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'AANDERAA_OPTODE_PHASE_COEF_3';
               metaData.techParamCode = 'AANDERAA_OPTODE_PHASE_COEF_3';
               metaData.techParamId = 1650;
               metaData.techParamValue = value(idSep(3)+1:end);
               o_metaData = [o_metaData metaData];
            else
               o_metaData(idF3).techParamValue = value(idSep(3)+1:end);
            end
         end
         
      case 'AANDERAA_OPTODE_COEF_'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idSep = strfind(value, ' ');
         if (length(idSep) == 6)
            
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'AANDERAA_OPTODE_COEF_0'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'AANDERAA_OPTODE_COEF_0';
               metaData.techParamCode = 'AANDERAA_OPTODE_COEF_0';
               metaData.techParamId = 1362;
               metaData.techParamValue = value(1:idSep(1)-1);
               o_metaData = [o_metaData metaData];
            else
               o_metaData(idF3).techParamValue = value(1:idSep(1)-1);
            end
            
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'AANDERAA_OPTODE_COEF_1'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'AANDERAA_OPTODE_COEF_1';
               metaData.techParamCode = 'AANDERAA_OPTODE_COEF_1';
               metaData.techParamId = 1363;
               metaData.techParamValue = value(idSep(1)+1:idSep(2)-1);
               o_metaData = [o_metaData metaData];
            else
               o_metaData(idF3).techParamValue = value(idSep(1)+1:idSep(2)-1);
            end
            
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'AANDERAA_OPTODE_COEF_2'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'AANDERAA_OPTODE_COEF_2';
               metaData.techParamCode = 'AANDERAA_OPTODE_COEF_2';
               metaData.techParamId = 1364;
               metaData.techParamValue = value(idSep(2)+1:idSep(3)-1);
               o_metaData = [o_metaData metaData];
            else
               o_metaData(idF3).techParamValue = value(idSep(2)+1:idSep(3)-1);
            end
            
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'AANDERAA_OPTODE_COEF_3'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'AANDERAA_OPTODE_COEF_3';
               metaData.techParamCode = 'AANDERAA_OPTODE_COEF_3';
               metaData.techParamId = 1365;
               metaData.techParamValue = value(idSep(3)+1:idSep(4)-1);
               o_metaData = [o_metaData metaData];
            else
               o_metaData(idF3).techParamValue = value(idSep(3)+1:idSep(4)-1);
            end
            
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'AANDERAA_OPTODE_COEF_4'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'AANDERAA_OPTODE_COEF_4';
               metaData.techParamCode = 'AANDERAA_OPTODE_COEF_4';
               metaData.techParamId = 1366;
               metaData.techParamValue = value(idSep(4)+1:idSep(5)-1);
               o_metaData = [o_metaData metaData];
            else
               o_metaData(idF3).techParamValue = value(idSep(4)+1:idSep(5)-1);
            end
            
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'AANDERAA_OPTODE_COEF_5'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'AANDERAA_OPTODE_COEF_5';
               metaData.techParamCode = 'AANDERAA_OPTODE_COEF_5';
               metaData.techParamId = 1367;
               metaData.techParamValue = value(idSep(5)+1:idSep(6)-1);
               o_metaData = [o_metaData metaData];
            else
               o_metaData(idF3).techParamValue = value(idSep(5)+1:idSep(6)-1);
            end
            
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'AANDERAA_OPTODE_COEF_6'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'AANDERAA_OPTODE_COEF_6';
               metaData.techParamCode = 'AANDERAA_OPTODE_COEF_6';
               metaData.techParamId = 1368;
               metaData.techParamValue = value(idSep(6)+1:end);
               o_metaData = [o_metaData metaData];
            else
               o_metaData(idF3).techParamValue = value(idSep(6)+1:end);
            end
         end
         
      otherwise
         fprintf('WARNING: Float #%d Cycle #%d: Not managed meta information ''%s''\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            metaId);
   end
   
end

return
