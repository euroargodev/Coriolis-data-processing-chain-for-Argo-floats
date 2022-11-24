% ------------------------------------------------------------------------------
% Parse Apex Iridium descending pressure marks data from .log file.
%
% SYNTAX :
%  [o_pMarkData] = parse_apx_ir_pmark_data_evts(a_events)
%
% INPUT PARAMETERS :
%   a_events : input log file event data
%
% OUTPUT PARAMETERS :
%   o_pMarkData : descending pressure marks data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_pMarkData] = parse_apx_ir_pmark_data_evts(a_events)

% output parameters initialization
o_pMarkData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global time status
global g_JULD_STATUS_2;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

PATTERN_UNUSED = [ ...
   {'Unexpected buoyancy position:'} ...
   ];

PATTERN = 'Pressure:';

data = [];
for idEv = 1:length(a_events)
   dataStr = a_events(idEv).info;
   %    fprintf('''%s''\n', dataStr);
   
   if (any(strfind(dataStr, PATTERN)))
      
      dataStr2 = strtrim(dataStr(length(PATTERN)+1:end));
      [pMarValue, status] = str2num(dataStr2);
      if ((status) && (dataStr2(end-1) == '.'))
         data = [data; a_events(idEv).time  pMarValue];
      else
         fprintf('DEC_INFO: %sAnomaly detected while parsing P mark measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
      end
      
   else
      idF = cellfun(@(x) strfind(dataStr, x), PATTERN_UNUSED, 'UniformOutput', 0);
      if (isempty([idF{:}]))
         fprintf('DEC_INFO: %sAnomaly detected while parsing P mark measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
         continue
      end
   end
end

if (~isempty(data))
   
   % process P marks
   % create the parameters
   paramJuld = get_netcdf_param_attributes('JULD');
   paramPres = get_netcdf_param_attributes('PRES');
   
   % store drift data
   o_pMarkData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_pMarkData.dateList = paramJuld;
   o_pMarkData.paramList = paramPres;
   
   % add parameter data to the data structure
   o_pMarkData.dates = data(:, 1);
   o_pMarkData.data = data(:, 2);
   
   % add date status to the data structure
   o_pMarkData.datesStatus = repmat(g_JULD_STATUS_2, size(o_pMarkData.dates));
end

return
