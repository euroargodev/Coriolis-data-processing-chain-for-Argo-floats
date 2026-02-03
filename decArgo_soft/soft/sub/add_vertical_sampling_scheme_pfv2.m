% ------------------------------------------------------------------------------
% Create and add the vertical sampling scheme information to the profiles of the
% Iridium floats.
%
% SYNTAX :
%  [o_tabProfiles] = add_vertical_sampling_scheme_pfv2(a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_tabProfiles : input profile structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : output profile structures
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = add_vertical_sampling_scheme_pfv2(a_tabProfiles)

% output parameters initialization
o_tabProfiles = a_tabProfiles;

% current cycle number
global g_decArgo_cycleNum;


% retrieve configuration information
[configNames, configValues] = get_float_config_pfv2(g_decArgo_cycleNum);

% add the vertical sampling scheme for each profile
for idP = 1:length(o_tabProfiles)
   prof = o_tabProfiles(idP);

   if (prof.direction == 'A')

      profType = 0;
      if (prof.payloadSensorNumber == 1)
         if (prof.primarySamplingProfileFlag == 1)
            vssText = 'Primary sampling:';
            profType = 1;
         else
            vssText = 'Near-surface sampling:';
            profType = 2;
         end
      elseif (prof.payloadSensorNumber == 2)
         vssText = 'Secondary sampling:';
         profType = 3;
      elseif (prof.payloadSensorNumber == 3)
         vssText = 'Primary sampling:';
         profType = 3;
      end

      thresholdZ = nan(4, 1);
      sampPeriodZ = nan(5, 1);
      treatTypeZ = nan(5, 1);
      slicesThickZ = nan(5, 1);
      for idZ = 1:5
         if (idZ < 5)
            configName = sprintf('SENSORS-SENSOR%02d-ASCENT-ZONE%d.P0', prof.payloadSensorNumber, idZ);
            zoneThreshold = get_config_value_pfv2_3(configName, configNames, configValues);
            if (~isempty(zoneThreshold))
               thresholdZ(idZ) = zoneThreshold;
            end
         end
         configName = sprintf('SENSORS-SENSOR%02d-ASCENT-ZONE%d.P1', prof.payloadSensorNumber, idZ);
         zoneSampPeriod = get_config_value_pfv2_3(configName, configNames, configValues);
         if (~isempty(zoneSampPeriod))
            sampPeriodZ(idZ) = zoneSampPeriod;
         end
         configName = sprintf('SENSORS-SENSOR%02d-ASCENT-ZONE%d.P3', prof.payloadSensorNumber, idZ);
         zoneTreatType = get_config_value_pfv2_3(configName, configNames, configValues);
         if (~isempty(zoneTreatType))
            treatTypeZ(idZ) = zoneTreatType;
         end
         configName = sprintf('SENSORS-SENSOR%02d-ASCENT-ZONE%d.P4', prof.payloadSensorNumber, idZ);
         zoneSlicesThick = get_config_value_pfv2_3(configName, configNames, configValues);
         if (~isempty(zoneSlicesThick))
            slicesThickZ(idZ) = zoneSlicesThick;
         end
      end

      if (all(~isnan(thresholdZ)) && all(~isnan(sampPeriodZ)) && ...
            all(~isnan(treatTypeZ)) && all(~isnan(slicesThickZ)))

         switch profType

            case 1

               % primary profile from profPres to presCutOff

               profPres = nan;
               configName = 'MISSION-L-C-DESC_PROF.P0';
               profilePres = get_config_value_pfv2_3(configName, configNames, configValues);
               if (~isempty(profilePres))
                  profPres = profilePres;
               end

               if (~isnan(profPres))

                  idStart = find(thresholdZ < profPres, 1, 'last');
                  if (~isempty(idStart))
                     idStart = idStart + 1;
                  else
                     idStart = 1;
                  end
                  thresholdZ(idStart) = profPres;

                  text3 = [];
                  flagAvg = 0;
                  flagDiscrete = 0;
                  for id = idStart:-1:1
                     if (sampPeriodZ(id) ~= 0)
                        if ((treatTypeZ(id) == 0) || (treatTypeZ(id) == 8))
                           text1 = sprintf('%dsec samp. in ', ...
                              sampPeriodZ(id));
                           flagDiscrete = 1;
                        else
                           text1 = sprintf('%dsec samp., %gdbar avg in ', ...
                              sampPeriodZ(id), slicesThickZ(id));
                           flagAvg = 2;
                        end

                        if (id > 1)
                           if (thresholdZ(id-1) > prof.presCutOffProf)
                              text2 = sprintf('%d-%d dbar', ...
                                 thresholdZ(id), thresholdZ(id-1));
                           else
                              text2 = sprintf('%d-%.2f dbar', ...
                                 thresholdZ(id), prof.presCutOffProf);
                           end
                        elseif (thresholdZ(id) > prof.presCutOffProf)
                           text2 = sprintf('%d-%.2f dbar', ...
                              thresholdZ(id), prof.presCutOffProf);
                        end
                        text3{end+1} = [text1 text2];
                     end
                  end

                  description = '';
                  if (~isempty(text3))
                     description = [sprintf('%s;', text3{1:end-1}) sprintf('%s', text3{end})];
                  end
                  switch flagAvg+flagDiscrete
                     case 1
                        vssText = [vssText ' discrete [' description ']'];
                     case 2
                        vssText = [vssText ' averaged [' description ']'];
                     case 3
                        vssText = [vssText ' mixed [' description ']'];
                  end

                  o_tabProfiles(idP).vertSamplingScheme = vssText;
               end

            case 2

               % unpumped profile from presCutOff to surface

               idStart = find(thresholdZ < prof.presCutOffProf, 1, 'last');
               if (~isempty(idStart))
                  idStart = idStart + 1;
               else
                  idStart = 1;
               end
               thresholdZ(idStart) = prof.presCutOffProf;

               text3 = [];
               flagAvg = 0;
               flagDiscrete = 0;
               for id = idStart:-1:1
                  if (sampPeriodZ(id) ~= 0)
                     if ((treatTypeZ(id) == 0) || (treatTypeZ(id) == 8))
                        if (id > 1)
                           text1 = sprintf('%dsec samp. in ', ...
                              sampPeriodZ(id));
                        else
                           text1 = sprintf('%dsec samp. from ', ...
                              sampPeriodZ(id));
                        end
                        flagDiscrete = 1;
                     else
                        if (id > 1)
                           text1 = sprintf('%dsec samp., %gdbar avg in ', ...
                              sampPeriodZ(id), slicesThickZ(id));
                        else
                           text1 = sprintf('%dsec samp., %gdbar avg from ', ...
                              sampPeriodZ(id), slicesThickZ(id));
                        end
                        flagAvg = 2;
                     end

                     if (id > 1)
                        if (id == idStart)
                           text2 = sprintf('%.2f - %ddbar', ...
                              thresholdZ(id), thresholdZ(id-1));
                        else
                           text2 = sprintf('%d-%d dbar', ...
                              thresholdZ(id), thresholdZ(id-1));
                        end
                     else
                        if (id == idStart)
                           text2 = sprintf('%.2fdbar to surface', ...
                              thresholdZ(id));
                        else
                           text2 = sprintf('%ddbar to surface', ...
                              thresholdZ(id));
                        end
                     end
                     text3{end+1} = [text1 text2];
                  end
               end

               description = '';
               if (~isempty(text3))
                  description = [sprintf('%s;', text3{1:end-1}) sprintf('%s', text3{end})];
               end
               switch flagAvg+flagDiscrete
                  case 1
                     vssText = [vssText ' discrete, unpumped [' description ']'];
                  case 2
                     vssText = [vssText ' averaged, unpumped [' description ']'];
                  case 3
                     vssText = [vssText ' mixed, unpumped [' description ']'];
               end

               o_tabProfiles(idP).vertSamplingScheme = vssText;

            case 3

               % primary profile from profPres to surface

               profPres = nan;
               configName = 'MISSION-L-C-DESC_PROF.P0';
               profilePres = get_config_value_pfv2_3(configName, configNames, configValues);
               if (~isempty(profilePres))
                  profPres = profilePres;
               end

               if (~isnan(profPres))

                  idStart = find(thresholdZ < profPres, 1, 'last');
                  if (~isempty(idStart))
                     idStart = idStart + 1;
                  else
                     idStart = 1;
                  end
                  thresholdZ(idStart) = profPres;

                  text3 = [];
                  flagAvg = 0;
                  flagDiscrete = 0;
                  for id = idStart:-1:1
                     if (sampPeriodZ(id) ~= 0)
                        if ((treatTypeZ(id) == 0) || (treatTypeZ(id) == 8))
                           if (id > 1)
                              text1 = sprintf('%dsec samp. in ', ...
                                 sampPeriodZ(id));
                           else
                              text1 = sprintf('%dsec samp. from ', ...
                                 sampPeriodZ(id));
                           end
                           flagDiscrete = 1;
                        else
                           if (id > 1)
                              text1 = sprintf('%dsec samp., %gdbar avg in ', ...
                                 sampPeriodZ(id), slicesThickZ(id));
                           else
                              text1 = sprintf('%dsec samp., %gdbar avg from ', ...
                                 sampPeriodZ(id), slicesThickZ(id));
                           end
                           flagAvg = 2;
                        end

                        if (id > 1)
                           text2 = sprintf('%d-%d dbar', ...
                              thresholdZ(id), thresholdZ(id-1));
                        else
                           text2 = sprintf('%ddbar to surface', ...
                              thresholdZ(id));
                        end
                        text3{end+1} = [text1 text2];
                     end
                  end

                  description = '';
                  if (~isempty(text3))
                     description = [sprintf('%s;', text3{1:end-1}) sprintf('%s', text3{end})];
                  end
                  switch flagAvg+flagDiscrete
                     case 1
                        vssText = [vssText ' discrete [' description ']'];
                     case 2
                        vssText = [vssText ' averaged [' description ']'];
                     case 3
                        vssText = [vssText ' mixed [' description ']'];
                  end

                  o_tabProfiles(idP).vertSamplingScheme = vssText;
               end
         end
      end

   elseif (prof.direction == 'D')

      if (prof.payloadSensorNumber == 2)
         vssText = 'Secondary sampling:';
      else
         vssText = 'Primary sampling:';
      end

      parkPres = nan;
      configName = 'MISSION-L-C-DESC_PARK.P0';
      parkingPres = get_config_value_pfv2_3(configName, configNames, configValues);
      if (~isempty(parkingPres))
         parkPres = parkingPres;
      end

      thresholdZ = nan(4, 1);
      sampPeriodZ = nan(5, 1);
      treatTypeZ = nan(5, 1);
      slicesThickZ = nan(5, 1);
      for idZ = 1:5
         if (idZ < 5)
            configName = sprintf('SENSORS-SENSOR%02d-DESCENT-ZONE%d.P0', prof.payloadSensorNumber, idZ);
            zoneThreshold = get_config_value_pfv2_3(configName, configNames, configValues);
            if (~isempty(zoneThreshold))
               thresholdZ(idZ) = zoneThreshold;
            end
         end
         configName = sprintf('SENSORS-SENSOR%02d-DESCENT-ZONE%d.P1', prof.payloadSensorNumber, idZ);
         zoneSampPeriod = get_config_value_pfv2_3(configName, configNames, configValues);
         if (~isempty(zoneSampPeriod))
            sampPeriodZ(idZ) = zoneSampPeriod;
         end
         configName = sprintf('SENSORS-SENSOR%02d-DESCENT-ZONE%d.P3', prof.payloadSensorNumber, idZ);
         zoneTreatType = get_config_value_pfv2_3(configName, configNames, configValues);
         if (~isempty(zoneTreatType))
            treatTypeZ(idZ) = zoneTreatType;
         end
         configName = sprintf('SENSORS-SENSOR%02d-DESCENT-ZONE%d.P4', prof.payloadSensorNumber, idZ);
         zoneSlicesThick = get_config_value_pfv2_3(configName, configNames, configValues);
         if (~isempty(zoneSlicesThick))
            slicesThickZ(idZ) = zoneSlicesThick;
         end
      end

      if (all(~isnan(thresholdZ)) && all(~isnan(sampPeriodZ)) && ...
            all(~isnan(treatTypeZ)) && all(~isnan(slicesThickZ)) && ~isnan(parkPres))

         idEnd = find(thresholdZ < parkPres, 1, 'last');
         if (~isempty(idEnd))
            idEnd = idEnd + 1;
         else
            idEnd = 1;
         end
         thresholdZ(idEnd) = parkPres;

         text3 = [];
         flagAvg = 0;
         flagDiscrete = 0;
         for id = 1:idEnd
            if (sampPeriodZ(id) ~= 0)
               if ((treatTypeZ(id) == 0) || (treatTypeZ(id) == 8))
                  if (id == 1)
                     text1 = sprintf('%dsec samp. from ', ...
                        sampPeriodZ(id));
                  else
                     text1 = sprintf('%dsec samp. in ', ...
                        sampPeriodZ(id));
                  end
                  flagDiscrete = 1;
               else
                  if (id == 1)
                     text1 = sprintf('%dsec samp., %gdbar avg from ', ...
                        sampPeriodZ(id), slicesThickZ(id));
                  else
                     text1 = sprintf('%dsec samp., %gdbar avg in ', ...
                        sampPeriodZ(id), slicesThickZ(id));
                  end
                  flagAvg = 2;
               end

               if (id == 1)
                  text2 = sprintf('surface to %ddbar', ...
                     thresholdZ(1));
               else
                  text2 = sprintf('%d-%d dbar', ...
                     thresholdZ(id-1), thresholdZ(id));
               end

               text3{end+1} = [text1 text2];
            end
         end

         description = '';
         if (~isempty(text3))
            description = [sprintf('%s;', text3{1:end-1}) sprintf('%s', text3{end})];
         end
         switch flagAvg+flagDiscrete
            case 1
               vssText = [vssText ' discrete [' description ']'];
            case 2
               vssText = [vssText ' averaged [' description ']'];
            case 3
               vssText = [vssText ' mixed [' description ']'];
         end

         o_tabProfiles(idP).vertSamplingScheme = vssText;
      end
   end
end

return
