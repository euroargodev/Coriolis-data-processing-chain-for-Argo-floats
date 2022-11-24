% ------------------------------------------------------------------------------
% Find (from float decoder Id and if needed from float firmware version) if the
% 2047 dbar bug has been fixed (for relative coding pressures) for a given
% float.
%
% Information from NKE (mail 05/06/2015 09:23 from Jerome SAGOT)
% the 2047 dbar bug has been fixed (for relative coding pressures only):
% - for ARVOR floats since version 5605A06 (december 2011)
% - for PROVOR CTS3.1 floats since version 5816A04 (december 2011)
%
% SYNTAX :
%  [o_fixed] = bug_2047_dbar_fixed(a_floatNum, a_decoderId)
%
% INPUT PARAMETERS :
%   a_floatNum  : WMO float number
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_fixed  : bug fixed flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/25/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fixed] = bug_2047_dbar_fixed(a_floatNum, a_decoderId)

% output parameter initialization
o_fixed = [];


% the 2047 dbar bug exists for Argos decoder Ids 1, 3, 4, 11, 12, 17, 19
% for decoder Id 24 it has been fixed in firmware version 5816A04 (dec 2011)
if (a_decoderId <= 19)
   o_fixed = 0;
elseif (a_decoderId == 24)
   
   % retrieve information from json meta-data file
   wantedMetaNames = [ ...
      {'FLOAT_SERIAL_NO'} ...
      {'FIRMWARE_VERSION'} ...
      ];
   [metaData] = get_meta_data_from_json_file(a_floatNum, wantedMetaNames);
   
   floatSerialNum = [];
   idVal = find(strcmp('FLOAT_SERIAL_NO', metaData) == 1);
   if (~isempty(idVal))
      floatSerialNum = strtrim(metaData{idVal+1});
   end;
   firmwareVersion = [];
   idVal = find(strcmp('FIRMWARE_VERSION', metaData) == 1);
   if (~isempty(idVal))
      firmwareVersion = strtrim(metaData{idVal+1});
   end;
   
   if (length(firmwareVersion) == 7)
      refFirmwareVersion = '5816A04';
      firmwareVersion2 = firmwareVersion;
      firmwareVersion2(5) = [];
      [~, status] = str2num(firmwareVersion2);
      if (isletter(firmwareVersion(5)) && (status == 1))
         if (str2num(firmwareVersion(1:4)) > str2num(refFirmwareVersion(1:4)))
            o_fixed = 1;
         elseif (str2num(firmwareVersion(1:4)) < str2num(refFirmwareVersion(1:4)))
            o_fixed = 0;
         else
            if (firmwareVersion(5) > refFirmwareVersion(5))
               o_fixed = 1;
            elseif (firmwareVersion(5) < refFirmwareVersion(5))
               o_fixed = 0;
            else
               if (str2num(firmwareVersion(6:7)) >= str2num(refFirmwareVersion(6:7)))
                  o_fixed = 1;
               elseif (str2num(firmwareVersion(6:7)) < str2num(refFirmwareVersion(6:7)))
                  o_fixed = 0;
               end
            end
         end
      end
   end
   
   if (isempty(o_fixed))
      if (length(floatSerialNum) >= 6)
         if (strncmpi(floatSerialNum, 'OIN-', length('OIN-')))
            idF = strfind(floatSerialNum, '-');
            if (length(idF) >= 2)
               [year, status] = str2num(floatSerialNum(idF(1)+1:idF(2)-1));
               if (status == 1)
                  if (year > 11)
                     o_fixed = 1;
                  else
                     o_fixed = 0;
                  end
               end
            end
         end
      end
   end
   
   if (isempty(o_fixed))
      fprintf('WARNING: Float #%d: Unable to retrieve FIRMWARE_VERSION - set bug 2047 dbar to ''not fixed''\n', ...
         a_floatNum);
      o_fixed = 0;
   end
else
   o_fixed = 1;
end

return
