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
for idPhase = 1:length(phaseNames)
   phaseName = phaseNames{idPhase};
   
   sampTypes = fieldnames(a_sampleConfData.(phaseName));
   for idSampType = 1:length(sampTypes)
      sampType = sampTypes{idSampType};

      sensorNames = fieldnames(a_sampleConfData.(phaseName).(sampType));
      for idSensor = 1:length(sensorNames)
         sensorName = sensorNames{idSensor};
         sampInfo = a_sampleConfData.(phaseName).(sampType).(sensorName);
         
         if (strcmp(sampType, 'SAMPLE'))
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
         elseif (strcmp(sampType, 'PROFILE'))
            [~, sortId] = sort(sampInfo(:, 1));
            sampInfo = sampInfo(sortId, :);
            o_configSampName{end+1} = ['CONFIG_PROFILE_' phaseName '_' sensorName '_NumberOfZones'];
            o_configSampVal{end+1} = num2str(size(sampInfo, 1));
            if (~strcmp(sensorName, 'PH'))
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
            else
               for idL = 1:size(sampInfo, 1)
                  o_configSampName{end+1} = ['CONFIG_PROFILE_' phaseName '_' sensorName '_' num2str(idL) '_StartPressure'];
                  o_configSampVal{end+1} = num2str(sampInfo(idL, 1));
                  o_configSampName{end+1} = ['CONFIG_PROFILE_' phaseName '_' sensorName '_' num2str(idL) '_StopPressure'];
                  o_configSampVal{end+1} = num2str(sampInfo(idL, 2));
                  o_configSampName{end+1} = ['CONFIG_PROFILE_' phaseName '_' sensorName '_' num2str(idL) '_TimeInterval'];
                  o_configSampVal{end+1} = num2str(sampInfo(idL, 3));
               end
            end
         elseif (strcmp(sampType, 'MEASURE'))
            o_configSampName{end+1} = ['CONFIG_MEASURE_' phaseName '_' sensorName '_' num2str(idL) '_NumberOfSamples'];
            o_configSampVal{end+1} = num2str(10);
            o_configSampName{end+1} = ['CONFIG_MEASURE_' phaseName '_' sensorName '_' num2str(idL) '_TimeInterval'];
            o_configSampVal{end+1} = num2str(15);
         else
            fprintf('ERROR: Unexpected sample type ''%s'' in the sample configuration file\n', sampType);
         end
      end
   end
end

return