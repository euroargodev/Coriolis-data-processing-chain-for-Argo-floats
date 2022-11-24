% ------------------------------------------------------------------------------
% Create the sampling configuration parameters from sample.cfg file contents.
%
% SYNTAX :
%  [o_configSampName, o_configSampVal] = create_sampling_configuration(a_sampleConfData)
%
% INPUT PARAMETERS :
%   a_sampleConfData : sample.cfg file contents
%
% OUTPUT PARAMETERS :
%   o_configSampName : sampling configuration names
%   o_configSampVal  : sampling configuration values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configSampName, o_configSampVal] = create_sampling_configuration(a_sampleConfData)

% output parameters initialization
o_configSampName = [];
o_configSampVal = [];

phaseNames = fieldnames(a_sampleConfData);
for idP = 1:length(phaseNames)
   phaseName = phaseNames{idP};
   
   sensorNames = fieldnames(a_sampleConfData.(phaseName));
   for idS = 1:length(sensorNames)
      sensorName = sensorNames{idS};
      sampInfo = a_sampleConfData.(phaseName).(sensorName);
      
      if (strcmp(sensorName, 'PTS'))
         [~, sortId] = sort(sampInfo(:, 1));
         sampInfo = sampInfo(sortId, :);
         o_configSampName{end+1} = ['CONFIG_SAMPLE_' phaseName '_' sensorName '_NumberOfZones'];
         o_configSampVal{end+1} = num2str(size(sampInfo, 1));
         for idL = 1:size(sampInfo, 1)
            o_configSampName{end+1} = ['CONFIG_SAMPLE_' phaseName '_' sensorName '_' num2str(idL) '_StartPressure'];
            o_configSampVal{end+1} = num2str(sampInfo(idL, 1));
            o_configSampName{end+1} = ['CONFIG_SAMPLE_' phaseName '_' sensorName '_' num2str(idL) '_StopPressure'];
            o_configSampVal{end+1} = num2str(sampInfo(idL, 2));
            o_configSampName{end+1} = ['CONFIG_SAMPLE_' phaseName '_' sensorName '_' num2str(idL) '_DepthInterval'];
            o_configSampVal{end+1} = num2str(sampInfo(idL, 3));
            o_configSampName{end+1} = ['CONFIG_SAMPLE_' phaseName '_' sensorName '_' num2str(idL) '_NumberOfSamples'];
            o_configSampVal{end+1} = num2str(sampInfo(idL, 4));
         end
      elseif (strcmp(sensorName, 'CTD'))
         [~, sortId] = sort(sampInfo(:, 1));
         sampInfo = sampInfo(sortId, :);
         o_configSampName{end+1} = ['CONFIG_PROFILE_' phaseName '_' sensorName '_NumberOfZones'];
         o_configSampVal{end+1} = num2str(size(sampInfo, 1));
         for idL = 1:size(sampInfo, 1)
            o_configSampName{end+1} = ['CONFIG_PROFILE_' phaseName '_' sensorName '_' num2str(idL) '_StartPressure'];
            o_configSampVal{end+1} = num2str(sampInfo(idL, 1));
            o_configSampName{end+1} = ['CONFIG_PROFILE_' phaseName '_' sensorName '_' num2str(idL) '_StopPressure'];
            o_configSampVal{end+1} = num2str(sampInfo(idL, 2));
            o_configSampName{end+1} = ['CONFIG_PROFILE_' phaseName '_' sensorName '_' num2str(idL) '_BinSize'];
            o_configSampVal{end+1} = num2str(sampInfo(idL, 3));
            o_configSampName{end+1} = ['CONFIG_PROFILE_' phaseName '_' sensorName '_' num2str(idL) '_SampleRate'];
            o_configSampVal{end+1} = num2str(sampInfo(idL, 4));
         end
      end
   end
end

return;