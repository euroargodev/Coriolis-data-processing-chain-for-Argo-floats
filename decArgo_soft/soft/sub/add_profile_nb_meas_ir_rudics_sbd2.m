% ------------------------------------------------------------------------------
% Add, in the profile structure, the number of measured levels for each depth
% zone.
%
% SYNTAX :
%  [o_profStruct] = add_profile_nb_meas_ir_rudics_sbd2(a_profStruct, a_sensorTech)
%
% INPUT PARAMETERS :
%   a_profStruct : input profile
%   a_sensorTech : technical information of the associatd sensor
%
% OUTPUT PARAMETERS :
%   o_profStruct : output profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/04/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = add_profile_nb_meas_ir_rudics_sbd2(a_profStruct, a_sensorTech)

% output parameters initialization
o_profStruct = [];

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;

% current float WMO number
global g_decArgo_floatNum;


if (~isempty(a_sensorTech))
   if (a_profStruct.phaseNumber == g_decArgo_phaseDsc2Prk)
      nbMeaslist = [];
      for idZ = 1:5
         nbDescMeasZ = a_sensorTech{3+idZ};
         if (~isempty(nbDescMeasZ))
            idF = find((nbDescMeasZ(:, 1) == a_profStruct.cycleNumber) & ...
               (nbDescMeasZ(:, 2) == a_profStruct.profileNumber));
            if (~isempty(idF))
               nbMeaslist = [nbMeaslist nbDescMeasZ(idF, 3)];
            end
         end
      end
      if (length(nbMeaslist) == 5)
         a_profStruct.nbMeas = nbMeaslist;
      end
   elseif (a_profStruct.phaseNumber == g_decArgo_phaseParkDrift)
      nbParkMeas = a_sensorTech{9};
      if (~isempty(nbParkMeas))
         idF = find((nbParkMeas(:, 1) == a_profStruct.cycleNumber) & ...
            (nbParkMeas(:, 2) == a_profStruct.profileNumber));
         if (~isempty(idF))
            a_profStruct.nbMeas = nbParkMeas(idF, 3);
         end
      end
   elseif (a_profStruct.phaseNumber == g_decArgo_phaseAscProf)
      nbMeaslist = [];
      for idZ = 1:5
         nbAscMeasZ = a_sensorTech{9+idZ};
         if (~isempty(nbAscMeasZ))
            idF = find((nbAscMeasZ(:, 1) == a_profStruct.cycleNumber) & ...
               (nbAscMeasZ(:, 2) == a_profStruct.profileNumber));
            if (~isempty(idF))
               nbMeaslist = [nbMeaslist nbAscMeasZ(idF, 3)];
            end
         end
      end
      if (length(nbMeaslist) == 5)
         a_profStruct.nbMeas = nbMeaslist;
      end
   end
end

% output data
o_profStruct = a_profStruct;

return
