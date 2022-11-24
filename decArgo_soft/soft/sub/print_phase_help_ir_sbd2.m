% ------------------------------------------------------------------------------
% Print phase acronym explanation in output CSV file.
%
% SYNTAX :
%  print_phase_help_ir_sbd2(varargin)
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function print_phase_help_ir_sbd2(varargin)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

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


fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; PHASE ACRONYMS\n', ...
   g_decArgo_floatNum, get_phase_name(-1));

fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Pre-mission\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phasePreMission));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Waiting at the surface\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseSurfWait));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Init new cycle\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseInitNewCy));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Init new profile\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseInitNewProf));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Buoyancy reduction\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseBuoyRed));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Descent to parking pressure\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseDsc2Prk));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Drift at parking pressure\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseParkDrift));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Descent to profile pressure\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseDsc2Prof));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Drift at profile pressure\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseProfDrift));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Ascending profile\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseAscProf));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Buoyancy inflation\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseAscEmerg));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Data processing\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseDataProc));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Satellite transmission\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseSatTrans));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : End of profile\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseEndOfProf));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : End of life\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseEndOfLife));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Emergency ascent\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseEmergencyAsc));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : User dialog mode\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(g_decArgo_phaseUserDialog));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Not applicable (no associated phase)\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(-1));
fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info phase help; %s : Erroneous transmitted phase #\n', ...
   g_decArgo_floatNum, get_phase_name(-1),get_phase_name(-2));

return
