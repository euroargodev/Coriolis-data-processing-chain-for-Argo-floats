% ------------------------------------------------------------------------------
% Retrieve global comment on some specific measurement codes for a given decoder.
%
% SYNTAX :
%  [o_comment] = get_global_comment_on_measurement_code(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_comment : output comment
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/11/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_comment] = get_global_comment_on_measurement_code(a_decoderId)

% output parameter initialization
o_comment = '';


% retrieve the liste of MCs for this decoder Id
mcList = get_mc_list(a_decoderId);

if (~isempty(mcList))
   for idM = 1:length(mcList)
      mcComment = get_comment(mcList(idM), a_decoderId);
      if (~isempty(mcComment))
         o_comment = [o_comment sprintf('%d: %s, ', mcList(idM), mcComment)];
      end
   end
   if (~isempty(o_comment))
      o_comment = ['Meaning of some specific measurement codes for this float: ' o_comment(1:end-2)];
   end
end

return;

% ------------------------------------------------------------------------------
% Retrieve the list of measurement codes for a given decoder.
%
% SYNTAX :
%  [o_mcList] = get_mc_list(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_mcList : list of MCs
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/11/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_mcList] = get_mc_list(a_decoderId)

% output parameters initialization
o_mcList = [];

% current float WMO number
global g_decArgo_floatNum;

% global measurement codes
global g_MC_FillValue;
global g_MC_Launch;
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_PressureOffset
global g_MC_MinPresInDriftAtParkSupportMeas;
global g_MC_MaxPresInDriftAtParkSupportMeas;
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
global g_MC_DET;
global g_MC_DescProfDeepestBin;
global g_MC_PST;
global g_MC_SpyAtPark;
global g_MC_DriftAtPark;
global g_MC_DriftAtParkStd;
global g_MC_DriftAtParkMeanOfDiff;
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
global g_MC_ContinuousProfileStartOrStop;
global g_MC_AET;
global g_MC_AET_Float;
global g_MC_SpyAtSurface;
global g_MC_TST;
global g_MC_TST_Float;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;
global g_MC_Grounded;

global g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST;
global g_MC_InAirSingleMeasRelativeToTST;
global g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSingleMeasRelativeToTET;


switch (a_decoderId)

   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 31}
      % Provor/Arvor Argos pre-Naos 2013
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_DST ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_AscProf ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         ];
      
   case {30, 32}
      % Provor/Arvor Argos post-Naos 2013
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_AST ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_AscProf ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];

   case {201, 202, 203}
      % Arvor Deep without "NS & IA"
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_SpyInDescToPark ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_SpyAtPark ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_SpyInDescToProf ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_SpyAtProf ...
         g_MC_AST ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_SpyInAscProf ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];
   
   case {215, 216}
      % Arvor Deep with "NS & IA"
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_SpyInDescToPark ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_SpyAtPark ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_SpyInDescToProf ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_SpyAtProf ...
         g_MC_AST ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_SpyInAscProf ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_AET ...
         g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
         g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];      
      
   case {204, 205, 206, 207, 208}
      % Provor/Arvor Iridium without "NS & IA"
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_AST ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];
      
   case {209}
      % Arvor Iridium 2DO
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_AST ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];
      
   case {210, 211, 212, 213, 214, 217}
      % Provor/Arvor Iridium with "NS & IA"
      % Arvor-ARN Iridium
      % Arvor-ARN-Ice Iridium
      % Provor-ARN-DO Iridium
      % Provor-ARN-DO-Ice Iridium
      % Arvor-ARN-DO-Ice Iridium 5.46
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_SpyInDescToPark ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_SpyAtPark ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_SpyInDescToProf ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_SpyAtProf ...
         g_MC_AST ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_SpyInAscProf ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_AET ...
         g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
         g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];
      
   case {105, 106, 107, 108, 109, 110, 111, 112, 301, 302, 303}
      % Provor CTS4 & Arvor CM
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_SpyInDescToPark ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_MaxPresInDescToPark ...
         g_MC_PST ...
         g_MC_SpyAtPark ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_SpyInDescToProf ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_SpyAtProf ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_SpyInAscProf ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];
      
   case {121}
      % Provor CTS5
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_SpyInDescToPark ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_PST ...
         g_MC_SpyAtPark ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_SpyInDescToProf ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_SpyAtProf ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_SpyInAscProf ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_AET ...
         g_MC_SpyAtSurface ...
         g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
         g_MC_TST ...
         g_MC_Surface ...
         g_MC_InAirSingleMeasRelativeToTET ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];      

   case {122, 123}
      % Provor CTS5
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_SpyInDescToPark ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_PST ...
         g_MC_SpyAtPark ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_SpyInDescToProf ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_SpyAtProf ...
         g_MC_MinPresInDriftAtProf ...
         g_MC_MaxPresInDriftAtProf ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_SpyInAscProf ...
         g_MC_AscProf ...
         g_MC_LastAscPumpedCtd ...
         g_MC_AET ...
         g_MC_SpyAtSurface ...
         g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
         g_MC_TST ...
         g_MC_Surface ...
         g_MC_InAirSingleMeasRelativeToTET ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];      
      
   case {1001, 1002, 1005, 1007, 1010}
      % Apex Argos
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_DriftAtParkMean ...
         g_MC_DriftAtParkStd ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MinPresInDriftAtParkSupportMeas ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtParkSupportMeas ...
         g_MC_DDET ...
         g_MC_DownTimeEnd ...
         g_MC_AST ...
         g_MC_AST_Float ...
         g_MC_AscProfDeepestBin ...
         g_MC_AET ...
         g_MC_AET_Float ...
         g_MC_TST ...
         g_MC_TST_Float ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         ];
      
   case {1003}
      % Apex Argos
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_DriftAtParkMean ...
         g_MC_DriftAtParkStd ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MinPresInDriftAtParkSupportMeas ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtParkSupportMeas ...
         g_MC_DDET ...
         g_MC_DownTimeEnd ...
         g_MC_AST ...
         g_MC_AST_Float ...
         g_MC_AscProfDeepestBin ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         ];
      
   case {1004}
      % Apex Argos
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_DriftAtParkMean ...
         g_MC_DriftAtParkStd ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MinPresInDriftAtParkSupportMeas ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtParkSupportMeas ...
         g_MC_DDET ...
         g_MC_AST ...
         g_MC_MedianValueInAscProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         ];

   case {1006, 1008, 1009, 1014, 1016}
      % Apex Argos
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_DriftAtParkMean ...
         g_MC_DriftAtParkStd ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MinPresInDriftAtParkSupportMeas ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtParkSupportMeas ...
         g_MC_DDET ...
         g_MC_DownTimeEnd ...
         g_MC_AST ...
         g_MC_AST_Float ...
         g_MC_AscProfDeepestBin ...
         g_MC_AET ...
         g_MC_AET_Float ...
         g_MC_TST ...
         g_MC_TST_Float ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_InAirSingleMeasRelativeToTET ...
         g_MC_LMT ...
         g_MC_TET ...
         ];
      
   case {1011, 1012}
      % Apex Argos
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_DriftAtParkMean ...
         g_MC_DriftAtParkStd ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MinPresInDriftAtParkSupportMeas ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtParkSupportMeas ...
         g_MC_DDET ...
         g_MC_DownTimeEnd ...
         g_MC_AST ...
         g_MC_AST_Float ...
         g_MC_MedianValueInAscProf ...
         g_MC_AscProfDeepestBin ...
         g_MC_AET ...
         g_MC_AET_Float ...
         g_MC_TST ...
         g_MC_TST_Float ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         ];
   
   case {1013}
      % Apex Argos
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_DDET ...
         g_MC_DownTimeEnd ...
         g_MC_AST ...
         g_MC_AST_Float ...
         g_MC_AscProfDeepestBin ...
         g_MC_AET ...
         g_MC_AET_Float ...
         g_MC_TST ...
         g_MC_TST_Float ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         ];    
      
   case {1015}
      % Apex Argos
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_DDET ...
         g_MC_DownTimeEnd ...
         g_MC_AST ...
         g_MC_AST_Float ...
         g_MC_AscProfDeepestBin ...
         g_MC_AET ...
         g_MC_AET_Float ...
         g_MC_TST ...
         g_MC_TST_Float ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_InAirSingleMeasRelativeToTET ...
         g_MC_LMT ...
         g_MC_TET ...
         ];
      
   case {1021, 1022}
      % Apex Argos
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_DST ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_DriftAtParkMean ...
         g_MC_DriftAtParkMeanOfDiff ...
         g_MC_DriftAtParkStd ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MinPresInDriftAtParkSupportMeas ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtParkSupportMeas ...
         g_MC_DownTimeEnd ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_TST ...
         g_MC_TST_Float ...
         g_MC_FMT ...
         g_MC_Surface ...
         g_MC_LMT ...
         g_MC_TET ...
         ];
      
   case {1102, 1103, 1104, 1106, 1107, 1108, 1109, 1113, 1314}
      % Apex Iridium Rudics & Sbd without surface measurement
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_DET ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_AET ...
         g_MC_TST ...
         g_MC_Surface ...
         g_MC_TET ...
         ];
      
   case {1101, 1105, 1110, 1111, 1112}
      % Apex Iridium Rudics & Sbd with surface measurement
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_DET ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_AET ...
         g_MC_InAirSingleMeasRelativeToTST ...
         g_MC_TST ...
         g_MC_Surface ...
         g_MC_TET ...
         ];
      
   case {1201}
      % Navis
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_DST ...
         g_MC_DescProf ...
         g_MC_DET ...
         g_MC_PST ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_AscProf ...
         g_MC_AET ...
         g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST ...
         g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
         g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
         g_MC_TST ...
         g_MC_Surface ...
         g_MC_TET ...
         ];

   case {1321}
      % Apex APF11 Iridium
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_DST-10 ...
         g_MC_DST ...
         g_MC_DET-11 ...
         g_MC_DET-10 ...
         g_MC_DET ...
         g_MC_PST-11 ...
         g_MC_PST-10 ...
         g_MC_PST ...
         g_MC_PET-11 ...
         g_MC_PET-10 ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_DDET-11 ...
         g_MC_DDET-10 ...
         g_MC_DDET ...
         g_MC_AST-11 ...
         g_MC_AST-10 ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_AET-11 ...
         g_MC_AET-10 ...
         g_MC_AET ...
         g_MC_TST-10 ...
         g_MC_TST ...
         g_MC_Surface ...
         g_MC_TET-10 ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];      

   case {1322}
      % Apex APF11 Iridium (with DO sensor)
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_DST-10 ...
         g_MC_DST ...
         g_MC_DET-11 ...
         g_MC_DET-10 ...
         g_MC_DET ...
         g_MC_PST-11 ...
         g_MC_PST-10 ...
         g_MC_PST ...
         g_MC_PET-11 ...
         g_MC_PET-10 ...
         g_MC_PET ...
         g_MC_RPP ...
         g_MC_DDET-11 ...
         g_MC_DDET-10 ...
         g_MC_DDET ...
         g_MC_AST-11 ...
         g_MC_AST-10 ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_AET-11 ...
         g_MC_AET-10 ...
         g_MC_AET ...
         g_MC_TST-10 ...
         g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
         g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST ...
         g_MC_TST ...
         g_MC_Surface ...
         g_MC_TET-10 ...
         g_MC_TET ...
         g_MC_Grounded ...
         ];      
            
   case {2001, 2002, 2003}
      % Nova, Dova
      o_mcList = [ ...
         g_MC_Launch ...
         g_MC_CycleStart ...
         g_MC_SpyInDescToPark ...
         g_MC_DST ...
         g_MC_FST ...
         g_MC_DescProf ...
         g_MC_DescProfDeepestBin ...
         g_MC_PST ...
         g_MC_SpyAtPark ...
         g_MC_DriftAtPark ...
         g_MC_PET ...
         g_MC_MinPresInDriftAtPark ...
         g_MC_MaxPresInDriftAtPark ...
         g_MC_RPP ...
         g_MC_SpyInDescToProf ...
         g_MC_MaxPresInDescToProf ...
         g_MC_DPST ...
         g_MC_SpyAtProf ...
         g_MC_AST ...
         g_MC_AscProfDeepestBin ...
         g_MC_SpyInAscProf ...
         g_MC_AscProf ...
         g_MC_AET ...
         g_MC_Surface ...
         g_MC_TST ...
         g_MC_FMT ...
         g_MC_LMT ...
         g_MC_TET ...
         ];      
      
otherwise
      fprintf('WARNING: Float #%d: No MC list assigned to decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      
end

o_mcList = unique(o_mcList);

return;

% ------------------------------------------------------------------------------
% Retrieve comment on some specific measurement code.
%
% SYNTAX :
%  [o_comment] = get_comment(a_measurementCode, a_decoderId)
%
% INPUT PARAMETERS :
%   a_measurementCode : MC number
%   a_decoderId       : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_comment : output comment
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/11/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_comment] = get_comment(a_measurementCode, a_decoderId)

% output parameters initialization
o_comment = [];

% global measurement codes
global g_MC_FillValue;
global g_MC_Launch;
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_PressureOffset
global g_MC_MinPresInDriftAtParkSupportMeas;
global g_MC_MaxPresInDriftAtParkSupportMeas;
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
global g_MC_DET;
global g_MC_DescProfDeepestBin;
global g_MC_PST;
global g_MC_SpyAtPark;
global g_MC_DriftAtPark;
global g_MC_DriftAtParkStd;
global g_MC_DriftAtParkMeanOfDiff;
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
global g_MC_ContinuousProfileStartOrStop;
global g_MC_AET;
global g_MC_AET_Float;
global g_MC_SpyAtSurface;
global g_MC_TST;
global g_MC_TST_Float;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;
global g_MC_Grounded;

global g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST;
global g_MC_InAirSingleMeasRelativeToTST;
global g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSingleMeasRelativeToTET;


apexApf11IrDecoderIdList = [1321 1322];

if (~ismember(a_decoderId, apexApf11IrDecoderIdList))

   switch (a_measurementCode)
      case {g_MC_CycleStart}
         o_comment = 'cycle start time';
      case {g_MC_SpyInDescToPark}
         o_comment = 'buoyancy action during descent to park pressure';
      case {g_MC_DescProf}
         if (a_decoderId < 1000)
            % NKE float
            o_comment = 'descending profile dated levels';
         elseif ((a_decoderId > 1000) && (a_decoderId < 2000))
            % Apex float
            o_comment = 'descending pressure marks';
         end
      case {g_MC_DescProfDeepestBin}
         o_comment = 'descending profile deepest level';
      case {g_MC_MaxPresInDescToPark}
         o_comment = 'max pressure sampled during descent to park pressure';
      case {g_MC_SpyAtPark}
         o_comment = 'buoyancy action during drift at park pressure';
      case {g_MC_MinPresInDriftAtPark}
         o_comment = 'min pressure sampled during drift at park pressure';
      case {g_MC_MaxPresInDriftAtPark}
         o_comment = 'max pressure sampled during drift at park pressure';
      case {g_MC_RPP}
         o_comment = 'representative park measurement';
      case {g_MC_SpyInDescToProf}
         o_comment = 'buoyancy action during descent to profile pressure';
      case {g_MC_MaxPresInDescToProf}
         o_comment = 'max pressure sampled during descent to profile pressure';
      case {g_MC_SpyAtProf}
         o_comment = 'buoyancy action during drift at profile pressure';
      case {g_MC_MinPresInDriftAtProf}
         o_comment = 'min pressure sampled during drift at profile pressure';
      case {g_MC_MaxPresInDriftAtProf}
         o_comment = 'max pressure sampled during drift at profile pressure';
      case {g_MC_AscProfDeepestBin}
         o_comment = 'ascending profile deepest level';
      case {g_MC_SpyInAscProf}
         o_comment = 'buoyancy action during ascending profile';
      case {g_MC_AscProf}
         o_comment = 'ascending profile dated levels';
      case {g_MC_LastAscPumpedCtd}
         o_comment = 'last pumped CTD raw measurement sampled during ascending profile';
      case {g_MC_SpyAtSurface}
         o_comment = 'start of surface final pump action to acquire max buoyancy';
      case {g_MC_Grounded}
         o_comment = 'grounded information';
         
         % Apex specific
      case {g_MC_DriftAtParkMean}
         o_comment = 'mean of measurements sampled during drift at park pressure';
      case {g_MC_DriftAtParkMeanOfDiff}
         o_comment = 'mean of measurement differences sampled during drift at park pressure';
      case {g_MC_DriftAtParkStd}
         o_comment = 'standard deviation of measurements sampled during drift at park pressure';
      case {g_MC_MinPresInDriftAtParkSupportMeas}
         o_comment = 'supporting meas of min pressure sampled during drift at park pressure';
      case {g_MC_MaxPresInDriftAtParkSupportMeas}
         o_comment = 'supporting meas of max pressure sampled during drift at park pressure';
      case {g_MC_DownTimeEnd}
         o_comment = 'DOWN TIME end';
      case {g_MC_MedianValueInAscProf}
         o_comment = 'median temperature of the samples collected between 50dbars and the surface';
      case {g_MC_AST_Float}
         o_comment = 'ascent start time transmitted by Apex float';
      case {g_MC_AET_Float}
         o_comment = 'ascent end time transmitted by Apex float';
      case {g_MC_TST_Float}
         o_comment = 'transmission time transmitted by Apex float';
         
         % Near Surface & In air
      case g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST % 690
         o_comment = 'in-water samples, part of end of profile, relative to TET';
      case g_MC_InAirSingleMeasRelativeToTST %699
         o_comment = 'in air single measurement, relative to TST';
      case g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST % 710
         o_comment = 'in-water samples, part of surface sequence, relative to TST';
      case g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST % 711
         o_comment = 'in-air samples, part of surface sequence, relative to TST';
      case g_MC_InAirSingleMeasRelativeToTET %799
         o_comment = 'in air single measurement, relative to TET';
   end
   
else
   
   switch (a_measurementCode)
      case {g_MC_RPP}
         o_comment = 'representative park measurement';
      case {g_MC_AscProfDeepestBin}
         o_comment = 'ascending profile deepest level';
      case {g_MC_Grounded}
         o_comment = 'grounded information';
         
      case {g_MC_DET-11, g_MC_PST-11, g_MC_PET-11, g_MC_DDET-11, g_MC_AST-11, g_MC_AET-11}
         o_comment = 'buoyancy action (recorded while transitioning towards MC+11)';
      case {g_MC_TET-10, g_MC_DST-10, g_MC_DET-10, g_MC_PST-10, g_MC_PET-10, g_MC_DDET-10, g_MC_AST-10, g_MC_AET-10, g_MC_TST-10}
         o_comment = 'series of measurements (recorded while transitioning towards MC+10)';         
         
         % Near Surface & In air
      case g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST % 710
         o_comment = 'in-water samples, part of surface sequence, relative to TST';
      case g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST % 711
         o_comment = 'in-air samples, part of surface sequence, relative to TST';
   end
   
end

return;
