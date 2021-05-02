from datetime import datetime
import json
import os   # Needed for API Key when not hardcoded; see key variable entries.
import requests

class NasaFun:
    @staticmethod
    def getAverage(obj):
        avg = ( ( obj['estimated_diameter_min'] + obj['estimated_diameter_max'] ) / 2 )
        return round(avg , 5)

    @staticmethod
    def makeObj(obj):
        cad = obj['close_approach_data'][0]
        lo = {
            "Name" : obj['name'] ,
            "ID" : obj['id'] ,
            "PotentiallyHazardous" : obj['is_potentially_hazardous_asteroid'] ,
            "CloseApproachDateTime" : cad['close_approach_date_full'] ,
            "MissDistanceInKM" : round(float(cad['miss_distance']['kilometers']) , 5 ) ,
            "AbsoluteMagnitudeH" : obj['absolute_magnitude_h'] ,
            "DiameterInMeters" : NasaFun.getAverage(obj['estimated_diameter']['meters']) ,
            "VelocityInKMpH" : round(float(cad['relative_velocity']['kilometers_per_hour']) , 5 ) ,
            "URL" : obj['nasa_jpl_url']
        }
        return lo

def makeDate():
    '''Return today's date'''
    return datetime.now().isoformat().split('T')[0]

def setConfig():
    '''Set basic configuration for script execution'''
    global url , hoy , msg , heads , params
    apj = "application/json"
    key = os.environ['NASA_API_KEY']  # for using key from environment.
    #key = 'HARD_CODED_KEY_HERE'  if not using environment (line above)
    url = 'https://api.nasa.gov/neo/rest/v1/feed'
    hoy = makeDate()
    msg = "Terminating.  Problem Accessing "+url+" the below URL for asteroid information:\n"
    heads = {
        "Content-Type" : apj ,
        "Accept" : apj
    }
    params = {
        "api_key" : key ,
        "start_date" : hoy ,
        "end_date" : hoy
    }

def getInfo():
    '''Retrieve Asteroid Information from NASA'''
    try:
        res = requests.get(url, headers=heads, params=params)
        res.raise_for_status()
    except requests.exceptions.HTTPError as err:
        print(msg + str(err))
        quit()
    else:
        jrd = res.json()
        return jrd['near_earth_objects'][hoy]

def procInfo(resp):
    '''Process returned Asteroid information'''
    arr = [
        NasaFun.makeObj(r)
        for r in resp
    ]
    lo = json.dumps(arr)
    print(lo)

if __name__ == "__main__":
    setConfig()
    procInfo(getInfo())