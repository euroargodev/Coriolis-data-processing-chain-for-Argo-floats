% ------------------------------------------------------------------------------
% Parse Navis near surface and surface data.
%
% SYNTAX :
%  [o_nearSurfData, o_surfDataBladderDeflated, o_surfDataBladderInflated] = ...
%    parse_nvs_ir_rudics_near_surface_data(a_nearSurfaceDataStr, a_decoderId)
%
% INPUT PARAMETERS :
%   a_nearSurfaceDataStr : input ASCII NS and surf data
%   a_decoderId          : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_nearSurfData            : NS data
%   o_surfDataBladderDeflated : surface data (bladder deflated)
%   o_surfDataBladderInflated : surface data (bladder inflated)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nearSurfData, o_surfDataBladderDeflated, o_surfDataBladderInflated] = ...
   parse_nvs_ir_rudics_near_surface_data(a_nearSurfaceDataStr, a_decoderId)

% output parameters initialization
o_nearSurfData = [];
o_surfDataBladderDeflated = [];
o_surfDataBladderInflated = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_nearSurfaceDataStr))
   return
end

switch (a_decoderId)
   
   case {1201} % 061113
      
      [o_nearSurfData, o_surfDataBladderDeflated, o_surfDataBladderInflated] = ...
         parse_nvs_ir_rudics_near_surface_data_1(a_nearSurfaceDataStr);
      
   otherwise
      fprintf('DEC_WARNING: Float #%d Cycle #%d: Nothing done yet in parse_nvs_ir_rudics_near_surface_data for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
      return
end

return

% ------------------------------------------------------------------------------
% Parse Navis near surface and surface data.
%
% SYNTAX :
%  [o_nearSurfData, o_surfDataBladderDeflated, o_surfDataBladderInflated] = ...
%    parse_nvs_ir_rudics_near_surface_data_1(a_nearSurfaceDataStr)
%
% INPUT PARAMETERS :
%   a_nearSurfaceDataStr : input ASCII NS and surf data
%
% OUTPUT PARAMETERS :
%   o_nearSurfData            : NS data
%   o_surfDataBladderDeflated : surface data (bladder deflated)
%   o_surfDataBladderInflated : surface data (bladder inflated)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nearSurfData, o_surfDataBladderDeflated, o_surfDataBladderInflated] = ...
   parse_nvs_ir_rudics_near_surface_data_1(a_nearSurfaceDataStr)

% output parameters initialization
o_nearSurfData = [];
o_surfDataBladderDeflated = [];
o_surfDataBladderInflated = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_epochDef;
global g_decArgo_presDef;
global g_decArgo_tPhaseDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_rPhaseDoxyDef;

% global time status
global g_JULD_STATUS_2;


% create the parameters
paramJuld = get_netcdf_param_attributes('JULD');
paramPres = get_netcdf_param_attributes('PRES');
paramTPhaseDoxy = get_netcdf_param_attributes('TPHASE_DOXY');
paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
paramRPhaseDoxy = get_netcdf_param_attributes('RPHASE_DOXY');

HEADER = 'Near-surface measurements';
PATTERN1 = '$  UNIX Epoch       p  Ph4330   T4330 RPh4330 (Near-surface samples)';
PATTERN2 = '$  UNIX Epoch       p  Ph4330   T4330 RPh4330 (Surface samples bladder-deflated)';
PATTERN3 = '$  UNIX Epoch       p  Ph4330   T4330 RPh4330 (Surface samples bladder-inflated)';

for idNS = 1:length(a_nearSurfaceDataStr)
   
   nearSurfaceDataStr = a_nearSurfaceDataStr{idNS};
   if (isempty(nearSurfaceDataStr))
      continue
   end
   
   dataType = [];
   store = 0;
   profNsEpoch = [];
   profNsPres = [];
   profNsTPhaseDoxy = [];
   profNsTempDoxy = [];
   profNsRPhaseDoxy = [];
   for idL = 1:length(nearSurfaceDataStr)
      
      if (store == 1)
         
         % convert decoder default values to netCDF fill values
         profNsPres(find(profNsPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
         profNsTPhaseDoxy(find(profNsTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
         profNsTempDoxy(find(profNsTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
         profNsRPhaseDoxy(find(profNsRPhaseDoxy == g_decArgo_rPhaseDoxyDef)) = paramRPhaseDoxy.fillValue;
         
         if (any(profNsPres ~= paramPres.fillValue) || ...
               any(profNsTPhaseDoxy ~= paramTPhaseDoxy.fillValue) || ...
               any(profNsTempDoxy ~= paramTempDoxy.fillValue) || ...
               any(profNsRPhaseDoxy ~= paramRPhaseDoxy.fillValue))
            
            % compute JULD from EPOCH
            profNsJuld = ones(size(profNsEpoch))*paramJuld.fillValue;
            idNoDef = find(profNsEpoch ~= g_decArgo_epochDef);
            profNsJuld(idNoDef) = epoch_2_julian_dec_argo(profNsEpoch(idNoDef));
            
            % store prof NS data
            profNsData = get_apx_profile_data_init_struct;
            
            % add parameter variables to the data structure
            profNsData.dateList = paramJuld;
            profNsData.paramList = [paramPres  ...
               paramTPhaseDoxy paramTempDoxy paramRPhaseDoxy];
            
            % add parameter data to the data structure
            profNsData.dates = profNsJuld;
            profNsData.data = [profNsPres  ...
               profNsTPhaseDoxy profNsTempDoxy profNsRPhaseDoxy];
            
            % add date status to the data structure
            profNsData.datesStatus = repmat(g_JULD_STATUS_2, size(profNsData.dates));
            
            switch (dataTypeSav)
               case 1
                  o_nearSurfData{end+1} = profNsData;
               case 2
                  o_surfDataBladderDeflated{end+1} = profNsData;
               case 3
                  o_surfDataBladderInflated{end+1} = profNsData;
                  
               otherwise
                  fprintf('DEC_WARNING: Float #%d Cycle #%d: Inconsistent NS data type\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_cycleNum);
                  return
            end
         end
         
         store = 0;
         profNsEpoch = [];
         profNsPres = [];
         profNsTPhaseDoxy = [];
         profNsTempDoxy = [];
         profNsRPhaseDoxy = [];
      end
      
      dataStr = nearSurfaceDataStr{idL};
      if (any(strfind(dataStr, HEADER)))
         continue
      end
      
      % set data type
      if (any(strfind(dataStr, PATTERN1)))
         dataType = 1;
         continue
      end
      if (any(strfind(dataStr, PATTERN2)))
         if (~isempty(dataType))
            dataTypeSav = dataType;
            store = 1;
         end
         dataType = 2;
         continue
      end
      if (any(strfind(dataStr, PATTERN3)))
         if (~isempty(dataType))
            dataTypeSav = dataType;
            store = 1;
         end
         dataType = 3;
         continue
      end
      
      % extract data
      data = strsplit(dataStr, ' ');
      if ((length(data) > 0) && ~strcmp(data{1}, 'nan'))
         dataEpoch = str2double(data{1});
      else
         dataEpoch = g_decArgo_epochDef;
      end
      if ((length(data) > 1) && ~strcmp(data{2}, 'nan'))
         dataPres = str2double(data{2});
      else
         dataPres = g_decArgo_presDef;
      end
      if ((length(data) > 2) && ~strcmp(data{3}, 'nan'))
         dataTPhaseDoxy = str2double(data{3});
      else
         dataTPhaseDoxy = g_decArgo_tPhaseDoxyDef;
      end
      if ((length(data) > 3) && ~strcmp(data{4}, 'nan'))
         dataTempDoxy = str2double(data{4});
      else
         dataTempDoxy = g_decArgo_tempDoxyDef;
      end
      if ((length(data) > 4) && ~strcmp(data{5}, 'nan'))
         dataRPhaseDoxy = str2double(data{5});
      else
         dataRPhaseDoxy = g_decArgo_rPhaseDoxyDef;
      end
      
      if (~isempty(dataType))
         profNsEpoch = [profNsEpoch; dataEpoch];
         profNsPres = [profNsPres; dataPres];
         profNsTPhaseDoxy = [profNsTPhaseDoxy; dataTPhaseDoxy];
         profNsTempDoxy = [profNsTempDoxy; dataTempDoxy];
         profNsRPhaseDoxy = [profNsRPhaseDoxy; dataRPhaseDoxy];
      end
   end
   
   if (~isempty(dataType))
      
      % convert decoder default values to netCDF fill values
      profNsPres(find(profNsPres(:, 1) == g_decArgo_presDef)) = paramPres.fillValue;
      profNsTPhaseDoxy(find(profNsTPhaseDoxy == g_decArgo_tPhaseDoxyDef)) = paramTPhaseDoxy.fillValue;
      profNsTempDoxy(find(profNsTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
      profNsRPhaseDoxy(find(profNsRPhaseDoxy == g_decArgo_rPhaseDoxyDef)) = paramRPhaseDoxy.fillValue;
      
      if (any(profNsPres ~= paramPres.fillValue) || ...
            any(profNsTPhaseDoxy ~= paramTPhaseDoxy.fillValue) || ...
            any(profNsTempDoxy ~= paramTempDoxy.fillValue) || ...
            any(profNsRPhaseDoxy ~= paramRPhaseDoxy.fillValue))
         
         % compute JULD from EPOCH
         profNsJuld = ones(size(profNsEpoch))*paramJuld.fillValue;
         idNoDef = find(profNsEpoch ~= g_decArgo_epochDef);
         profNsJuld(idNoDef) = epoch_2_julian_dec_argo(profNsEpoch(idNoDef));
         
         % store prof NS data
         profNsData = get_apx_profile_data_init_struct;
         
         % add parameter variables to the data structure
         profNsData.dateList = paramJuld;
         profNsData.paramList = [paramPres  ...
            paramTPhaseDoxy paramTempDoxy paramRPhaseDoxy];
         
         % add parameter data to the data structure
         profNsData.dates = profNsJuld;
         profNsData.data = [profNsPres  ...
            profNsTPhaseDoxy profNsTempDoxy profNsRPhaseDoxy];
         
         % add date status to the data structure
         profNsData.datesStatus = repmat(g_JULD_STATUS_2, size(profNsData.dates));
         
         switch (dataType)
            case 1
               o_nearSurfData{end+1} = profNsData;
            case 2
               o_surfDataBladderDeflated{end+1} = profNsData;
            case 3
               o_surfDataBladderInflated{end+1} = profNsData;
               
            otherwise
               fprintf('DEC_WARNING: Float #%d Cycle #%d: Inconsistent NS data type\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
               return
         end
      end
   end
end

return
