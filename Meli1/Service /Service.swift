//
//  Service.swift
//  Meli1
//
//  Created by Oswaldo Garcia on 11/10/21.
//

import Foundation
import Moya
import RxSwift
import Alamofire
import UIKit


let provider = MoyaProvider<Service>()
var disposeBag = DisposeBag()

enum Service {
    case searchProduct(parameters:[String : Any])
}

// MARK: - TargetType Protocol Implementation
extension Service: TargetType {
    
    var baseURL: URL { URL(string: "https://api.mercadolibre.com/sites/MCO")! }
    
    var path: String {
        switch self {
       
        case .searchProduct(_):
            return "/search"
        }
    }
    
    
    var method: Moya.Method {
        switch self {
        case .searchProduct(_):
            return .get
        }
    }
    
    var task: Task {
        switch self {
        case .searchProduct(let parameters):
            return .requestParameters(parameters:parameters, encoding: URLEncoding.queryString)
        }
    }

    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
    
    
    static func requestService<T: Codable>(service:Service,model:T) -> Observable<T> {
        
        return Observable<T>.create { (observer) -> Disposable in
            UIApplication.shared.activityStartAnimating()
            provider.rx.request(service).subscribe { result in
                switch result {
                case let .success(response):
                    print(response.request!)
                    switch response.statusCode {
                    case 200...299:
                        let path = "results"
                        if let model = try? response.map(T.self, atKeyPath: path, using: JSONDecoder.init(), failsOnEmptyData: false) {
                            UIApplication.shared.activityStopAnimating()
                            observer.onNext(model)
                            observer.onCompleted()
                        }else {
                            print("Error: Something fail creating the model")
                            UIApplication.shared.activityStopAnimating()
                        }
                    default:
                        if let model = try? response.map(RequestErrorModel.self, using: JSONDecoder.init(), failsOnEmptyData: false) {
                            UIApplication.shared.activityStopAnimating()
                            UIApplication.shared.showErrorAlert(model.message ?? "",title: model.error ?? "Error")
                            
                        }else {
                            print("Error: Something fail creating the error model")
                            UIApplication.shared.activityStopAnimating()
                        }
                        
                        print("Error: \(response.statusCode)")
                    }
                        
                    
                case let .failure(error):
                    UIApplication.shared.activityStopAnimating()
                    UIApplication.shared.showErrorAlert(error.localizedDescription)
                    
                    print(error)
                    observer.onError(error)
                    observer.onCompleted()
                }
            }.disposed(by: disposeBag)
            
            return Disposables.create {}
        }
    }
}


