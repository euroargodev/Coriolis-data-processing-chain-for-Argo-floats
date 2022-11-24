% ------------------------------------------------------------------------------
% Create configuration parameter lists of decoder names and NetCDF names.
%
% SYNTAX :
%  [o_decArgoConfParamNames, o_ncConfParamNames] = create_config_param_names_ir_sbd2_301
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%    o_decArgoConfParamNames : internal configuration parameter names
%    o_ncConfParamNames      : NetCDF configuration parameter names
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decArgoConfParamNames, o_ncConfParamNames] = create_config_param_names_ir_sbd2_301

% output parameters initialization
o_decArgoConfParamNames = [];
o_ncConfParamNames = [];

% output NetCDF configuration parameter Ids
global g_decArgo_outputNcConfParamId;

% output NetCDF configuration parameter labels
global g_decArgo_outputNcConfParamLabel;


% sensor names
sensor = [ ...
   {'CTD'}; ...
   {'Optode'}; ...
   {''}; ...
   {''}; ...
   {'Flbb'} ...
   ];

% create configuration names for decoder and associated one for NetCDF
decConfNames = [];
ncConfNames = [];
excluded = [219, 220, 223, 224, 225];
for id = 0:27
   if (~ismember(200+id, excluded))
      decConfNames{end+1} = sprintf('CONFIG_PT_%d', id);
      idParamName = find(g_decArgo_outputNcConfParamId == 200+id);
      ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
   end
end
for id = 0:2
   decConfNames{end+1} = sprintf('CONFIG_PM_%d', id);
   idParamName = find(g_decArgo_outputNcConfParamId == 300+id);
   ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
end
for id = 3:7
   for idP = 0:9
      decConfNames{end+1} = sprintf('CONFIG_PM_%d', id+idP*5);
      idParamName = find(g_decArgo_outputNcConfParamId == 300+id);
      [paramName] = g_decArgo_outputNcConfParamLabel{idParamName};
      ncConfNames{end+1} = paramName;
   end
end
for id = 0:2
   decConfNames{end+1} = sprintf('CONFIG_PV_%d', id);
   idParamName = find(g_decArgo_outputNcConfParamId == 400+id);
   ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
end
for id = 0:3
   for idZ = 1:5
      decConfNames{end+1} = sprintf('CONFIG_PV_%d', id+3+(idZ-1)*4);
      idParamName = find(g_decArgo_outputNcConfParamId == 400+3+id);
      [paramName] = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
         [{'<D>'} {num2str(idZ)}]);
      ncConfNames{end+1} = paramName;
   end
end
decConfNames{end+1} = 'CONFIG_PV_03';
idParamName = find(g_decArgo_outputNcConfParamId == 407);
ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
excluded = [507];
for idS = [0 1 4]
   for id = 0:4
      decConfNames{end+1} = sprintf('CONFIG_PC_%d_0_%d', idS, id);
      idParamName = find(g_decArgo_outputNcConfParamId == 500+id);
      [paramName] = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
         [{'<short_sensor_name>'} {sensor{idS+1}}]);
      ncConfNames{end+1} = paramName;
   end
   for idZ = 1:5
      for id = 5:8
         if (~ismember(500+id, excluded))
            decConfNames{end+1} = sprintf('CONFIG_PC_%d_0_%d', idS, id+(idZ-1)*5);
            idParamName = find(g_decArgo_outputNcConfParamId == 500+id);
            [paramName] = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
               [{'<short_sensor_name>'} {sensor{idS+1}} {'<N>'} {num2str(idZ)}]);
            ncConfNames{end+1} = paramName;
         end
      end
   end
   for idZ = 1:4
      decConfNames{end+1} = sprintf('CONFIG_PC_%d_0_%d', idS, 9+(idZ-1)*5);
      idParamName = find(g_decArgo_outputNcConfParamId == 509);
      [paramName] = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
         [{'<short_sensor_name>'} {sensor{idS+1}} ...
         {'<N>'} {num2str(idZ)} ...
         {'<N+1>'} {num2str(idZ+1)}]);
      ncConfNames{end+1} = paramName;
   end
end
for idS = [0 1 4]
   switch idS
      case 0
         lastId = 12;
         firstId = 600;
         excluded = [610, 611];
      case 1
         lastId = 8;
         firstId = 613;
         excluded = [];
      case 4
         lastId = 6;
         firstId = 671;
         excluded = [];
   end
   for id = 0:lastId
      if (~ismember(firstId+id, excluded))
         decConfNames{end+1} = sprintf('CONFIG_PC_%d_1_%d', idS, id);
         if (id <= 2)
            idParamName = find(g_decArgo_outputNcConfParamId == 600+id);
            [paramName] = create_param_name_ir_rudics_sbd2(g_decArgo_outputNcConfParamLabel{idParamName}, ...
               [{'<short_sensor_name>'} {sensor{idS+1}}]);
         else
            idParamName = find(g_decArgo_outputNcConfParamId == firstId+id);
            [paramName] = g_decArgo_outputNcConfParamLabel{idParamName};
         end
         ncConfNames{end+1} = paramName;
      end
   end
end
for idT = 0:3
   for idS = [0 1 7]
      for idP = 0:1
         for idI = 0:3
            for idK = 0:8
               paramNum = 100000 + idK + idI*10 + idP*100 + idS*1000 + idT*10000;
               idParamName = find(g_decArgo_outputNcConfParamId == paramNum);
               if (~isempty(idParamName))
                  decConfNames{end+1} = sprintf('CONFIG_PX_%d_%d_%d_%d_%d', idT, idS, idP, idI, idK);
                  ncConfNames{end+1} = g_decArgo_outputNcConfParamLabel{idParamName};
               end
            end
         end
      end
   end
end

% % output for check
% for id = 1:length(decConfNames)
%    fprintf('%s;%s\n', decConfNames{id}, ncConfNames{id});
% end

% update output parameters
o_decArgoConfParamNames = decConfNames;
o_ncConfParamNames = ncConfNames;

return;
