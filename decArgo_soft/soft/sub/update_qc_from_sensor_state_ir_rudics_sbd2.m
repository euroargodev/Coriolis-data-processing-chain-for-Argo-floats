% ------------------------------------------------------------------------------
% Set the QC of sensor raw and derived measurements to '3' when the sensor
% status is KO.
%
% SYNTAX :
%  [o_tabProfiles, o_tabTrajNMeas] = ...
%    update_qc_from_sensor_state_ir_rudics_sbd2(a_tabProfiles, a_tabTrajNMeas)
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas] = ...
   update_qc_from_sensor_state_ir_rudics_sbd2(a_tabProfiles, a_tabTrajNMeas)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];

% global default values
global g_decArgo_qcDef;

% array to store ko sensor states
global g_decArgo_koSensorState;


if (~isempty(g_decArgo_koSensorState))

   koSensorState = unique(g_decArgo_koSensorState, 'rows');
   
   % process profile measurements
   for idProf = 1:length(a_tabProfiles)
      prof = a_tabProfiles(idProf);
      for idK = 1:size(koSensorState, 1)
         if ((prof.cycleNumber == koSensorState(idK, 1)) && ...
               (prof.profileNumber == koSensorState(idK, 2)) && ...
               (prof.sensorNumber == koSensorState(idK, 3)))
            
            dataQc = prof.dataQc;
            if (isempty(dataQc))
               dataQc = ones(size(prof.data))*g_decArgo_qcDef;
            end
            
            if (isempty(prof.paramNumberWithSubLevels))
               
               % none of the profile parameters has sublevels
            
               parameterList = prof.paramList;
               for idParam = 1:length(parameterList)
                  
                  profParam = parameterList(idParam);
                  if (strcmp(profParam.name, 'PRES') && (prof.sensorNumber ~= 0))
                     % PRES_QC is not modified (except if it is the CTD sensor
                     continue;
                  end
                  
                  param = get_netcdf_param_attributes(profParam.name);
                  paramData = prof.data(:, idParam);
                  paramDataQc = ones(length(paramData), 1)*g_decArgo_qcDef;
                  paramDataQc(find(paramData ~= param.fillValue)) = 3;
                  dataQc(:, idParam) = paramDataQc;
               end
            else
               
               % some profile parameters have sublevels
            
               parameterList = prof.paramList;
               for idParam = 1:length(parameterList)
                  
                  profParam = parameterList(idParam);
                  if (strcmp(profParam.name, 'PRES') && (prof.sensorNumber ~= 0))
                     % PRES_QC is not modified (except if it is the CTD sensor
                     continue;
                  end
                  
                  % retrieve the column(s) associated with the parameter data
                  idF = find(prof.paramNumberWithSubLevels < idParam);
                  if (isempty(idF))
                     firstCol = idParam;
                  else
                     firstCol = idParam + sum(prof.paramNumberOfSubLevels(idF)) - length(idF);
                  end
                  
                  idF = find(prof.paramNumberWithSubLevels == idParam);
                  if (isempty(idF))
                     lastCol = firstCol;
                  else
                     lastCol = firstCol + prof.paramNumberOfSubLevels(idF) - 1;
                  end
                  
                  param = get_netcdf_param_attributes(profParam.name);
                  paramData = prof.data(:, firstCol:lastCol);
                  paramDataQc = ones(size(paramData))*g_decArgo_qcDef;
                  paramDataQc(find(paramData ~= param.fillValue)) = 3;
                  dataQc(:, firstCol:lastCol) = paramDataQc;
               end
            end
               
            a_tabProfiles(idProf).dataQc = dataQc;
         end
      end
   end
   
   % process N_MEASUREMENT measurements
   for idNmeas = 1:length(a_tabTrajNMeas)
      nMeas = a_tabTrajNMeas(idNmeas);
      for idK = 1:size(koSensorState, 1)
         if ((nMeas.cycleNumber == koSensorState(idK, 1)) && ...
               (nMeas.profileNumber == koSensorState(idK, 2)))
            
            tabMeas = nMeas.tabMeas;
            if (~isempty(tabMeas))
               sensorList = [tabMeas.sensorNumber];
               idM = find(sensorList == koSensorState(idK, 3));
               for id = 1:length(idM)
                  tabMeasOne = tabMeas(idM(id));
                  
                  paramDataQc = tabMeasOne.paramDataQc;
                  if (isempty(paramDataQc))
                     paramDataQc = ones(size(tabMeasOne.paramData))*g_decArgo_qcDef;
                  end
                  
                  if (isempty(tabMeasOne.paramNumberWithSubLevels))
                     
                     % none of the profile parameters has sublevels
                     
                     parameterList = tabMeasOne.paramList;
                     for idParam = 1:length(parameterList)
                        
                        measParam = parameterList(idParam);
                        if (strcmp(measParam.name, 'PRES') && (tabMeasOne.sensorNumber ~= 0))
                           % PRES_QC is not modified (except if it is the CTD
                           % sensor)
                           continue;
                        end
                        
                        param = get_netcdf_param_attributes(measParam.name);
                        measData = tabMeasOne.paramData(:, idParam);
                        measDataQc = ones(length(measData), 1)*g_decArgo_qcDef;
                        measDataQc(find(measData ~= param.fillValue)) = 3;
                        paramDataQc(:, idParam) = measDataQc;
                     end
                  else
                     
                     % some profile parameters have sublevels
                     
                     parameterList = tabMeasOne.paramList;
                     for idParam = 1:length(parameterList)
                        
                        measParam = parameterList(idParam);
                        if (strcmp(measParam.name, 'PRES') && (tabMeasOne.sensorNumber ~= 0))
                           % PRES_QC is not modified (except if it is the CTD
                           % sensor)
                           continue;
                        end
                        
                        % retrieve the column(s) associated with the parameter data
                        idF = find(tabMeasOne.paramNumberWithSubLevels < idParam);
                        if (isempty(idF))
                           firstCol = idParam;
                        else
                           firstCol = idParam + sum(tabMeasOne.paramNumberOfSubLevels(idF)) - length(idF);
                        end
                        
                        idF = find(tabMeasOne.paramNumberWithSubLevels == idParam);
                        if (isempty(idF))
                           lastCol = firstCol;
                        else
                           lastCol = firstCol + tabMeasOne.paramNumberOfSubLevels(idF) - 1;
                        end
                        
                        param = get_netcdf_param_attributes(measParam.name);
                        measData = tabMeasOne.paramData(:, firstCol:lastCol);
                        measDataQc = ones(size(measData))*g_decArgo_qcDef;
                        measDataQc(find(measData ~= param.fillValue)) = 3;
                        paramDataQc(:, firstCol:lastCol) = measDataQc;
                     end
                  end
                  
                  tabMeas(idM(id)).paramDataQc = paramDataQc;
               end
               a_tabTrajNMeas(idNmeas).tabMeas = tabMeas;
            end
         end
      end
   end
   
end

% update output parameters
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;

return;
