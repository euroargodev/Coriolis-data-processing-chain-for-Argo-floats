% ------------------------------------------------------------------------------
% Retrieve information (first and last Argos message dates) from the TRAJ file
% to compute the cycle number associated to the Argos input file.
%
% SYNTAX :
%  [o_cycleNumber, o_firstMsgDate, o_lastMsgDate] = ...
%    get_traj_data_for_cycle_number_determination(a_floatNum)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%
% OUTPUT PARAMETERS :
%   o_cycleNumber  : cycle numbers
%   o_firstMsgDate : first Argos message dates
%   o_lastMsgDate  : last Argos message dates
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleNumber, o_firstMsgDate, o_lastMsgDate] = ...
   get_traj_data_for_cycle_number_determination(a_floatNum)

% output parameters initialization
o_cycleNumber = [];
o_firstMsgDate = [];
o_lastMsgDate = [];

% default values
global g_decArgo_dateDef;

% input NetCDF directory
global g_decArgo_dirOutputTraj31NetcdfFile;
global g_decArgo_dirOutputTraj32NetcdfFile;

% global measurement codes
global g_MC_FMT;
global g_MC_LMT;


% netCDF TRAJ file pathname
% in the RT decoder when 'processmode' = 'profile' or 'redecode',
% g_decArgo_generateNcTraj32 and g_decArgo_generateNcTraj31 are set to 0, we are
% then not able to know which TRAJ version was usually needed.
% We then check for both versions with the priority to the 3.2 one.
ncTrajPathFileName = [g_decArgo_dirOutputTraj32NetcdfFile '/' num2str(a_floatNum) '/' num2str(a_floatNum) '_Rtraj.nc'];
if ~(exist(ncTrajPathFileName, 'file') == 2)
   ncTrajPathFileName = [g_decArgo_dirOutputTraj31NetcdfFile '/' num2str(a_floatNum) '/' num2str(a_floatNum) '_Rtraj.nc'];
end

if (exist(ncTrajPathFileName, 'file') == 2)
   
   % TRAJ variables to retrieve
   wantedTrajVars = [ ...
      {'JULD'} ...
      {'CYCLE_NUMBER'} ...
      {'MEASUREMENT_CODE'} ...
      ];
   
   % retrieve information from TRAJ netCDF file
   [trajData] = get_data_from_nc_file(ncTrajPathFileName, wantedTrajVars);
   
   % select FMT and LMT
   juld = [];
   cycleNumber = [];
   measCode = [];
   idVal = find(strcmp('JULD', trajData) == 1);
   if (~isempty(idVal))
      juld = trajData{idVal+1};
   end
   idVal = find(strcmp('CYCLE_NUMBER', trajData) == 1);
   if (~isempty(idVal))
      cycleNumber = trajData{idVal+1};
   end
   idVal = find(strcmp('MEASUREMENT_CODE', trajData) == 1);
   if (~isempty(idVal))
      measCode = trajData{idVal+1};
   end
   
   if (~isempty(juld) && ~isempty(cycleNumber) && ~isempty(measCode))
      idFLMT = find((measCode == g_MC_FMT) | (measCode == g_MC_LMT));
      o_cycleNumber = unique(cycleNumber(idFLMT));
      o_firstMsgDate = ones(length(o_cycleNumber), 1)*g_decArgo_dateDef;
      o_lastMsgDate = ones(length(o_cycleNumber), 1)*g_decArgo_dateDef;
      for id = 1:length(o_cycleNumber)
         idFMT = find((measCode == g_MC_FMT) & (cycleNumber == o_cycleNumber(id)));
         if (~isempty(idFMT))
            o_firstMsgDate(id) = juld(idFMT);
         end
         idLMT = find((measCode == g_MC_LMT) & (cycleNumber == o_cycleNumber(id)));
         if (~isempty(idLMT))
            o_lastMsgDate(id) = juld(idLMT);
         end
      end
   end
end

return
