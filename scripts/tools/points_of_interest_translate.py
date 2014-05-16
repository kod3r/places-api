'''
A translation function for the points of interest data set
It is to be used with ogr2osm:
https://github.com/pnorman/ogr2osm
http://wiki.openstreetmap.org/wiki/Ogr2osm

The fields in the dataset are:
ALPHACODE FACILITY  NAME  DESCRIPTIO  TYPE

ALPHACODE:   is the park code, we can keep it
FACILITY:    will be converted to "nps:fcat"
NAME:        will be converted to "name"
DESCRIPTIO:  will be converted to nps:description
TYPE:        will be converted to nps:type 

My big bad list of fcode that we convert:

Ampitheater               amenity=theatre; "theatre:type": "amphi"
Bench                     amenity=bench
Bicycle Rack              amenity=bicycle_parking
Boarding Station          railway=station
Boat Launch               leisure=slipway
Bridge                    bridge=yes
Bridges                   bridge=yes
Building                  building=yes
Buoys                     man_made=buoy
Bus Stop                  highway=bus_stop
Campground                tourism=camp_site
Campsite                  tourism=camp_site; camp_site=pitch
Canoe Access              access=canoe
Cave                      natural=cave_entrance
Clinic                    amenity=clinic
Crosscountry Skiing       piste:type=nordic
Dock                      waterway=dock
Entrance Station          barrier=entrance
Exhibit                   tourism=attraction
Ferry                     amenity=ferry_terminal
Fishing                   leisure=fishing
Food Service              amenity=food_court
Gas Station               amenity=fuel
Gate                      barrier=gate
Grill                     amenity=bbq
Headquarters              building=office
Information               tourism=information
Ladder                    safety_equipment:ladder
Light House               man_made=lighthouse
Lodge                     tourism=hotel
Map                       tourism=information; information=map
Marina                    leisure=marina
Metro Station             railway=subway_entrance
Mile Marker               highway=milemarker
Museum                    tourism=museum
Nature Center             leisure=nature_reserve
Overlook                  tourism=viewpoint
Parasailing Launch        free_flying:site=takeoff
Park Headquarters         building=office
Parking                   amenity=parking
Permit Station            amenity=ranger_station
Picnic Area               tourism=picnic_site
Picnic Table              tourism=picnic_site
Playground                leisure=playground
Point of Interest         tourism=attraction
Pull Off                  highway=rest_area
Pullout                   highway=rest_area
Ranger Station            amenity=ranger_station
Recycling                 amenity=recycling
Restroom                  amenity=toilets
Shelter                   amenity=shelter; building=hut; tourism=camp_site
Shower                    amenity=shower
Sledding                  piste:type=sled
Stable                    building=stable
Store                     shop=general
Swim                      sport=swimming
Telephone                 amenity=telephone
Train Station             railway=station
Trash                     amenity=waste_basket
Vegetation                natural=scrub
Viewpoint                 tourism=viewpoint
Visitor Center            building=yes; information=office; tourism=information
Water                     amenity=drinking_water
Water Shuttle Dock        amenity=ferry_terminal
Wheelchair Accessability  wheelchair=yes
---
Trailhead                 highway=trailhead
Cemetery                  landuse=cemetery
Park                      leisure=park
Waterfall                 waterway=waterfall
Wayside                   tourism=attraction
Historic Building         building=yes; historic=building
Gravesite                 cemetery=grave

Peak                      natural=peak
Fortification             historic=archaeological_site; site_type=fortification; fortification_type=hill_fort
'''

def filterTags(attrs):
    if not attrs:
        return
    tags = {}
        
    if 'ALPHACODE' in attrs:
      tags['nps:alphacode'] = attrs['ROADNAME'].title()

    if 'NAME' in attrs:
      tags['name'] = attrs['NAME'].title()

    if 'DESCRIPTIO' in attrs:
      tags['nps:description'] = attrs['DESCRIPTIO'].title()

    if 'TYPE' in attrs:
      tags['nps:type'] = attrs['TYPE'].title()

    '''
    Now for the big list!
    '''

    if 'FACILITY' in attrs:
      tags['nps:fcat'] = attrs['FACILITY'].title()
      '''Ampitheater               amenity=theatre; "theatre:type": "amphi"'''
      if attrs['FACILITY'].strip() == 'Ampitheater':
        tags['amenity'] = 'theatre'
        tags['theatre:type'] = 'amphi'

      '''Bench                     amenity=bench'''
      if attrs['FACILITY'].strip() == 'Bench':
        tags['amenity'] = 'bench'

      '''Bicycle Rack              amenity=bicycle_parking'''
      if attrs['FACILITY'].strip() == 'Bicycle Rack':
        tags['amenity'] = 'bicycle_parking'

      '''Boarding Station          railway=station'''
      if attrs['FACILITY'].strip() == 'Boarding Station':
        tags['railway'] = 'station'

      '''Boat Launch               leisure=slipway'''
      if attrs['FACILITY'].strip() == 'Boat Launch':
        tags['leisure'] = 'slipway'

      '''Bridge                    bridge=yes'''
      if attrs['FACILITY'].strip() == 'Bridge':
        tags['bridge'] = 'yes'
        
      '''Bridges                   bridge=yes'''
      if attrs['FACILITY'].strip() == 'Bridges':
        tags['bridge'] = 'yes'

      '''Building                  building=yes'''
      if attrs['FACILITY'].strip() == 'Building':
        tags['building'] = 'yes'

      '''Buoys                     man_made=buoy'''
      if attrs['FACILITY'].strip() == 'Buoys':
        tags['man_made'] = 'buoy'

      '''Bus Stop                  highway=bus_stop'''
      if attrs['FACILITY'].strip() == 'Bus Stop':
        tags['highway'] = 'bus_stop'

      '''Campground                tourism=camp_site'''
      if attrs['FACILITY'].strip() == 'Campground':
        tags['tourism'] = 'camp_site'

      '''Campsite                  tourism=camp_site; camp_site=pitch'''
      if attrs['FACILITY'].strip() == 'Campsite':
        tags['tourism'] = 'camp_site'
        tags['camp_site'] = 'pitch'

      '''Canoe Access              access=canoe'''
      if attrs['FACILITY'].strip() == 'Canoe Access':
        tags['access'] = 'canoe'

      '''Cave                      natural=cave_entrance'''
      if attrs['FACILITY'].strip() == 'Cave':
        tags['natural'] = 'cave_entrance'

      '''Clinic                    amenity=clinic'''
      if attrs['FACILITY'].strip() == 'Clinic':
        tags['amenity'] = 'clinic'

      '''Crosscountry Skiing       piste:type=nordic'''
      if attrs['FACILITY'].strip() == 'Crosscountry Skiing':
        tags['piste:type'] = 'nordic'

      '''Dock                      waterway=dock'''
      if attrs['FACILITY'].strip() == 'Dock':
        tags['waterway'] = 'dock'

      '''Entrance Station          barrier=entrance'''
      if attrs['FACILITY'].strip() == 'Entrance Station':
        tags['barrier'] = 'entrance'

      '''Exhibit                   tourism=attraction'''
      if attrs['FACILITY'].strip() == 'Exhibit':
        tags['tourism'] = 'attraction'

      '''Ferry                     amenity=ferry_terminal'''
      if attrs['FACILITY'].strip() == 'Ferry':
        tags['amenity'] = 'ferry_terminal'

      '''Fishing                   leisure=fishing'''
      if attrs['FACILITY'].strip() == 'Fishing':
        tags['leisure'] = 'fishing'

      '''Food Service              amenity=food_court'''
      if attrs['FACILITY'].strip() == 'Food Service':
        tags['amenity'] = 'food_court'

      '''Gas Station               amenity=fuel'''
      if attrs['FACILITY'].strip() == 'Gas Station':
        tags['amenity'] = 'fuel'

      '''Gate                      barrier=gate'''
      if attrs['FACILITY'].strip() == 'Gate':
        tags['barrier'] = 'gate'

      '''Grill                     amenity=bbq'''
      if attrs['FACILITY'].strip() == 'Grill':
        tags['amenity'] = 'bbq'

      '''Headquarters              building=office'''
      if attrs['FACILITY'].strip() == 'Headquarters':
        tags['building'] = 'office'

      '''Information               tourism=information'''
      if attrs['FACILITY'].strip() == 'Information':
        tags['tourism'] = 'information'

      '''Ladder                    safety_equipment:ladder'''
      if attrs['FACILITY'].strip() == 'Ladder':
        tags['safety_equipment'] = 'ladder'

      '''Light House               man_made=lighthouse'''
      if attrs['FACILITY'].strip() == 'Light House':
        tags['man_made'] = 'lighthouse'

      '''Lodge                     tourism=hotel'''
      if attrs['FACILITY'].strip() == 'Lodge':
        tags['tourism'] = 'hotel'

      '''Map                       tourism=information; information=map'''
      if attrs['FACILITY'].strip() == 'Map':
        tags['tourism'] = 'information'
        tags['information'] = 'map'

      '''Marina                    leisure=marina'''
      if attrs['FACILITY'].strip() == 'Marina ':
        tags['leisure'] = 'marina'

      '''Metro Station             railway=subway_entrance'''
      if attrs['FACILITY'].strip() == 'Metro Station':
        tags['railway'] = 'subway_entrance'

      '''Mile Marker               highway=milemarker'''
      if attrs['FACILITY'].strip() == 'Mile Marker':
        tags['highway'] = 'milemarker'

      '''Museum                    tourism=museum'''
      if attrs['FACILITY'].strip() == 'Museum':
        tags['tourism'] = 'museum'

      '''Nature Center             leisure=nature_reserve'''
      if attrs['FACILITY'].strip() == 'Nature Center':
        tags['leisure'] = 'nature_reserve'

      '''Overlook                  tourism=viewpoint'''
      if attrs['FACILITY'].strip() == 'Overlook':
        tags['tourism'] = 'viewpoint'

      '''Parasailing Launch        free_flying:site=takeoff'''
      if attrs['FACILITY'].strip() == 'Parasailing Launch':
        tags['free_flying:takeoff'] = 'viewpoint'

      '''Park Headquarters         building=office'''
      if attrs['FACILITY'].strip() == 'Park Headquarters':
        tags['building'] = 'office'

      '''Parking                   amenity=parking'''
      if attrs['FACILITY'].strip() == 'Parking':
        tags['amenity'] = 'parking'

      '''Permit Station            amenity=ranger_station'''
      if attrs['FACILITY'].strip() == 'Permit Station':
        tags['amenity'] = 'ranger_station'

      '''Picnic Area               tourism=picnic_site'''
      if attrs['FACILITY'].strip() == 'Picnic Area':
        tags['tourism'] = 'picnic_site'

      '''Picnic Table              tourism=picnic_site'''
      if attrs['FACILITY'].strip() == 'Picnic Table':
        tags['tourism'] = 'picnic_site'

      '''Playground                leisure=playground'''
      if attrs['FACILITY'].strip() == 'Playground':
        tags['leisure'] = 'playground'

      '''Point of Interest         tourism=attraction'''
      if attrs['FACILITY'].strip() == 'Point of Interest':
        tags['tourism'] = 'attraction'

      '''Pull Off                  highway=rest_area'''
      if attrs['FACILITY'].strip() == 'Pull Off':
        tags['highway'] = 'rest_area'

      '''Pullout                   highway=rest_area'''
      if attrs['FACILITY'].strip() == 'Pullout':
        tags['highway'] = 'rest_area'

      '''Ranger Station            amenity=ranger_station'''
      if attrs['FACILITY'].strip() == 'Ranger Station':
        tags['amenity'] = 'ranger_station'

      '''Recycling                 amenity=recycling'''
      if attrs['FACILITY'].strip() == 'Recycling':
        tags['amenity'] = 'recycling'

      '''Restroom                  amenity=toilets'''
      if attrs['FACILITY'].strip() == 'Restroom':
        tags['amenity'] = 'toilets'

      '''Shelter                   amenity=shelter; building=hut; tourism=camp_site'''
      if attrs['FACILITY'].strip() == 'Shelter':
        tags['amenity'] = 'shelter'
        tags['building'] = 'hut'
        tags['tourism'] = 'camp_site'

      '''Shower                    amenity=shower'''
      if attrs['FACILITY'].strip() == 'Shower':
        tags['amenity'] = 'shower'

      '''Sledding                  piste:type=sled'''
      if attrs['FACILITY'].strip() == 'Sledding':
        tags['piste:type'] = 'sled'

      '''Stable                    building=stable'''
      if attrs['FACILITY'].strip() == 'Stable':
        tags['building'] = 'stable'

      '''Store                     shop=general'''
      if attrs['FACILITY'].strip() == 'Store':
        tags['shop'] = 'general'

      '''Swim                      sport=swimming'''
      if attrs['FACILITY'].strip() == 'Swim':
        tags['sport'] = 'swimming'

      '''Telephone                 amenity=telephone'''
      if attrs['FACILITY'].strip() == 'Telephone':
        tags['amenity'] = 'telephone'

      '''Train Station             railway=station'''
      if attrs['FACILITY'].strip() == 'Train Station':
        tags['railway'] = 'station'

      '''Trash                     amenity=waste_basket'''
      if attrs['FACILITY'].strip() == 'Trash':
        tags['amenity'] = 'waste_basket'

      '''Vegetation                natural=scrub'''
      if attrs['FACILITY'].strip() == 'Vegetation':
        tags['natural'] = 'scrub'

      '''Viewpoint                 tourism=viewpoint'''
      if attrs['FACILITY'].strip() == 'Viewpoint':
        tags['tourism'] = 'viewpoint'

      '''Visitor Center            building=yes; information=office; tourism=information'''
      if attrs['FACILITY'].strip() == 'Visitor Center':
        tags['building'] = 'yes'
        tags['information'] = 'office'
        tags['tourism'] = 'information'

      '''Water                     amenity=drinking_water'''
      if attrs['FACILITY'].strip() == 'Water':
        tags['amenity'] = 'drinking_water'

      '''Water Shuttle Dock        amenity=ferry_terminal'''
      if attrs['FACILITY'].strip() == 'Water Shuttle Dock':
        tags['amenity'] = 'ferry_terminal'

      '''Wheelchair Accessability  wheelchair=yes'''
      if attrs['FACILITY'].strip() == 'Wheelchair Accessability':
        tags['wheelchair'] = 'yes'
        
      '''---'''
      
      '''Trailhead                 highway=trailhead'''
      if attrs['FACILITY'].strip() == 'Trailhead':
        tags['highway'] = 'trailhead'
        
      '''Cemetery                  landuse=cemetery'''
      if attrs['FACILITY'].strip() == 'Cemetery':
        tags['landuse'] = 'cemetery'
        
      '''Park                      leisure=park'''
      if attrs['FACILITY'].strip() == 'Park':
        tags['leisure'] = 'park'
        
      '''Waterfall                 waterway=waterfall'''
      if attrs['FACILITY'].strip() == 'Waterfall':
        tags['waterway'] = 'waterfall'
        
      '''Wayside                   tourism=attraction'''
      if attrs['FACILITY'].strip() == 'Wayside':
        tags['tourism'] = 'attraction'
        
      '''Historic Building         building=yes; historic=building'''
      if attrs['FACILITY'].strip() == 'Historic Building':
        tags['building'] = 'yes'
        tags['historic'] = 'building'
        
      '''Gravesite                 cemetery=grave'''
      if attrs['FACILITY'].strip() == 'building':
        tags['cemetery'] = 'grave'

      '''Peak                      natural=peak'''
      if attrs['FACILITY'].strip() == 'Peak':
        tags['natural'] = 'peak'   
        
      '''Fortification             historic=archaeological_site; site_type=fortification; fortification_type=hill_fort'''
      if attrs['FACILITY'].strip() == 'Fortification':
        tags['historic'] = 'archaeological_site'
        tags['site_type'] = 'fortification'
        tags['fortification_type'] = 'hill_fort'
        
    return tags
