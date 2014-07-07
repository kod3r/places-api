
def filterTags(attrs):
    if not attrs:
        return
    tags = {}

    if 'Building_ID' in attrs:
        tags['nps:building_id'] = attrs['Building_ID']

    if 'Common_Name' in attrs:
        tags['name'] = attrs['Common_Name'].title()

    if 'Unit_Code' in attrs:
        tags['nps:alphacode'] = attrs['Unit_Code'].title()

    '''
    Now for the big list!
    '''

    if 'Main_usage_type' in attrs:
        tags['nps:fcat'] = attrs['Main_usage_type'].title()

        '''All Other       building=yes           '''
        if attrs['Main_usage_type'].strip() == 'All Other':
            tags['building'] = 'yes'

        '''Animal Shelter  building=yes    amenity=animal_shelter '''
        if attrs['Main_usage_type'].strip() == 'Animal Shelter':
            tags['building'] = 'yes'
            tags['amenity'] = 'animal_shelter'

        '''Auditorium      building=yes           '''
        if attrs['Main_usage_type'].strip() == 'Auditorium':
            tags['building'] = 'yes'

        '''Barn Stable     building=stable        '''
        if attrs['Main_usage_type'].strip() == 'Barn Stable':
            tags['building'] = 'stable'

        '''Clinic  building=yes    amenity=clinic '''
        if attrs['Main_usage_type'].strip() == 'Clinic':
            tags['building'] = 'yes'
            tags['amenity'] = 'clinic'

        '''Comfort Stations        building=yes    amenity=toilet '''
        if attrs['Main_usage_type'].strip() == 'Comfort Stations':
            tags['building'] = 'yes'
            tags['amenity'] = 'toilet'

        '''Communications Systems  building=yes    ?      '''
        if attrs['Main_usage_type'].strip() == 'Communications Systems':
            tags['building'] = 'yes'

        '''Courthouse      building=yes    amenity=courthouse     '''
        if attrs['Main_usage_type'].strip() == 'Courthouse':
            tags['building'] = 'yes'
            tags['amenity'] = 'courthouse'

        '''Cultural Center building=yes    amenity=community_centre       '''
        if attrs['Main_usage_type'].strip() == 'Cultural Center':
            tags['building'] = 'yes'
            tags['amenity'] = 'community_centre'

        '''Dining Hall Cafeteria   building=yes    amenity=food_court     '''
        if attrs['Main_usage_type'].strip() == 'Dining Hall Cafeteria':
            tags['building'] = 'yes'
            tags['amenity'] = 'food_court'

        '''Dormitories/ Barracks   building=dormitory             '''
        if attrs['Main_usage_type'].strip() == 'Dormitories/ Barracks':
            tags['building'] = 'dormitory'

        '''Entrance Station        building=yes    barrier=entrance       '''
        if attrs['Main_usage_type'].strip() == 'Entrance Station':
            tags['building'] = 'yes'
            tags['barrier'] = 'entrance'

        '''Fire Station    building=yes    amenity=fire_station   '''
        if attrs['Main_usage_type'].strip() == 'Fire Station':
            tags['building'] = 'yes'
            tags['amenity'] = 'fire_station'

        '''Greenhouse      building=greenhouse            '''
        if attrs['Main_usage_type'].strip() == 'Greenhouse':
            tags['building'] = 'greenhouse'

        '''Gymnasium       building=yes    leisure=sports_centre  '''
        if attrs['Main_usage_type'].strip() == 'Gymnasium':
            tags['building'] = 'yes'
            tags['leisure'] = 'sports_centre'

        '''Hogan   building=cabin         '''
        if attrs['Main_usage_type'].strip() == 'Hogan':
            tags['building'] = 'cabin'

        '''Housing Apartment       building=apartments            '''
        if attrs['Main_usage_type'].strip() == 'Housing Apartment':
            tags['building'] = 'apartments'

        '''Housing Cabin   building=cabin         '''
        if attrs['Main_usage_type'].strip() == 'Housing Cabin':
            tags['building'] = 'cabin'

        '''Housing Garage  building=garage        '''
        if attrs['Main_usage_type'].strip() == 'Housing Garage':
            tags['building'] = 'garage'

        '''Housing Mobile Home     building=static_caravan        '''
        if attrs['Main_usage_type'].strip() == 'Housing Mobile Home':
            tags['building'] = 'static_caravan'

        '''Housing Multi- Family Plex      building=residential           '''
        if attrs['Main_usage_type'].strip() == 'Housing Multi- Family Plex':
            tags['building'] = 'residential'

        '''Housing Single Family   building=residential           '''
        if attrs['Main_usage_type'].strip() == 'Housing Single Family':
            tags['building'] = 'residential'

        '''Housing Support Building        building=residential           '''
        if attrs['Main_usage_type'].strip() == 'Housing Support Building':
            tags['building'] = 'residential'

        '''Laboratory      building=yes    ?      '''
        if attrs['Main_usage_type'].strip() == 'Laboratory':
            tags['building'] = 'yes'

        '''Laundry building=yes    shop=laundry   '''
        if attrs['Main_usage_type'].strip() == 'Laundry':
            tags['shop'] = 'laundry'
            tags['building'] = 'yes'

        '''Law Enforcement Center  building=yes    amenity=police '''
        if attrs['Main_usage_type'].strip() == 'Law Enforcement Center':
            tags['building'] = 'yes'
            tags['amenity'] = 'police'

        '''Library building=yes    amenity=library '''
        if attrs['Main_usage_type'].strip() == 'Library':
            tags['building'] = 'yes'
            tags['amenity'] = 'library'

        '''Lighthouse      building=yes    man_made=lighthouse    '''
        if attrs['Main_usage_type'].strip() == 'Lighthouse':
            tags['building'] = 'yes'
            tags['man_made'] = 'lighthouse'

        '''Lodge/Motel/Hotel       building=hotel  tourism=hotel   '''
        if attrs['Main_usage_type'].strip() == 'Lodge/Motel/Hotel':
            tags['building'] = 'hotel'
            tags['tourism'] = 'hotel'

        '''Multi-Purpose   building=yes            '''
        if attrs['Main_usage_type'].strip() == 'Multi-Purpose':
            tags['building'] = 'yes'

        '''Museum Repository       building=yes    tourism=museum '''
        if attrs['Main_usage_type'].strip() == 'Museum Repository':
            tags['building'] = 'yes'
            tags['tourism'] = 'museum'

        '''Office  building=yes    building=commercial    '''
        if attrs['Main_usage_type'].strip() == 'Office':
            tags['building'] = 'yes'
            tags['building'] = 'commercial'

        '''Other Institutional Uses        building=yes           '''
        if attrs['Main_usage_type'].strip() == 'Other Institutional Uses':
            tags['building'] = 'yes'

        '''Post Office     building=yes    amenity=post_office    '''
        if attrs['Main_usage_type'].strip() == 'Post Office':
            tags['building'] = 'yes'
            tags['amenity'] = 'post_office'

        '''Power Generation        building=yes    power=station  '''
        if attrs['Main_usage_type'].strip() == 'Power Generation':
            tags['building'] = 'yes'
            tags['power'] = 'station'

        '''Pump House Well House   building=yes    man_made=water_well    '''
        if attrs['Main_usage_type'].strip() == 'Pump House Well House':
            tags['building'] = 'yes'
            tags['man_made'] = 'water_well'

        '''Restaurant      building=yes    amenity=restaurant     '''
        if attrs['Main_usage_type'].strip() == 'Restaurant':
            tags['building'] = 'yes'
            tags['amenity'] = 'restaurant'

        '''Retail Store    building=yes           '''
        if attrs['Main_usage_type'].strip() == 'Retail Store':
            tags['building'] = 'yes'

        '''School  building=school        '''
        if attrs['Main_usage_type'].strip() == 'School':
            tags['building'] = 'school'

        '''School Day Care building=school        '''
        if attrs['Main_usage_type'].strip() == 'School Day Care':
            tags['building'] = 'school'

        '''Service Shop Maintenance        building=yes           '''
        if attrs['Main_usage_type'].strip() == 'Service Shop Maintenance':
            tags['building'] = 'yes'

        '''Sewage Treatment    building=yes    man_made=wastewater_plant   '''
        if attrs['Main_usage_type'].strip() == 'Sewage Treatment':
            tags['building'] = 'yes'
            tags['man_made'] = 'wastewater_plant'

        '''Training Center building=yes           '''
        if attrs['Main_usage_type'].strip() == 'Training Center':
            tags['building'] = 'yes'

        '''Vault Toilets/Pit Toilets '''
        if attrs['Main_usage_type'].strip() == 'Vault Toilets/Pit Toilets':
            tags['building'] = 'yes'
            tags['amenity'] = ' toilets'
            tags['toilets:disposal'] = 'pitlatrine'

        '''Visitor Center  '''
        if attrs['Main_usage_type'].strip() == 'Visitor Center':
            tags['building'] = 'yes'
            tags['information'] = 'office'
            tags['tourism'] = 'information'

        '''Visitor Contact Station building=yes           '''
        if attrs['Main_usage_type'].strip() == 'Visitor Contact Station':
            tags['building'] = 'yes'

        '''Warehouse Chemical      building'] = 'warehouse' '''
        if attrs['Main_usage_type'].strip() == 'Warehouse Chemical':
            tags['building'] = 'warehouse'

        '''Warehouse Equipment Vehicle     building=warehouse             '''
        if attrs['Main_usage_type'].strip() == 'Warehouse Equipment Vehicle':
            tags['building'] = 'warehouse'

        '''Warehouse Explosive     building=warehouse             '''
        if attrs['Main_usage_type'].strip() == 'Warehouse Explosive':
            tags['building'] = 'warehouse'

        '''Warehouse Fire Cache    building=warehouse             '''
        if attrs['Main_usage_type'].strip() == 'Warehouse Fire Cache':
            tags['building'] = 'warehouse'

        '''Warehouse Shed Outbuilding      building=warehouse             '''
        if attrs['Main_usage_type'].strip() == 'Warehouse Shed Outbuilding':
            tags['building'] = 'warehouse'

        '''Warehouse Warehouse     building=warehouse             '''
        if attrs['Main_usage_type'].strip() == 'Warehouse Warehouse':
            tags['building'] = 'warehouse'

        '''Warehouses      building=warehouse             '''
        if attrs['Main_usage_type'].strip() == 'Warehouses':
            tags['building'] = 'warehouse'

        '''Water Treatment building=yes    man_made=water_works   '''
        if attrs['Main_usage_type'].strip() == 'Water Treatment building=yes':
            tags['man_made'] = 'water_works'

    return tags
