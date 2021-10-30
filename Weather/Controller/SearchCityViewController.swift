//
//  SearchCityViewController.swift
//  Weather
//
//  Created by Yinxing Gao on 10/28/21.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftSpinner
import RealmSwift

class SearchCityViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
       
    @IBOutlet weak var tblView: UITableView!
    
    var arrCityInfo : [CityInfo] = [CityInfo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count < 3 {
            return
        }
        arrCityInfo.removeAll()
        getCitiesFromSearch(searchText)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // You will change this to arrCityInfo.count
        return arrCityInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        // You will change this to getr values from arrCityinfo and assign text
        let cityInfo = arrCityInfo[indexPath.row]
        let text = "\(cityInfo.localizedName) \(cityInfo.administrativeID), \(cityInfo.countryLocalizedName)"
        cell.textLabel?.text = text
        
        return cell
    }
    
    func getSearchURL(_ searchText : String) -> String{
        return locationSearchURL + "apikey=" + apiKey + "&q=" + searchText
    }
    
    func getCitiesFromSearch(_ searchText : String) {
        // Network call from there
        let url = getSearchURL(searchText)
        Alamofire.request(url).responseJSON { response in
            if response.error != nil {
                print(response.error?.localizedDescription)
            }
            
            // You will receive JSON array
            // Parse the JSON array
            // Add values in arrCityInfo
            // Reload table with the values
            let cities = JSON(response.data)
            for (_, city):(String, JSON) in cities {
                let cityInfo = CityInfo()
                cityInfo.key = city["Key"].stringValue
                cityInfo.administrativeID = city["AdministrativeArea"]["ID"].stringValue
                cityInfo.countryLocalizedName = city["Country"]["LocalizedName"].stringValue
                cityInfo.localizedName = city["LocalizedName"].stringValue
                cityInfo.type = city["Type"].stringValue
                self.arrCityInfo.append(cityInfo)
            }
            
            self.tblView.reloadData()
        }
        
    }
    
    func doesCityExistInDB(_ symbol : String) -> Bool {
        do{
            let realm = try Realm()
            if realm.object(ofType: CityInfo.self, forPrimaryKey: symbol) != nil { return true }
        
        }catch{
            print("Error in getting values from DB \(error)")
        }
        return false
    }
    
    func addCityinDB(_ cityInfo : CityInfo){
        do{
            let realm = try Realm()
            try realm.write {
                realm.add(cityInfo, update: .modified)
            }
        }catch{
            print("Error in getting values from DB \(error)")
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        // You will get the Index of the city info from here and then add it into the realm Database
        // Once the city is added in the realm DB pop the navigation view controller
        let cityInfo = arrCityInfo[indexPath.row]
        if !doesCityExistInDB(cityInfo.key) {
            addCityinDB(cityInfo)
        }
        self.navigationController?.popViewController(animated: true)
    }

}
