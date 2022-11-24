% ------------------------------------------------------------------------------
% Decode IMU data transmitted by a CTS5-USEA float.
%
% SYNTAX :
%  [o_imuRawData, o_imuTiltHeadingData, o_imuWaveData] = decode_apmt_imu(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : APMT IMU file to decode
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
function [o_imuRawData, o_imuTiltHeadingData, o_imuWaveData] = decode_apmt_imu(a_inputFilePathName)

% output parameters initialization
o_imuRawData = [];
o_imuTiltHeadingData = [];
o_imuWaveData = [];


if ~(exist(a_inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_imu: File not found: %s\n', a_inputFilePathName);
   return
end

% open the file and read the data
fId = fopen(a_inputFilePathName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_inputFilePathName);
   return
end
data = fread(fId);
fclose(fId);

% find the position of the last useful byte
lastByteNum = get_last_byte_number(data, hex2dec('1a'));

% decode the data according to the first byte flag
switch (data(1))
   case {33}
      o_imuRawData = decode_apmt_imu_raw(data, lastByteNum, a_inputFilePathName);
   case {34}
      o_imuTiltHeadingData = decode_apmt_imu_tilt_heading(data, lastByteNum, a_inputFilePathName);
   case {35}
      o_imuWaveData = decode_apmt_imu_wave(data, lastByteNum, a_inputFilePathName);
   otherwise
      fprintf('ERROR: Unexpected file type byte in file: %s\n', a_inputFilePathName);
end

return
