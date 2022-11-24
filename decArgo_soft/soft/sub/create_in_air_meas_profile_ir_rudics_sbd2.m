% ------------------------------------------------------------------------------
% Cut the DO profile at the cut-off pressure of the CTD pump and compute
% PPOX_DOXY in the resulting unpumped data.
%
% SYNTAX :
%  [o_inAirMeasProfile] = create_in_air_meas_profile_ir_rudics_sbd2(a_decoderId, ...
%    a_ctdProfile, a_doProfile)
%
% INPUT PARAMETERS :
%   a_decoderId  : float decoder Id
%   a_ctdProfile : input CTD profile
%   a_doProfile  : input DO profile
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
function [o_inAirMeasProfile] = create_in_air_meas_profile_ir_rudics_sbd2(a_decoderId, ...
   a_ctdProfile, a_doProfile)

% output parameters initialization
o_inAirMeasProfile = [];

% global default values
global g_decArgo_presDef;

% current float WMO number
global g_decArgo_floatNum;


if (a_doProfile.presCutOffProf ~= g_decArgo_presDef)
   
   presCutOffProf = a_doProfile.presCutOffProf;
   
   presMeas = a_doProfile.data(:, 1);
   paramPres = get_netcdf_param_attributes('PRES');
   idLevPrimary = find((presMeas ~= paramPres.fillValue) & (presMeas > presCutOffProf));
   % be careful, if acquisition mode is 'raw', the pressure measurements are not
   % necessarily monotonic! (ex: 6901516 #247)
   idStop = find(diff(idLevPrimary) ~= 1);
   if (~isempty(idStop))
      for id = 1:length(idStop)
         if (presMeas(idStop(id)+id) ~= paramPres.fillValue)
            idLevPrimary = idLevPrimary(1:idStop(id));
            break;
         end
      end
   end
   idLevNearSurface = '';
   if (~isempty(idLevPrimary))
      if ((length(presMeas) > idLevPrimary(end)) && ...
            (~isempty(find(presMeas(idLevPrimary(end)+1:end) ~= paramPres.fillValue, 1))))
         idLevNearSurface = (idLevPrimary(end)+1):length(presMeas);
      end
   else
      idLevNearSurface = 1:length(presMeas);
   end
   
   if (~isempty(idLevNearSurface))
      unpumpedProfile = a_doProfile;
      unpumpedProfile.primarySamplingProfileFlag = 0;
      unpumpedProfile.vertSamplingScheme = unpumpedProfile.vertSamplingScheme{2};      
      unpumpedProfile.data = unpumpedProfile.data(idLevNearSurface(1):end, :);
      if (~isempty(unpumpedProfile.dataQc))
         unpumpedProfile.dataQc = unpumpedProfile.dataQc(idLevNearSurface(1):end, :);
      end
      datesNearSurface = unpumpedProfile.dates(idLevNearSurface(1):end, 1);
      unpumpedProfile.dates = datesNearSurface;
      datesNearSurface(find(datesNearSurface == unpumpedProfile.dateList(1).fillValue)) = [];
      unpumpedProfile.minMeasDate = min(datesNearSurface);
      unpumpedProfile.maxMeasDate = max(datesNearSurface);
      
      % compute PPOX_DOXY and replace DOXY values with PPOX_DOXY ones
      
      idPres = find(strcmp({a_ctdProfile.paramList.name}, 'PRES') == 1, 1);
      idTemp = find(strcmp({a_ctdProfile.paramList.name}, 'TEMP') == 1, 1);
      idPsal = find(strcmp({a_ctdProfile.paramList.name}, 'PSAL') == 1, 1);
      idPresDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'PRES') == 1, 1);
      if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal) && ~isempty(idPresDoxy))
         idNoDef = find((a_ctdProfile.data(:, idPres) ~= a_ctdProfile.paramList(idPres).fillValue) & ...
            (a_ctdProfile.data(:, idTemp) ~= a_ctdProfile.paramList(idTemp).fillValue) & ...
            (a_ctdProfile.data(:, idPsal) ~= a_ctdProfile.paramList(idPsal).fillValue));
         ctdDataNoDef = a_ctdProfile.data(idNoDef, [idPres idTemp idPsal]);
         if (~isempty(ctdDataNoDef))
            
            % interpolate and extrapolate the CTD data at the pressures of the OPTODE
            % measurements
            ctdIntData = compute_interpolated_CTD_measurements(ctdDataNoDef, unpumpedProfile.data(:, idPresDoxy), 0);
            if (~isempty(ctdIntData))
               
               idNoNan = find(~isnan(ctdIntData(:, 2)));
               optodeInAirMeasFlag = get_static_config_value('CONFIG_PX_1_1_0_0_7', 0);
               
               switch (a_decoderId)
                  
                  case {106, 301}
                     
                     if ((a_decoderId == 106) && (isempty(optodeInAirMeasFlag) || (optodeInAirMeasFlag == 0)))
                        return;
                     end
                     
                     idC1PhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'C1PHASE_DOXY') == 1, 1);
                     idC2PhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'C2PHASE_DOXY') == 1, 1);
                     idTempDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'TEMP_DOXY') == 1, 1);
                     idDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DOXY') == 1, 1);
                     if (~isempty(idC1PhaseDoxy) && ~isempty(idC2PhaseDoxy) && ...
                           ~isempty(idTempDoxy) && ~isempty(idDoxy))
                        
                        unpumpedProfile.paramList(idDoxy) = get_netcdf_param_attributes('PPOX_DOXY');

                        % compute PPOX_DOXY values using the Aanderaa standard calibration method
                        unpumpedProfile.data(idNoNan, idDoxy) = ...
                           compute_PPOX_DOXY_106_301( ...
                           unpumpedProfile.data(idNoNan, idC1PhaseDoxy), ...
                           unpumpedProfile.data(idNoNan, idC2PhaseDoxy), ...
                           unpumpedProfile.data(idNoNan, idTempDoxy), ...
                           unpumpedProfile.paramList(idC1PhaseDoxy).fillValue, ...
                           unpumpedProfile.paramList(idC2PhaseDoxy).fillValue, ...
                           unpumpedProfile.paramList(idTempDoxy).fillValue, ...
                           ctdIntData(idNoNan, 1), ...
                           ctdIntData(idNoNan, 2), ...
                           a_ctdProfile.paramList(idPres).fillValue, ...
                           a_ctdProfile.paramList(idTemp).fillValue, ...
                           unpumpedProfile.paramList(idDoxy).fillValue, ...
                           unpumpedProfile);
                        
                        % update output parameters
                        o_inAirMeasProfile = unpumpedProfile;

                     end
                     
                  case {107, 109, 110}
                     
                     if (isempty(optodeInAirMeasFlag) || (optodeInAirMeasFlag == 0))
                        return;
                     end
                     
                     idC1PhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'C1PHASE_DOXY') == 1, 1);
                     idC2PhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'C2PHASE_DOXY') == 1, 1);
                     idTempDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'TEMP_DOXY') == 1, 1);
                     idDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DOXY') == 1, 1);
                     if (~isempty(idC1PhaseDoxy) && ~isempty(idC2PhaseDoxy) && ...
                           ~isempty(idTempDoxy) && ~isempty(idDoxy))
                        
                        unpumpedProfile.paramList(idDoxy) = get_netcdf_param_attributes('PPOX_DOXY');

                        % compute PPOX_DOXY values using the Stern-Volmer equation
                        unpumpedProfile.data(idNoNan, idDoxy) = ...
                           compute_PPOX_DOXY_107_109_110( ...
                           unpumpedProfile.data(idNoNan, idC1PhaseDoxy), ...
                           unpumpedProfile.data(idNoNan, idC2PhaseDoxy), ...
                           unpumpedProfile.data(idNoNan, idTempDoxy), ...
                           unpumpedProfile.paramList(idC1PhaseDoxy).fillValue, ...
                           unpumpedProfile.paramList(idC2PhaseDoxy).fillValue, ...
                           unpumpedProfile.paramList(idTempDoxy).fillValue, ...
                           ctdIntData(idNoNan, 1), ...
                           ctdIntData(idNoNan, 2), ...
                           a_ctdProfile.paramList(idPres).fillValue, ...
                           a_ctdProfile.paramList(idTemp).fillValue, ...
                           unpumpedProfile.paramList(idDoxy).fillValue, ...
                           unpumpedProfile);
                                                
                        % update output parameters
                        o_inAirMeasProfile = unpumpedProfile;

                     end
                     
                  case {302, 303}
                     
                     idDPhaseDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DPHASE_DOXY') == 1, 1);
                     idTempDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'TEMP_DOXY') == 1, 1);
                     idDoxy = find(strcmp({unpumpedProfile.paramList.name}, 'DOXY') == 1, 1);
                     if (~isempty(idDPhaseDoxy) && ~isempty(idTempDoxy) && ~isempty(idDoxy))
                        
                        unpumpedProfile.paramList(idDoxy) = get_netcdf_param_attributes('PPOX_DOXY');

                        % compute PPOX_DOXY from DPHASE_DOXY using the Aanderaa standard calibration
                        unpumpedProfile.data(idNoNan, idDoxy) = ...
                           compute_PPOX_DOXY_302_303( ...
                           unpumpedProfile.data(idNoNan, idDPhaseDoxy), ...
                           unpumpedProfile.data(idNoNan, idTempDoxy), ...
                           unpumpedProfile.paramList(idDPhaseDoxy).fillValue, ...
                           unpumpedProfile.paramList(idTempDoxy).fillValue, ...
                           ctdIntData(idNoNan, 1), ...
                           ctdIntData(idNoNan, 2), ...
                           a_ctdProfile.paramList(idPres).fillValue, ...
                           a_ctdProfile.paramList(idTemp).fillValue, ...
                           unpumpedProfile.paramList(idDoxy).fillValue, ...
                           unpumpedProfile);
                                                
                        % update output parameters
                        o_inAirMeasProfile = unpumpedProfile;

                     end

                  otherwise
                     fprintf('WARNING: Float #%d Cycle #%d Profile #%d: PPOX_DOXY processing not implemented yet for decoderId #%d\n', ...
                        g_decArgo_floatNum, ...
                        a_profOptode.cycleNumber, ...
                        a_profOptode.profileNumber, ...
                        a_decoderId);
               end
            end
         end
      end
   end
end

return;
