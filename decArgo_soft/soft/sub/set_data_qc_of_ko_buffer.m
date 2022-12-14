% ------------------------------------------------------------------------------
% Set the QC of profile and data measurements to '3' when the decoding buffer is
% not completed.
%
% SYNTAX :
%  [o_tabProfiles, o_tabTrajNMeas] = ...
%    set_data_qc_of_ko_buffer(a_tabProfiles, a_tabTrajNMeas)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%   a_tabTrajNMeas  : input trajectory N_MEASUREMENT measurement structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles   : output profile structures
%   o_tabTrajNMeas  : output trajectory N_MEASUREMENT measurement structures
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/06/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas] = ...
   set_data_qc_of_ko_buffer(a_tabProfiles, a_tabTrajNMeas)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];

% global default values
global g_decArgo_qcDef;
global g_decArgo_qcCorrectable;


% process profile measurements
for idProf = 1:length(a_tabProfiles)
   prof = a_tabProfiles(idProf);
         
   dataQc = prof.dataQc;
   if (isempty(dataQc))
      dataQc = ones(size(prof.data, 1), length(prof.paramList))*g_decArgo_qcDef;
   end
   
   if (isempty(prof.paramNumberWithSubLevels))
      
      % none of the profile parameters has sublevels
      
      parameterList = prof.paramList;
      for idParam = 1:length(parameterList)
         profParam = parameterList(idParam);
         param = get_netcdf_param_attributes(profParam.name);
         paramData = prof.data(:, idParam);
         paramDataQc = ones(size(paramData, 1), 1)*g_decArgo_qcDef;
         paramDataQc(find(paramData ~= param.fillValue)) = g_decArgo_qcCorrectable;
         dataQc(:, idParam) = paramDataQc;
      end
   else
      
      % some profile parameters have sublevels
      
      parameterList = prof.paramList;
      for idParam = 1:length(parameterList)
         
         profParam = parameterList(idParam);
         
         % retrieve the column(s) associated with the parameter data
         [~, firstCol, lastCol] = get_param_data_index(prof, profParam.name);
         
         param = get_netcdf_param_attributes(profParam.name);
         paramData = prof.data(:, firstCol:lastCol);
         paramDataQc = ones(size(paramData, 1), 1)*g_decArgo_qcDef;
         for idL = 1:size(paramData, 1)
            if (any(paramData(idL, :) ~= param.fillValue))
               paramDataQc(idL) = g_decArgo_qcCorrectable;
            end
         end
         dataQc(:, idParam) = paramDataQc;
      end
   end
   
   a_tabProfiles(idProf).dataQc = dataQc;
end

% process N_MEASUREMENT measurements
for idNmeas = 1:length(a_tabTrajNMeas)
   
   nMeas = a_tabTrajNMeas(idNmeas);
   tabMeas = nMeas.tabMeas;
   for id = 1:length(tabMeas)
      
      tabMeasOne = tabMeas(id);
      
      paramDataQc = tabMeasOne.paramDataQc;
      if (isempty(paramDataQc))
         paramDataQc = ones(size(tabMeasOne.paramData, 1), length(tabMeasOne.paramList))*g_decArgo_qcDef;
      end
      
      if (isempty(tabMeasOne.paramNumberWithSubLevels))
         
         % none of the profile parameters has sublevels
         
         parameterList = tabMeasOne.paramList;
         for idParam = 1:length(parameterList)
            measParam = parameterList(idParam);
            param = get_netcdf_param_attributes(measParam.name);
            measData = tabMeasOne.paramData(:, idParam);
            measDataQc = ones(size(measData, 1), 1)*g_decArgo_qcDef;
            measDataQc(find(measData ~= param.fillValue)) = g_decArgo_qcCorrectable;
            paramDataQc(:, idParam) = measDataQc;
         end
      else
         
         % some profile parameters have sublevels
         
         parameterList = tabMeasOne.paramList;
         for idParam = 1:length(parameterList)
            
            measParam = parameterList(idParam);
            
            % retrieve the column(s) associated with the parameter data
            [~, firstCol, lastCol] = get_param_data_index(tabMeasOne, measParam.name);
            
            param = get_netcdf_param_attributes(measParam.name);
            measData = tabMeasOne.paramData(:, firstCol:lastCol);
            measDataQc = ones(size(measData, 1), 1)*g_decArgo_qcDef;
            for idL = 1:size(measData, 1)
               if (any(measData(idL, :) ~= param.fillValue))
                  measDataQc(idL) = g_decArgo_qcCorrectable;
               end
            end
            paramDataQc(:, idParam) = measDataQc;
         end
      end
      
      tabMeas(id).paramDataQc = paramDataQc;
   end
   a_tabTrajNMeas(idNmeas).tabMeas = tabMeas;
end

% update output parameters
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;

return
