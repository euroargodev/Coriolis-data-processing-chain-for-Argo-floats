
% ------------------------------------------------------------------------------
% Initialize global default values.
%
% SYNTAX :
%  init_default_values(varargin)
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
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function init_default_values(varargin)

% global default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;
global g_decArgo_ncDateDef;
global g_decArgo_ncArgosLonDef;
global g_decArgo_ncArgosLatDef;
global g_decArgo_presCountsDef;
global g_decArgo_presCountsOkDef;
global g_decArgo_tempCountsDef;
global g_decArgo_salCountsDef;
global g_decArgo_cndcCountsDef;
global g_decArgo_oxyPhaseCountsDef;
global g_decArgo_chloroACountsDef;
global g_decArgo_chloroAVoltCountsDef;
global g_decArgo_backscatCountsDef;
global g_decArgo_cdomCountsDef;
global g_decArgo_iradianceCountsDef;
global g_decArgo_parCountsDef;
global g_decArgo_turbiCountsDef;
global g_decArgo_turbiVoltCountsDef;
global g_decArgo_concNitraCountsDef;
global g_decArgo_coefAttCountsDef;
global g_decArgo_molarDoxyCountsDef;
global g_decArgo_tPhaseDoxyCountsDef;
global g_decArgo_c1C2PhaseDoxyCountsDef;
global g_decArgo_phaseDelayDoxyCountsDef;
global g_decArgo_tempDoxyCountsDef;

global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_cndcDef;
global g_decArgo_molarDoxyDef;
global g_decArgo_mlplDoxyDef;
global g_decArgo_tPhaseDoxyDef;
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_bPhaseDoxyDef;
global g_decArgo_phaseDelayDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_doxyDef;
global g_decArgo_oxyPhaseDef;
global g_decArgo_chloroADef;
global g_decArgo_backscatDef;
global g_decArgo_cdomDef;
global g_decArgo_chloroDef;
global g_decArgo_chloroVoltDef;
global g_decArgo_turbiDef;
global g_decArgo_turbiVoltDef;
global g_decArgo_concNitraDef;
global g_decArgo_coefAttDef;

global g_decArgo_CHLADef;
global g_decArgo_PARTICLE_BACKSCATTERINGDef;

global g_decArgo_groundedDef;
global g_decArgo_durationDef;

global g_decArgo_janFirst1950InMatlab;
global g_decArgo_janFirst1970InJulD;
global g_decArgo_janFirst2000InJulD;

global g_decArgo_nbHourForProfDateCompInRtOffsetAdj;

global g_decArgo_profNum;
global g_decArgo_vertSpeed;

global g_decArgo_decoderVersion;

global g_decArgo_minNonTransDurForNewCycle;
global g_decArgo_minNonTransDurForGhost
global g_decArgo_minNumMsgForNotGhost;
global g_decArgo_minSubSurfaceCycleDuration;
global g_decArgo_minSubSurfaceCycleDurationIrSbd2;
global g_decArgo_maxDelayToReplaceIrLocByInterpolatedGpsLoc;

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseInitNewCy;
global g_decArgo_phaseInitNewProf;
global g_decArgo_phaseBuoyRed;
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseDsc2Prof;
global g_decArgo_phaseProfDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseAscEmerg;
global g_decArgo_phaseDataProc;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseEndOfProf;
global g_decArgo_phaseEndOfLife;
global g_decArgo_phaseEmergencyAsc;
global g_decArgo_phaseUserDialog;

% treatment types
global g_decArgo_treatRaw;
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;
global g_decArgo_qcGood;
global g_decArgo_qcProbablyGood;
global g_decArgo_qcCorrectable;
global g_decArgo_qcBad;
global g_decArgo_qcChanged;
global g_decArgo_qcInterpolated;
global g_decArgo_qcMissing;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;
global g_decArgo_qcStrGood;
global g_decArgo_qcStrProbablyGood;
global g_decArgo_qcStrCorrectable;
global g_decArgo_qcStrBad;
global g_decArgo_qcStrChanged;
global g_decArgo_qcStrUnused1;
global g_decArgo_qcStrUnused2;
global g_decArgo_qcStrInterpolated;
global g_decArgo_qcStrMissing;

% global default values initialization
g_decArgo_dateDef = 99999.99999999;
g_decArgo_argosLonDef = 999.999;
g_decArgo_argosLatDef = 99.999;
g_decArgo_ncDateDef = 999999;
g_decArgo_ncArgosLonDef = 99999;
g_decArgo_ncArgosLatDef = 99999;
g_decArgo_presCountsDef = 99999;
g_decArgo_presCountsOkDef = -1;
g_decArgo_tempCountsDef = 99999;
g_decArgo_salCountsDef = 99999;
g_decArgo_cndcCountsDef = 99999;
g_decArgo_oxyPhaseCountsDef = 9999999999;
g_decArgo_chloroACountsDef = 99999;
g_decArgo_chloroAVoltCountsDef = 99999;
g_decArgo_backscatCountsDef = 99999;
g_decArgo_cdomCountsDef = 99999;
g_decArgo_iradianceCountsDef = 9999999999;
g_decArgo_parCountsDef = 9999999999;
g_decArgo_turbiCountsDef = 99999;
g_decArgo_turbiVoltCountsDef = 99999;
g_decArgo_concNitraCountsDef = 999e+036; % max = 3.40282346e+038
g_decArgo_coefAttCountsDef = 99999;
g_decArgo_molarDoxyCountsDef = 99999;
g_decArgo_tPhaseDoxyCountsDef = 99999;
g_decArgo_c1C2PhaseDoxyCountsDef = 99999;
g_decArgo_phaseDelayDoxyCountsDef = 99999;
g_decArgo_tempDoxyCountsDef = 99999;

g_decArgo_presDef = 9999.9;
g_decArgo_tempDef = 99.999;
g_decArgo_salDef = 99.999;
g_decArgo_cndcDef = 99.9999;
g_decArgo_molarDoxyDef = 999;
g_decArgo_mlplDoxyDef = 999;
g_decArgo_tPhaseDoxyDef = 999.999;
g_decArgo_c1C2PhaseDoxyDef = 999.999;
g_decArgo_bPhaseDoxyDef = 999.999;
g_decArgo_phaseDelayDoxyDef = 99999.999;
g_decArgo_tempDoxyDef = 99.999;
g_decArgo_doxyDef = 999.999;
g_decArgo_oxyPhaseDef = 9999999.999;
g_decArgo_chloroADef = 9999.9;
g_decArgo_backscatDef = 9999.9;
g_decArgo_cdomDef = 9999.9;
g_decArgo_chloroDef = 9999.9;
g_decArgo_chloroVoltDef = 9.999;
g_decArgo_turbiDef = 9999.9;  
g_decArgo_turbiVoltDef = 9.999;
g_decArgo_concNitraDef = 9.99e+038;
g_decArgo_coefAttDef = 99.999;

g_decArgo_CHLADef = 99999;
g_decArgo_PARTICLE_BACKSCATTERINGDef = 99999;

g_decArgo_groundedDef = -1;
g_decArgo_durationDef = -1;

g_decArgo_janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');

g_decArgo_janFirst1970InJulD = gregorian_2_julian_dec_argo('1970/01/01 00:00:00');

g_decArgo_janFirst2000InJulD = gregorian_2_julian_dec_argo('2000/01/01 00:00:00');

% RT offset adjustments comes from meta-data and are dated. The following
% parameter is used as the accepted interval to compare profile dates to
% adjustment dates (because historical adjustments could have been done with a
% different algorithm for profile date determination, thus cannot be directly
% compared)
g_decArgo_nbHourForProfDateCompInRtOffsetAdj = 2;

g_decArgo_profNum = 99;
g_decArgo_vertSpeed = 99.9;

% the first 3 digits are incremented at each new complete dated release
% the last digit is incremented at each patch associated to a given complete
% dated release 
g_decArgo_decoderVersion = '003k';

% minimum duration (in hour) of a non-transmission period to create a new
% cycle for an Argos float
g_decArgo_minNonTransDurForNewCycle = 18;

% minimum duration (in hour) of a non-transmission period to use the ghost
% detection algorithm
g_decArgo_minNonTransDurForGhost = 3;

% minimum duration (in hour) of a sub-surface period for an Iridium float
g_decArgo_minSubSurfaceCycleDuration = 5;
g_decArgo_minSubSurfaceCycleDurationIrSbd2 = 1.5;

% minimum number of float messages in an Argos files to use it
% (if the Argos file conatins less than g_decArgo_minNumMsgForNotGhost float
% Argos messages, the file is not decoded because considered as a ghost
% file (i.e. it only contains ghost messages))
g_decArgo_minNumMsgForNotGhost = 4;

% maximum time difference (in days) between 2 GPS locations used to replace
% Iridium profile locations by interpolated GPS profile locations
g_decArgo_maxDelayToReplaceIrLocByInterpolatedGpsLoc = 30;


g_decArgo_phasePreMission = 0;
g_decArgo_phaseSurfWait = 1;
g_decArgo_phaseInitNewCy = 2;
g_decArgo_phaseInitNewProf = 3;
g_decArgo_phaseBuoyRed = 4;
g_decArgo_phaseDsc2Prk = 5;
g_decArgo_phaseParkDrift = 6;
g_decArgo_phaseDsc2Prof = 7;
g_decArgo_phaseProfDrift = 8;
g_decArgo_phaseAscProf = 9;
g_decArgo_phaseAscEmerg = 10;
g_decArgo_phaseDataProc = 11;
g_decArgo_phaseSatTrans = 12;
g_decArgo_phaseEndOfProf = 13;
g_decArgo_phaseEndOfLife = 14;
g_decArgo_phaseEmergencyAsc = 15;
g_decArgo_phaseUserDialog = 16;

g_decArgo_treatRaw = 0;
g_decArgo_treatAverage = 1;
g_decArgo_treatAverageAndStDev = 7;

g_decArgo_longNameOfParamAdjErr = 'Contains the error on the adjusted values as determined by the delayed mode QC process';

% QC flag values (numerical)
g_decArgo_qcDef = -1;
g_decArgo_qcNoQc = 0;
g_decArgo_qcGood = 1;
g_decArgo_qcProbablyGood = 2;
g_decArgo_qcCorrectable = 3;
g_decArgo_qcBad = 4;
g_decArgo_qcChanged = 5;
g_decArgo_qcInterpolated = 8;
g_decArgo_qcMissing = 9;

% QC flag values (char)
g_decArgo_qcStrDef = ' ';
g_decArgo_qcStrNoQc = '0';
g_decArgo_qcStrGood = '1';
g_decArgo_qcStrProbablyGood = '2';
g_decArgo_qcStrCorrectable = '3';
g_decArgo_qcStrBad = '4';
g_decArgo_qcStrChanged = '5';
g_decArgo_qcStrUnused1 = '6';
g_decArgo_qcStrUnused2 = '7';
g_decArgo_qcStrInterpolated = '8';
g_decArgo_qcStrMissing = '9';

return;
