% ------------------------------------------------------------------------------
% Decode IMU data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_imuRawData, o_imuTiltHeadingData, o_imuWaveData] = decode_apmt_imu(a_fileNameInfo)
%
% INPUT PARAMETERS :
%   a_fileNameInfo : information on APMT IMU file to decode
%
% OUTPUT PARAMETERS :
%   o_imuRawData         : IMU Raw decoded data
%   o_imuTiltHeadingData : IMU Tilt & Heading decoded data
%   o_imuWaveData        : IMU Wave decoded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/22/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_imuRawData, o_imuTiltHeadingData, o_imuWaveData] = decode_apmt_imu(a_fileNameInfo)

% output parameters initialization
o_imuRawData = [];
o_imuTiltHeadingData = [];
o_imuWaveData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;


% input data file
inputFilePathName = [a_fileNameInfo{4} a_fileNameInfo{1}];

if ~(exist(inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_imu: File not found: %s\n', inputFilePathName);
   return
end

% open the file and read the data
fId = fopen(inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', inputFilePathName);
   return
end
data = fread(fId);
fclose(fId);

% find the position of the last useful byte
lastByteNum = get_last_byte_number(data, hex2dec('1a'));

try

   % decode the data according to the first byte flag
   switch (data(1))
      case {33}
         o_imuRawData = decode_apmt_imu_raw(data, lastByteNum, inputFilePathName);
      case {34}
         o_imuTiltHeadingData = decode_apmt_imu_tilt_heading(data, lastByteNum, inputFilePathName);
      case {35}
         o_imuWaveData = decode_apmt_imu_wave(data, lastByteNum, inputFilePathName);
      otherwise
         fprintf('ERROR: Unexpected file type byte (%d) in file: %s\n', data(1), inputFilePathName);
   end

catch MException
   switch MException.identifier
      case 'MATLAB:badsubscript'

         fprintf('ERROR: Float #%d: (Cy,Ptn)=(%d,%d): File ''%s'' is inconsistent (shorter than expected) - file ignored\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat, ...
            a_fileNameInfo{1});
         return
   end
   rethrow(MException)
end

return
