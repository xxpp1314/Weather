//
//  ViewController.swift
//  Weather
//
//  Created by Yinxing Gao on 10/28/21.
//

import UIKit
import RealmSwift
import Alamofire
import SwiftyJSON
import SwiftSpinner
import PromiseKit


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
   
    
    var arrCityInfo: [CityInfo] = [CityInfo]()
    var arrCurrentWeather : [CurrentWeather] = [CurrentWeather]()

    
    @IBOutlet weak var tblView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadCurrentConditions()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrCurrentWeather.count // You will replace this with arrCurrentWeather.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        // replace this with values from arrCurrentWeather array
        let currentWeather = arrCurrentWeather[indexPath.row]
        let text = "\(currentWeather.cityInfoName) \(currentWeather.temp)℉ \(currentWeather.weatherText)"
        cell.textLabel?.text = text
        return cell
    }
    
    
    func loadCurrentConditions(){
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        // Read all the values from realm DB and fill up the arrCityInfo
        // for each city info het the city key and make a NW call to current weather condition
        // wait for all the promises to be fulfilled
        // Once all the promises are fulfilled fill the arrCurrentWeather array
        // call for reload of tableView
        
        do{
            let realm = try Realm()
            let cities = realm.objects(CityInfo.self)
            if cities.count == 0 {
                return
            }
            getAllCurrentWeather(Array(cities)).done { arrCurrentWeather in
                self.arrCurrentWeather = arrCurrentWeather
                self.tblView.reloadData()
            }
            .catch { error in
                    print(error)
                }
        }catch{
            print("Error in reading Database \(error)")
        }
    }
    
    func getAllCurrentWeather(_ cities: [CityInfo] ) -> Promise<[CurrentWeather]> {
            
            var promises: [Promise< CurrentWeather>] = []
            
            for i in 0 ... cities.count - 1 {
                promises.append( getCurrentWeather(cities[i]) )
            }
            
            return when(fulfilled: promises)
            
        }
    
    
    func getCurrentWeather(_ cityKey : CityInfo) -> Promise<CurrentWeather>{
            return Promise<CurrentWeather> { seal -> Void in
                let url = "\(currentConditionURL)\(cityKey.key)?apikey=\(apiKey)" // build URL for current weather here
                
                Alamofire.request(url).responseJSON { response in
                    
                    if response.error != nil {
                        seal.reject(response.error!)
                    }
                                      
                                    
                    let weathers = JSON( response.data!).array

                    guard let firstWeather = weathers!.first else { seal.fulfill(CurrentWeather())
                        return
                    }

                    let currentWeather = CurrentWeather()

                    currentWeather.cityKey = cityKey.key
                    currentWeather.cityInfoName = cityKey.localizedName
                    currentWeather.weatherText = firstWeather["WeatherText"].stringValue
                    currentWeather.epochTime = firstWeather["epochTime"].intValue
                    currentWeather.isDayTime = firstWeather["isDayTime"].boolValue
                    currentWeather.temp = firstWeather["Temperature"]["Metric"]["Value"].intValue

                    
                    seal.fulfill(currentWeather)
                    
                }
            }
    }

}
