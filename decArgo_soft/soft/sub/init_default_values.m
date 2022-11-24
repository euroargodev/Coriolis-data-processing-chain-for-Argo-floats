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

% decoder version
global g_decArgo_decoderVersion;

% lists of managed decoders
global g_decArgo_decoderIdListNkeArgos;
global g_decArgo_decoderIdListNkeIridiumRbr;
global g_decArgo_decoderIdListNkeIridiumNotDeep;
global g_decArgo_decoderIdListNkeIridiumDeep;
global g_decArgo_decoderIdListNkeIridium;
global g_decArgo_decoderIdListNkeCts4NotIce;
global g_decArgo_decoderIdListNkeCts4Ice;
global g_decArgo_decoderIdListNkeCts4;
global g_decArgo_decoderIdListNkeCts5Osean;
global g_decArgo_decoderIdListNkeCts5Usea;
global g_decArgo_decoderIdListNkeCts5;
global g_decArgo_decoderIdListNkeMisc;
global g_decArgo_decoderIdListNke;
global g_decArgo_decoderIdListApexApf9Argos;
global g_decArgo_decoderIdListApexApf9IridiumRudics;
global g_decArgo_decoderIdListApexApf9IridiumSbd;
global g_decArgo_decoderIdListApexApf9Iridium;
global g_decArgo_decoderIdListApexApf11IridiumRudics;
global g_decArgo_decoderIdListApexApf11IridiumSbd;
global g_decArgo_decoderIdListApexApf11Iridium;
global g_decArgo_decoderIdListApexApf11Argos;
global g_decArgo_decoderIdListApexArgos;
global g_decArgo_decoderIdListApexIridium;
global g_decArgo_decoderIdListApex;
global g_decArgo_decoderIdListNavis;
global g_decArgo_decoderIdListNova;
global g_decArgo_decoderIdListNemo;
global g_decArgo_decoderIdListAll;
global g_decArgo_decoderIdListDeepFloat;
global g_decArgo_decoderIdListBgcFloatNKE;
global g_decArgo_decoderIdListBgcFloatApex;
global g_decArgo_decoderIdListBgcFloatAll;
global g_decArgo_decoderIdListProfWithDatedLev;
global g_decArgo_decoderIdListMtime;

% lists of CTS5 files
global g_decArgo_provorCts5OseanFileTypeListRsync;
global g_decArgo_provorCts5UseaFileTypeListRsync;
global g_decArgo_provorCts5UseaFileTypeListCopy;
global g_decArgo_provorCts5UseaFileTypeList;
global g_decArgo_provorCts5OseanFileTypeListAll;
global g_decArgo_provorCts5UseaFileTypeListAll;

% global default values
global g_decArgo_dateDef;
global g_decArgo_epochDef;
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
global g_decArgo_vrsPhCountsDef;
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
global g_decArgo_nbSampleDef;
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_bPhaseDoxyDef;
global g_decArgo_tPhaseDoxyDef;
global g_decArgo_rPhaseDoxyDef;
global g_decArgo_phaseDelayDoxyDef;
global g_decArgo_frequencyDoxyDef;
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
global g_decArgo_vrsPhDef;
global g_decArgo_fluorescenceChlaDef;
global g_decArgo_betaBackscattering700Def;
global g_decArgo_tempCpuChlaDef;
global g_decArgo_blueRefDef;
global g_decArgo_ntuRefDef;
global g_decArgo_sideScatteringTurbidityDef;

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

global g_decArgo_minNonTransDurForNewCycle;
global g_decArgo_minNonTransDurForGhost
global g_decArgo_minNumMsgForNotGhost;
global g_decArgo_minNumMsgForProcessing;
global g_decArgo_minSubSurfaceCycleDuration;
global g_decArgo_minSubSurfaceCycleDurationIrSbd2;
global g_decArgo_maxIntervalToRecoverConfigMessageBeforeLaunchDate;

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
global g_decArgo_phaseBuoyInv;

% treatment types
global g_decArgo_treatRaw;
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;
global g_decArgo_treatAverageAndMedian;
global g_decArgo_treatAverageAndStDevAndMedian;
global g_decArgo_treatMedian;
global g_decArgo_treatMin;
global g_decArgo_treatMax;
global g_decArgo_treatStDev;
global g_decArgo_treatDecimatedRaw;

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

% max number of CTD samples in one NOVA sensor data packet
global g_decArgo_maxCTDSampleInNovaDataPacket;

% max number of CTDO samples in one DOVA sensor data packet
global g_decArgo_maxCTDOSampleInDovaDataPacket;

% codes for CTS5 phases (used to decode CTD data)
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseDeepProfile;
global g_decArgo_cts5PhaseShortPark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types (used to decode CTD data)
global g_decArgo_cts5Treat_AM_SD_MD;
global g_decArgo_cts5Treat_AM_SD;
global g_decArgo_cts5Treat_AM_MD;
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_AM;
global g_decArgo_cts5Treat_SS;
global g_decArgo_cts5Treat_DW;

% DOXY coefficients
global g_decArgo_doxy_nomAirPress;
global g_decArgo_doxy_nomAirMix;

global g_decArgo_doxy_201and202_201_301_d0;
global g_decArgo_doxy_201and202_201_301_d1;
global g_decArgo_doxy_201and202_201_301_d2;
global g_decArgo_doxy_201and202_201_301_d3;
global g_decArgo_doxy_201and202_201_301_sPreset;
global g_decArgo_doxy_201and202_201_301_b0_aanderaa;
global g_decArgo_doxy_201and202_201_301_b1_aanderaa;
global g_decArgo_doxy_201and202_201_301_b2_aanderaa;
global g_decArgo_doxy_201and202_201_301_b3_aanderaa;
global g_decArgo_doxy_201and202_201_301_c0_aanderaa;
global g_decArgo_doxy_201and202_201_301_b0;
global g_decArgo_doxy_201and202_201_301_b1;
global g_decArgo_doxy_201and202_201_301_b2;
global g_decArgo_doxy_201and202_201_301_b3;
global g_decArgo_doxy_201and202_201_301_c0;
global g_decArgo_doxy_201and202_201_301_pCoef2;
global g_decArgo_doxy_201and202_201_301_pCoef3;

global g_decArgo_doxy_202_204_204_d0;
global g_decArgo_doxy_202_204_204_d1;
global g_decArgo_doxy_202_204_204_d2;
global g_decArgo_doxy_202_204_204_d3;
global g_decArgo_doxy_202_204_204_sPreset;
global g_decArgo_doxy_202_204_204_b0;
global g_decArgo_doxy_202_204_204_b1;
global g_decArgo_doxy_202_204_204_b2;
global g_decArgo_doxy_202_204_204_b3;
global g_decArgo_doxy_202_204_204_c0;
global g_decArgo_doxy_202_204_204_pCoef1;
global g_decArgo_doxy_202_204_204_pCoef2;
global g_decArgo_doxy_202_204_204_pCoef3;

global g_decArgo_doxy_202_204_202_a0;
global g_decArgo_doxy_202_204_202_a1;
global g_decArgo_doxy_202_204_202_a2;
global g_decArgo_doxy_202_204_202_a3;
global g_decArgo_doxy_202_204_202_a4;
global g_decArgo_doxy_202_204_202_a5;
global g_decArgo_doxy_202_204_202_d0;
global g_decArgo_doxy_202_204_202_d1;
global g_decArgo_doxy_202_204_202_d2;
global g_decArgo_doxy_202_204_202_d3;
global g_decArgo_doxy_202_204_202_sPreset;
global g_decArgo_doxy_202_204_202_b0;
global g_decArgo_doxy_202_204_202_b1;
global g_decArgo_doxy_202_204_202_b2;
global g_decArgo_doxy_202_204_202_b3;
global g_decArgo_doxy_202_204_202_c0;
global g_decArgo_doxy_202_204_202_pCoef1;
global g_decArgo_doxy_202_204_202_pCoef2;
global g_decArgo_doxy_202_204_202_pCoef3;

global g_decArgo_doxy_202_204_203_a0;
global g_decArgo_doxy_202_204_203_a1;
global g_decArgo_doxy_202_204_203_a2;
global g_decArgo_doxy_202_204_203_a3;
global g_decArgo_doxy_202_204_203_a4;
global g_decArgo_doxy_202_204_203_a5;
global g_decArgo_doxy_202_204_203_d0;
global g_decArgo_doxy_202_204_203_d1;
global g_decArgo_doxy_202_204_203_d2;
global g_decArgo_doxy_202_204_203_d3;
global g_decArgo_doxy_202_204_203_sPreset;
global g_decArgo_doxy_202_204_203_b0;
global g_decArgo_doxy_202_204_203_b1;
global g_decArgo_doxy_202_204_203_b2;
global g_decArgo_doxy_202_204_203_b3;
global g_decArgo_doxy_202_204_203_c0;
global g_decArgo_doxy_202_204_203_pCoef1;
global g_decArgo_doxy_202_204_203_pCoef2;
global g_decArgo_doxy_202_204_203_pCoef3;

global g_decArgo_doxy_202_204_302_a0;
global g_decArgo_doxy_202_204_302_a1;
global g_decArgo_doxy_202_204_302_a2;
global g_decArgo_doxy_202_204_302_a3;
global g_decArgo_doxy_202_204_302_a4;
global g_decArgo_doxy_202_204_302_a5;
global g_decArgo_doxy_202_204_302_d0;
global g_decArgo_doxy_202_204_302_d1;
global g_decArgo_doxy_202_204_302_d2;
global g_decArgo_doxy_202_204_302_d3;
global g_decArgo_doxy_202_204_302_sPreset;
global g_decArgo_doxy_202_204_302_b0;
global g_decArgo_doxy_202_204_302_b1;
global g_decArgo_doxy_202_204_302_b2;
global g_decArgo_doxy_202_204_302_b3;
global g_decArgo_doxy_202_204_302_c0;
global g_decArgo_doxy_202_204_302_pCoef1;
global g_decArgo_doxy_202_204_302_pCoef2;
global g_decArgo_doxy_202_204_302_pCoef3;

global g_decArgo_doxy_202_205_302_a0;
global g_decArgo_doxy_202_205_302_a1;
global g_decArgo_doxy_202_205_302_a2;
global g_decArgo_doxy_202_205_302_a3;
global g_decArgo_doxy_202_205_302_a4;
global g_decArgo_doxy_202_205_302_a5;
global g_decArgo_doxy_202_205_302_d0;
global g_decArgo_doxy_202_205_302_d1;
global g_decArgo_doxy_202_205_302_d2;
global g_decArgo_doxy_202_205_302_d3;
global g_decArgo_doxy_202_205_302_sPreset;
global g_decArgo_doxy_202_205_302_b0;
global g_decArgo_doxy_202_205_302_b1;
global g_decArgo_doxy_202_205_302_b2;
global g_decArgo_doxy_202_205_302_b3;
global g_decArgo_doxy_202_205_302_c0;
global g_decArgo_doxy_202_205_302_pCoef1;
global g_decArgo_doxy_202_205_302_pCoef2;
global g_decArgo_doxy_202_205_302_pCoef3;

global g_decArgo_doxy_202_204_303_a0;
global g_decArgo_doxy_202_204_303_a1;
global g_decArgo_doxy_202_204_303_a2;
global g_decArgo_doxy_202_204_303_a3;
global g_decArgo_doxy_202_204_303_a4;
global g_decArgo_doxy_202_204_303_a5;
global g_decArgo_doxy_202_204_303_d0;
global g_decArgo_doxy_202_204_303_d1;
global g_decArgo_doxy_202_204_303_d2;
global g_decArgo_doxy_202_204_303_d3;
global g_decArgo_doxy_202_204_303_sPreset;
global g_decArgo_doxy_202_204_303_b0;
global g_decArgo_doxy_202_204_303_b1;
global g_decArgo_doxy_202_204_303_b2;
global g_decArgo_doxy_202_204_303_b3;
global g_decArgo_doxy_202_204_303_c0;
global g_decArgo_doxy_202_204_303_pCoef1;
global g_decArgo_doxy_202_204_303_pCoef2;
global g_decArgo_doxy_202_204_303_pCoef3;

global g_decArgo_doxy_202_205_303_a0;
global g_decArgo_doxy_202_205_303_a1;
global g_decArgo_doxy_202_205_303_a2;
global g_decArgo_doxy_202_205_303_a3;
global g_decArgo_doxy_202_205_303_a4;
global g_decArgo_doxy_202_205_303_a5;
global g_decArgo_doxy_202_205_303_d0;
global g_decArgo_doxy_202_205_303_d1;
global g_decArgo_doxy_202_205_303_d2;
global g_decArgo_doxy_202_205_303_d3;
global g_decArgo_doxy_202_205_303_sPreset;
global g_decArgo_doxy_202_205_303_b0;
global g_decArgo_doxy_202_205_303_b1;
global g_decArgo_doxy_202_205_303_b2;
global g_decArgo_doxy_202_205_303_b3;
global g_decArgo_doxy_202_205_303_c0;
global g_decArgo_doxy_202_205_303_pCoef1;
global g_decArgo_doxy_202_205_303_pCoef2;
global g_decArgo_doxy_202_205_303_pCoef3;

global g_decArgo_doxy_202_205_304_d0;
global g_decArgo_doxy_202_205_304_d1;
global g_decArgo_doxy_202_205_304_d2;
global g_decArgo_doxy_202_205_304_d3;
global g_decArgo_doxy_202_205_304_sPreset;
global g_decArgo_doxy_202_205_304_b0;
global g_decArgo_doxy_202_205_304_b1;
global g_decArgo_doxy_202_205_304_b2;
global g_decArgo_doxy_202_205_304_b3;
global g_decArgo_doxy_202_205_304_c0;
global g_decArgo_doxy_202_205_304_pCoef1;
global g_decArgo_doxy_202_205_304_pCoef2;
global g_decArgo_doxy_202_205_304_pCoef3;

global g_decArgo_doxy_103_208_307_d0;
global g_decArgo_doxy_103_208_307_d1;
global g_decArgo_doxy_103_208_307_d2;
global g_decArgo_doxy_103_208_307_d3;
global g_decArgo_doxy_103_208_307_sPreset;
global g_decArgo_doxy_103_208_307_solB0;
global g_decArgo_doxy_103_208_307_solB1;
global g_decArgo_doxy_103_208_307_solB2;
global g_decArgo_doxy_103_208_307_solB3;
global g_decArgo_doxy_103_208_307_solC0;
global g_decArgo_doxy_103_208_307_pCoef1;
global g_decArgo_doxy_103_208_307_pCoef2;
global g_decArgo_doxy_103_208_307_pCoef3;

global g_decArgo_doxy_201_203_202_d0;
global g_decArgo_doxy_201_203_202_d1;
global g_decArgo_doxy_201_203_202_d2;
global g_decArgo_doxy_201_203_202_d3;
global g_decArgo_doxy_201_203_202_sPreset;
global g_decArgo_doxy_201_203_202_b0;
global g_decArgo_doxy_201_203_202_b1;
global g_decArgo_doxy_201_203_202_b2;
global g_decArgo_doxy_201_203_202_b3;
global g_decArgo_doxy_201_203_202_c0;
global g_decArgo_doxy_201_203_202_pCoef1;
global g_decArgo_doxy_201_203_202_pCoef2;
global g_decArgo_doxy_201_203_202_pCoef3;

global g_decArgo_doxy_201_202_202_d0;
global g_decArgo_doxy_201_202_202_d1;
global g_decArgo_doxy_201_202_202_d2;
global g_decArgo_doxy_201_202_202_d3;
global g_decArgo_doxy_201_202_202_sPreset;
global g_decArgo_doxy_201_202_202_b0;
global g_decArgo_doxy_201_202_202_b1;
global g_decArgo_doxy_201_202_202_b2;
global g_decArgo_doxy_201_202_202_b3;
global g_decArgo_doxy_201_202_202_c0;
global g_decArgo_doxy_201_202_202_pCoef1;
global g_decArgo_doxy_201_202_202_pCoef2;
global g_decArgo_doxy_201_202_202_pCoef3;

global g_decArgo_doxy_202_204_304_d0;
global g_decArgo_doxy_202_204_304_d1;
global g_decArgo_doxy_202_204_304_d2;
global g_decArgo_doxy_202_204_304_d3;
global g_decArgo_doxy_202_204_304_sPreset;
global g_decArgo_doxy_202_204_304_b0;
global g_decArgo_doxy_202_204_304_b1;
global g_decArgo_doxy_202_204_304_b2;
global g_decArgo_doxy_202_204_304_b3;
global g_decArgo_doxy_202_204_304_c0;
global g_decArgo_doxy_202_204_304_pCoef1;
global g_decArgo_doxy_202_204_304_pCoef2;
global g_decArgo_doxy_202_204_304_pCoef3;

global g_decArgo_doxy_102_207_206_a0;
global g_decArgo_doxy_102_207_206_a1;
global g_decArgo_doxy_102_207_206_a2;
global g_decArgo_doxy_102_207_206_a3;
global g_decArgo_doxy_102_207_206_a4;
global g_decArgo_doxy_102_207_206_a5;
global g_decArgo_doxy_102_207_206_b0;
global g_decArgo_doxy_102_207_206_b1;
global g_decArgo_doxy_102_207_206_b2;
global g_decArgo_doxy_102_207_206_b3;
global g_decArgo_doxy_102_207_206_c0;

% NITRATE coefficients
global g_decArgo_nitrate_a;
global g_decArgo_nitrate_b;
global g_decArgo_nitrate_c;
global g_decArgo_nitrate_d;
global g_decArgo_nitrate_opticalWavelengthOffset;


% the first 3 digits are incremented at each new complete dated release
% the last digit is incremented at each patch associated to a given complete
% dated release 
g_decArgo_decoderVersion = '044s';

% list of managed decoders

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE FOLLOWING LISTS SHOULD BE UPDATED FOR EACH NEW DECODER

% all managed decoders
g_decArgo_decoderIdListNkeArgos = [1, 3, 4, 11, 12, 17, 19, 24, 25, 27:32];
g_decArgo_decoderIdListNkeIridiumRbr = [224];
g_decArgo_decoderIdListNkeIridiumDeep = [201, 202, 203, 215, 216, 218, 221];
g_decArgo_decoderIdListNkeIridiumNotDeep = setdiff([201:223 225], g_decArgo_decoderIdListNkeIridiumDeep);
g_decArgo_decoderIdListNkeIridium = [ ...
   g_decArgo_decoderIdListNkeIridiumNotDeep ...
   g_decArgo_decoderIdListNkeIridiumDeep ...
   g_decArgo_decoderIdListNkeIridiumRbr];
g_decArgo_decoderIdListNkeCts4NotIce = [105, 106, 107, 109, 110, 112];
g_decArgo_decoderIdListNkeCts4Ice = [111 113 114 115];
g_decArgo_decoderIdListNkeCts4 = [ ...
   g_decArgo_decoderIdListNkeCts4NotIce ...
   g_decArgo_decoderIdListNkeCts4Ice];
g_decArgo_decoderIdListNkeCts5Osean = [121:125];
g_decArgo_decoderIdListNkeCts5Usea = [126 127];
g_decArgo_decoderIdListNkeCts5 = [ ...
   g_decArgo_decoderIdListNkeCts5Osean ...
   g_decArgo_decoderIdListNkeCts5Usea ...
   ];
g_decArgo_decoderIdListNkeMisc = [301, 302, 303];

g_decArgo_decoderIdListNke = [ ...
   g_decArgo_decoderIdListNkeArgos ...
   g_decArgo_decoderIdListNkeIridium ...
   g_decArgo_decoderIdListNkeCts4 ...
   g_decArgo_decoderIdListNkeCts5 ...
   g_decArgo_decoderIdListNkeMisc];

g_decArgo_decoderIdListApexApf9Argos = [1001:1016];
g_decArgo_decoderIdListApexApf9IridiumRudics = [1101:1114];
g_decArgo_decoderIdListApexApf9IridiumSbd = [1314];
g_decArgo_decoderIdListApexApf9Iridium = [ ...
   g_decArgo_decoderIdListApexApf9IridiumRudics ...
   g_decArgo_decoderIdListApexApf9IridiumSbd];
g_decArgo_decoderIdListApexApf11Argos = [1021, 1022];
g_decArgo_decoderIdListApexApf11IridiumRudics = [1121:1128];
g_decArgo_decoderIdListApexApf11IridiumSbd = [1321:1323];
g_decArgo_decoderIdListApexApf11Iridium = [ ...
   g_decArgo_decoderIdListApexApf11IridiumRudics ...
   g_decArgo_decoderIdListApexApf11IridiumSbd];
g_decArgo_decoderIdListApexArgos = [ ...
   g_decArgo_decoderIdListApexApf9Argos ...
   g_decArgo_decoderIdListApexApf11Argos];
g_decArgo_decoderIdListApexIridium = [ ...
   g_decArgo_decoderIdListApexApf9Iridium ...
   g_decArgo_decoderIdListApexApf11Iridium];

g_decArgo_decoderIdListApex = [ ...
   g_decArgo_decoderIdListApexArgos ...
   g_decArgo_decoderIdListApexIridium];

g_decArgo_decoderIdListNavis = [1201];
g_decArgo_decoderIdListNova = [2001, 2002, 2003];
g_decArgo_decoderIdListNemo = [3001];

g_decArgo_decoderIdListAll = [ ...
   g_decArgo_decoderIdListNke ...
   g_decArgo_decoderIdListApex ...
   g_decArgo_decoderIdListNavis ...
   g_decArgo_decoderIdListNova ...
   g_decArgo_decoderIdListNemo];

% DEEP float decoders
g_decArgo_decoderIdListDeepFloat = g_decArgo_decoderIdListNkeIridiumDeep;

% BGC float decoders (each sensor has is own PRES axis, i.e. need to interpolate
% the CTD data when needed by a BGC parameter)
g_decArgo_decoderIdListBgcFloatNKE = [ ...
   g_decArgo_decoderIdListNkeCts4 ...
   g_decArgo_decoderIdListNkeCts5 ...
   g_decArgo_decoderIdListNkeMisc ...
   ];
g_decArgo_decoderIdListBgcFloatApex = g_decArgo_decoderIdListApexApf11Iridium;
g_decArgo_decoderIdListBgcFloatAll = [ ...
   g_decArgo_decoderIdListBgcFloatNKE ...
   g_decArgo_decoderIdListBgcFloatApex];

% the floats that report profile dated levels are:
% - all NKE floats
% - all NOVA/DOVA floats
% - all NAVIS floats
% - all NEMO floats
% - Apex APF11 Iridium floats
g_decArgo_decoderIdListProfWithDatedLev = [ ...
   g_decArgo_decoderIdListNke ...
   g_decArgo_decoderIdListNova ...
   g_decArgo_decoderIdListNavis ...
   g_decArgo_decoderIdListNemo ...
   g_decArgo_decoderIdListApexIridium];

% the float with 'MTIME' parameter
g_decArgo_decoderIdListMtime = [ ...
   g_decArgo_decoderIdListNkeCts5 ...
   g_decArgo_decoderIdListApexApf11Iridium ...
   g_decArgo_decoderIdListNavis ...
   g_decArgo_decoderIdListNemo];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% lists of CTS5 files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THE FOLLOWING LISTS SHOULD BE UPDATED FOR EACH NEW CTS5 DECODER OR SENSOR

g_decArgo_provorCts5OseanFileTypeListRsync = [ ...
   {'_apmt'} {'.ini'}; ...
   {'_autotest_'} {'.txt'}; ...
   {'_default_'} {'.txt'}; ...
   {'_technical'} {'.txt'}; ...
   {'_payload'} {'.bin'}; ...
   {'_payload_'} {'.txt'}; ...
   {'_payload'} {'.xml'}; ...
   {'_sbe41'} {'.hex'}; ...
   {'_system_'} {'.hex'}; ...
   ];

g_decArgo_provorCts5UseaFileTypeListRsync = [ ...
   {'_apmt'} {'.ini'}; ...
   {'_payload'} {'.xml'}; ...
   {'_payload_'} {'.txt'}; ...
   {'_autotest_'} {'.txt'}; ...
   {'_technical'} {'.txt'}; ...
   {'_default_'} {'.txt'}; ...
   {'_sbe41'} {'.hex'}; ...
   {'_payload'} {'.bin'}; ...
   {'_system_'} {'.hex'}; ...
   {'_metadata'} {'.xml'}; ... % CTS5-USEA
   {'_do'} {'.hex'}; ... % CTS5-USEA
   {'_eco'} {'.hex'}; ... % CTS5-USEA
   {'_ocr'} {'.hex'}; ... % CTS5-USEA
   {'_opus_blk'} {'.hex'}; ... % CTS5-USEA
   {'_opus_lgt'} {'.hex'}; ... % CTS5-USEA
   {'_uvp6_blk'} {'.hex'}; ... % CTS5-USEA
   {'_uvp6_lpm'} {'.hex'}; ... % CTS5-USEA
   {'_crover'} {'.hex'}; ... % CTS5-USEA
   {'_sbeph'} {'.hex'}; ... % CTS5-USEA
   {'_suna'} {'.hex'}; ... % CTS5-USEA
   {'_ramses'} {'.hex'}; ... % CTS5-USEA
   ];

g_decArgo_provorCts5UseaFileTypeListCopy = [ ...
   {'*_apmt*.ini'} ...
   {'*_payload*.xml'} ...
   {'_payload_*.txt'} ...
   {'*_autotest_*.txt'} ...
   {'*_technical*.txt'} ...
   {'*_default_*.txt'} ...
   {'*_sbe41*.hex'} ...
   {'*_payload*.bin'} ...
   {'*_system_*.hex'} ...
   {'*_metadata*.xml'} ... % CTS5-USEA
   {'*_do*.hex'} ... % CTS5-USEA
   {'*_eco*.hex'} ... % CTS5-USEA
   {'*_ocr*.hex'} ... % CTS5-USEA
   {'*_opus_blk*.hex'} ... % CTS5-USEA
   {'*_opus_lgt*.hex'} ... % CTS5-USEA
   {'*_uvp6_blk*.hex'} ... % CTS5-USEA
   {'*_uvp6_lpm*.hex'} ... % CTS5-USEA
   {'*_crover*.hex'} ... % CTS5-USEA
   {'*_sbeph*.hex'} ... % CTS5-USEA
   {'*_suna*.hex'} ... % CTS5-USEA
   {'*_ramses*.hex'} ... % CTS5-USEA
   ];

g_decArgo_provorCts5UseaFileTypeList = [ ...
   {'*_apmt*.ini'} ...
   {'*_autotest_*.txt'} ...
   {'*_technical*.txt'} ...
   {'*_default_*.txt'} ...
   {'*_sbe41*.hex'} ...
   {'*_payload*.bin'} ...
   {'*_metadata*.xml'} ... % CTS5-USEA
   {'*_do*.hex'} ... % CTS5-USEA
   {'*_eco*.hex'} ... % CTS5-USEA
   {'*_ocr*.hex'} ... % CTS5-USEA
   {'*_opus_blk*.hex'} ... % CTS5-USEA
   {'*_opus_lgt*.hex'} ... % CTS5-USEA
   {'*_uvp6_blk*.hex'} ... % CTS5-USEA
   {'*_uvp6_lpm*.hex'} ... % CTS5-USEA
   {'*_crover*.hex'} ... % CTS5-USEA
   {'*_sbeph*.hex'} ... % CTS5-USEA
   {'*_suna*.hex'} ... % CTS5-USEA
   {'*_ramses*.hex'} ... % CTS5-USEA
   ];

g_decArgo_provorCts5OseanFileTypeListAll = [ ...
   {1} {'*_apmt*.ini'} {'_%u_%u_apmt'} {16} {'_%03d_%02d_apmt*.ini'};...
   {9} {'*_payload*.xml'} {'_%u_%u_payload'} {19} {'_%03d_%02d_payload*.xml'}; ...
   {2} {'_payload*.txt'} {''} {[]} {''}; ...
   {3} {'*_autotest_*.txt'} {'_%u_autotest'} {17} {'_%03d_autotest_*.txt'}; ...
   {4} {'*_technical*.txt'} {'_%u_%u_technical'} {21} {'_%03d_%02d_technical*.txt'}; ...
   {5} {'*_default_*.txt'} {'_%u_%u_default'} {19} {'_%03d_%02d_default_*.txt'}; ...
   {6} {'*_sbe41*.hex'} {'_%u_%u_sbe41'} {17} {'_%03d_%02d_sbe41*.hex'}; ...
   {7} {'*_payload*.bin'} {'_%u_%u_payload'} {19} {'_%03d_%02d_payload*.bin'}; ...
   %    {8} {'_system_*.hex'} {'_system_%u.hex'} {''}; ...
   ];

g_decArgo_provorCts5UseaFileTypeListAll = [ ...
   {1} {'*_apmt*.ini'} {'_%u_%u_apmt'} {16} {'_%03d_%02d_apmt*.ini'};...
   {2} {'*_metadata*.xml'} {'_%u_%u_metadata'} {20} {'_%03d_%02d_metadata*.xml'};... % not used (already used at float declaration)
   {3} {'*_autotest_*.txt'} {'_%u_autotest'} {17} {'_%03d_autotest_*.txt'}; ...
   {4} {'*_technical*.txt'} {'_%u_%u_technical'} {21} {'_%03d_%02d_technical*.txt'}; ...
   {5} {'*_default_*.txt'} {'_%u_%u_default'} {19} {'_%03d_%02d_default_*.txt'}; ...
   {6} {'*_sbe41*.hex'} {'_%u_%u_sbe41'} {17} {'_%03d_%02d_sbe41*.hex'}; ...
   {7} {'*_do*.hex'} {'_%u_%u_do'} {14} {'_%03d_%02d_do*.hex'}; ...
   {8} {'*_eco*.hex'} {'_%u_%u_eco'} {15} {'_%03d_%02d_eco*.hex'}; ...
   {9} {'*_ocr*.hex'} {'_%u_%u_ocr'} {15} {'_%03d_%02d_ocr*.hex'}; ...
   {10} {'*_uvp6_blk*.hex'} {'_%u_%u_uvp6_blk'} {20} {'_%03d_%02d_uvp6_blk*.hex'}; ...
   {11} {'*_uvp6_lpm*.hex'} {'_%u_%u_uvp6_lpm'} {20} {'_%03d_%02d_uvp6_lpm*.hex'}; ...
   {12} {'*_crover*.hex'} {'_%u_%u_crover'} {18} {'_%03d_%02d_crover*.hex'}; ...
   {13} {'*_sbeph*.hex'} {'_%u_%u_sbeph'} {17} {'_%03d_%02d_sbeph*.hex'}; ...
   {14} {'*_suna*.hex'} {'_%u_%u_suna'} {16} {'_%03d_%02d_suna*.hex'}; ...
   {15} {'*_opus_blk*.hex'} {'_%u_%u_opus_blk'} {20} {'_%03d_%02d_opus_blk*.hex'}; ...
   {16} {'*_opus_lgt*.hex'} {'_%u_%u_opus_lgt'} {20} {'_%03d_%02d_opus_lgt*.hex'}; ...
   {17} {'*_ramses*.hex'} {'_%u_%u_ramses'} {18} {'_%03d_%02d_ramses*.hex'}; ...
   ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% global default values initialization
g_decArgo_dateDef = 99999.99999999;
g_decArgo_epochDef = 9999999999;
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
g_decArgo_vrsPhCountsDef = 99999;
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
g_decArgo_nbSampleDef = 99999;
g_decArgo_c1C2PhaseDoxyDef = 999.999;
g_decArgo_bPhaseDoxyDef = 999.999;
g_decArgo_tPhaseDoxyDef = 999.999;
g_decArgo_rPhaseDoxyDef = 999.999;
g_decArgo_phaseDelayDoxyDef = 99999.999;
g_decArgo_frequencyDoxyDef = 99999.99;
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
g_decArgo_vrsPhDef = 99.999999;
g_decArgo_fluorescenceChlaDef = 9999;
g_decArgo_betaBackscattering700Def = 9999;
g_decArgo_tempCpuChlaDef = 999;
g_decArgo_blueRefDef = 99999;
g_decArgo_ntuRefDef = 99999;
g_decArgo_sideScatteringTurbidityDef = 99999;

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

% minimum duration (in hour) of a non-transmission period to create a new
% cycle for an Argos float
g_decArgo_minNonTransDurForNewCycle = 10;

% minimum duration (in hour) of a non-transmission period to use the ghost
% detection algorithm
g_decArgo_minNonTransDurForGhost = 3;

% minimum duration (in hour) of a sub-surface period for an Iridium float
g_decArgo_minSubSurfaceCycleDuration = 5;
g_decArgo_minSubSurfaceCycleDurationIrSbd2 = 1.5;

% minimum number of float messages in an Argos file to use it
% (if the Argos file contains less than g_decArgo_minNumMsgForNotGhost float
% Argos messages, the file is not decoded because considered as a ghost
% file (i.e. it only contains ghost messages))
g_decArgo_minNumMsgForNotGhost = 4;

% minimum number of float messages in an Argos file to be processed within the
% 'profile' mode
g_decArgo_minNumMsgForProcessing = 5;

% for delayed decoders: interval, before float launch date to consider float
% configuration messages of the prelude phase (when they are transmitted before
% float launch date)
g_decArgo_maxIntervalToRecoverConfigMessageBeforeLaunchDate = 6/24; % in days

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
g_decArgo_phaseBuoyInv = 17;

g_decArgo_treatRaw = 0;
g_decArgo_treatAverage = 1;
g_decArgo_treatAverageAndStDev = 7;
g_decArgo_treatAverageAndMedian = 8;
g_decArgo_treatAverageAndStDevAndMedian = 9;
g_decArgo_treatMedian = 10;
g_decArgo_treatMin = 11;
g_decArgo_treatMax = 12;
g_decArgo_treatStDev = 13;
g_decArgo_treatDecimatedRaw = 14;

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

% max number of CTD samples in one NOVA sensor data packet (340 bytes max)
g_decArgo_maxCTDSampleInNovaDataPacket = 55;

% max number of CTDO samples in one DOVA sensor data packet (340 bytes max)
g_decArgo_maxCTDOSampleInDovaDataPacket = 33;

% codes for CTS5 phases (used to decode CTD data)
g_decArgo_cts5PhaseDescent = 1;
g_decArgo_cts5PhasePark = 2;
g_decArgo_cts5PhaseDeepProfile = 3;
g_decArgo_cts5PhaseShortPark = 4;
g_decArgo_cts5PhaseAscent = 5;
g_decArgo_cts5PhaseSurface = 6;

% codes for CTS5 treatment types (used to decode CTD data)
g_decArgo_cts5Treat_AM_SD_MD = 1; % mean + st dev + median
g_decArgo_cts5Treat_AM_SD = 2; % mean + st dev
g_decArgo_cts5Treat_AM_MD = 3; % mean + median
g_decArgo_cts5Treat_RW = 4; % raw
g_decArgo_cts5Treat_AM = 5; % mean
g_decArgo_cts5Treat_SS = 6; % sub-surface point (last pumped raw measurement)
g_decArgo_cts5Treat_DW = 7; % decimated raw

% DOXY coefficients
g_decArgo_doxy_nomAirPress = 1013.25;
g_decArgo_doxy_nomAirMix = 0.20946;

g_decArgo_doxy_201and202_201_301_d0 = 24.4543;
g_decArgo_doxy_201and202_201_301_d1 = -67.4509;
g_decArgo_doxy_201and202_201_301_d2 = -4.8489;
g_decArgo_doxy_201and202_201_301_d3 = -5.44e-4;
g_decArgo_doxy_201and202_201_301_sPreset = 0;
g_decArgo_doxy_201and202_201_301_b0_aanderaa = -6.24097e-3;
g_decArgo_doxy_201and202_201_301_b1_aanderaa = -6.93498e-3;
g_decArgo_doxy_201and202_201_301_b2_aanderaa = -6.90358e-3;
g_decArgo_doxy_201and202_201_301_b3_aanderaa = -4.29155e-3;
g_decArgo_doxy_201and202_201_301_c0_aanderaa = -3.11680e-7;
g_decArgo_doxy_201and202_201_301_b0 = -6.24523e-3;
g_decArgo_doxy_201and202_201_301_b1 = -7.37614e-3;
g_decArgo_doxy_201and202_201_301_b2 = -1.03410e-2;
g_decArgo_doxy_201and202_201_301_b3 = -8.17083e-3;
g_decArgo_doxy_201and202_201_301_c0 = -4.88682e-7;
g_decArgo_doxy_201and202_201_301_pCoef2 = 0.00025;
g_decArgo_doxy_201and202_201_301_pCoef3 = 0.0328;

g_decArgo_doxy_202_204_204_d0 = 24.4543;
g_decArgo_doxy_202_204_204_d1 = -67.4509;
g_decArgo_doxy_202_204_204_d2 = -4.8489;
g_decArgo_doxy_202_204_204_d3 = -5.44e-4;
g_decArgo_doxy_202_204_204_sPreset = 0;
g_decArgo_doxy_202_204_204_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_204_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_204_b2 = -1.03410e-2;
g_decArgo_doxy_202_204_204_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_204_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_204_pCoef1 = 0.1;
g_decArgo_doxy_202_204_204_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_204_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_202_a0 = 2.00856;
g_decArgo_doxy_202_204_202_a1 = 3.22400;
g_decArgo_doxy_202_204_202_a2 = 3.99063;
g_decArgo_doxy_202_204_202_a3 = 4.80299;
g_decArgo_doxy_202_204_202_a4 = 9.78188e-1;
g_decArgo_doxy_202_204_202_a5 = 1.71069;
g_decArgo_doxy_202_204_202_d0 = 24.4543;
g_decArgo_doxy_202_204_202_d1 = -67.4509;
g_decArgo_doxy_202_204_202_d2 = -4.8489;
g_decArgo_doxy_202_204_202_d3 = -5.44e-4;
g_decArgo_doxy_202_204_202_sPreset = 0;
g_decArgo_doxy_202_204_202_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_202_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_202_b2 = -1.03410e-2;
g_decArgo_doxy_202_204_202_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_202_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_202_pCoef1 = 0.1;
g_decArgo_doxy_202_204_202_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_202_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_203_a0 = 2.00856;
g_decArgo_doxy_202_204_203_a1 = 3.22400;
g_decArgo_doxy_202_204_203_a2 = 3.99063;
g_decArgo_doxy_202_204_203_a3 = 4.80299;
g_decArgo_doxy_202_204_203_a4 = 9.78188e-1;
g_decArgo_doxy_202_204_203_a5 = 1.71069;
g_decArgo_doxy_202_204_203_d0 = 24.4543;
g_decArgo_doxy_202_204_203_d1 = -67.4509;
g_decArgo_doxy_202_204_203_d2 = -4.8489;
g_decArgo_doxy_202_204_203_d3 = -5.44e-4;
g_decArgo_doxy_202_204_203_sPreset = 0;
g_decArgo_doxy_202_204_203_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_203_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_203_b2 = -1.03410e-2;
g_decArgo_doxy_202_204_203_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_203_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_203_pCoef1 = 0.1;
g_decArgo_doxy_202_204_203_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_203_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_302_a0 = 2.00856;
g_decArgo_doxy_202_204_302_a1 = 3.22400;
g_decArgo_doxy_202_204_302_a2 = 3.99063;
g_decArgo_doxy_202_204_302_a3 = 4.80299;
g_decArgo_doxy_202_204_302_a4 = 9.78188e-1;
g_decArgo_doxy_202_204_302_a5 = 1.71069;
g_decArgo_doxy_202_204_302_d0 = 24.4543;
g_decArgo_doxy_202_204_302_d1 = -67.4509;
g_decArgo_doxy_202_204_302_d2 = -4.8489;
g_decArgo_doxy_202_204_302_d3 = -5.44e-4;
g_decArgo_doxy_202_204_302_sPreset = 0;
g_decArgo_doxy_202_204_302_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_302_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_302_b2 = -1.03410e-2;
g_decArgo_doxy_202_204_302_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_302_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_302_pCoef1 = 0.1;
g_decArgo_doxy_202_204_302_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_302_pCoef3 = 0.0419;

g_decArgo_doxy_202_205_302_a0 = 2.00856;
g_decArgo_doxy_202_205_302_a1 = 3.22400;
g_decArgo_doxy_202_205_302_a2 = 3.99063;
g_decArgo_doxy_202_205_302_a3 = 4.80299;
g_decArgo_doxy_202_205_302_a4 = 9.78188e-1;
g_decArgo_doxy_202_205_302_a5 = 1.71069;
g_decArgo_doxy_202_205_302_d0 = 24.4543;
g_decArgo_doxy_202_205_302_d1 = -67.4509;
g_decArgo_doxy_202_205_302_d2 = -4.8489;
g_decArgo_doxy_202_205_302_d3 = -5.44e-4;
g_decArgo_doxy_202_205_302_sPreset = 0;
g_decArgo_doxy_202_205_302_b0 = -6.24523e-3;
g_decArgo_doxy_202_205_302_b1 = -7.37614e-3;
g_decArgo_doxy_202_205_302_b2 = -1.03410e-2;
g_decArgo_doxy_202_205_302_b3 = -8.17083e-3;
g_decArgo_doxy_202_205_302_c0 = -4.88682e-7;
g_decArgo_doxy_202_205_302_pCoef1 = 0.1;
g_decArgo_doxy_202_205_302_pCoef2 = 0.00022;
g_decArgo_doxy_202_205_302_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_303_a0 = 2.00856;
g_decArgo_doxy_202_204_303_a1 = 3.22400;
g_decArgo_doxy_202_204_303_a2 = 3.99063;
g_decArgo_doxy_202_204_303_a3 = 4.80299;
g_decArgo_doxy_202_204_303_a4 = 9.78188e-1;
g_decArgo_doxy_202_204_303_a5 = 1.71069;
g_decArgo_doxy_202_204_303_d0 = 24.4543;
g_decArgo_doxy_202_204_303_d1 = -67.4509;
g_decArgo_doxy_202_204_303_d2 = -4.8489;
g_decArgo_doxy_202_204_303_d3 = -5.44e-4;
g_decArgo_doxy_202_204_303_sPreset = 0;
g_decArgo_doxy_202_204_303_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_303_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_303_b2 = -1.03410e-2;
g_decArgo_doxy_202_204_303_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_303_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_303_pCoef1 = 0.1;
g_decArgo_doxy_202_204_303_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_303_pCoef3 = 0.0419;

g_decArgo_doxy_202_205_303_a0 = 2.00856;
g_decArgo_doxy_202_205_303_a1 = 3.22400;
g_decArgo_doxy_202_205_303_a2 = 3.99063;
g_decArgo_doxy_202_205_303_a3 = 4.80299;
g_decArgo_doxy_202_205_303_a4 = 9.78188e-1;
g_decArgo_doxy_202_205_303_a5 = 1.71069;
g_decArgo_doxy_202_205_303_d0 = 24.4543;
g_decArgo_doxy_202_205_303_d1 = -67.4509;
g_decArgo_doxy_202_205_303_d2 = -4.8489;
g_decArgo_doxy_202_205_303_d3 = -5.44e-4;
g_decArgo_doxy_202_205_303_sPreset = 0;
g_decArgo_doxy_202_205_303_b0 = -6.24523e-3;
g_decArgo_doxy_202_205_303_b1 = -7.37614e-3;
g_decArgo_doxy_202_205_303_b2 = -1.03410e-2;
g_decArgo_doxy_202_205_303_b3 = -8.17083e-3;
g_decArgo_doxy_202_205_303_c0 = -4.88682e-7;
g_decArgo_doxy_202_205_303_pCoef1 = 0.1;
g_decArgo_doxy_202_205_303_pCoef2 = 0.00022;
g_decArgo_doxy_202_205_303_pCoef3 = 0.0419;

g_decArgo_doxy_202_205_304_d0 = 24.4543;
g_decArgo_doxy_202_205_304_d1 = -67.4509;
g_decArgo_doxy_202_205_304_d2 = -4.8489;
g_decArgo_doxy_202_205_304_d3 = -5.44e-4;
g_decArgo_doxy_202_205_304_sPreset = 0;
g_decArgo_doxy_202_205_304_b0 = -6.24523e-3;
g_decArgo_doxy_202_205_304_b1 = -7.37614e-3;
g_decArgo_doxy_202_205_304_b2 = -1.03410e-2;
g_decArgo_doxy_202_205_304_b3 = -8.17083e-3;
g_decArgo_doxy_202_205_304_c0 = -4.88682e-7;
g_decArgo_doxy_202_205_304_pCoef1 = 0.1;
g_decArgo_doxy_202_205_304_pCoef2 = 0.00022;
g_decArgo_doxy_202_205_304_pCoef3 = 0.0419;

g_decArgo_doxy_103_208_307_d0 = 24.4543;
g_decArgo_doxy_103_208_307_d1 = -67.4509;
g_decArgo_doxy_103_208_307_d2 = -4.8489;
g_decArgo_doxy_103_208_307_d3 = -5.44e-4;
g_decArgo_doxy_103_208_307_sPreset = 0;
g_decArgo_doxy_103_208_307_solB0 = -6.24523e-3;
g_decArgo_doxy_103_208_307_solB1 = -7.37614e-3;
g_decArgo_doxy_103_208_307_solB2 = -1.03410e-2;
g_decArgo_doxy_103_208_307_solB3 = -8.17083e-3;
g_decArgo_doxy_103_208_307_solC0 = -4.88682e-7;
g_decArgo_doxy_103_208_307_pCoef1 = 0.115;
g_decArgo_doxy_103_208_307_pCoef2 = 0.00022;
g_decArgo_doxy_103_208_307_pCoef3 = 0.0419;

g_decArgo_doxy_201_203_202_d0 = 24.4543;
g_decArgo_doxy_201_203_202_d1 = -67.4509;
g_decArgo_doxy_201_203_202_d2 = -4.8489;
g_decArgo_doxy_201_203_202_d3 = -5.44e-4;
g_decArgo_doxy_201_203_202_sPreset = 0;
g_decArgo_doxy_201_203_202_b0 = -6.24523e-3;
g_decArgo_doxy_201_203_202_b1 = -7.37614e-3;
g_decArgo_doxy_201_203_202_b2 = -1.03410e-2;
g_decArgo_doxy_201_203_202_b3 = -8.17083e-3;
g_decArgo_doxy_201_203_202_c0 = -4.88682e-7;
g_decArgo_doxy_201_203_202_pCoef1 = 0.1;
g_decArgo_doxy_201_203_202_pCoef2 = 0.00022;
g_decArgo_doxy_201_203_202_pCoef3 = 0.0419;

g_decArgo_doxy_201_202_202_d0 = 24.4543;
g_decArgo_doxy_201_202_202_d1 = -67.4509;
g_decArgo_doxy_201_202_202_d2 = -4.8489;
g_decArgo_doxy_201_202_202_d3 = -5.44e-4;
g_decArgo_doxy_201_202_202_sPreset = 0;
g_decArgo_doxy_201_202_202_b0 = -6.24523e-3;
g_decArgo_doxy_201_202_202_b1 = -7.37614e-3;
g_decArgo_doxy_201_202_202_b2 = -1.03410e-2;
g_decArgo_doxy_201_202_202_b3 = -8.17083e-3;
g_decArgo_doxy_201_202_202_c0 = -4.88682e-7;
g_decArgo_doxy_201_202_202_pCoef1 = 0.1;
g_decArgo_doxy_201_202_202_pCoef2 = 0.00022;
g_decArgo_doxy_201_202_202_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_304_d0 = 24.4543;
g_decArgo_doxy_202_204_304_d1 = -67.4509;
g_decArgo_doxy_202_204_304_d2 = -4.8489;
g_decArgo_doxy_202_204_304_d3 = -5.44e-4;
g_decArgo_doxy_202_204_304_sPreset = 0;
g_decArgo_doxy_202_204_304_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_304_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_304_b2 = -1.03410e-2;
g_decArgo_doxy_202_204_304_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_304_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_304_pCoef1 = 0.1;
g_decArgo_doxy_202_204_304_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_304_pCoef3 = 0.0419;

g_decArgo_doxy_102_207_206_a0 = 2.00907;
g_decArgo_doxy_102_207_206_a1 = 3.22014;
g_decArgo_doxy_102_207_206_a2 = 4.0501;
g_decArgo_doxy_102_207_206_a3 = 4.94457;
g_decArgo_doxy_102_207_206_a4 = -0.256847;
g_decArgo_doxy_102_207_206_a5 = 3.88767;
g_decArgo_doxy_102_207_206_b0 = -0.00624523;
g_decArgo_doxy_102_207_206_b1 = -0.00737614;
g_decArgo_doxy_102_207_206_b2 = -0.00103410;    
g_decArgo_doxy_102_207_206_b3 = -0.00817083;
g_decArgo_doxy_102_207_206_c0 = -0.000000488682;

% NITRATE coefficients
g_decArgo_nitrate_a = 1.1500276;
g_decArgo_nitrate_b = 0.02840;
g_decArgo_nitrate_c = -0.3101349;
g_decArgo_nitrate_d = 0.001222;
g_decArgo_nitrate_opticalWavelengthOffset = 208.5;

return
