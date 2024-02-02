% ------------------------------------------------------------------------------
% Create configuration parameter lists of decoder names and NetCDF names.
%
% SYNTAX :
%  [o_decArgoConfParamNames, o_ncConfParamNames, o_ncConfParamIds] = ...
%    create_config_param_names_ir_sbd2_302_303(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%    o_decArgoConfParamNames : internal configuration parameter names
%    o_ncConfParamNames      : NetCDF configuration parameter names
%    o_ncConfParamIds        : NetCDF configuration parameter Ids
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decArgoConfParamNames, o_ncConfParamNames, o_ncConfParamIds] = ...
   create_config_param_names_ir_sbd2_302_303(a_decoderId)

% output parameters initialization
o_decArgoConfParamNames = [];
o_ncConfParamNames = [];
o_ncConfParamIds = [];

% output NetCDF configuration parameter Ids
global g_decArgo_outputNcConfParamId;

% output NetCDF configuration parameter labels
global g_decArgo_outputNcConfParamLabel;

% current float WMO number
global g_decArgo_floatNum;

% max index for misc configuration parameters (CONFIG_PX)
global g_decArgo_configPxMaxT;
global g_decArgo_configPxMaxS;
global g_decArgo_configPxMaxP;
global g_decArgo_configPxMaxI;
global g_decArgo_configPxMaxK;


% information specific to each decoder
switch (a_decoderId)

   case {302}

      % sensor names
      sensor = [ ...
         {'CTD'}; ...
         {'Optode'}; ...
         {''}; ...
         {''}; ...
         {'Flntu'} ...
         ];

      % sensor list numbers
      sensorListNum = [0 1 4];
      sensorListNum2 = [0 1 4];

   case {303}

      % sensor names
      sensor = [ ...
         {'CTD'}; ...
         {'Optode'}; ...
         {''}; ...
         {''}; ...
         {'Flntu'}; ...
         {''}; ...
         {''}; ...
         {'Cyc'}; ...
         {'Stm'} ...
         ];

      % sensor list numbers
      sensorListNum = [0 1 4 7 8];
      sensorListNum2 = [0 1 4 8 9];

   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet for specific information for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

% create configuration names for decoder and associated one for NetCDF
decConfNames = [];
ncConfNames = [];
ncConfIds = [];
excluded = [219, 220, 223, 224, 225];
for id = 0:27
   if (~ismember(200+id, excluded))
      decConfNames{end+1} = sprintf('CONFIG_PT_%d', id);
      idParamName = find(g_decArgo_outputNcConfParamId == 200+id);
      ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
      ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
   end
end
for id = 0:2
   decConfNames{end+1} = sprintf('CONFIG_PM_%d', id);
   idParamName = find(g_decArgo_outputNcConfParamId == 300+id);
   ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
   ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
end
for id = 3:7
   for idP = 0
      decConfNames{end+1} = sprintf('CONFIG_PM_%d', id+idP*5);
      idParamName = find(g_decArgo_outputNcConfParamId == 300+id);
      [paramName] = g_decArgo_outputNcConfParamLabel{idParamName};
      ncConfNames{end+1} = paramName;
      ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
   end
end
for id = 0:2
   decConfNames{end+1} = sprintf('CONFIG_PV_%d', id);
   idParamName = find(g_decArgo_outputNcConfParamId == 400+id);
   ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
   ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
end
for id = 0:3
   for idZ = 1:5
      decConfNames{end+1} = sprintf('CONFIG_PV_%d', id+3+(idZ-1)*4);
      idParamName = find(g_decArgo_outputNcConfParamId == 400+3+id);
      [paramName] = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
         [{'<D>'} {num2str(idZ)}]);
      ncConfNames{end+1} = paramName;
      ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
   end
end
decConfNames{end+1} = 'CONFIG_PV_03';
idParamName = find(g_decArgo_outputNcConfParamId == 407);
ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
excluded = [507];
for idS = sensorListNum
   for idZ = 1:5
      for id = 0:8
         if (~ismember(500+id, excluded))
            offset = 0;
            if (ismember(sensor{idS+1}, [{'Cyc'} {'Stm'}]))
               offset = 1000;
            end
            decConfNames{end+1} = sprintf('CONFIG_PC_%d_0_%d', idS, id+(idZ-1)*9);
            idParamName = find(g_decArgo_outputNcConfParamId == 500+id+offset);
            paramName = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
               [{'<short_sensor_name>'} {sensor{idS+1}} {'<N>'} {num2str(idZ)}]);
            ncConfNames{end+1} = paramName;
            ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
         end
      end
   end
   for idZ = 1:4
      offset = 0;
      if (ismember(sensor{idS+1}, [{'Cyc'} {'Stm'}]))
         offset = 1000;
      end
      decConfNames{end+1} = sprintf('CONFIG_PC_%d_0_%d', idS, 45+(idZ-1));
      idParamName = find(g_decArgo_outputNcConfParamId == 500+9+offset);
      paramName = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
         [{'<short_sensor_name>'} {sensor{idS+1}} ...
         {'<N>'} {num2str(idZ)} ...
         {'<N+1>'} {num2str(idZ+1)}]);
      ncConfNames{end+1} = paramName;
      ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
   end
end
for idS = sensorListNum
   switch idS
      case 0
         lastId = 15;
         firstId = 600;
         excluded = [603 611 612];
      case 1
         lastId = 10;
         firstId = 616;
         excluded = [619 622 623];
      case 4
         lastId = 12;
         firstId = 627;
         excluded = [630 635:638];
      case 7
         lastId = 12;
         firstId = 640;
         excluded = [643 647:650];
      case 8
         lastId = 12;
         firstId = 653;
         excluded = [656 660:663];
   end
   for id = 0:lastId
      if (~ismember(firstId+id, excluded))
         decConfNames{end+1} = sprintf('CONFIG_PC_%d_1_%d', idS, id);
         if (id <= 2)
            offset = 0;
            if (ismember(sensor{idS+1}, [{'Cyc'} {'Stm'}]))
               offset = 1000;
            end
            idParamName = find(g_decArgo_outputNcConfParamId == 600+id+offset);
            paramName = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
               [{'<short_sensor_name>'} {sensor{idS+1}}]);
         else
            idParamName = find(g_decArgo_outputNcConfParamId == firstId+id);
            paramName = g_decArgo_outputNcConfParamLabel{idParamName};
         end
         ncConfNames{end+1} = paramName;
         ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
      end
   end
end
for idT = 0:g_decArgo_configPxMaxT
   for idS = 0:g_decArgo_configPxMaxS
      for idP = 0:g_decArgo_configPxMaxP
         for idI = 0:g_decArgo_configPxMaxI
            for idK = 0:g_decArgo_configPxMaxK
               if (idS < 10)
                  paramNum = 100000 + idK + idI*10 + idP*100 + idS*1000 + idT*10000;
               else
                  paramNum = 1000000 + idK + idI*10 + idP*100 + idS*1000 + idT*100000;
               end
               idParamName = find(g_decArgo_outputNcConfParamId == paramNum);
               if (~isempty(idParamName))
                  decConfNames{end+1} = sprintf('CONFIG_PX_%d_%d_%d_%d_%d', idT, idS, idP, idI, idK);
                  ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
                  ncConfIds = [ncConfIds g_decArgo_outputNcConfParamId(idParamName)];
               end
            end
         end
      end
   end
end

% output for check
% for id = 1:length(decConfNames)
%    fprintf('%s;%s\n', decConfNames{id}, ncConfNames{id});
% end

% update output parameters
o_decArgoConfParamNames = decConfNames;
o_ncConfParamNames = ncConfNames;
o_ncConfParamIds = ncConfIds;

return
