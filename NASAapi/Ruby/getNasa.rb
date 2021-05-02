require "http"
require "json"

class NasaFun
    def self.getAverage(obj)
        avg = ( ( obj['estimated_diameter_min'] + obj['estimated_diameter_max'] ) / 2 )
        return avg.round(5)
    end

    def self.makeObj(obj)
        cad = obj['close_approach_data'][0]
        lo = {
            "Name" => obj['name'] ,
            "ID" => obj['id'] ,
            "PotentiallyHazardous" => obj['is_potentially_hazardous_asteroid'] ,
            "CloseApproachDateTime" => cad['close_approach_date_full'] ,
            "MissDistanceInKM" => (cad['miss_distance']['kilometers']).to_f.round(5) ,
            "AbsoluteMagnitudeH" => obj['absolute_magnitude_h'] ,
            "DiameterInMeters" => NasaFun.getAverage(obj['estimated_diameter']['meters']) ,
            "VelocityInKMpH" => (cad['relative_velocity']['kilometers_per_hour']).to_f.round(5) ,
            "URL" => obj['nasa_jpl_url']
        }
        return lo
    end
end

def makeDate
    hoy = Time.now().to_s.split()[0]
end

def setConfig
    apj = "application/json"
    key = ENV['NASA_API_KEY']  # for using key from environment.
    #key = 'HARD_CODED_KEY_HERE'  if not using environment (line above)
    $url = 'https://api.nasa.gov/neo/rest/v1/feed'
    $hoy = makeDate()
    $msg = "Terminating.  Problem Accessing "+$url+" the below URL for asteroid information:\n"
    $heads = {
        "Content-Type" => apj ,
        "Accept" => apj
    }
    $params = {
        "api_key" => key ,
        "start_date" => $hoy ,
        "end_date" => $hoy
    }
end

def getInfo
    begin
        res = HTTP.get($url, :headers => $heads, :params => $params)
        if not res.status.success?
            raise res
        end
    rescue Exception => err
        puts($msg,err)
        exit
    end
    jrd = JSON.parse(res)
    return jrd['near_earth_objects'][$hoy]
end

def procInfo(resp)
    arr = []
    for r in resp
        arr.push(NasaFun.makeObj(r))
    end
    lo = JSON.dump(arr)
    puts(lo)
end

setConfig()
procInfo(getInfo())