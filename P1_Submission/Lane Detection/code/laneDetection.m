clear all;
close all;
clc;
video = VideoReader('project_video.mp4');
output = VideoWriter('project_output','MPEG-4');
output.FrameRate = video.FrameRate;
open(output);
x = [350,550,770,1090];
y = [680,500,505,665];
i = 0;
direction = 'Straight';
while hasFrame(video)    
  cla reset;
  frame = readFrame(video);  
  maskedRGBImage = createMask(frame);
  I2  = rgb2gray(maskedRGBImage);
  BW = edge(I2, 'sobel');
  c = [520 762 1250 275];
  r = [464 464 720 720];
  mask = roipoly(frame,c,r);
  roi = zeros(720,1280);
  for i = 1 : 1080
   for j = 1 : 720
    if(mask(j,i) == 1)  
      roi(j,i) = BW(j,i);
    end 
   end
  end
  [H,T,R] = hough(roi);
  P = houghpeaks(H,4);
  lines = houghlines(roi,T,R,P,'FillGap',100,'MinLength',10);
  for k = 1:length(lines)   
    xy(:,:,k) = [lines(k).point1; lines(k).point2];
    slope(k) = (xy(1,2,k) - xy(2,2,k))/(xy(1,1,k) - xy(2,1,k));
  end
  [x1,x2,x3,x4,y1,y2,y3,y4,m,c] = twolines(slope,xy);
  if (~isnan(x1) && abs(x(1)-x1) < 50) 
      x(1) = x1; 
  end
  if (~isnan(x2) && abs(x(2)-x2) < 50)
      x(2) = x2; 
  end
  if (~isnan(x3) && abs(x(3)-x3) < 50) 
      x(3) = x3; 
  end
  if (~isnan(x4) && abs(x(4)-x4) < 50) 
      x(4) = x4; 
  end
  y(1) = y1; 
  y(2) = y2; 
  y(3) = y3; 
  y(4) = y4;
  prevDir = direction;
  if(~isnan(x1) && ~isnan(x2) && ...
      ~isnan(x3) && ~isnan(x4))      
    [direction,center] = predictTurn(m,c);
    if(~strcmp(direction,prevDir) && ...
      ((center>633 && center<640) || ...
       (center>643 &&center<650)))
       direction = prevDir;
    elseif(~strcmp(direction,prevDir) && ...
       ((strcmp(prevDir,'Right') && ...
        strcmp(direction,'Left')) || ...
       (strcmp(prevDir,'Left') && ...
        strcmp(direction,'Right'))))
       direction = prevDir;     
    end    
  end
  imshow(frame); hold on;
  h = fill([x(1),x(2),x(3),x(4),x(1)],[y(1),y(2),y(3),y(4),y(1)],'r');
  text(580,100,direction,'FontSize',24);
  set (h,'facealpha',0.20);
  plotted = getframe(gcf);
  writeVideo(output,plotted);
  i = i + 1;
  impixelinfo(gcf);
  hold off;
end
close(output);

function maskedRGBImage = createMask(RGB) 
  I = rgb2hsv(RGB);
  channel1Min = 0.8;
  channel1Max = 0.2;
  channel2Min1 = 0.000;
  channel2Max1 = 0.090;
  channel2Min2 = 0.400;
  channel2Max2 = 1.000;
  channel3Min = 0.8;
  channel3Max = 1.000;
  BW = ( (I(:,:,1) >= channel1Min) | (I(:,:,1) <= channel1Max) ) & ...
    ((I(:,:,2) >= channel2Min1 ) & (I(:,:,2) <= channel2Max1)|...
    (I(:,:,2) >= channel2Min2 ) & (I(:,:,2) <= channel2Max2)) & ...
    (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);
  maskedRGBImage = RGB;
  maskedRGBImage(repmat(~BW,[1 1 3])) = 0;
end

function [x1,x2,x3,x4,y1,y2,y3,y4,m,c] = twolines(slope, xy) 
pos = 0;
neg = 0;
x1 = 0; y1 = 0;
x2 = 0; y2 = 0;
x3 = 0; y3 = 0;
x4 = 0; y4 = 0;
 for n = 1 : length(slope) 
  if(slope(n)<0)  
    x1 = x1 + xy(1,1,n);
    x2 = x2 + xy(2,1,n);
    y1 = y1 + xy(1,2,n);
    y2 = y2 + xy(2,2,n);
    neg = neg + 1;
  else
    x3 = x3 + xy(1,1,n);
    x4 = x4 + xy(2,1,n);
    y3 = y3 + xy(1,2,n);
    y4 = y4 + xy(2,2,n);
    pos = pos + 1;
  end
 end
 x1 = x1/neg;
 x2 = x2/neg;
 x3 = x3/pos;
 x4 = x4/pos;
 y1 = y1/neg;
 y2 = y2/neg;
 y3 = y3/pos;
 y4 = y4/pos;
 m(1) = (y2 - y1)/(x2 - x1);
 m(2) = (y4 - y3)/(x4 - x3);
 c(1) = y1 - (m(1)*x1);
 c(2) = y3 - (m(2)*x3);
 y1 = 680;
 y2 = 500;
 y3 = 505;
 y4 = 665;
 x1 = (y1 - c(1))/m(1);
 x2 = (y2 - c(1))/m(1);
 x3 = (y3 - c(2))/m(2);
 x4 = (y4 - c(2))/m(2);
end

function [direction,x] = predictTurn(m,c)
  x = (c(2)-c(1))/(m(1)-m(2));
  if(x<635)
    direction = 'Left';
  elseif(x>645)
    direction = 'Right'; 
  else
    direction = 'Straight';
  end  
end