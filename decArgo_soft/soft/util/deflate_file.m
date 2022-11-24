% ------------------------------------------------------------------------------
% Check the deflate levels of NetCDF 4.
%
% SYNTAX :
%  deflate_file
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2016 - RNU - creation
% ------------------------------------------------------------------------------
function deflate_file

% input directory
INPUT_DIR_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEST_DEFLATE\IN\';

% output directory
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEST_DEFLATE\OUT\';

% deflate levels
DEFLATE_LEVELS = 0:9;

% number of output type formats to manage
NB_FORMAT_TYPE = 2;

% shuffle flag
SHUFFLE_FLAG = true;


if ~(exist(INPUT_DIR_NAME, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', INPUT_DIR_NAME);
   return;
end
if (exist(OUTPUT_DIR_NAME, 'dir') == 7)
   fprintf('INFO: Cleaning directory: %s\n', OUTPUT_DIR_NAME);
   rmdir(OUTPUT_DIR_NAME, 's');
end
mkdir(OUTPUT_DIR_NAME);

dirFiles = dir([INPUT_DIR_NAME '/*.nc']);
for idFile = 1:length(dirFiles)
   fileName = dirFiles(idFile).name;
   filePathNameIn = [INPUT_DIR_NAME '/' fileName];
   
   % read test
   tic;
   fCdf = netcdf.open(filePathNameIn, 'NC_NOWRITE');
   [nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(fCdf);
   for idVar = 0:nbVars-1
      data = netcdf.getVar(fCdf, idVar);
      clear('data');
   end
   netcdf.close(fCdf);
   readTime = toc;
   
   % read and save test
   tic;
   fCdf = netcdf.open(filePathNameIn, 'NC_WRITE');
   [nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(fCdf);
   for idVar = 0:nbVars-1
      data = netcdf.getVar(fCdf, idVar);
      if (~isempty(data))
         netcdf.putVar(fCdf, idVar, data);
      end
      clear('data');
   end
   netcdf.close(fCdf);
   readSaveTime = toc;

   fileSizeOri = dirFiles(idFile).bytes;
   fprintf('Input file: %s Size: %d (bytes) Read test time: %.1f (sec) Read/save test time: %.1f (sec)\n', ...
      fileName, ...
      dirFiles(idFile).bytes, ...
      readTime, readSaveTime);
   
   for idMode = 1:NB_FORMAT_TYPE
      for idDL = 1:length(DEFLATE_LEVELS)
         
         % convert the file
         if (idMode == 1)
            mode = netcdf.getConstant('NETCDF4');
            mode = bitor(mode, netcdf.getConstant('CLASSIC_MODEL'));
            outputDirNamePart = ['/NETCDF4_CLASSIC_MODEL_DEFLATE_LEVEL_' num2str(DEFLATE_LEVELS(idDL)) '/'];
         else
            mode = netcdf.getConstant('NETCDF4');
            outputDirNamePart = ['/NETCDF4_DEFLATE_LEVEL_' num2str(DEFLATE_LEVELS(idDL)) '/'];
         end
         outputDirName = [OUTPUT_DIR_NAME outputDirNamePart];
         mkdir(outputDirName);
         filePathNameOut = [outputDirName '/' fileName];
         
         tic;
         fCdfIn = netcdf.open(filePathNameIn, 'NC_NOWRITE');
         fCdfOut = netcdf.create(filePathNameOut, mode);
         
         [nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(fCdfIn);
         
         for idDim = 0:nbDims-1
            [dimname, dimlen] = netcdf.inqDim(fCdfIn, idDim);
            netcdf.defDim(fCdfOut, dimname, dimlen);
         end
         
         for idVarIn = 0:nbVars-1
            [varname, xtype, dimids, natts] = netcdf.inqVar(fCdfIn, idVarIn);
            netcdf.defVar(fCdfOut, varname, xtype, dimids);
            idVarOut = netcdf.inqVarID(fCdfOut, varname);
            netcdf.defVarDeflate(fCdfOut, idVarOut, SHUFFLE_FLAG, true, DEFLATE_LEVELS(idDL));
            for idAtt = 0:natts-1
               attName = netcdf.inqAttName(fCdfIn, idVarIn, idAtt);
               netcdf.copyAtt(fCdfIn, idVarIn, attName, fCdfOut, idVarOut)
            end
         end
         
         for idGAtt = 0:nbGAtts-1
            attName = netcdf.inqAttName(fCdfIn, netcdf.getConstant('NC_GLOBAL'), idGAtt);
            netcdf.copyAtt(fCdfOut, netcdf.getConstant('NC_GLOBAL'), attName, fCdfOut, netcdf.getConstant('NC_GLOBAL'))
         end
         
         netcdf.endDef(fCdfOut);
         
         for idVarIn = 0:nbVars-1
            [varname, xtype, dimids, natts] = netcdf.inqVar(fCdfIn, idVarIn);
            idVarOut = netcdf.inqVarID(fCdfOut, varname);
            data = netcdf.getVar(fCdfIn, idVarIn);
            if (~isempty(data))
               netcdf.putVar(fCdfOut, idVarOut, data);
            end
         end
         
         netcdf.close(fCdfOut);
         netcdf.close(fCdfIn);
         
         conversionTime = toc;
         
         % read test
         tic;
         fCdf = netcdf.open(filePathNameOut, 'NC_NOWRITE');
         [nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(fCdf);
         for idVar = 0:nbVars-1
            data = netcdf.getVar(fCdf, idVar);
            clear('data');
         end
         netcdf.close(fCdf);
         readTime = toc;
         
         % read and save test
         tic;
         fCdf = netcdf.open(filePathNameOut, 'NC_WRITE');
         [nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(fCdf);
         for idVar = 0:nbVars-1
            data = netcdf.getVar(fCdf, idVar);
            if (~isempty(data))
               netcdf.putVar(fCdf, idVar, data);
            end
            clear('data');
         end
         netcdf.close(fCdf);
         readSaveTime = toc;
         
         infoFile = dir([outputDirName '/' fileName]);
         
         ratio = fileSizeOri/infoFile(1).bytes;
         ratioComment = 'times smaller';
         if (ratio < 1)
            ratio = 1/ratio;
            ratioComment = 'times bigger';
         end
         fprintf('Output file: %s Size: %d (bytes) (%.1f %s) Conversion time: %.1f (sec) Read test time: %.1f (sec) Read/save test time: %.1f (sec)\n', ...
            [outputDirNamePart fileName], ...
            infoFile(1).bytes, ratio, ratioComment, ...
            conversionTime, readTime, readSaveTime);
      end
   end
end

return;
