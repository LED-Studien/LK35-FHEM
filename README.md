# LK35-FHEM
FHEM module to control LK35 Wifi LED-Controller or compatible products from Sunricher

# Using
upload file into FHEM module directory
change file owner to FHEM (Gruppe dialout): chown fhem:dialout ./32_LK35.pm
change permissions: chmod 0775 ./32_LK35.pm

## Definition in fhem.cfg
#for RGBW controller

define Wohnzimmer LK35 RGBW <IP>
  
#for CCT controller (warmwhite/coldwhite)

define Kueche LK35 CCT <IP>
  
#for simple dimmer

define Flur LK35 DIM <IP>
  
  
## Add it to TabletUI, i.e.

``` html
  <li data-row="2" data-col="1" data-sizex="3" data-sizey="2">
  		<header>Wohnzimmer (RGBW)</header>
  		<div class="cell inline">
  			<div data-type="switch" data-device="Wohnzimmer" class="cell" data-icon="fa-power-off"></div>
  		</div>
  		<div class="cell inline">
  			<div data-type="slider" data-device='Wohnzimmer' class="cell " data-get="brightness" data-set="dim" data-min="0"  data-max="255" data-background-color="#444444"  data-color="#AAAAAA"></div> H
          </div>
  		<div class="cell inline">
  			<div data-type="slider" data-device="Wohnzimmer" class="cell " data-get="R" data-set="R" data-min="0" data-max="255" data-background-color="#770000" data-color="#FF0000"></div> R
  		</div>
  		<div class="cell inline">
  			<div data-type="slider" data-device="Wohnzimmer" class="cell " data-get="G" data-set="G" data-min="0" data-max="255" data-background-color="#007700" data-color="#00FF00"></div> G
  		</div>
  		<div class="cell inline">
  			<div data-type="slider" data-device="Wohnzimmer" class="cell " data-get="B" data-set="B" data-min="0" data-max="255" data-background-color="#000077"  data-color="#0000FF"></div> B
  		</div>
  		<div class="cell inline">
  			<div data-type="slider" data-device="Wohnzimmer" class="cell " data-get="W" data-set="W" data-min="0" data-max="255" data-background-color="#777777"  data-color="#FFFFFF"></div> W
  		</div>
  </li>
  <li data-row="2" data-col="1" data-sizex="4" data-sizey="2">
  		<header>LK35_1 (RGBW)</header>
  		<div class="cell inline">
  			<div data-type="switch" data-device="LK35_1" class="cell" data-icon="fa-power-off"></div>
  		</div>
  		<div class="cell inline">
  			<div data-type="slider" data-device='LK35_1' class="cell " data-get="brightness" data-set="dim" data-min="0"  data-max="255" data-background-color="#444444"  data-color="#AAAAAA"></div> H
      </div>
  		<div data-type="colorwheel" data-device='LK35_1' data-get="RGB" data-set="RGB" class="roundIndicator cell inline"></div>
  		<div class="cell inline">
  			<div data-type="slider" data-device="LK35_1" class="cell " data-get="W" data-set="W" data-min="0" data-max="255" data-background-color="#777777"  data-color="#FFFFFF"></div> W
  		</div>
  </li>
  <li data-row="2" data-col="1" data-sizex="3" data-sizey="2">
      <header>LK35_1 (4-Kanal)</header>
      <div class="cell inline">
        <div data-type="switch" data-device="LK35_1" class="cell" data-icon="fa-power-off"></div>
      </div>
      <div class="cell inline">
        <div data-type="slider" data-device='LK35_1' class="cell " data-get="brightness" data-set="dim" data-min="0"  data-max="255" data-background-color="#444444"  data-color="#AAAAAA"></div> H
      </div>
      <div class="cell inline">
        <div data-type="slider" data-device="LK35_1" class="cell " data-get="R" data-set="R" data-min="0" data-max="255" data-background-color="#777777" data-color="#FFFFFF"></div> 1
      </div>
      <div class="cell inline">
        <div data-type="slider" data-device="LK35_1" class="cell " data-get="G" data-set="G" data-min="0" data-max="255" data-background-color="#777777" data-color="#FFFFFF"></div> 2
      </div>
      <div class="cell inline">
        <div data-type="slider" data-device="LK35_1" class="cell " data-get="B" data-set="B" data-min="0" data-max="255" data-background-color="#777777"  data-color="#FFFFFF"></div> 3
      </div>
      <div class="cell inline">
        <div data-type="slider" data-device="LK35_1" class="cell " data-get="W" data-set="W" data-min="0" data-max="255" data-background-color="#777777"  data-color="#FFFFFF"></div> 4
      </div>
  </li>
  <li data-row="2" data-col="1" data-sizex="2" data-sizey="2">
  		<header>KÃ¼che (CCT)</header>
  		<div class="cell inline">
  			<div data-type="switch" data-device="Kueche" class="cell" data-icon="fa-power-off"></div>
  		</div>
  		<div class="cell inline">
  			<div data-type="slider" data-device='Kueche' class="cell " data-get="brightness" data-set="dim" data-min="0"  data-max="255" data-background-color="#444444"  data-color="#AAAAAA"></div> H
      </div>
  		<div class="cell inline">
  			<div data-type="slider" data-device="Kueche" class="cell " data-get="WW" data-set="WW" data-min="0" data-max="255" data-background-color="#ba9643" data-color="#ffce5b"></div> WW
  		</div>
  		<div class="cell inline">
  			<div data-type="slider" data-device="Kueche" class="cell " data-get="CW" data-set="CW" data-min="0" data-max="255" data-background-color="#296a9b" data-color="#42a7f4"></div> CW
  		</div>
  		<div class="cell inline">
  			CW <div data-type="slider" data-device="Kueche" class="cell inline horizontal" data-get="CCT" data-set="CCT" data-min="0" data-max="255" data-background-color="#42a7f4"  data-color="#ffce5b"></div> WW
  		</div>
  </li>
  <li data-row="2" data-col="1" data-sizex="1" data-sizey="2">
  		<header>LK35_2 (DIM)</header>
  		<div data-type="switch" data-device="LK35_2" class="cell" data-icon="fa-power-off"></div>
  		<div data-type="slider" data-device='LK35_2' class="cell " data-get="brightness" data-set="dim" data-min="0"  data-max="255" data-background-color="#777777"  data-color="#FFFFFF"></div> H
  </li>
  ```
