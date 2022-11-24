% ------------------------------------------------------------------------------
% Initialize measurement code values.
%
% SYNTAX :
%  init_measurement_codes(varargin)
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function init_measurement_codes(varargin)

% global measurement codes
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
global g_MC_LastAscPumpedCtd;
global g_MC_AET;
global g_MC_AET_Float;
global g_MC_InAirMeasBeforeTST;
global g_MC_TST;
global g_MC_TST_Float;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;
global g_MC_Grounded;

% global time status
global g_JULD_STATUS_fill_value;
global g_JULD_STATUS_0;
global g_JULD_STATUS_1;
global g_JULD_STATUS_2;
global g_JULD_STATUS_3;
global g_JULD_STATUS_4;
global g_JULD_STATUS_9;

% RPP status
global g_RPP_STATUS_fill_value;
global g_RPP_STATUS_1;
global g_RPP_STATUS_2;
global g_RPP_STATUS_3;
global g_RPP_STATUS_4;
global g_RPP_STATUS_5;
global g_RPP_STATUS_6;
global g_RPP_STATUS_7;

% measurement code values
g_MC_Launch = 0;
g_MC_CycleStart = 89;
g_MC_DST = 100;
g_MC_PressureOffset = 101;
g_MC_FST = 150;
g_MC_SpyInDescToPark = 189;
g_MC_DescProf = 190;
g_MC_MaxPresInDescToPark = 198;
g_MC_DET = 200;
g_MC_DescProfDeepestBin = 203;
g_MC_PST = 250;
g_MC_MinPresInDriftAtParkSupportMeas = 287;
g_MC_MaxPresInDriftAtParkSupportMeas = 288;
g_MC_SpyAtPark = 289;
g_MC_DriftAtPark = 290;
g_MC_DriftAtParkStd = 294;
g_MC_DriftAtParkMean = 296;
g_MC_MinPresInDriftAtPark = 297;
g_MC_MaxPresInDriftAtPark = 298;
g_MC_PET = 300;
g_MC_RPP = 301;
g_MC_SpyInDescToProf = 389;
g_MC_MaxPresInDescToProf = 398;
g_MC_DDET = 400;
g_MC_DPST = 450;
g_MC_SpyAtProf = 489;
g_MC_MinPresInDriftAtProf = 497;
g_MC_MaxPresInDriftAtProf = 498;
g_MC_AST = 500;
g_MC_DownTimeEnd = 501;
g_MC_AST_Float = 502;
g_MC_AscProfDeepestBin = 503;
g_MC_SpyInAscProf = 589;
g_MC_AscProf = 590;
g_MC_LastAscPumpedCtd = 599;
g_MC_AET = 600;
g_MC_AET_Float = 602;
g_MC_InAirMeasBeforeTST = 690;
g_MC_TST = 700;
g_MC_TST_Float = 701;
g_MC_FMT = 702;
g_MC_Surface = 703;
g_MC_LMT = 704;
g_MC_TET = 800;
g_MC_Grounded = 901;

% status values
g_JULD_STATUS_fill_value = ' ';
g_JULD_STATUS_0 = '0';
g_JULD_STATUS_1 = '1';
g_JULD_STATUS_2 = '2';
g_JULD_STATUS_3 = '3';
g_JULD_STATUS_4 = '4';
g_JULD_STATUS_9 = '9';

g_RPP_STATUS_fill_value = ' ';
g_RPP_STATUS_1 = '1';
g_RPP_STATUS_2 = '2';
g_RPP_STATUS_3 = '3';
g_RPP_STATUS_4 = '4';
g_RPP_STATUS_5 = '5';
g_RPP_STATUS_6 = '6';
g_RPP_STATUS_7 = '7';

return;
