% ------------------------------------------------------------------------------
% Store ICE related information for delayed check.
%
% SYNTAX :
% store_ice_information_apf9_argos(a_miscInfo, a_profData, a_profNstData, a_surfData)
%
% INPUT PARAMETERS :
%   a_miscInfo    : misc info from test and data messages
%   a_profData    : profile data
%   a_profNstData : NST profile data
%   a_surfData    : surface data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/08/2024 - RNU - creation
% ------------------------------------------------------------------------------
function store_ice_information_apf9_argos(a_miscInfo, a_profData, a_profNstData, a_surfData)

% current cycle number
global g_decArgo_cycleNum;

% to store ICE data used for delayed processing
global g_decArgo_iceData;


if (g_decArgo_cycleNum == 0)
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TECH

iceEvasionRecord = nan;
idF = contains({cell2mat(a_miscInfo).label}, 'Ice evasion record');
if (~isempty(idF))
   iceEvasionRecord = bin2dec(a_miscInfo{idF}.value);
end
nbSamples = nan;
idF = contains({cell2mat(a_miscInfo).label}, 'Number of mixed-layer samples taken');
if (~isempty(idF))
   nbSamples = a_miscInfo{idF}.value;
end
medianTemp = nan;
idF = contains({cell2mat(a_miscInfo).label}, 'Median of the mixed-layer temperature');
if (~isempty(idF))
   medianTemp = a_miscInfo{idF}.value;
end
infimumTemp = nan;
idF = contains({cell2mat(a_miscInfo).label}, 'Infimum of the mixed-layer median temperature since the last successful telemetry');
if (~isempty(idF))
   infimumTemp = a_miscInfo{idF}.value;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRESSURE MEASUREMENTS

paramPres = get_netcdf_param_attributes('PRES');
presMin = realmax("double");
profPresMin = realmax("double");
measDataProf = [a_profData, a_profNstData];
for idP = 1:length(measDataProf)
   measData = measDataProf(idP);
   idPres = find(strcmp({measData.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      profPresMeas = measData.data(:, idPres);
      presMin = min([presMin min(profPresMeas(profPresMeas ~= paramPres.fillValue))]);
      profPresMin = min([profPresMin min(profPresMeas(profPresMeas ~= paramPres.fillValue))]);
   end
end
if (~isempty(a_surfData))
   idPres = find(strcmp({a_surfData.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      presMeas = a_surfData.data(:, idPres);
      presMin = min([presMin min(presMeas(presMeas ~= paramPres.fillValue))]);
   end
end
if (presMin == realmax("double"))
   presMin = nan;
end
if (profPresMin == realmax("double"))
   profPresMin = nan;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% OUTPUT

% ICE data information
% 1- cycle number
% 2- ICE evasion record
% 3- number of samples
% 4- median TEMP
% 5- infimum TEMP
% 6- PRES min measurement
% 7- profile PRES min measurement

g_decArgo_iceData = [g_decArgo_iceData; ...
   [g_decArgo_cycleNum, ...
   iceEvasionRecord, nbSamples, medianTemp, infimumTemp, ...
   presMin, profPresMin ...
   ]];

return
