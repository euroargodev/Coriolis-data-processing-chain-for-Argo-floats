% ------------------------------------------------------------------------------
% Compute PPOX_DOXY in the unpumped data profile.
%
% SYNTAX :
%  [o_inAirMeasProfile] = create_in_air_meas_profile(a_decoderId, a_profile)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%   a_profile   : input unpumped data profile
%
% OUTPUT PARAMETERS :
%   o_inAirMeasProfile : output IN AIR measurements profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/02/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inAirMeasProfile] = create_in_air_meas_profile(a_decoderId, a_profile)

% output parameters initialization
o_inAirMeasProfile = [];

% current float WMO number
global g_decArgo_floatNum;

  
unpumpedProfile = a_profile;

% remove PSAL values

idPsal = find(strcmp({unpumpedProfile.paramList.name}, 'PSAL') == 1, 1);
if (~isempty(idPsal))
   unpumpedProfile.paramList(idPsal) = [];
   if (~isempty(unpumpedProfile.data))
      unpumpedProfile.data(:, idPsal) = [];
   end
   if (~isempty(unpumpedProfile.dataQc))
      unpumpedProfile.dataQc(:, idPsal) = [];
   end
end

% compute PPOX_DOXY and replace DOXY values with PPOX_DOXY ones

idPres = find(strcmp({unpumpedProfile.paramList.name}, 'PRES') == 1, 1);
idTemp = find(strcmp({unpumpedProfile.paramList.name}, 'TEMP') == 1, 1);
if (~isempty(idPres) && ~isempty(idTemp))
   idNoDef = find((unpumpedProfile.data(:, idPres) ~= unpumpedProfile.paramList(idPres).fillValue) & ...
      (unpumpedProfile.data(:, idTemp) ~= unpumpedProfile.paramList(idTemp).fillValue));
   if (~isempty(idNoDef))
      
      switch (a_decoderId)
         
         case {4, 19, 25}
            
            idMolarDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'MOLAR_DOXY') == 1, 1);
            idDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DOXY') == 1, 1);
            if (~isempty(idMolarDoxy) && ~isempty(idDoxy))
               
               unpumpedProfile.paramList(idDoxy) = get_netcdf_param_attributes('PPOX_DOXY');
               
               % compute PPOX_DOXY values from MOLAR_DOXY
               unpumpedProfile.data(idNoDef, idDoxy) = ...
                  compute_PPOX_DOXY_4_19_25( ...
                  unpumpedProfile.data(idNoDef, idMolarDoxy), ...
                  unpumpedProfile.paramList(idMolarDoxy).fillValue, ...
                  unpumpedProfile.data(idNoDef, idPres), ...
                  unpumpedProfile.data(idNoDef, idTemp), ...
                  unpumpedProfile.paramList(idPres).fillValue, ...
                  unpumpedProfile.paramList(idTemp).fillValue, ...
                  unpumpedProfile.paramList(idDoxy).fillValue);
               
               % update output parameters
               o_inAirMeasProfile = unpumpedProfile;
            end
            
         case {27, 32}
            
            idTPhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'TPHASE_DOXY') == 1, 1);
            idDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DOXY') == 1, 1);
            if (~isempty(idTPhaseDoxy) && ~isempty(idDoxy))
               
               unpumpedProfile.paramList(idDoxy) = get_netcdf_param_attributes('PPOX_DOXY');
               
               % compute PPOX_DOXY from TPHASE_DOXY using the Stern-Volmer equation
               unpumpedProfile.data(idNoDef, idDoxy) = ...
                  compute_PPOX_DOXY_27_32( ...
                  unpumpedProfile.data(idNoDef, idTPhaseDoxy), ...
                  unpumpedProfile.paramList(idTPhaseDoxy).fillValue, ...
                  unpumpedProfile.data(idNoDef, idPres), ...
                  unpumpedProfile.data(idNoDef, idTemp), ...
                  unpumpedProfile.paramList(idPres).fillValue, ...
                  unpumpedProfile.paramList(idTemp).fillValue, ...
                  unpumpedProfile.paramList(idDoxy).fillValue);
               
               % update output parameters
               o_inAirMeasProfile = unpumpedProfile;
            end
            
         case {28}
            
            idTPhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'TPHASE_DOXY') == 1, 1);
            idDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DOXY') == 1, 1);
            if (~isempty(idTPhaseDoxy) && ~isempty(idDoxy))
               
               unpumpedProfile.paramList(idDoxy) = get_netcdf_param_attributes('PPOX_DOXY');
               
               % compute PPOX_DOXY from TPHASE_DOXY using the Aanderaa standard calibration
               unpumpedProfile.data(idNoDef, idDoxy) = ...
                  compute_PPOX_DOXY_28( ...
                  unpumpedProfile.data(idNoDef, idTPhaseDoxy), ...
                  unpumpedProfile.paramList(idTPhaseDoxy).fillValue, ...
                  unpumpedProfile.data(idNoDef, idPres), ...
                  unpumpedProfile.data(idNoDef, idTemp), ...
                  unpumpedProfile.paramList(idPres).fillValue, ...
                  unpumpedProfile.paramList(idTemp).fillValue, ...
                  unpumpedProfile.paramList(idDoxy).fillValue);
               
               % update output parameters
               o_inAirMeasProfile = unpumpedProfile;
            end
            
         case {29}
            
            idTPhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'TPHASE_DOXY') == 1, 1);
            idDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DOXY') == 1, 1);
            if (~isempty(idTPhaseDoxy) && ~isempty(idDoxy))
               
               unpumpedProfile.paramList(idDoxy) = get_netcdf_param_attributes('PPOX_DOXY');
               
               % compute PPOX_DOXY from TPHASE_DOXY using the Aanderaa standard calibration +
               % an additional two-point adjustment
               unpumpedProfile.data(idNoDef, idDoxy) = ...
                  compute_PPOX_DOXY_29( ...
                  unpumpedProfile.data(idNoDef, idTPhaseDoxy), ...
                  unpumpedProfile.paramList(idTPhaseDoxy).fillValue, ...
                  unpumpedProfile.data(idNoDef, idPres), ...
                  unpumpedProfile.data(idNoDef, idTemp), ...
                  unpumpedProfile.paramList(idPres).fillValue, ...
                  unpumpedProfile.paramList(idTemp).fillValue, ...
                  unpumpedProfile.paramList(idDoxy).fillValue);
               
               % update output parameters
               o_inAirMeasProfile = unpumpedProfile;
            end
            
         case {202, 207}
            
            idC1PhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'C1PHASE_DOXY') == 1, 1);
            idC2PhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'C2PHASE_DOXY') == 1, 1);
            idTempDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'TEMP_DOXY') == 1, 1);
            idDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DOXY') == 1, 1);
            if (~isempty(idC1PhaseDoxy) && ~isempty(idC2PhaseDoxy) && ~isempty(idTempDoxy) && ~isempty(idDoxy))
               
               unpumpedProfile.paramList(idDoxy) = get_netcdf_param_attributes('PPOX_DOXY');
               
               % compute PPOX_DOXY from C1PHASE_DOXY and C2PHASE_DOXY using the Aanderaa standard calibration
               unpumpedProfile.data(idNoDef, idDoxy) = ...
                  compute_PPOX_DOXY_202_207( ...
                  unpumpedProfile.data(idNoDef, idC1PhaseDoxy), ...
                  unpumpedProfile.data(idNoDef, idC2PhaseDoxy), ...
                  unpumpedProfile.data(idNoDef, idTempDoxy), ...
                  unpumpedProfile.paramList(idC1PhaseDoxy).fillValue, ...
                  unpumpedProfile.paramList(idC2PhaseDoxy).fillValue, ...
                  unpumpedProfile.paramList(idTempDoxy).fillValue, ...
                  unpumpedProfile.data(idNoDef, idPres), ...
                  unpumpedProfile.data(idNoDef, idTemp), ...
                  unpumpedProfile.paramList(idPres).fillValue, ...
                  unpumpedProfile.paramList(idTemp).fillValue, ...
                  unpumpedProfile.paramList(idDoxy).fillValue);
               
               % update output parameters
               o_inAirMeasProfile = unpumpedProfile;
            end
            
         case {208}
            
            idC1PhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'C1PHASE_DOXY') == 1, 1);
            idC2PhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'C2PHASE_DOXY') == 1, 1);
            idTempDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'TEMP_DOXY') == 1, 1);
            idDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DOXY') == 1, 1);
            if (~isempty(idC1PhaseDoxy) && ~isempty(idC2PhaseDoxy) && ~isempty(idTempDoxy) && ~isempty(idDoxy))
               
               unpumpedProfile.paramList(idDoxy) = get_netcdf_param_attributes('PPOX_DOXY');
               
               % compute PPOX_DOXY from C1PHASE_DOXY and C2PHASE_DOXY using the Aanderaa standard calibration
               unpumpedProfile.data(idNoDef, idDoxy) = ...
                  compute_PPOX_DOXY_208( ...
                  unpumpedProfile.data(idNoDef, idC1PhaseDoxy), ...
                  unpumpedProfile.data(idNoDef, idC2PhaseDoxy), ...
                  unpumpedProfile.data(idNoDef, idTempDoxy), ...
                  unpumpedProfile.paramList(idC1PhaseDoxy).fillValue, ...
                  unpumpedProfile.paramList(idC2PhaseDoxy).fillValue, ...
                  unpumpedProfile.paramList(idTempDoxy).fillValue, ...
                  unpumpedProfile.data(idNoDef, idPres), ...
                  unpumpedProfile.data(idNoDef, idTemp), ...
                  unpumpedProfile.paramList(idPres).fillValue, ...
                  unpumpedProfile.paramList(idTemp).fillValue, ...
                  unpumpedProfile.paramList(idDoxy).fillValue);
               
               % update output parameters
               o_inAirMeasProfile = unpumpedProfile;
            end
            
         case {201, 203, 206}
            
            idC1PhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'C1PHASE_DOXY') == 1, 1);
            idC2PhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'C2PHASE_DOXY') == 1, 1);
            idTempDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'TEMP_DOXY') == 1, 1);
            idDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DOXY') == 1, 1);
            if (~isempty(idC1PhaseDoxy) && ~isempty(idC2PhaseDoxy) && ~isempty(idTempDoxy) && ~isempty(idDoxy))
               
               unpumpedProfile.paramList(idDoxy) = get_netcdf_param_attributes('PPOX_DOXY');
               
               % compute PPOX_DOXY from C1PHASE_DOXY and C2PHASE_DOXY using the Stern-Volmer equation
               unpumpedProfile.data(idNoDef, idDoxy) = ...
                  compute_PPOX_DOXY_201_203_206_209_213( ...
                  unpumpedProfile.data(idNoDef, idC1PhaseDoxy), ...
                  unpumpedProfile.data(idNoDef, idC2PhaseDoxy), ...
                  unpumpedProfile.data(idNoDef, idTempDoxy), ...
                  unpumpedProfile.paramList(idC1PhaseDoxy).fillValue, ...
                  unpumpedProfile.paramList(idC2PhaseDoxy).fillValue, ...
                  unpumpedProfile.paramList(idTempDoxy).fillValue, ...
                  unpumpedProfile.data(idNoDef, idPres), ...
                  unpumpedProfile.data(idNoDef, idTemp), ...
                  unpumpedProfile.paramList(idPres).fillValue, ...
                  unpumpedProfile.paramList(idTemp).fillValue, ...
                  unpumpedProfile.paramList(idDoxy).fillValue);
               
               % update output parameters
               o_inAirMeasProfile = unpumpedProfile;
            end
            
         case {209}
            
            idC1PhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'C1PHASE_DOXY') == 1, 1);
            idC2PhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'C2PHASE_DOXY') == 1, 1);
            idTempDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'TEMP_DOXY') == 1, 1);
            idDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DOXY') == 1, 1);
            if (~isempty(idC1PhaseDoxy) && ~isempty(idC2PhaseDoxy) && ~isempty(idTempDoxy) && ~isempty(idDoxy))
               
               unpumpedProfile.paramList(idDoxy) = get_netcdf_param_attributes('PPOX_DOXY');
               
               % compute PPOX_DOXY from C1PHASE_DOXY and C2PHASE_DOXY using the Stern-Volmer equation
               unpumpedProfile.data(idNoDef, idDoxy) = ...
                  compute_PPOX_DOXY_201_203_206_209_213( ...
                  unpumpedProfile.data(idNoDef, idC1PhaseDoxy), ...
                  unpumpedProfile.data(idNoDef, idC2PhaseDoxy), ...
                  unpumpedProfile.data(idNoDef, idTempDoxy), ...
                  unpumpedProfile.paramList(idC1PhaseDoxy).fillValue, ...
                  unpumpedProfile.paramList(idC2PhaseDoxy).fillValue, ...
                  unpumpedProfile.paramList(idTempDoxy).fillValue, ...
                  unpumpedProfile.data(idNoDef, idPres), ...
                  unpumpedProfile.data(idNoDef, idTemp), ...
                  unpumpedProfile.paramList(idPres).fillValue, ...
                  unpumpedProfile.paramList(idTemp).fillValue, ...
                  unpumpedProfile.paramList(idDoxy).fillValue);
               
               % update output parameters
               o_inAirMeasProfile = unpumpedProfile;
            end
            
            idPhaseDelayDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'PHASE_DELAY_DOXY') == 1, 1);
            idTempDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'TEMP_DOXY2') == 1, 1);
            idDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DOXY2') == 1, 1);
            if (~isempty(idC1PhaseDoxy) && ~isempty(idC2PhaseDoxy) && ~isempty(idTempDoxy) && ~isempty(idDoxy))
               
               unpumpedProfile.paramList(idDoxy) = get_netcdf_param_attributes('PPOX_DOXY2');
               
               % compute PPOX_DOXY from PHASE_DELAY_DOXY reported by the SBE 63 optode
               unpumpedProfile.data(idNoDef, idDoxy) = ...
                  compute_PPOX_DOXY_SBE_209( ...
                  unpumpedProfile.data(idNoDef, idPhaseDelayDoxy), ...
                  unpumpedProfile.data(idNoDef, idTempDoxy), ...
                  unpumpedProfile.paramList(idPhaseDelayDoxy).fillValue, ...
                  unpumpedProfile.paramList(idTempDoxy).fillValue, ...
                  unpumpedProfile.data(idNoDef, idPres), ...
                  unpumpedProfile.data(idNoDef, idTemp), ...
                  unpumpedProfile.paramList(idPres).fillValue, ...
                  unpumpedProfile.paramList(idTemp).fillValue, ...
                  unpumpedProfile.paramList(idDoxy).fillValue);
               
               % update output parameters
               o_inAirMeasProfile = unpumpedProfile;
            end
            
         otherwise
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d: PPOX_DOXY processing not implemented yet for decoderId #%d\n', ...
               g_decArgo_floatNum, ...
               a_profile.cycleNumber, ...
               a_profile.profileNumber, ...
               a_decoderId);
      end
   end
end

return;