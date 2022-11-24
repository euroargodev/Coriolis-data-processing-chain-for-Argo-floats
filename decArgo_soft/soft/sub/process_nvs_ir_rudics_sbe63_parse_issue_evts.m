% ------------------------------------------------------------------------------
% Parse and process Navis SBE 63 data from log file (measurements that
% experienced a parsing issue).
%
% SYNTAX :
%  [o_sbe63ParseIssueData] = process_nvs_ir_rudics_sbe63_parse_issue_evts(a_events)
%
% INPUT PARAMETERS :
%   a_events : input log file event data
%
% OUTPUT PARAMETERS :
%   o_sbe63ParseIssueData : SBE 63 data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sbe63ParseIssueData] = process_nvs_ir_rudics_sbe63_parse_issue_evts(a_events)

% output parameters initialization
o_sbe63ParseIssueData = [];

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
   
HEADER = 'Regex violation:';

data = [];
for idEv = 1:length(a_events)
   dataStr = a_events(idEv).info;
   %    fprintf('''%s''\n', dataStr);
   
   if (any(strfind(dataStr, HEADER)))
      
      [val, count, errmsg, nextIndex] = sscanf(dataStr, 'Regex violation: [%f,%f,%f,%f]');
      if (isempty(errmsg) && (count == 4))
         data = [data; a_events(idEv).time val(1) val(4)];
      end
   else
      fprintf('DEC_INFO: %sAnomaly detected while parsing surface measurements (from evts) ''%s'' => ignored\n', errorHeader, dataStr);
   end
end

if (~isempty(data))
   
   % create the parameters
   paramJuld = get_netcdf_param_attributes('JULD');
   paramPhaseDelayDoxy = get_netcdf_param_attributes('PHASE_DELAY_DOXY2');
   paramTempDoxy2 = get_netcdf_param_attributes('TEMP_DOXY2');
   
   % store surface data
   o_sbe63ParseIssueData = get_apx_profile_data_init_struct;
   
   % add parameter variables to the data structure
   o_sbe63ParseIssueData.dateList = paramJuld;
   o_sbe63ParseIssueData.paramList = [paramPhaseDelayDoxy paramTempDoxy2];
   
   % add parameter data to the data structure
   o_sbe63ParseIssueData.dates = data(:, 1);
   o_sbe63ParseIssueData.data = data(:, 2:3);
   
   % add date status to the data structure
   o_sbe63ParseIssueData.datesStatus = repmat(g_JULD_STATUS_2, size(o_sbe63ParseIssueData.dates));

end

return
