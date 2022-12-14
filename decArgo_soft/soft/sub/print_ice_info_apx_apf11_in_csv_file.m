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

for idI = 1:length(a_iceDetection)
   iceDetection = a_iceDetection{idI};
   
   if (~isempty(iceDetection.thermalDetect.sampleTime))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Thermal; SAMPLE #; JULD; JULD_ADJUSTED; PRES (decibar); TEMP (degree_Celsius); ; PRES_ADJUSTED (decibar); TEMP (degree_Celsius)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      for idM = 1:length(iceDetection.thermalDetect.sampleTime)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Thermal; #%d; %s; %s; %g; %g; ; %g; %g\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idM, ...
            julian_2_gregorian_dec_argo(iceDetection.thermalDetect.sampleTime(idM)), ...
            julian_2_gregorian_dec_argo(iceDetection.thermalDetect.sampleTimeAdj(idM)), ...
            iceDetection.thermalDetect.samplePres(idM), ...
            iceDetection.thermalDetect.sampleTemp(idM), ...
            iceDetection.thermalDetect.samplePresAdj(idM), ...
            iceDetection.thermalDetect.sampleTemp(idM));
      end
   end
   if (~isempty(iceDetection.thermalDetect.medianTempTime))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Thermal; MEDIAN; JULD; JULD_ADJUSTED; TEMP (degree_Celsius)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Thermal; MEDIAN; %s; %s; %g\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         julian_2_gregorian_dec_argo(iceDetection.thermalDetect.medianTempTime), ...
         julian_2_gregorian_dec_argo(iceDetection.thermalDetect.medianTempTimeAdj), ...
         iceDetection.thermalDetect.medianTemp);
   end
   if (~isempty(iceDetection.thermalDetect.detectTime))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Thermal; DETECT; JULD; JULD_ADJUSTED; PRES (decibar); MEDIAN PRES (decibar); NB SAMPLES; ; PRES_ADJUSTED (decibar); MEDIAN PRES_ADJUSTED (decibar); NB SAMPLES\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Thermal; DETECT; %s; %s; %g; %g; %d; ; %g; %g; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         julian_2_gregorian_dec_argo(iceDetection.thermalDetect.detectTime), ...
         julian_2_gregorian_dec_argo(iceDetection.thermalDetect.detectTimeAdj), ...
         iceDetection.thermalDetect.detectPres, ...
         iceDetection.thermalDetect.detectMedianPres, ...
         iceDetection.thermalDetect.detectNbSample, ...
         iceDetection.thermalDetect.detectPresAdj, ...
         iceDetection.thermalDetect.detectMedianPresAdj, ...
         iceDetection.thermalDetect.detectNbSample);
   end
   if (~isempty(iceDetection.breakupDetect.detectTime))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Breakup; #; JULD; JULD_ADJUSTED; FLAG (1:TRUE, 0:FALSE)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      for idM = 1:length(iceDetection.breakupDetect.detectTime)
         fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; Breakup; #%d; %s; %s; %d\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            idM, ...
            julian_2_gregorian_dec_argo(iceDetection.breakupDetect.detectTime(idM)), ...
            julian_2_gregorian_dec_argo(iceDetection.breakupDetect.detectTimeAdj(idM)), ...
            iceDetection.breakupDetect.detectFlag(idM));
      end
   end
   if (~isempty(iceDetection.ascent.abortTypeTime))
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; ASCENT ABORT; -; JULD; JULD_ADJUSTED; PRES (decibar); TYPE (1:thermal, 2: breakup); ; PRES_ADJUSTED (decibar); TYPE (1:thermal, 2: breakup)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      presStr = '-';
      presAdjStr = '-';
      if (~isempty(iceDetection.thermalDetect.detectPres))
         presStr = num2str(iceDetection.thermalDetect.detectPres);
         presAdjStr = num2str(iceDetection.thermalDetect.detectPresAdj);
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; Ice; ASCENT ABORT; -; %s; %s; %s; %d; ; %s; %d\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         julian_2_gregorian_dec_argo(iceDetection.ascent.abortTypeTime), ...
         julian_2_gregorian_dec_argo(iceDetection.ascent.abortTypeTimeAdj), ...
         presStr, ...
         iceDetection.ascent.abortType, ...
         presAdjStr, ...
         iceDetection.ascent.abortType);
   end
end

return
