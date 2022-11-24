function S=lov_netcdf_pickprod(filename,varargin)
%
%
% loads oao lovbio profile netcdf files
%
% inspired by SDS_pickprod from Heidi Dierssen, UConn
% adapted for netcdf files
% Henry Bittig, GEOMAR
% 10.10.2013
% 31.10.2016, LOV, more specific adaptations to Argo netcdf files (QC field
%             data type and option to load only specific fields)
% 10.01.2019, IOW, modified to include dimension information
%
% input:
% filename - (path &) filename of netcdf file
% loadflag - 0 or 1 to indicate to actually load the data or not (optional)
%            (relevant for large files' attribute exploration without data
%            usage)
% fnames   - cellstr of field names that are to be loaded into S; all other
%            variables are ignored (optional)
%
% usage:
% S=lov_netcdf_pickprod('test.nc');
% S=lov_netcdf_pickprod('test.nc',0);
% S=lov_netcdf_pickprod('test.nc',{'VAR1';'VAR2'});
% S=lov_netcdf_pickprod('test.nc',{'VAR1';'VAR2'},0);


%
% Script for reading in SDS hdf datafile
%  And finding the number datasets and names of datasets within
%    the file.
%INPUT:  filename = '   '
%
%OUTPUT: 2 structural arrays
% SDS_info = global attributes
% SDS_prod = dataset names numbered

clear SDS_prod SDS_info



tmp=cellfun(@isnumeric,varargin);
if any(tmp) 
   loadflag = varargin{tmp};
   varargin = varargin(~tmp); 
else
    loadflag=1;
end

if ~isempty(varargin)
    fnames=varargin{1};
    % and add '^' to mark that regexp needs to start from start of varname
    % and add '$' to mark its end
    fnames=cellfun(@(x)['^' x '$'],fnames,'uniform',0);
else
    fnames=[];
end

%% start access to the file
ncid=netcdf.open(filename,'NC_NOWRITE');
if ncid == -1;
   error('ERROR: bad ncid');
end

%% file info
[ndims,nvariables,nglobal_attr,unlimdim_id] = netcdf.inq(ncid);

Info = ''; %Descrip of all the file attributes

% get global attributes if present
[f1,f2]=fileparts(filename);
SDS_info.GLOBAL.path=f1;
SDS_info.GLOBAL.filename=f2;
if nglobal_attr>0
    i=netcdf.getConstant('NC_GLOBAL')+1; % VarID global = -1; 
    for j=1:nglobal_attr
        nameatt=netcdf.inqAttName(ncid,i-1,j-1);
        [xtype_att,attlen] = netcdf.inqAtt(ncid,i-1,nameatt);
        valueatt=netcdf.getAtt(ncid,i-1,nameatt);
        %% convert to double precision
        if xtype_att>4
            valueatt = double(valueatt);
        end
        %% convert spaces, hyphens, slashes to underscores
        %nameatt=strrep(nameatt,'_FillValue','FillValue');
        if strncmp(nameatt,'_',1), nameatt=nameatt(2:end); end
        nameatt = strrep(nameatt,' ','_');
        nameatt=strrep(nameatt,'-','_');
        nameatt=strrep(nameatt,'/','_');
        nameatt=strrep(nameatt,'.','_');
        % 
        SDS_info.GLOBAL.(nameatt)=valueatt;
    end
end

% get dimensions
if ndims>0
    for j=1:ndims
        [nameatt,attlen] = netcdf.inqDim(ncid,j-1);
        %valueatt=netcdf.getAtt(ncid,i-1,nameatt);
        %% convert spaces, hyphens, slashes to underscores
        %nameatt=strrep(nameatt,'_FillValue','FillValue');
        if strncmp(nameatt,'_',1), nameatt=nameatt(2:end); end
        nameatt = strrep(nameatt,' ','_');
        nameatt=strrep(nameatt,'-','_');
        nameatt=strrep(nameatt,'/','_');
        nameatt=strrep(nameatt,'.','_');
        % 
        SDS_info.GLOBAL.dims.(nameatt)=attlen;        
    end
end

%% get all data sets
for i = 1:nvariables;
    [name,data_type,dimids,natts]=netcdf.inqVar(ncid,i-1);
    %% convert spaces, hyphens, slashes to underscores
       name = strrep(name,' ','_');
       name=strrep(name,'-','_');
       name=strrep(name,'/','_');
       name=strrep(name,'.','_');
    %% check if data set names are limited and if so, whether current one is to load
    %if isempty(fnames) || any(strcmp(fnames,name))
    if isempty(fnames) || any(~cellfun(@isempty,regexp(name,fnames,'match')));
    %% get variable attributes value
    for j=1:natts
        nameatt=netcdf.inqAttName(ncid,i-1,j-1);
        [xtype_att,attlen] = netcdf.inqAtt(ncid,i-1,nameatt);
        valueatt=netcdf.getAtt(ncid,i-1,nameatt);
        %% convert to double precision
        if xtype_att>4
            valueatt = double(valueatt);
        end
        %% convert spaces, hyphens, slashes to underscores
        nameatt=strrep(nameatt,'_FillValue','FillValue');
        nameatt = strrep(nameatt,' ','_');
        nameatt=strrep(nameatt,'-','_');
        nameatt=strrep(nameatt,'/','_');
        nameatt=strrep(nameatt,'.','_');
        if nameatt(1)=='_', nameatt=nameatt(2:end); end
        % 
        SDS_info.(name).(nameatt)=valueatt;
    end
    %% get variable dimension names and values
    [a,b]=arrayfun(@(x)netcdf.inqDim(ncid,x),dimids,'uniform',0);
    SDS_info.(name).dimname=a;
    SDS_info.(name).dimvalue=cell2mat(b);
    if loadflag % actually load the data
    % get variable value
    SDS_info.(name).value=netcdf.getVar(ncid,i-1);
    % and replace FillValue with NaN
    if data_type>2
        try
            SDS_info.(name).value(SDS_info.(name).FillValue==SDS_info.(name).value)=NaN;
        catch me
            warning off
            SDS_info.(name).value(99999==SDS_info.(name).value)=NaN;
            SDS_info.(name).value(9.969209968386869e+36==SDS_info.(name).value)=NaN;
            %warning on
            %disp(['no FillValue available for ' name ])
        end
        try
            SDS_info.(name).value(SDS_info.(name).missing_value==SDS_info.(name).value)=NaN;
        catch me
            
        end
    end
    % and tidy up result 
    if data_type==2 & (isempty(strfind(name,'QC')) | ~isempty(strfind(name,'QCTEST'))) % flip character arrays if not QC field
        try
            SDS_info.(name).value=SDS_info.(name).value';
            SDS_info.(name).dimname=SDS_info.(name).dimname([2 1]);
            SDS_info.(name).dimvalue=SDS_info.(name).dimvalue([2 1]);
        catch me
        end

    elseif data_type<3 & isempty(strfind(name,'PROFILE')) % make double for data QC "string" fields
        SDS_info.(name).value=double(SDS_info.(name).value)-double('0');
        SDS_info.(name).value(SDS_info.(name).value==-16)=NaN; % double(' ')-double('0')=-16;
    elseif data_type>4 % make double for float, double, 
        SDS_info.(name).value=double(SDS_info.(name).value);
%{
    elseif data_type<3 % make double and sparse for QC "string" fields
        SDS_info.(name).value=sparse(double(SDS_info.(name).value));
	elseif data_type>4 % make double and sparse for float and double fields
        SDS_info.(name).value=glsparse(double(SDS_info.(name).value));
%}
    end % tidy up
    end % loadflag
    end % check field names
%{       
  %% convert to double precision
  if strcmp(class(value),'single') == 1
      value = double(value);
  end
  
  if strcmp(class(value),'struct') == 1
   %% put number place holder
     SDS_info.(name) =  i;
  else
      SDS_info.(name) =  value;
  end
    %}
end
netcdf.close(ncid);

%{
%---pick dataset
for jj=0:(ndatasets-1);
sds_index=jj;
sds_id=hdfsd('select',ncid,sds_index);
[name,rank,dimsizes,data_type,nattrs,status]=hdfsd('getinfo',sds_id);
   %% convert spaces, hyphens, slashes to underscores
      name = strrep(name,' ','_');
      name=strrep(name,'-','_');
      name=strrep(name,'/','_');
      name=strrep(name,'.','_');
SDS_prod.(name) =  jj;
end

%% end access to dataset
status = hdfsd('endaccess',sds_id);
if status == -1;
   error('ERROR: bad end access to dataset');
end

%% end access to the file
status = hdfsd('end',ncid);
if status == -1;
   error('ERROR: bad end access to file');
end
%}

S=SDS_info;

clear cb cm ax pc ratio x y plot ti top base slope intercept name value j
clear li ans i sds_id sds_index status rank nattrs ndatasets 
clear dimsizes edge nglobal_attr data_type count name bottom top
clear lat_step lon_step vrbl dellat
