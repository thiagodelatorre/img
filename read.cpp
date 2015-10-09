/*
 #
 #  File        : tutorial.cpp
 #                ( C++ source file )
 #
 #  Description : View the color profile of an image, along the X-axis.
 #                This file is a part of the CImg Library project.
 #                ( http://cimg.eu )
 #
 #  Copyright   : David Tschumperle
 #                ( http://tschumperle.users.greyc.fr/ )
 #
 #  License     : CeCILL v2.0
 #                ( http://www.cecill.info/licences/Licence_CeCILL_V2-en.html )
 #
 #  This software is governed by the CeCILL  license under French law and
 #  abiding by the rules of distribution of free software.  You can  use,
 #  modify and/ or redistribute the software under the terms of the CeCILL
 #  license as circulated by CEA, CNRS and INRIA at the following URL
 #  "http://www.cecill.info".
 #
 #  As a counterpart to the access to the source code and  rights to copy,
 #  modify and redistribute granted by the license, users are provided only
 #  with a limited warranty  and the software's author,  the holder of the
 #  economic rights,  and the successive licensors  have only  limited
 #  liability.
 #
 #  In this respect, the user's attention is drawn to the risks associated
 #  with loading,  using,  modifying and/or developing or reproducing the
 #  software by the user in light of its specific status of free software,
 #  that may mean  that it is complicated to manipulate,  and  that  also
 #  therefore means  that it is reserved for developers  and  experienced
 #  professionals having in-depth computer knowledge. Users are therefore
 #  encouraged to load and test the software's suitability as regards their
 #  requirements in conditions enabling the security of their systems and/or
 #  data to be ensured and,  more generally, to use and operate it in the
 #  same conditions as regards security.
 #
 #  The fact that you are presently reading this means that you have had
 #  knowledge of the CeCILL license and that you accept its terms.
 #
*/

// Include CImg library file and use its main namespace
#include "CImg/CImg.h"
#include <iostream>
#include <unordered_map>
using namespace cimg_library;
using namespace std;

#ifndef cimg_imagepath
#define cimg_imagepath "img/"
#endif

// Main procedure
//----------------
int main(int argc,char **argv) {

  // Define program usage and read command line parameters
  //-------------------------------------------------------

  // Display program usage, when invoked from the command line with option '-h'.
  //cimg_usage("View the color profile of an image along the X axis");

  // Read image filename from the command line (or set it to "img/parrot.ppm" if option '-i' is not provided).
  const char* file_i = cimg_option("-i",cimg_imagepath "default1.jpg","Input image");

  // Read pre-blurring variance from the command line (or set it to 1.0 if option '-blur' is not provided).
  //const double sigma = cimg_option("-blur",1.0,"Variance of gaussian pre-blurring");

  // Init variables
  //----------------

  // Load an image, transform it to a color image (if necessary) and blur it with the standard deviation sigma.
  const CImg<unsigned char> image = CImg<>(file_i);//.normalize(0,255).blur((float)sigma).resize(-100,-100,1,3);

  // Create two display window, one for the image, the other for the color profile.
  CImgDisplay
    main_disp(image,"Color image (Try to move mouse pointer over)",0);
//    draw_disp(500,400,"Color profile of the X-axis",0);

  // Define colors used to plot the profile, and a hatch to draw the vertical line
  unsigned int hatch = 0xF0F0F0F0;
  const unsigned char
    red[]   = { 255,0,0 },
    green[] = { 0,255,0 },
    blue [] = { 0,0,255 },
    black[] = { 0,0,0 };

    // Enter event loop. This loop ends when one of the two display window is closed or
    // when the keys 'ESC' or 'Q' are pressed.
int x,y;
unsigned int val_red, val_green, val_blue;
unsigned long key;

int white=0;
unordered_map<unsigned long,int> m;


cimg_forXY(image,x,y) { 

val_red =image(x,y,0);val_green=image(x,y,1);val_blue=image(x,y,2);

key = val_red*1000000+val_green*1000+val_blue;

m[key]++;
}

for(unordered_map<unsigned long,int> it=m.begin();
	it != m.end(); it++){
cout << it.first << '\t' << it.second << endl;

}

getchar();
exit(0);

    return 0;
}
