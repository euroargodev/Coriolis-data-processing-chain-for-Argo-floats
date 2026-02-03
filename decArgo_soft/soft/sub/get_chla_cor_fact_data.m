% ------------------------------------------------------------------------------
% Retrieve PHYSIO_RATIO from CHLA correction factor file.
%
% SYNTAX :
%  [o_physioRatio] = get_chla_cor_fact_data(a_lon, a_lat)
%
% INPUT PARAMETERS :
%   a_lon : profile longitude
%   a_lat : profile latitude
%
% OUTPUT PARAMETERS :
%   o_physioRatio : PHYSIO_RATIO value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_physioRatio] = get_chla_cor_fact_data(a_lon, a_lat)

% output parameters initialization
o_physioRatio = nan(size(a_lon));

% WOA file path name
global g_decArgo_chlaCorFactFile;

% global default values
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;


% check that the CHLA correction factor file is available
CHLA_COR_FACT_FILE_NAME = g_decArgo_chlaCorFactFile;
if ~(exist(CHLA_COR_FACT_FILE_NAME, 'file') == 2)
   fprintf('ERROR: CHLA correction factor file not found: %s - CHLA data cannot be adjusted\n', CHLA_COR_FACT_FILE_NAME);
   return
end

% retrieve data from CHLA_COR_FACT_FILE_NAME file
wantedVars = [ ...
   {'longitude'} ...
   {'latitude'} ...
   {'fluorescence_chlorophyll_ratio'} ...
   ];
physioRatioData = get_data_from_nc_file(CHLA_COR_FACT_FILE_NAME, wantedVars);

physioRatioLon = get_data_from_name('longitude', physioRatioData);
physioRatioLat = get_data_from_name('latitude', physioRatioData);
physioRatioVal = get_data_from_name('fluorescence_chlorophyll_ratio', physioRatioData);

% retrieve information from CHLA_COR_FACT_FILE_NAME file
wantedVarAtts = [ ...
   {'fluorescence_chlorophyll_ratio'} {'_FillValue'} ...
   ];
physioRatioDataAtt = get_att_from_nc_file(CHLA_COR_FACT_FILE_NAME, wantedVarAtts);

physioRatioFillValue = get_att_from_name('fluorescence_chlorophyll_ratio', '_FillValue', physioRatioDataAtt);

for id = 1:length(a_lon)
   if ((a_lon(id) ~= g_decArgo_argosLonDef) && (a_lat(id) ~= g_decArgo_argosLatDef))
      [~, lonId] = min(abs(a_lon(id) - physioRatioLon));
      [~, latId] = min(abs(a_lat(id) - physioRatioLat));
      physioRatio = physioRatioVal(lonId, latId);
      if (physioRatio ~= physioRatioFillValue)
         % update output parameters
         o_physioRatio(id) = physioRatio;
      else
         fprintf('ERROR: PHYSIO_RATIO = FV at (lon, lat) = (%.3f, %.3f)\n', a_lon(id), a_lat(id));
      end
   end
end

return
