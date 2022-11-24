% ------------------------------------------------------------------------------
% Update the N_HISTORY dimension of a trajectory file.
%
% SYNTAX :
%  [o_ok] = update_n_history_dim_in_traj_file(a_trajFileName, a_nbStepToAdd)
%
% INPUT PARAMETERS :
%   a_trajFileName : trajectory file path name
%   a_nbStepToAdd  : N_HISTORY dimension increasing number
%
% OUTPUT PARAMETERS :
%   o_ok : ok flag (1 if in the update succeeded, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/05/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = update_n_history_dim_in_traj_file(a_trajFileName, a_nbStepToAdd)

% output parameters initialization
o_ok = 0;


% directory to store temporary files
[filePath, fileName, fileExtension] = fileparts(a_trajFileName);
DIR_TMP_FILE = [filePath '/tmp/'];

% delete the temp directory
remove_directory(DIR_TMP_FILE);

% create the temp directory
mkdir(DIR_TMP_FILE);

% make a copy of the file in the temp directory
trajFileName = [DIR_TMP_FILE '/' fileName fileExtension];
tmpTrajFileName = [DIR_TMP_FILE '/' fileName '_tmp' fileExtension];
copy_file(a_trajFileName, tmpTrajFileName);

% retrieve the file schema
outputFileSchema = ncinfo(tmpTrajFileName);

% retrieve the N_HISTORY dimension length
idF = find(strcmp([{outputFileSchema.Dimensions.Name}], 'N_HISTORY') == 1, 1);
nHistory = outputFileSchema.Dimensions(idF).Length;

% update the file schema with the correct N_HISTORY dimension
[outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
   'N_HISTORY', nHistory+a_nbStepToAdd);

% create updated file
ncwriteschema(trajFileName, outputFileSchema);

% copy data in updated file
for idVar = 1:length(outputFileSchema.Variables)
   varData = ncread(tmpTrajFileName, outputFileSchema.Variables(idVar).Name);
   if (~isempty(varData))
      ncwrite(trajFileName, outputFileSchema.Variables(idVar).Name, varData);
   end
end

% update input file
move_file(trajFileName, a_trajFileName);

% delete the temp directory
remove_directory(DIR_TMP_FILE);

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Modify the value of a dimension in a NetCDF schema.
%
% SYNTAX :
%  [o_outputSchema] = update_dim_in_nc_schema(a_inputSchema, ...
%    a_dimName, a_dimVal)
%
% INPUT PARAMETERS :
%   a_inputSchema  : input NetCDF schema
%   a_dimName      : dimension name
%   a_dimVal       : dimension value
%
% OUTPUT PARAMETERS :
%   o_outputSchema  : output NetCDF schema
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/09/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputSchema] = update_dim_in_nc_schema(a_inputSchema, ...
   a_dimName, a_dimVal)

% output parameters initialization
o_outputSchema = [];

% update the dimension
idDim = find(strcmp(a_dimName, {a_inputSchema.Dimensions.Name}) == 1, 1);

if (~isempty(idDim))
   a_inputSchema.Dimensions(idDim).Length = a_dimVal;
   
   % update the dimensions of the variables
   for idVar = 1:length(a_inputSchema.Variables)
      var = a_inputSchema.Variables(idVar);
      idDims = find(strcmp(a_dimName, {var.Dimensions.Name}) == 1);
      a_inputSchema.Variables(idVar).Size(idDims) = a_dimVal;
      for idDim = 1:length(idDims)
         a_inputSchema.Variables(idVar).Dimensions(idDims(idDim)).Length = a_dimVal;
      end
   end
end

o_outputSchema = a_inputSchema;

return
