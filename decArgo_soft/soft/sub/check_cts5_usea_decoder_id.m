% ------------------------------------------------------------------------------
% Check that the right decoder is used for a given float using:
% - the firmware versions of the primary and secondary controller boards
% - the specific configurations of SUNA, OCR or FLUOROMETER_CHLA sensors
%
% SYNTAX :
%  check_cts5_usea_decoder_id(a_decoderId, a_floatNum)
%
% INPUT PARAMETERS :
%   a_decoderId : decoder id used
%   a_floatNum  : float number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/25/2025 - RNU - creation
% ------------------------------------------------------------------------------
function check_cts5_usea_decoder_id(a_decoderId, a_floatNum)

% json meta-data
global g_decArgo_jsonMetaData;

% decoder Id check flag
global g_decArgo_decIdCheckFlag;
g_decArgo_decIdCheckFlag = 1; % the check is done only once for each float


% check primary and secondary firmware versions

firmwareVersionPrimary = '';
firmwareVersionSecondary = '';
if (isfield(g_decArgo_jsonMetaData, 'FIRMWARE_VERSION'))
   firmwareVersionPrimary = strtrim(g_decArgo_jsonMetaData.FIRMWARE_VERSION);
end
if (isfield(g_decArgo_jsonMetaData, 'META_AUX_FIRMWARE_VERSION_SECONDARY'))
   firmwareVersionSecondary = strtrim(g_decArgo_jsonMetaData.META_AUX_FIRMWARE_VERSION_SECONDARY);
end

if (~isempty(firmwareVersionPrimary) || ~isempty(firmwareVersionSecondary))

   switch (a_decoderId)
      case {126, 136}
         firmwareVersionPrimaryList = [{'1.07.024'}];
         firmwareVersionSecondaryList = [{'1.00.0024'}];
      case {127, 134}
         firmwareVersionPrimaryList = [{'1.08.005'}, {'1.08.004'}];
         firmwareVersionSecondaryList = [{'1.01.005'}, {'1.01.004'}];
      case {128}
         firmwareVersionPrimaryList = [{'1.09.001'}];
         firmwareVersionSecondaryList = [{'1.02.001'}];
      case {129, 130, 131, 132, 133, 137, 141}
         firmwareVersionPrimaryList = [{'1.09.002'}, {'1.09.003'}, {'1.09.004'}];
         firmwareVersionSecondaryList = [{'1.02.002'}, {'1.02.003'}, {'1.02.004'}];
      case {135, 138}
         firmwareVersionPrimaryList = [{'1.09.005'}];
         firmwareVersionSecondaryList = [{'1.02.005'}];
      case {139, 140}
         firmwareVersionPrimaryList = [{'1.09.008'}];
         firmwareVersionSecondaryList = [{'1.02.008'}];
      otherwise
         fprintf('WARNING: Float #%d: decoderId=%d not managed yet in check_cts5_usea_decoder_id\n', ...
            a_floatNum, a_decoderId);
         return
   end

   ok = 0;
   for id = 1:length(firmwareVersionPrimaryList)
      firmwareVersionPrimaryExpected = firmwareVersionPrimaryList{id};
      firmwareVersionSecondaryExpected = firmwareVersionSecondaryList{id};
      if (~isempty(firmwareVersionPrimary) && ~isempty(firmwareVersionSecondary))
         if (strcmp(firmwareVersionPrimary, firmwareVersionPrimaryExpected) && ...
               strcmp(firmwareVersionSecondary, firmwareVersionSecondaryExpected))
            ok = 1;
            break
         end
      elseif (~isempty(firmwareVersionPrimary))
         if (strcmp(firmwareVersionPrimary, firmwareVersionPrimaryExpected))
            ok = 1;
            break
         end
      else
         if (strcmp(firmwareVersionSecondary, firmwareVersionSecondaryExpected))
            ok = 1;
            break
         end
      end
   end
   if (~ok)
      fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float - inconsistent firmware versions\n', ...
         a_floatNum, a_decoderId);
   end
end

% check sensor specificities

% SUNA configuration
if (ismember(a_decoderId, [127, 134, 136, 137, 141]))
   ok = 0;
   if (isfield(g_decArgo_jsonMetaData, 'SENSOR_MOUNTED_ON_FLOAT'))
      if (any(strcmp(struct2cell(g_decArgo_jsonMetaData.SENSOR_MOUNTED_ON_FLOAT), 'SUNA')))
         if (isfield(g_decArgo_jsonMetaData, 'PARAMETER'))
            if (any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'BISULFIDE')))
               ok = 1;
            end
         end
      end
   end
   if (~ok)
      fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float - inconstent SUNA configuration\n', ...
         a_floatNum, a_decoderId);
   end
end

% OCR configuration
if (isfield(g_decArgo_jsonMetaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   if (any(strcmp(struct2cell(g_decArgo_jsonMetaData.SENSOR_MOUNTED_ON_FLOAT), 'OCR')))
      if (isfield(g_decArgo_jsonMetaData, 'PARAMETER'))
         ok = 0;
         switch (a_decoderId)
            case {130, 131}
               if (any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE412')) && ...
                     any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE443')) && ...
                     any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE490')) && ...
                     any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE665')))
                  ok = 1;
               end
            case {133, 138, 139, 140}
               if (any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE380')) && ...
                     any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE443')) && ...
                     any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE490')) && ...
                     any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE555')))
                  ok = 1;
               end
            case {134}
               if (any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE443')) && ...
                     any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE490')) && ...
                     any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE555')) && ...
                     any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_PAR')))
                  ok = 1;
               end
            otherwise
               if (any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE380')) && ...
                     any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE412')) && ...
                     any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_IRRADIANCE490')) && ...
                     any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'RAW_DOWNWELLING_PAR')))
                  ok = 1;
               end
         end
         if (~ok)
            fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float - inconstent OCR configuration\n', ...
               a_floatNum, a_decoderId);
         end
      end
   end
end

% FLUOROMETER_CHLA configuration
if (ismember(a_decoderId, [131, 132, 137, 140]))
   ok = 0;
   if (isfield(g_decArgo_jsonMetaData, 'SENSOR_MOUNTED_ON_FLOAT'))
      if (any(strcmp(struct2cell(g_decArgo_jsonMetaData.SENSOR_MOUNTED_ON_FLOAT), 'ECO3')))
         if (isfield(g_decArgo_jsonMetaData, 'PARAMETER'))
            if (any(strcmp(struct2cell(g_decArgo_jsonMetaData.PARAMETER), 'FLUORESCENCE_CHLA435')))
               ok = 1;
            end
         end
      end
   end
   if (~ok)
      fprintf('ERROR: Float #%d: A wrong decoder (#%d) seems to be used for this float - inconstent FLUOROMETER_CHLA configuration\n', ...
         a_floatNum, a_decoderId);
   end
end

return
