% ------------------------------------------------------------------------------
% Get the basic structure to store a profile information.
%
% SYNTAX :
%  [o_profStruct] = get_profile_init_struct( ...
%    a_cycleNum, a_profNum, a_phaseNum, a_PrimarySamplingProfileFlag)
%
% INPUT PARAMETERS :
%   a_cycleNum                    : cycle number
%   a_profNum                     : profile number
%   a_phaseNum                    : phase number
%   a_PrimarySamplingProfileFlag  : 1 if it is a primary sampling profile,
%                                   0 otherwise
%
% OUTPUT PARAMETERS :
%   o_profStruct : profile initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/25/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = get_profile_init_struct( ...
   a_cycleNum, a_profNum, a_phaseNum, a_primarySamplingProfileFlag)

% global default values
global g_decArgo_dateDef;
global g_decArgo_presDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;


% output parameters initialization
o_profStruct = struct( ...
   'cycleNumber', a_cycleNum, ...
   'outputCycleNumber', -1, ...
   'profileNumber', a_profNum, ...
   'profileCompleted', '', ...
   'primarySamplingProfileFlag', a_primarySamplingProfileFlag, ...
   'phaseNumber', a_phaseNum, ...
   'direction', 'A', ...
   'date', g_decArgo_dateDef, ...
   'dateQc', '', ...
   'locationDate', g_decArgo_dateDef, ...
   'locationLon', g_decArgo_argosLonDef, ...
   'locationLat', g_decArgo_argosLatDef, ...
   'locationQc', ' ', ...
   'iridiumLocation', ' ', ... % 1 if the profile location has been computed from Iridium ones
   'posSystem', '', ...
   'locationDate2', g_decArgo_dateDef, ...
   'locationLon2', g_decArgo_argosLonDef, ...
   'locationLat2', g_decArgo_argosLatDef, ...
   'locationQc2', ' ', ...
   'iridiumLocation2', ' ', ... % 1 if the profile location has been computed from Iridium ones
   'posSystem2', '', ...
   'vertSamplingScheme', ' ', ...
   'additionnalBottomThreshold', [], ... % additionnal depth zone created only after grounding (PM18 of decId 221)
   'paramList', [], ...
   'paramDataMode', [], ...
   'paramNumberWithSubLevels', [], ... % position, in the paramList of the parameters with a sublevel
   'paramNumberOfSubLevels', [], ... % number of sublevels for the concerned parameter
   'data', [], ...
   'dataQc', [], ...
   'dataAdj', [], ...
   'dataAdjQc', [], ...
   'dataAdjError', [], ...
   'ptsForDoxy', [], ... % to store PTS data used to compute DOXY
   'rmsError', [], ... % to store RMS error of the fit done when computing NITRATE from spectrum (RMS error is used in NITRATE adjustment)
   'dateList', [], ...
   'dates', [], ...
   'datesAdj', [], ...
   'minMeasDate', g_decArgo_dateDef, ...
   'maxMeasDate', g_decArgo_dateDef, ...
   'configMissionNumber', '', ...
   'sensorNumber', '', ... % sensor number in Argo decoder (based on CTS4 sensor numbers)
   'payloadSensorNumber', '', ... % sensor numbers from the payload card of the CTS5 - or - in CTS5-USEA, sensor number (used to get configuration parameters)
   'presCutOffProf', g_decArgo_presDef, ...
   'presOffset', '', ...
   'subSurfMeasReceived', 0, ...
   'treatType', -1, ...
   'nbMeas', '', ...
   'merged', 0, ... % 1 for merged profile
   'derived', 0, ... % 1 if the derived parameters have been computed and added
   'updated', 0, ... % 1 if the associated nc file must be updated % NOT USED ANYMORE
   'rtOffset', g_decArgo_rtOffsetInfo, ...
   'rtParamAdjIdList', [], ... % list of information on RT param adjustment for the profile (first column of g_decArgo_paramProfAdjInfo)
   'fakeProfFlag', 0, ... % 1 if it is a 'default' profile created by the decoder to pass the java checker
   'bounceFlag', '' ... 
   );

return
