% ------------------------------------------------------------------------------
% Update the float surface data structure with the previous excluded cycles.
%
% SYNTAX :
%  [o_floatSurfData] = update_previous_cycle_surf_data( ...
%    a_floatSurfData, a_floatArgosId, a_floatNum, a_frameLength, ...
%    a_excludedCycleList, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_floatSurfData     : input float surface data structure
%   a_floatArgosId      : float PTT number
%   a_floatNum          : float WMO number
%   a_frameLength       : Argos data frame length
%   a_excludedCycleList : excluded cycle numbers
%   a_cycleNum          : current cycle number
%
% OUTPUT PARAMETERS :
%   o_floatSurfData : updated float surface data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/03/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatSurfData] = update_previous_cycle_surf_data( ...
   a_floatSurfData, a_floatArgosId, a_floatNum, a_frameLength, ...
   a_excludedCycleList, a_cycleNum)

% output parameters initialization
o_floatSurfData = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef
global g_decArgo_argosLatDef;


% update the surface data structure for the excluded cycles
idCycleToProcess = find((a_excludedCycleList < a_cycleNum) & ...
   (a_excludedCycleList > a_floatSurfData.updatedForCycleNumber));
cycleToProcess = a_excludedCycleList(idCycleToProcess);

for idCy = 1:length(cycleToProcess)
   cyNum = cycleToProcess(idCy);
   
   % get the Argos file name(s) for this cycle
   [argosPathFileName, unused] = get_argos_path_file_name(a_floatArgosId, a_floatNum, cyNum, g_decArgo_dateDef);
   
   % read Argos file(s)
   [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
      argosDataDate, argosDataData] = read_argos_file(argosPathFileName, a_floatArgosId, a_frameLength);
   
   % retrieve the previous cycle locations
   [prevCycleNum, lastLocDate, lastLocLon, lastLocLat, lastMsgDate] = ...
      get_previous_cycle_surf_data(a_floatSurfData, cyNum);
   
   % compute the JAMSTEC QC for the cycle locations
   lastLocDateOfPrevCycle = g_decArgo_dateDef;
   lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
   lastLocLatOfPrevCycle = g_decArgo_argosLatDef;
   if (~isempty(prevCycleNum))
      if (prevCycleNum == cyNum-1)
         lastLocDateOfPrevCycle = lastLocDate;
         lastLocLonOfPrevCycle = lastLocLon;
         lastLocLatOfPrevCycle = lastLocLat;
      end
   end
   
   [argosLocQc] = compute_jamstec_qc( ...
      argosLocDate, argosLocLon, argosLocLat, argosLocAcc, ...
      lastLocDateOfPrevCycle, lastLocLonOfPrevCycle, lastLocLatOfPrevCycle, []);
   
   % initialize the cycle surface data structure
   cycleSurfData = get_cycle_surf_data_init_struct;

   % store the cycle surface data in the structure
   cycleSurfData.firstMsgTime = min([argosLocDate; argosDataDate]);
   cycleSurfData.lastMsgTime = max([argosLocDate; argosDataDate]);
   cycleSurfData.argosLocDate = argosLocDate;
   cycleSurfData.argosLocLon = argosLocLon;
   cycleSurfData.argosLocLat = argosLocLat;
   cycleSurfData.argosLocAcc = argosLocAcc;
   cycleSurfData.argosLocSat = argosLocSat;
   cycleSurfData.argosLocQc = argosLocQc;
   
   % update the float surface data structure
   a_floatSurfData.cycleNumbers = [a_floatSurfData.cycleNumbers cyNum];
   a_floatSurfData.cycleData = [a_floatSurfData.cycleData cycleSurfData];
end

% update the float surface data structure
a_floatSurfData.updatedForCycleNumber = a_cycleNum;

% output data
o_floatSurfData = a_floatSurfData;

return
