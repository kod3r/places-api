
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
        '''Barn Stable     building=stable        '''
        '''Clinic  building=yes    amenity=clinic '''
        '''Comfort Stations        building=yes    amenity=toilet '''
        '''Communications Systems  building=yes    ?      '''
        '''Courthouse      building=yes    amenity=courthouse     '''
        '''Cultural Center building=yes    amenity=community_centre       '''
        '''Dining Hall Cafeteria   building=yes    amenity=food_court     '''
        '''Dormitories/ Barracks   building=dormitory             '''
        '''Entrance Station        building=yes    barrier=entrance       '''
        '''Fire Station    building=yes    amenity=fire_station   '''
        '''Greenhouse      building=greenhouse            '''
        '''Gymnasium       building=yes    leisure=sports_centre  '''
        '''Hogan   building=cabin         '''
        '''Housing Apartment       building=apartments            '''
        '''Housing Cabin   building=cabin         '''
        '''Housing Garage  building=garage        '''
        '''Housing Mobile Home     building=static_caravan        '''
        '''Housing Multi- Family Plex      building=residential           '''
        '''Housing Single Family   building=residential           '''
        '''Housing Support Building        building=residential           '''
        '''Laboratory      building=yes    ?      '''
        '''Laundry building=yes    shop=laundry   '''
        '''Law Enforcement Center  building=yes    amenity=police '''
        '''Library building=yes    amenity=library'''
        '''Lighthouse      building=yes    man_made=lighthouse    '''
        '''Lodge/Motel/Hotel       building=hotel  tourism=hotel   '''
        '''Multi-Purpose   building=yes            '''
        '''Museum Repository       building=yes    tourism=museum '''
        '''Office  building=yes    building=commercial    '''
        '''Other Institutional Uses        building=yes           '''
        '''Post Office     building=yes    amenity=post_office    '''
        '''Power Generation        building=yes    power=station  '''
        '''Pump House Well House   building=yes    man_made=water_well    '''
        '''Restaurant      building=yes    amenity=restaurant     '''
        '''Retail Store    building=yes           '''
        '''School  building=school        '''
        '''School Day Care building=school        '''
        '''School Environmental Education  building=school        '''
        '''Service Shop Maintenance        building=yes           '''
        '''Sewage Treatment    building=yes    man_made=wastewater_plant   '''
        '''Training Center building=yes           '''
        '''Vault Toilets/Pit Toilets '''
        '''   building=yes amenity=toilets toilets:disposal=pitlatrine'''
        '''Visitor Center  '''
        '''   building=yes information=office   tourism=information'''
        '''Visitor Contact Station building=yes           '''
        '''Warehouse Chemical      building=warehouse             '''
        '''Warehouse Equipment Vehicle     building=warehouse             '''
        '''Warehouse Explosive     building=warehouse             '''
        '''Warehouse Fire Cache    building=warehouse             '''
        '''Warehouse Shed Outbuilding      building=warehouse             '''
        '''Warehouse Warehouse     building=warehouse             '''
        '''Warehouses      building=warehouse             '''
        '''Water Treatment building=yes    man_made=water_works   '''

    return tags
