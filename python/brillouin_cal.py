# -*- coding: utf-8 -*-
"""
Created on Thu Jul 12 14:42:38 2018 

(https://git.sthu.org/?p=persistence.git;
a=blob;f=2Dpers.ipynb;h=898a094962eee19f88fbf045f5d979fd697cd643;
hb=b210d5622c539c64875465bf873e794db9c50cfd) modified line(79-97)

@author: s1655685
"""

import h5py
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt
import cv2
from imagepers import persistence
import sys
import traceback as tr



def h5py_dataset_iterator(g, prefix=''):
    for key in g.keys():
        item = g[key]
        path = '{}/{}'.format(prefix, key)
        if isinstance(item, h5py.Dataset): # test for dataset
            yield (path, item)
            #return (path, item)
        elif isinstance(item, h5py.Group): # test for group (go down)
            yield from h5py_dataset_iterator(item, path)
            
def get_distance_corner(start,end):
    return np.sqrt((start[0]-end[0])**2+(start[1]-end[1])**2)

def get_distance_middle(m1,t1,y2,x2):
    """gets distance from connection between outer points"""
    t2=y2+(x2/m1)
    xs=(t2-t1)/(m1+(1/m1))
    #ys=-xs/m1 + t2
    ys=m1*xs + t1
    return (ys,xs,t2,np.sqrt((xs-x2)**2+((ys-y2)**2)))

test_dir = "Z:\Members\Timon\python\Brillouin\_forTimon"
#test_dir = "Z:\Members\Raimund\MeasurementData\\13_MeasurementUncertainty\\2017-11-20_UncertaintyWater\\"
p = Path(test_dir)
h5_file_list=list(p.glob('**/*.h5'))
print([x for x in p.iterdir() if x.is_dir()])
print("number of analysed files: ", len(h5_file_list))



"""defines number of expected peaks in the region of the image, which is used
for calibration"""
n_cal_peak_max = 7 
n_cal_peak_min = 4
cut_off_edge = 10
treshold_pers_div = 45

error_log=[]




save_image_folder = "Z:\Members\Timon\python\Brillouin\_forTimon\calibration_images"

counter=0
for h5_file_name in h5_file_list[:2]:
    
    q =  p / h5_file_name
    filename = q.parts[-3] +"_" + q.parts[-2] +"_"+ q.name 
    print(q.parts)
    print(filename)

    try:
        with h5py.File(q, 'r') as f:
    
            print(list(f.keys()))
            calibration_h5=f['/calibration/calibrationData/1'] #group
            print(type(calibration_h5))
            calibration = np.zeros(np.shape(calibration_h5))
            print(np.shape(calibration_h5))
            for i in range(np.size(calibration_h5,0)):
                calibration[i,:] = np.asarray(calibration_h5[i])
    
    
            calibration_sum = np.empty(calibration.shape[1:])
            for i in range(calibration.shape[0]):
                calibration_sum += calibration[i]
                
            """Apply median filter, to reduce salt and pepper noise"""
            median=cv2.medianBlur(np.uint16(calibration_sum[cut_off_edge:-cut_off_edge][cut_off_edge:-cut_off_edge]
            -np.min(calibration_sum[cut_off_edge:-cut_off_edge][cut_off_edge:-cut_off_edge])),5)

            fig1 = plt.figure(figsize=(8,8))
            ax = plt.subplot()
            plt.gray()
            ax.imshow(-(median-(np.max(median))))
            
    
            groups = persistence(median)
            treshold_pers=(np.max(calibration_sum)-np.min(calibration_sum))/treshold_pers_div
            print("treshold persistence: ", treshold_pers)
            
            """magic number 20"""
            peak_data = np.empty((30, 6))
            peak_data.fill(np.nan)
            
            print("peak_number [p_birth (y,x), bl, pers, p_death (y,x)], int_p_birth")
            for i, homclass in enumerate(groups):
                
                p_birth, bl, pers, p_death = homclass
                int_p_birth=median[p_birth[0],p_birth[1]]
                
                if pers <= treshold_pers or int_p_birth <= 1.5*treshold_pers:
                    continue

                """first peak does not die, p_death = None"""
                if i==0:
                    peak_data[i]= *p_birth, bl, pers, p_death, p_death
                    print(i+1,[*p_birth, bl, pers, p_death], int_p_birth)
                    
                else:
                    peak_data[i]= *p_birth, bl, pers, *p_death
                    print(i+1,[*p_birth, bl, pers, *p_death], int_p_birth)
                  
        
                y, x = p_birth
                ax.plot([x], [y], '.', c='b')
                ax.text(x+2, y+2, str(i+1), color='b')
                
                try:
                    y2, x2 = p_death
                    ax.plot([x2], [y2], '.', c='r')
                    ax.text(x2-5, y2-5, str(i+1), color='r')
                except:
                    continue
                
               
                
            up_l_rayleigh_yx=[np.nanmin(peak_data[:,0]), np.nanmax(peak_data[:,1])]
            
            image_size=np.shape(calibration_h5)[1:]
            up_l_corner=[0,0]
            low_r_corner=[*image_size]
            
            upper_l_peak=[np.inf,np.nan,np.nan] #[distance from corner,x,y]
            lower_r_peak=[np.inf,np.nan,np.nan] #[distance from corner,x,y]
            
            for peak_yx in peak_data[:,:2]:
                dist_up_l_peak=get_distance_corner(up_l_corner,[*peak_yx])
                dist_low_r_peak=get_distance_corner(low_r_corner,[*peak_yx])
                #print(dist_up_l_peak)
                if dist_up_l_peak < upper_l_peak[0]:
                    upper_l_peak = [dist_up_l_peak,*peak_yx]
                if dist_low_r_peak < lower_r_peak[0]:
                    lower_r_peak = [dist_low_r_peak, *peak_yx]
                    
    
            ax.plot(upper_l_peak[2], upper_l_peak[1], 'o', c='black', alpha=0.7, mfc='none', ms=15)
            ax.plot(lower_r_peak[2], lower_r_peak[1], 'o', c='black', alpha=0.7, mfc='none', ms=15)
            ax.plot([upper_l_peak[2], lower_r_peak[2]], 
                    [upper_l_peak[1], lower_r_peak[1]], c='black', alpha=0.6, ls='--', lw=0.8)
            
            #y = mx + t
            """find connnection between upper left and lower right peak"""
            m = (lower_r_peak[1]-upper_l_peak[1])/(lower_r_peak[2]-upper_l_peak[2])
            t = upper_l_peak[1] - m*upper_l_peak[2]
            x = np.linspace(0,image_size[0])
            
    
            counter=0
            cal_points = np.empty((n_cal_peak_max,4))
            cal_points.fill(np.nan)
    
            for i in range(peak_data.shape[0]):
                
                ys,xs,t2,distance_middle = get_distance_middle(m,t,*peak_data[i,:2])
                
                # change this magic treshold to some more sophisticated 
                # approach
                if distance_middle < 30:
                    print("saving", counter, i, ys, xs, *peak_data[i,:2], distance_middle)
    
                    cal_points[counter] = i,*peak_data[i,:2],distance_middle 
    
                    ax.plot([xs, peak_data[i,1]],[ys,peak_data[i,0]], c='steelblue', alpha=0.6, ls='--')
    
                    ax.plot(xs, ys, 'o', c='steelblue', alpha=0.7, mfc='none', ms=6)
                    counter=counter+1
                
        #fig1.savefig(save_image_folder +"/"+filename+".png", dpi=300)
        plt.show()
    

    except Exception as ex:
        print("Unexepected Error, continuing with next dataset, check error log")
        print(''.join(tr.format_tb(sys.exc_info()[-1])))

        error_log.append([q, ''.join(tr.format_tb(sys.exc_info()[-1]))])
    
        continue
    
if len(error_log)>0:    
    print("---------Error log-----------")
    for error in error_log:
        print (error, "\n")
    
#print(error_log)
    
