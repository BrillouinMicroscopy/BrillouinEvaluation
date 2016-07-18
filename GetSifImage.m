function [ newdata, X, Y ] = GetSifImage(FileName, frame)
%GetSifImage imports the data from an .sif file
%   The function imports and reshapes the .sif image 'FileName'
%   frame: frame-number to import
%
%   output:
%   newdata: matrix with image-data
%   X: x-resolution of the image
%   Y: y-resolution of the image

rc=atsif_setfileaccessmode(0);
rc=atsif_readfromfile(FileName);
if (rc == 22002)
  signal=0;
  [~,present]=atsif_isdatasourcepresent(signal);
  if present
    [~,no_frames]=atsif_getnumberframes(signal);
    if (no_frames > 0)
        [~,size]=atsif_getframesize(signal);
        [~,left,bottom,right,top,hBin,vBin]=atsif_getsubimageinfo(signal,0);
        [~,data]=atsif_getframe(signal,frame,size);
        [~,pattern]=atsif_getpropertyvalue(signal,'ReadPattern');
        if(pattern == '0')
           error('data in sif-file is not found as "source"');
        elseif(pattern == '4')
           X = ((right - left)+1)/hBin;
           Y = ((top-bottom)+1)/vBin;
           newdata=reshape(data,X,Y);
        end
    end    
  end
  atsif_closefile;
else
  disp('Could not load file.  ERROR - ');
  disp(rc);
end
end

