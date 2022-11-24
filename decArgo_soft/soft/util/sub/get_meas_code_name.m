% ------------------------------------------------------------------------------
% Associate a label to a given measurement code.
%
% SYNTAX :
%  [o_measCodeName] = get_meas_code_name(a_measCode)
%
% INPUT PARAMETERS :
%   a_measCode : measurement code
%
% OUTPUT PARAMETERS :
%   o_measCodeName : measurement code associated label
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/23/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_measCodeName] = get_meas_code_name(a_measCode)

o_measCodeName = '';

% global measurement codes
global g_MC_Launch;
global g_MC_CycleStart;
global g_MC_PressureOffset
global g_MC_DST;
global g_MC_MinPresInDriftAtParkSupportMeas;
global g_MC_MaxPresInDriftAtParkSupportMeas;
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
global g_MC_DescProfDeepestBin;
global g_MC_DET;
global g_MC_PST;
global g_MC_SpyAtPark;
global g_MC_DriftAtPark;
global g_MC_DriftAtParkStd;
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
global g_MC_AET;
global g_MC_AET_Float;
global g_MC_InAirSingleMeas;
global g_MC_TST;
global g_MC_TST_Float;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;
global g_MC_Grounded;


switch (a_measCode)
   
   case g_MC_Launch
      o_measCodeName = sprintf('%03d: FLOAT_LAUNCH', a_measCode);
      
   case g_MC_CycleStart
      o_measCodeName = sprintf('%03d: CYCLE_START', a_measCode);
      
   case g_MC_PressureOffset
      o_measCodeName = sprintf('%03d: PRESSURE_OFFSET', a_measCode);
      
   case g_MC_DST
      o_measCodeName = sprintf('%03d: DESCENT_START', a_measCode);
      
   case g_MC_MinPresInDriftAtParkSupportMeas
      o_measCodeName = sprintf('%03d: MIN_MEAS_DRIFT_AT_PARK_SUPPORT_MEAS', a_measCode);
      
   case g_MC_MaxPresInDriftAtParkSupportMeas
      o_measCodeName = sprintf('%03d: MAX_MEAS_DRIFT_AT_PARK_SUPPORT_MEAS', a_measCode);
      
   case g_MC_FST
      o_measCodeName = sprintf('%03d: FIRST_STABILIZATION', a_measCode);
      
   case g_MC_SpyInDescToPark
      o_measCodeName = sprintf('%03d: BUOY_ACTION_DESC_TO_PARK', a_measCode);
      
   case g_MC_DescProf
      o_measCodeName = sprintf('%03d: DESC_PROF', a_measCode);
      
   case g_MC_MaxPresInDescToPark
      o_measCodeName = sprintf('%03d: MAX_P_DESC_TO_PARK', a_measCode);
      
   case g_MC_DescProfDeepestBin
      o_measCodeName = sprintf('%03d: DESC_PROF_DEEPEST_MEAS', a_measCode);
      
   case g_MC_DET
      o_measCodeName = sprintf('%03d: DESCENT_END', a_measCode);
      
   case g_MC_PST
      o_measCodeName = sprintf('%03d: PARK_START', a_measCode);
      
   case g_MC_SpyAtPark
      o_measCodeName = sprintf('%03d: BUOY_ACTION_DRIFT_AT_PARK', a_measCode);
      
   case g_MC_DriftAtPark
      o_measCodeName = sprintf('%03d: DRIFT_AT_PARK', a_measCode);
      
   case g_MC_DriftAtParkStd
      o_measCodeName = sprintf('%03d: DRIFT_AT_PARK_STD', a_measCode);
      
   case g_MC_DriftAtParkMean
      o_measCodeName = sprintf('%03d: DRIFT_AT_PARK_MEAN', a_measCode);
      
   case g_MC_MinPresInDriftAtPark
      o_measCodeName = sprintf('%03d: MIN_MEAS_DRIFT_AT_PARK', a_measCode);
      
   case g_MC_MaxPresInDriftAtPark
      o_measCodeName = sprintf('%03d: MAX_MEAS_DRIFT_AT_PARK', a_measCode);
      
   case g_MC_PET
      o_measCodeName = sprintf('%03d: PARK_END', a_measCode);
      
   case g_MC_RPP
      o_measCodeName = sprintf('%03d: REPRESENTATIVE_PARK_MEAS', a_measCode);
      
   case g_MC_SpyInDescToProf
      o_measCodeName = sprintf('%03d: BUOY_ACTION_DESC_TO_PROF', a_measCode);
      
   case g_MC_MaxPresInDescToProf
      o_measCodeName = sprintf('%03d: MAX_P_DESC_TO_PROF', a_measCode);
      
   case g_MC_DDET
      o_measCodeName = sprintf('%03d: DEEP_DESCENT_END', a_measCode);
      
   case g_MC_DPST
      o_measCodeName = sprintf('%03d: DEEP_PARK_START', a_measCode);
      
   case g_MC_SpyAtProf
      o_measCodeName = sprintf('%03d: BUOY_ACTION_DRIFT_AT_PROF', a_measCode);
      
   case g_MC_MinPresInDriftAtProf
      o_measCodeName = sprintf('%03d: MIN_MEAS_DRIFT_AT_PROF', a_measCode);
      
   case g_MC_MaxPresInDriftAtProf
      o_measCodeName = sprintf('%03d: MAX_MEAS_DRIFT_AT_PROF', a_measCode);

   case g_MC_AST
      o_measCodeName = sprintf('%03d: ASCENT_START', a_measCode);
      
   case g_MC_DownTimeEnd
      o_measCodeName = sprintf('%03d: DOWN_TIME_END', a_measCode);
      
   case g_MC_AST_Float
      o_measCodeName = sprintf('%03d: ASCENT_START_FROM_FLOAT', a_measCode);
      
   case g_MC_AscProfDeepestBin
      o_measCodeName = sprintf('%03d: ASC_PROF_DEEPEST_MEAS', a_measCode);

   case g_MC_SpyInAscProf
      o_measCodeName = sprintf('%03d: BUOY_ACTION_ASC_TO_SURFACE', a_measCode);
      
   case g_MC_AscProf
      o_measCodeName = sprintf('%03d: ASC_PROF', a_measCode);
      
   case g_MC_MedianValueInAscProf
      o_measCodeName = sprintf('%03d: MEDIAN_IN_ASC_PROF', a_measCode);
      
   case g_MC_LastAscPumpedCtd
      o_measCodeName = sprintf('%03d: LAST_PUMPED_CTD_MEAS', a_measCode);
      
   case g_MC_AET
      o_measCodeName = sprintf('%03d: ASCENT_END', a_measCode);
      
   case g_MC_AET_Float
      o_measCodeName = sprintf('%03d: ASCENT_END_FROM_FLOAT', a_measCode);
      
   case g_MC_InAirSingleMeas
      o_measCodeName = sprintf('%03d: IN_AIR_MEAS', a_measCode);

   case g_MC_TST
      o_measCodeName = sprintf('%03d: TRANSMISSION_START', a_measCode);

   case g_MC_TST_Float
      o_measCodeName = sprintf('%03d: TRANSMISSION_START_FROM_FLOAT', a_measCode);

   case g_MC_FMT
      o_measCodeName = sprintf('%03d: FIRST_MESSAGE', a_measCode);

   case g_MC_Surface
      o_measCodeName = sprintf('%03d: SURFACE', a_measCode);

   case g_MC_LMT
      o_measCodeName = sprintf('%03d: LAST_MESSAGE', a_measCode);

   case g_MC_TET
      o_measCodeName = sprintf('%03d: TRANSMISSION_END', a_measCode);

   case g_MC_Grounded
      o_measCodeName = sprintf('%03d: GROUNDED', a_measCode);
   
   otherwise
      o_measCodeName = num2str(a_measCode);
      fprintf('WARNING: no meas code name for meas code #%d\n', ...
         a_measCode);

end

return;
