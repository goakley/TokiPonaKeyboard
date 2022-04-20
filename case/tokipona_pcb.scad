pcbsize = [3850,2350];
pcbthickness = 62;
module pcb() {
    scale(1000) {
        translate([-1,1,0]) {
            intersection() {
                translate([0,-3.36,-0.53]) cube(10);
                linear_extrude(height = pcbthickness/1000, convexity = 10) import("map.dxf");
            }
        }
    }
}

headerheight = 250; // the breadboard headers' length for the bottom part
//screwheight = (headerheight + 10) - pcbthickness;
screwheight = 250;
screwhole=74; // M2 screw - https://www.engineersedge.com/hardware/metric-external-thread-sizes1.htm
joythickness = 175;
joyroundness = 720;
joypositions = [ [400,-800], [1400, -500], [2400, -800], [3400, -1900] ];
boxbuffer = 10;
pcbposition = [boxbuffer,boxbuffer];
usbplace = 3400;
wallsize=50;
boxsize=pcbsize+[boxbuffer*2,boxbuffer*2];
// TODO: this
boxheight = screwheight+pcbthickness+joythickness;

module stand(diameter) {
    /*difference() {
        cylinder(screwheight, screwhole*1.5, screwhole*1.5);
        cylinder(screwheight*2, screwhole/2, screwhole/2);
    }*/
    cylinder(screwheight, 100, 100);
    cylinder(boxheight, diameter/2, diameter/2);
}
module standpair() {
    // 1400 1800 // 1690 1404 // 1750 2154
    translate([290,396]) stand(75);
    translate([350,-354]) stand(75);
}
module screw(diameter) {
    difference() {
        cylinder(screwheight, diameter*1.5, diameter*1.5);
        cylinder(screwheight*2, diameter/2, diameter/2);
    }
}
module screwpair() {
    // 1400 1800 // 1690 1404 // 1750 2154
    translate([290,396]) screw(screwhole);
    translate([350,-354]) screw(screwhole);
}


module case() {
    difference() {
        translate([-wallsize,-wallsize,-wallsize]){
            cube([boxsize[0]+wallsize*2,boxsize[1]+wallsize*2,boxheight+wallsize]);
        }
        union() {
            cube([boxsize[0],boxsize[1],boxheight+1]);
        /*
        translate([100+wallsize, 0, 0]) {
        cube([boxsize[0]-2*(100+wallsize),boxsize[1],boxheight+1]);
        }
        translate([0,100+wallsize, 0]) {
        cube([boxsize[0],boxsize[1]-2*3(100+wallsize),boxheight+1]);
        }
        */
        // the usb port
        //translate([usbpos[1]-(wallsize/2),usbpos[0],usbpos[2]]) {
        //    cube([wallsize*2, usbsize[0], boxheight*2]);
        //}
        }
        translate([boxbuffer+usbplace-200,boxsize[1]-1,screwheight]) {
            cube([400,102,10000]);
        }
    }
    for (i = joypositions) {
        translate(pcbposition+[0,pcbsize[1]]+i) standpair();
    }
// support
// TODO: could be a screw hole to hold the lid to the case?
//translate([boxsize[0]/2, boxsize[1]/2, 0]) cylinder(boxheight, 200, 200);
}
case();
//translate([pcbposition[0],pcbposition[1]+pcbsize[1],screwheight]) pcb();
$fn=64;
module bullshit() {
    for (i = [1:4]) {
        translate([0,250*i,0]) stand(70);
    }
    for (i = [1:4]) {
        translate([250,250*i,0]) stand(74);
    }
    for (i = [1:4]) {
        translate([500,250*i,0]) stand(78);
    }
    for (i = [1:4]) {
        translate([750,250*i,0]) screw(70);
    }
    for (i = [1:4]) {
        translate([1000,250*i,0]) screw(74);
    }
    for (i = [1:4]) {
        translate([1250,250*i,0]) screw(78);
    }
}
//bullshit();
echo(screwheight);
echo(boxheight);
