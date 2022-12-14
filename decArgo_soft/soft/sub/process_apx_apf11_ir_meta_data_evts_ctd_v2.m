% ------------------------------------------------------------------------------
% Get CTD meta-data information from Apex APF11 events.
%
% SYNTAX :
%  [o_metaData] = process_apx_apf11_ir_meta_data_evts_ctd_v2(a_events, a_metaData)
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
function [o_metaData] = process_apx_apf11_ir_meta_data_evts_ctd_v2(a_events, a_metaData)

% output parameters initialization
o_metaData = a_metaData;


% get CTD useful information
for idEv = 1:length(a_events)
   evt = a_events(idEv);
   dataStr = evt.message;
   o_metaData = get_ctd_meta(dataStr, o_metaData);
end

% finalize meta-data
if (length(o_metaData) > length(a_metaData))
   
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_MODEL'));
   idF2 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_VERSION'));
   if (~isempty(idF1) && ~isempty(idF2))
      o_metaData(idF1).techParamValue = [ ...
         o_metaData(idF1).techParamValue '_V' o_metaData(idF2).techParamValue];
   end
   
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_SERIAL_NUMBER'));
   if (~isempty(idF1))
      metaData = o_metaData(idF1);
      metaData.metaConfigLabel = 'CTD_TEMP_SERIAL_NUMBER';
      o_metaData = [o_metaData metaData];
      metaData = o_metaData(idF1);
      metaData.metaConfigLabel = 'CTD_CNDC_SERIAL_NUMBER';
      o_metaData = [o_metaData metaData];
      o_metaData(idF1).techParamId = -1;
   end
   
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_TEMP_CALIB_DATE'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = [ ...
         'date of predeployment calibration: ' ...
         datestr(datenum(o_metaData(idF1).techParamValue, 'dd-mmm-YY'), 'yyyymmddHHMMSS')];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_DATE'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = [ ...
         'date of predeployment calibration: ' ...
         datestr(datenum(o_metaData(idF1).techParamValue, 'dd-mmm-YY'), 'yyyymmddHHMMSS')];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_DATE'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = [ ...
         'date of predeployment calibration: ' ...
         datestr(datenum(o_metaData(idF1).techParamValue, 'dd-mmm-YY'), 'yyyymmddHHMMSS')];
   end
   
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_TEMP_CALIB_COEF_TA0'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['a0=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_TEMP_CALIB_COEF_TA1'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['a1=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_TEMP_CALIB_COEF_TA2'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['a2=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_TEMP_CALIB_COEF_TA3'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['a3=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_G'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['g=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_H'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['h=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_I'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['i=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_J'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['j=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_CPCOR'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['CPcor=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_CTCOR'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['CTcor=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_WBOTC'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['WBOTC=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PA0'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['PA0=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PA1'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['PA1=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PA2'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['PA2=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTCA0'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['PTCA0=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTCA1'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['PTCA1=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTCA2'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['PTCA2=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTCB0'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['PTCB0=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTCB1'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['PTCB1=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTCB2'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['PTCB2=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTHA0'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['PTHA0=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTHA1'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['PTHA1=' o_metaData(idF1).techParamValue];
   end
   idF1 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTHA2'));
   if (~isempty(idF1))
      o_metaData(idF1).techParamValue = ['PTHA2=' o_metaData(idF1).techParamValue];
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve meta-data information from event label.
%
% SYNTAX :
%  [o_metaData] = get_ctd_meta(a_eventdata, a_metaData)
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
function [o_metaData] = get_ctd_meta(a_eventdata, a_metaData)

% output parameters initialization
o_metaData = a_metaData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


PATTERN_USED = [ ...
   {'Model:'} {'CTD_MODEL'}; ...
   {'Version:'} {'CTD_VERSION'}; ...
   {'Serial Number:'} {'CTD_SERIAL_NUMBER'}; ...
   {'pcutoff:'} {'CTD_PRES_CUT_OFF'}; ...
   {'temperature:'} {'CTD_TEMP_CALIB_DATE'}; ...
   {'temperature_1:'} {'CTD_TEMP_CALIB_DATE'}; ...
   {'temperature_2:'} {'CTD_TEMP_CALIB_DATE'}; ...
   {'TA0:'} {'CTD_TEMP_CALIB_COEF_TA0'}; ...
   {'TA1:'} {'CTD_TEMP_CALIB_COEF_TA1'}; ...
   {'TA2:'} {'CTD_TEMP_CALIB_COEF_TA2'}; ...
   {'TA3:'} {'CTD_TEMP_CALIB_COEF_TA3'}; ...
   {'conductivity:'} {'CTD_CNDC_CALIB_DATE'}; ...
   {'G:'} {'CTD_CNDC_CALIB_COEF_G'}; ...
   {'H:'} {'CTD_CNDC_CALIB_COEF_H'}; ...
   {'I:'} {'CTD_CNDC_CALIB_COEF_I'}; ...
   {'J:'} {'CTD_CNDC_CALIB_COEF_J'}; ...
   {'CPCOR:'} {'CTD_CNDC_CALIB_COEF_CPCOR'}; ...
   {'CTCOR:'} {'CTD_CNDC_CALIB_COEF_CTCOR'}; ...
   {'WBOTC:'} {'CTD_CNDC_CALIB_COEF_WBOTC'}; ...
   {'pressure S/N ='} {'CTD_PRES_SERIAL_NUMBER'}; ...
   {'PA0'} {'CTD_PRES_CALIB_COEF_PA0'}; ...
   {'PA1'} {'CTD_PRES_CALIB_COEF_PA1'}; ...
   {'PA2'} {'CTD_PRES_CALIB_COEF_PA2'}; ...
   {'PTCA0'} {'CTD_PRES_CALIB_COEF_PTCA0'}; ...
   {'PTCA1'} {'CTD_PRES_CALIB_COEF_PTCA1'}; ...
   {'PTCA2'} {'CTD_PRES_CALIB_COEF_PTCA2'}; ...
   {'PTCB0'} {'CTD_PRES_CALIB_COEF_PTCB0'}; ...
   {'PTCB1'} {'CTD_PRES_CALIB_COEF_PTCB1'}; ...
   {'PTCB2'} {'CTD_PRES_CALIB_COEF_PTCB2'}; ...
   {'PTHA0'} {'CTD_PRES_CALIB_COEF_PTHA0'}; ...
   {'PTHA1'} {'CTD_PRES_CALIB_COEF_PTHA1'}; ...
   {'PTHA2'} {'CTD_PRES_CALIB_COEF_PTHA2'} ...
   ];

idF = cellfun(@(x) strfind(a_eventdata, x), PATTERN_USED(:, 1), 'UniformOutput', 0);
idF = find(~cellfun(@isempty, idF) == 1);
if (~isempty(idF))
   
   metaId = PATTERN_USED{idF, 2};
   switch (metaId)
      case 'CTD_MODEL'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         value = regexprep(value, ' ', '');
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_MODEL'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_MODEL';
            metaData.techParamCode = 'SENSOR_MODEL';
            metaData.techParamId = 410;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_VERSION'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_VERSION'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_VERSION';
            metaData.techParamCode = 'SENSOR_VERSION';
            metaData.techParamId = -1;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_SERIAL_NUMBER'
         if (strncmp(a_eventdata, ['CTD|' PATTERN_USED{idF, 1}], length(['CTD|' PATTERN_USED{idF, 1}])))
            idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
            value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_SERIAL_NUMBER'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'CTD_SERIAL_NUMBER';
               metaData.techParamCode = 'SENSOR_SERIAL_NO';
               metaData.techParamId = 411;
               metaData.techParamValue = value;
               o_metaData = [o_metaData metaData];
            else
               if (~strcmp(o_metaData(idF3).techParamValue, value))
                  o_metaData(idF3).techParamValue = value;
               end
            end
         end
         
      case 'CTD_PRES_CUT_OFF'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = num2str(str2num(strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end))));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CUT_OFF'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CUT_OFF';
            metaData.techParamCode = 'CTD_CUT_OFF_PRESSURE';
            metaData.techParamId = 1910;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_TEMP_CALIB_DATE'
         if (strncmp(a_eventdata, ['CTD|' PATTERN_USED{idF, 1}], length(['CTD|' PATTERN_USED{idF, 1}])))
            idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
            value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
            idF3 = [];
            if (~isempty(o_metaData))
               idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_TEMP_CALIB_DATE'));
            end
            if (isempty(idF3))
               metaData = get_apx_meta_data_init_struct(1);
               metaData.metaConfigLabel = 'CTD_TEMP_CALIB_DATE';
               metaData.techParamCode = 'PREDEPLOYMENT_CALIB_COMMENT';
               metaData.techParamId = 418;
               metaData.techParamValue = value;
               o_metaData = [o_metaData metaData];
            else
               if (~strcmp(o_metaData(idF3).techParamValue, value))
                  o_metaData(idF3).techParamValue = value;
               end
            end
         end
         
      case 'CTD_TEMP_CALIB_COEF_TA0'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_TEMP_CALIB_COEF_TA0'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_TEMP_CALIB_COEF_TA0';
            metaData.techParamCode = 'SBE_TEMP_COEF_TA0';
            metaData.techParamId = 2416;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_TEMP_CALIB_COEF_TA1'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_TEMP_CALIB_COEF_TA1'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_TEMP_CALIB_COEF_TA1';
            metaData.techParamCode = 'SBE_TEMP_COEF_TA1';
            metaData.techParamId = 2417;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_TEMP_CALIB_COEF_TA2'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_TEMP_CALIB_COEF_TA2'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_TEMP_CALIB_COEF_TA2';
            metaData.techParamCode = 'SBE_TEMP_COEF_TA2';
            metaData.techParamId = 2418;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_TEMP_CALIB_COEF_TA3'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_TEMP_CALIB_COEF_TA3'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_TEMP_CALIB_COEF_TA3';
            metaData.techParamCode = 'SBE_TEMP_COEF_TA3';
            metaData.techParamId = 2419;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_CNDC_CALIB_DATE'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_DATE'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_CNDC_CALIB_DATE';
            metaData.techParamCode = 'PREDEPLOYMENT_CALIB_COMMENT';
            metaData.techParamId = 418;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_CNDC_CALIB_COEF_G'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_G'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_CNDC_CALIB_COEF_G';
            metaData.techParamCode = 'SBE_CNDC_COEF_G';
            metaData.techParamId = 2420;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_CNDC_CALIB_COEF_H'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_H'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_CNDC_CALIB_COEF_H';
            metaData.techParamCode = 'SBE_CNDC_COEF_H';
            metaData.techParamId = 2421;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_CNDC_CALIB_COEF_I'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_I'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_CNDC_CALIB_COEF_I';
            metaData.techParamCode = 'SBE_CNDC_COEF_I';
            metaData.techParamId = 2422;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_CNDC_CALIB_COEF_J'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_J'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_CNDC_CALIB_COEF_J';
            metaData.techParamCode = 'SBE_CNDC_COEF_J';
            metaData.techParamId = 2423;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_CNDC_CALIB_COEF_CPCOR'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_CPCOR'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_CNDC_CALIB_COEF_CPCOR';
            metaData.techParamCode = 'SBE_CNDC_COEF_CPCOR';
            metaData.techParamId = 2424;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_CNDC_CALIB_COEF_CTCOR'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_CTCOR'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_CNDC_CALIB_COEF_CTCOR';
            metaData.techParamCode = 'SBE_CNDC_COEF_CTCOR';
            metaData.techParamId = 2425;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_CNDC_CALIB_COEF_WBOTC'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_CNDC_CALIB_COEF_WBOTC'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_CNDC_CALIB_COEF_WBOTC';
            metaData.techParamCode = 'SBE_CNDC_COEF_WBOTC';
            metaData.techParamId = 2426;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_SERIAL_NUMBER'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         idF2bis = strfind(a_eventdata, ',');
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:idF2bis-1));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_SERIAL_NUMBER'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_SERIAL_NUMBER';
            metaData.techParamCode = 'SENSOR_SERIAL_NO';
            metaData.techParamId = 411;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
         idF2 = strfind(a_eventdata, ':');
         value = strtrim(a_eventdata(idF2+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_DATE'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_DATE';
            metaData.techParamCode = 'PREDEPLOYMENT_CALIB_COMMENT';
            metaData.techParamId = 418;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_CALIB_COEF_PA0'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PA0'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_COEF_PA0';
            metaData.techParamCode = 'SBE_PRES_COEF_PA0';
            metaData.techParamId = 2427;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_CALIB_COEF_PA1'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PA1'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_COEF_PA1';
            metaData.techParamCode = 'SBE_PRES_COEF_PA1';
            metaData.techParamId = 2428;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_CALIB_COEF_PA2'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PA2'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_COEF_PA2';
            metaData.techParamCode = 'SBE_PRES_COEF_PA2';
            metaData.techParamId = 2429;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_CALIB_COEF_PTCA0'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTCA0'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_COEF_PTCA0';
            metaData.techParamCode = 'SBE_PRES_COEF_PTCA0';
            metaData.techParamId = 2430;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_CALIB_COEF_PTCA1'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTCA1'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_COEF_PTCA1';
            metaData.techParamCode = 'SBE_PRES_COEF_PTCA1';
            metaData.techParamId = 2431;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_CALIB_COEF_PTCA2'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTCA2'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_COEF_PTCA2';
            metaData.techParamCode = 'SBE_PRES_COEF_PTCA2';
            metaData.techParamId = 2432;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_CALIB_COEF_PTCB0'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTCB0'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_COEF_PTCB0';
            metaData.techParamCode = 'SBE_PRES_COEF_PTCB0';
            metaData.techParamId = 2433;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_CALIB_COEF_PTCB1'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTCB1'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_COEF_PTCB1';
            metaData.techParamCode = 'SBE_PRES_COEF_PTCB1';
            metaData.techParamId = 2434;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_CALIB_COEF_PTCB2'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTCB2'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_COEF_PTCB2';
            metaData.techParamCode = 'SBE_PRES_COEF_PTCB2';
            metaData.techParamId = 2435;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_CALIB_COEF_PTHA0'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTHA0'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_COEF_PTHA0';
            metaData.techParamCode = 'SBE_PRES_COEF_PTHA0';
            metaData.techParamId = 2436;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_CALIB_COEF_PTHA1'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTHA1'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_COEF_PTHA1';
            metaData.techParamCode = 'SBE_PRES_COEF_PTHA1';
            metaData.techParamId = 2437;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
            end
         end
         
      case 'CTD_PRES_CALIB_COEF_PTHA2'
         idF2 = strfind(a_eventdata, PATTERN_USED{idF, 1});
         value = strtrim(a_eventdata(idF2+length(PATTERN_USED{idF, 1})+1:end));
         idF3 = [];
         if (~isempty(o_metaData))
            idF3 = find(strcmp({o_metaData.metaConfigLabel}, 'CTD_PRES_CALIB_COEF_PTHA2'));
         end
         if (isempty(idF3))
            metaData = get_apx_meta_data_init_struct(1);
            metaData.metaConfigLabel = 'CTD_PRES_CALIB_COEF_PTHA2';
            metaData.techParamCode = 'SBE_PRES_COEF_PTHA2';
            metaData.techParamId = 2438;
            metaData.techParamValue = value;
            o_metaData = [o_metaData metaData];
         else
            if (~strcmp(o_metaData(idF3).techParamValue, value))
               o_metaData(idF3).techParamValue = value;
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
