% ------------------------------------------------------------------------------
% Print Ice data in CSV file.
%
% SYNTAX :
%  print_ice_info_apx_apf11_in_csv_file(a_iceDetection)
%
% INPUT PARAMETERS :
%   a_iceDetection : Ice detection data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function print_ice_info_apx_apf11_in_csv_file(a_iceDetection)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_iceDetection))
   return
end

if (~isempty(a_iceDetection.thermalDetect.sampleTime))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Thermal; SAMPLE #; JULD; JULD_ADJUSTED; PRES (decibar); TEMP (degree_Celsius); ; PRES_ADJUSTED (decibar); TEMP (degree_Celsius)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   for idI = 1:length(a_iceDetection.thermalDetect.sampleTime)
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Thermal; #%d; %s; %s; %g; %g; ; %g; %g\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idI, ...
         julian_2_gregorian_dec_argo(a_iceDetection.thermalDetect.sampleTime(idI)), ...
         julian_2_gregorian_dec_argo(a_iceDetection.thermalDetect.sampleTimeAdj(idI)), ...
         a_iceDetection.thermalDetect.samplePres(idI), ...
         a_iceDetection.thermalDetect.sampleTemp(idI), ...
         a_iceDetection.thermalDetect.samplePresAdj(idI), ...
         a_iceDetection.thermalDetect.sampleTemp(idI));
   end
end
if (~isempty(a_iceDetection.thermalDetect.medianTempTime))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Thermal; MEDIAN; JULD; JULD_ADJUSTED; TEMP (degree_Celsius)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Thermal; MEDIAN; %s; %s; %g\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_iceDetection.thermalDetect.medianTempTime), ...
      julian_2_gregorian_dec_argo(a_iceDetection.thermalDetect.medianTempTimeAdj), ...
      a_iceDetection.thermalDetect.medianTemp);
end
if (~isempty(a_iceDetection.thermalDetect.detectTime))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Thermal; DETECT; JULD; JULD_ADJUSTED; PRES (decibar); MEDIAN PRES (decibar); NB SAMPLES; ; PRES_ADJUSTED (decibar); MEDIAN PRES_ADJUSTED (decibar); NB SAMPLES\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Thermal; DETECT; %s; %s; %g; %g; %d; ; %g; %g; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_iceDetection.thermalDetect.detectTime), ...
      julian_2_gregorian_dec_argo(a_iceDetection.thermalDetect.detectTimeAdj), ...
      a_iceDetection.thermalDetect.detectPres, ...
      a_iceDetection.thermalDetect.detectMedianPres, ...
      a_iceDetection.thermalDetect.detectNbSample, ...
      a_iceDetection.thermalDetect.detectPresAdj, ...
      a_iceDetection.thermalDetect.detectMedianPresAdj, ...
      a_iceDetection.thermalDetect.detectNbSample);
end
if (~isempty(a_iceDetection.breakupDetect.detectTime))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Breakup; #; JULD; JULD_ADJUSTED; FLAG (1:TRUE, 0:FALSE)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   for idI = 1:length(a_iceDetection.breakupDetect.detectTime)
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Breakup; #%d; %s; %s; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         idI, ...
         julian_2_gregorian_dec_argo(a_iceDetection.breakupDetect.detectTime(idI)), ...
         julian_2_gregorian_dec_argo(a_iceDetection.breakupDetect.detectTimeAdj(idI)), ...
         a_iceDetection.breakupDetect.detectFlag(idI));
   end
end
if (~isempty(a_iceDetection.ascent.abortTypeTime))
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; ASCENT ABORT; -; JULD; JULD_ADJUSTED; PRES (decibar); TYPE (1:thermal, 2: breakup); ; PRES_ADJUSTED (decibar); TYPE (1:thermal, 2: breakup)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   presStr = '-';
   presAdjStr = '-';
   if (~isempty(a_iceDetection.thermalDetect.detectPres))
      presStr = num2str(a_iceDetection.thermalDetect.detectPres);
      presAdjStr = num2str(a_iceDetection.thermalDetect.detectPresAdj);
   end
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; ASCENT ABORT; -; %s; %s; %s; %d; ; %s; %d\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(a_iceDetection.ascent.abortTypeTime), ...
      julian_2_gregorian_dec_argo(a_iceDetection.ascent.abortTypeTimeAdj), ...
      presStr, ...
      a_iceDetection.ascent.abortType, ...
      presAdjStr, ...
      a_iceDetection.ascent.abortType);
end

return