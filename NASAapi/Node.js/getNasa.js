const superagent = require('superagent');
const lodash = require('lodash');

class NasaFun
{
    static getAverage(obj)
    {
        let avg = ( ( obj['estimated_diameter_min'] + obj['estimated_diameter_max'] ) / 2 ) ;
        return lodash.round(avg , 5) ;
    }

    static makeObj(obj)
    {
        let cad = obj['close_approach_data'][0] ;
        let lo = {
            "Name" : obj['name'] ,
            "ID" : obj['id'] ,
            "PotentiallyHazardous" : obj['is_potentially_hazardous_asteroid'] ,
            "CloseApproachDateTime" : cad['close_approach_date_full'] ,
            "MissDistanceInKM" : lodash.round((cad['miss_distance']['kilometers']) , 5 ) ,
            "AbsoluteMagnitudeH" : obj['absolute_magnitude_h'] ,
            "DiameterInMeters" : NasaFun.getAverage(obj['estimated_diameter']['meters']) ,
            "VelocityInKMpH" : lodash.round((cad['relative_velocity']['kilometers_per_hour']) , 5 ) ,
            "URL" : obj['nasa_jpl_url']
        }
        return lo
    }
}

function setConfig()
{
    let apj = "application/json" ;
    let key = process.env.NASA_API_KEY ;
    //let key = 'HARD_CODED_KEY_HERE'  if not using environment (line above)
    url = 'https://api.nasa.gov/neo/rest/v1/feed' ;
    hoy = makeDate() ;
    msg = "Terminating.  Problem Accessing "+url+" for asteroid information:" ;
    heads = {
        "Content-Type": apj,
        "Accept": apj
    };
    params = {
        "api_key": key,
        "start_date": hoy,
        "end_date": hoy
    };
}

function padDate(dp)
{
    // Put this hack in as Date().toISOString() returns UTC as opposed to local time.
    let hack = (dp.length > 1 ) ? (dp) : "0"+dp ;
    return hack ;
}

function makeDate()
{
    rd = new Date().toLocaleString().split(",")[0].split("/") ;
    pd = (rd[2]+"-"+padDate(rd[0])+"-"+padDate(rd[1]) ) ;
    return pd ;
}

async function getInfo()
{
    try
    {
        const res = await superagent.get(url).query(params).set(heads) ;
        return res.body['near_earth_objects'][hoy] ;
    }
    catch (err)
    {
        console.log(msg,"\n",err) ;
        process.exit() ;
    }
}

function procInfo(resp)
{
    let arr = [] ;
    for (let r = 0 ; r < resp.length ; r++)
    {
        arr.push(NasaFun.makeObj(resp[r]))
    }
    console.log(arr) ;
}

setConfig() ;
getInfo().then(resp => procInfo(resp)) ;