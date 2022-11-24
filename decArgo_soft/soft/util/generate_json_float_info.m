% ------------------------------------------------------------------------------
% Convert common float information file (used by decode_provor_2_csv and
% decode_provor_2_nc) to individual json float information files (used by
% decode_provor_2_nc_rt).
%
% SYNTAX :
%  generate_json_float_info()
%
% INPUT PARAMETERS :
%  
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/17/2013 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_info()

% common float information file
floatInfoFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\floats_info_NOVA.txt';
% floatInfoFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\floats_info_APX.txt';
floatInfoFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\floats_info_PRV.txt';
% floatInfoFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\floats_info_REM_sbd.txt';
% floatInfoFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\floats_info_APMT.txt';
floatInfoFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\floats_info_APX_IR.txt';
% floatInfoFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\floats_info_Arvor_C.txt';
% floatInfoFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\floats_info_NEMO.txt';

% directory of individual json float information files
outputDirName = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\json_float_info_files_' datestr(now, 'yyyymmddTHHMMSS')];

if ~(exist(floatInfoFileName, 'file') == 2)
   fprintf('ERROR: Float information file not found: %s\n', floatInfoFileName);
   return
end

fId = fopen(floatInfoFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening file : %s\n', floatInfoFileName);
end

data = textscan(fId, '%d %d %s %d %d %d %s %s %s %s %s %s %d %s');

listWmoNum = data{1}(:);
listDecId = data{2}(:);
listArgosId = data{3}(:);
listFrameLen = data{4}(:);
listCycleTime = data{5}(:);
listDriftSamplingPeriod = data{6}(:);
listDelay = data{7}(:);
listLaunchDate = data{8}(:);
listLaunchLon = data{9}(:);
listLaunchLat = data{10}(:);
listRefDay = data{11}(:);
listEndDate = data{12}(:);
listDmFlag = data{13}(:);
listDecVer = data{14}(:);

fclose(fId);

mkdir(outputDirName);

for id = 1:length(listWmoNum)

   outputFileName = [outputDirName '/' sprintf('%d_%s_info.json', listWmoNum(id), listArgosId{id})];
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      fprintf('ERROR: Unable to create json output file: %s\n', outputFileName);
      return
   end

   floatType = 'UNKNOWN';
   if (listDecId(id) < 1000)
      floatType = 'PROVOR';
   elseif ((listDecId(id) > 1000) && (listDecId(id) < 2000))
      floatType = 'APEX';
   elseif ((listDecId(id) > 2000) && (listDecId(id) < 3000))
      floatType = 'NOVA';
   elseif (listDecId(id) > 3000)
      floatType = 'NEMO';
   end
   
   fprintf(fidOut, '{\n');
   fprintf(fidOut, '   "WMO" : "%d",\n', listWmoNum(id));
   fprintf(fidOut, '   "PTT" : "%s",\n', listArgosId{id});
   fprintf(fidOut, '   "FLOAT_TYPE" : "%s",\n', floatType);
   fprintf(fidOut, '   "DECODER_VERSION" : "%s",\n', listDecVer{id});
   fprintf(fidOut, '   "DECODER_ID" : "%d",\n', listDecId(id));
   fprintf(fidOut, '   "FRAME_LENGTH" : "%d",\n', listFrameLen(id));
   fprintf(fidOut, '   "CYCLE_LENGTH" : "%d",\n', listCycleTime(id));
   fprintf(fidOut, '   "DRIFT_SAMPLING_PERIOD" : "%d",\n', listDriftSamplingPeriod(id));
   fprintf(fidOut, '   "DELAI" : "%s",\n', listDelay{id});
   fprintf(fidOut, '   "LAUNCH_DATE" : "%s",\n', listLaunchDate{id});
   fprintf(fidOut, '   "LAUNCH_LON" : "%s",\n', listLaunchLon{id});
   fprintf(fidOut, '   "LAUNCH_LAT" : "%s",\n', listLaunchLat{id});
   fprintf(fidOut, '   "END_DECODING_DATE" : "%s",\n', listEndDate{id});
   fprintf(fidOut, '   "REFERENCE_DAY" : "%s",\n', listRefDay{id});
   fprintf(fidOut, '   "DM_FLAG" : "%d"\n', listDmFlag(id));
   fprintf(fidOut, '}\n');
   
   fclose(fidOut);
end

return
