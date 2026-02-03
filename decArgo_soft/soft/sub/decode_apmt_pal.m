% ------------------------------------------------------------------------------
% Decode PAL data transmitted by a CTS5-USEA float.
%
% SYNTAX :
% [o_palRainWind, o_palHighResolution, o_palHighDynamicRange, ...
%   o_palFullSpectrum] = decode_apmt_pal(a_fileNameInfo)
%
% INPUT PARAMETERS :
%   a_fileNameInfo : information on APMT PAL file to decode
%
% OUTPUT PARAMETERS :
%   o_palRainWind         : PAL decoded data (rain plus wind format))
%   o_palHighResolution   : PAL decoded data (high resolution, meteorological spectrum format
%   o_palHighDynamicRange : PAL decoded data (high dynamic range, meteorological spectrum format)
%   o_palFullSpectrum     : PAL decoded data (full spectrum format)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/19/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_palRainWind, o_palHighResolution, o_palHighDynamicRange, ...
   o_palFullSpectrum] = decode_apmt_pal(a_fileNameInfo)

% output parameters initialization
o_palRainWind = [];
o_palHighResolution = [];
o_palHighDynamicRange = [];
o_palFullSpectrum = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;


% input data file
inputFilePathName = [a_fileNameInfo{4} a_fileNameInfo{1}];

if ~(exist(inputFilePathName, 'file') == 2)
   fprintf('ERROR: decode_apmt_pal: File not found: %s\n', inputFilePathName);
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
      case {36}
         fprintf('ERROR: decode_apmt_pal36 not implemented yet\n');
      case {37}
         fprintf('ERROR: decode_apmt_pal37 not implemented yet\n');
      case {38}
         o_palHighDynamicRange = decode_apmt_pal_hdr(data, lastByteNum, inputFilePathName);
      case {39}
         o_palFullSpectrum = decode_apmt_pal_fs(data, lastByteNum, inputFilePathName);
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
