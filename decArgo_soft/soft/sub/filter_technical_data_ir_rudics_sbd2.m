% ------------------------------------------------------------------------------
% Filter useless technical data for TECH NetCDF file.
% 
% SYNTAX :
%  filter_technical_data_ir_rudics_sbd2
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
%   03/01/2013 - RNU - creation
% ------------------------------------------------------------------------------
function filter_technical_data_ir_rudics_sbd2

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

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


% filter float technical data packets

if (~isempty(g_decArgo_outputNcParamIndex))
   
   % use only SAT TRANS phase data for TECH file
   idDel = find ((g_decArgo_outputNcParamIndex(:, 1) == 253) & ...
      (g_decArgo_outputNcParamIndex(:, 4) ~= g_decArgo_phaseSatTrans));
   
   g_decArgo_outputNcParamIndex(idDel, :) = [];
   g_decArgo_outputNcParamValue(idDel) = [];
   
   % set phase number to -1 (so that it will not appear in the TECH file)
   id253 = find (g_decArgo_outputNcParamIndex(:, 1) == 253);
   g_decArgo_outputNcParamIndex(id253, 4) = -1;
   
   % OLD START
   
   %    % for PRELUDE phase
   %    techIdForPrelude = [100:102 106:110 168:175];
   %    idPhase = find ((g_decArgo_outputNcParamIndex(:, 1) == 253) & ...
   %       (g_decArgo_outputNcParamIndex(:, 4) == 0));
   %    idDel = find(ismember(g_decArgo_outputNcParamIndex(idPhase, 5), techIdForPrelude) == 0);
   %
   %    g_decArgo_outputNcParamIndex(idPhase(idDel), :) = [];
   %    g_decArgo_outputNcParamValue(idPhase(idDel)) = [];
   %
   %    % for SURFACE WAIT phase
   %    techIdForSurfWait = [100:110 168:175];
   %    idPhase = find ((g_decArgo_outputNcParamIndex(:, 1) == 253) & ...
   %       (g_decArgo_outputNcParamIndex(:, 4) == 1));
   %    idDel = find(ismember(g_decArgo_outputNcParamIndex(idPhase, 5), techIdForSurfWait) == 0);
   %
   %    g_decArgo_outputNcParamIndex(idPhase(idDel), :) = [];
   %    g_decArgo_outputNcParamValue(idPhase(idDel)) = [];
   
   %OLD END
   
end

return
