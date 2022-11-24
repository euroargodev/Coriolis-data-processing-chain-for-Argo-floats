% ------------------------------------------------------------------------------
% Cut the CTD profiles at the cut-off pressure of the CTD pump.
%
% SYNTAX :
%  [o_cutProfiles] = cut_ctd_profile_ir_sbd2(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%
% OUTPUT PARAMETERS :
%   o_cutProfiles   : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/29/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cutProfiles] = cut_ctd_profile_ir_sbd2(a_tabProfiles)

% output parameters initialization
o_cutProfiles = [];


% cut the CTD profiles
tabProfiles = [];
for idProf = 1:length(a_tabProfiles)
   
   profile = a_tabProfiles(idProf);
   
   if (profile.primarySamplingProfileFlag == -1)
      if (profile.direction == 'A')
         [cutProfiles] = cut_profile(profile);
         tabProfiles = [tabProfiles cutProfiles];
      else
         a_tabProfiles(idProf).primarySamplingProfileFlag = 1;
         tabProfiles = [tabProfiles a_tabProfiles(idProf)];
      end
   else
      tabProfiles = [tabProfiles a_tabProfiles(idProf)];
   end
end

% update output parameters
o_cutProfiles = tabProfiles;

return;

% ------------------------------------------------------------------------------
% Cut a CTD profile at the cut-off pressure of the CTD pump.
%
% SYNTAX :
%  [o_cutProfiles] = cut_profile(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%
% OUTPUT PARAMETERS :
%   o_cutProfiles   : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/29/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cutProfiles] = cut_profile(a_tabProfile)

% output parameters initialization
o_cutProfiles = [];

% global default values
global g_decArgo_presDef;


if (a_tabProfile.presCutOffProf ~= g_decArgo_presDef)
      
   presMeas = a_tabProfile.data(:, 1);
   paramPres = get_netcdf_param_attributes('PRES');
   idLevPrimary = find((presMeas ~= paramPres.fillValue) & (presMeas > a_tabProfile.presCutOffProf));
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
   
   if (~isempty(idLevPrimary))
      primaryProfile = a_tabProfile;
      primaryProfile.primarySamplingProfileFlag = 1;
      primaryProfile.vertSamplingScheme = primaryProfile.vertSamplingScheme{1};      
      primaryProfile.data = primaryProfile.data(1:idLevPrimary(end), :);
      datesPrimary = primaryProfile.dates(1:idLevPrimary(end), 1);
      primaryProfile.dates = datesPrimary;
      datesPrimary(find(datesPrimary == primaryProfile.dateList(1).fillValue)) = [];
      primaryProfile.minMeasDate = min(datesPrimary);
      primaryProfile.maxMeasDate = max(datesPrimary);

      o_cutProfiles = [o_cutProfiles primaryProfile];
   end
   
   if (~isempty(idLevNearSurface))
      nearSurfaceProfile = a_tabProfile;
      nearSurfaceProfile.primarySamplingProfileFlag = 2;
      nearSurfaceProfile.vertSamplingScheme = nearSurfaceProfile.vertSamplingScheme{2};      
      nearSurfaceProfile.data = nearSurfaceProfile.data(idLevNearSurface(1):end, :);
      datesNearSurface = nearSurfaceProfile.dates(idLevNearSurface(1):end, 1);
      nearSurfaceProfile.dates = datesNearSurface;
      datesNearSurface(find(datesNearSurface == nearSurfaceProfile.dateList(1).fillValue)) = [];
      nearSurfaceProfile.minMeasDate = min(datesNearSurface);
      nearSurfaceProfile.maxMeasDate = max(datesNearSurface);

      o_cutProfiles = [o_cutProfiles nearSurfaceProfile];
   end

else
   
   a_tabProfile.primarySamplingProfileFlag = 1;
   a_tabProfile.vertSamplingScheme = a_tabProfile.vertSamplingScheme{1};
   
   o_cutProfiles = a_tabProfile;
end

return;
